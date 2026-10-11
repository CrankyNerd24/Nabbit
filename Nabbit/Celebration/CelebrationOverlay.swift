import SwiftUI

/// Drawn over Home for under 1.5 seconds. Never takes a tap.
struct CelebrationOverlay: View {
    let celebration: Celebration
    let theme: Theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static func duration(for size: Celebration.Size) -> Double {
        switch size {
        case .small: 0.8
        case .medium: 1.1
        case .big, .clearBoard: 1.4
        }
    }

    var body: some View {
        ZStack {
            if celebration.size == .clearBoard {
                ClearBoardView(theme: theme)
            }
            if reduceMotion {
                FlashView(color: theme.done.color, size: celebration.size)
            } else {
                ConfettiView(size: celebration.size, colors: [
                    theme.tap1.color, theme.tap2.color, theme.tap3.color, theme.alert.color, theme.done.color,
                ])
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// Paper confetti in the theme's colors: plain shapes, each animated from start to end.
private struct ConfettiView: View {
    let size: Celebration.Size
    let colors: [Color]
    @State private var pieces: [Piece] = []

    fileprivate struct Piece: Identifiable {
        let id = UUID()
        let start: CGPoint
        let end: CGPoint
        let spin: Double
        let width: Double
        let height: Double
        let color: Color
        let falls: Bool
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPiece(piece: piece, duration: CelebrationOverlay.duration(for: size))
                }
            }
            .onAppear {
                pieces = (0..<count).map { _ in makePiece(in: proxy.size) }
            }
        }
    }

    private var count: Int {
        switch size {
        case .small: 24
        case .medium: 70
        case .big, .clearBoard: 160
        }
    }

    private func makePiece(in area: CGSize) -> Piece {
        let color = colors.randomElement() ?? .orange
        let width = Double.random(in: 7...12)
        let height = Double.random(in: 9...16)
        switch size {
        case .small, .medium:
            // A burst up and out from the bottom, where the banner sits.
            let power = size == .small ? 0.6 : 1.0
            let start = CGPoint(x: area.width * (0.5 + .random(in: -0.06...0.06)), y: area.height * 0.85)
            let end = CGPoint(x: start.x + area.width * .random(in: -0.5...0.5) * power,
                              y: start.y - area.height * .random(in: 0.3...0.75) * power)
            return Piece(start: start, end: end, spin: .random(in: -9...9),
                         width: width, height: height, color: color, falls: false)
        case .big, .clearBoard:
            // A shower down the whole screen.
            let x = area.width * .random(in: 0...1)
            let start = CGPoint(x: x, y: -area.height * .random(in: 0...0.25))
            let end = CGPoint(x: x + .random(in: -80...80), y: area.height * .random(in: 0.7...1.1))
            return Piece(start: start, end: end, spin: .random(in: -9...9),
                         width: width, height: height, color: color, falls: true)
        }
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiView.Piece
    let duration: Double
    @State private var launched = false

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: piece.width, height: piece.height)
            .animation(piece.falls ? .easeIn(duration: duration) : .easeOut(duration: duration)) {
                $0.rotationEffect(.radians(launched ? piece.spin : 0))
                    .position(launched ? piece.end : piece.start)
            }
            // Holds full color, then fades over the last 40%.
            .animation(.easeIn(duration: duration * 0.4).delay(duration * 0.6)) {
                $0.opacity(launched ? 0 : 1)
            }
            .task {
                // After the first frame, so the move animates from the start point.
                launched = true
            }
    }
}

/// Reduce Motion: a quick wash of the Done color instead of confetti.
private struct FlashView: View {
    let color: Color
    let size: Celebration.Size
    @State private var opacity = 0.0

    var body: some View {
        color
            .opacity(opacity)
            .onAppear {
                opacity = size == .small ? 0.35 : 0.6
                withAnimation(.easeOut(duration: CelebrationOverlay.duration(for: size))) {
                    opacity = 0
                }
            }
    }
}

/// The whole day is done: an empty fridge door.
private struct ClearBoardView: View {
    let theme: Theme
    @State private var opacity = 1.0

    var body: some View {
        ZStack {
            theme.done.color
            VStack(spacing: 28) {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.done.text.color, lineWidth: 6)
                    .frame(width: 180, height: 260)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(theme.done.text.color)
                            .frame(width: 8, height: 70)
                            .padding(.leading, 20)
                    }
                Text("Clear board.\nNothing left today.")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(theme.done.text.color)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
                opacity = 0
            }
        }
    }
}

/// A done note lifts off its corner and floats away.
struct PeelEffect: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(-18 * progress), anchor: .topTrailing)
            .scaleEffect(1 - 0.15 * progress, anchor: .topTrailing)
            .offset(x: 80 * progress, y: -40 * progress)
            .opacity(1 - progress)
    }
}

extension AnyTransition {
    static var peel: AnyTransition {
        .asymmetric(insertion: .opacity,
                    removal: .modifier(active: PeelEffect(progress: 1), identity: PeelEffect(progress: 0)))
    }
}
