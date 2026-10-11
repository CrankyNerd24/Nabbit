import SwiftUI

/// A big square note, the basic tap target throughout the app.
struct StickyNote: View {
    let text: String
    let fill: ThemeColor
    /// Smaller note for the Again? strip.
    var compact = false

    var body: some View {
        Text(text)
            .font(compact ? .headline : .title2.bold())
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .foregroundStyle(fill.text.color)
            .padding(12)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? nil : 110)
            .frame(width: compact ? 150 : nil, height: compact ? 80 : nil)
            .background(fill.color, in: .rect(cornerRadius: 6))
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }
}

/// Presses a note down slightly so the tap registers.
struct NoteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

enum NoteGrid {
    static let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
}

#Preview {
    StickyNote(text: "Pick up", fill: Theme.ember.tap1)
        .padding()
}
