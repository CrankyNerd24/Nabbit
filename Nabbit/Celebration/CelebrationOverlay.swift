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

/// Paper confetti in the theme's colors, drawn on a canvas.
private struct ConfettiView: View {
    let size: Celebration.Size
    let colors: [Color]
    @State private var start = Date.now
    @State private var pieces: [Piece] = []

    private struct Piece {
        var x, y, vx, vy, spin, width, height: Double
        var color: Color
    }

    var body: some View {
        let duration = CelebrationOverlay.duration(for: size)
        TimelineView(.animation) { timeline in
            Canvas { context, canvas in
                let t = timeline.date.timeIntervalSince(start)
                guard t < duration else { return }
                // Fades over the last 40%.
                let fade = min(1, max(0, (duration - t) / (duration * 0.4)))
                for piece in pieces {
                    var note = context
                    note.opacity = fade
                    note.translateBy(x: piece.x * canvas.width + piece.vx * t,
                                     y: piece.y * canvas.height + piece.vy * t + 0.5 * 1400 * t * t)
                    note.rotate(by: .radians(piece.spin * t))
                    let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height)
                    note.fill(Path(rect), with: .color(piece.color))
                }
            }
        }
        .onAppear {
            start = .now
            pieces = (0..<count).map { _ in makePiece() }
        }
    }

    private var count: Int {
        switch size {
        case .small: 24
        case .medium: 70
        case .big, .clearBoard: 160
        }
    }

    private func makePiece() -> Piece {
        let color = colors.randomElement() ?? .orange
        switch size {
        case .small, .medium:
            // A burst up from the bottom, where the banner sits.
            let power = size == .small ? 0.7 : 1.0
            return Piece(x: 0.5 + .random(in: -0.08...0.08), y: 0.85,
                         vx: .random(in: -420...420) * power, vy: .random(in: -1300 ... -700) * power,
                         spin: .random(in: -12...12), width: .random(in: 6...11), height: .random(in: 8...14),
                         color: color)
        case .big, .clearBoard:
            // A shower across the whole screen.
            return Piece(x: .random(in: 0...1), y: .random(in: -0.15...0),
                         vx: .random(in: -120...120), vy: .random(in: 0...350),
                         spin: .random(in: -10...10), width: .random(in: 7...12), height: .random(in: 9...16),
                         color: color)
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
