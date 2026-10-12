import SwiftUI

/// A big square note, the basic tap target throughout the app.
struct StickyNote: View {
    let text: String
    let fill: ThemeColor
    /// Smaller note for the Again? strip.
    var compact = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // At accessibility text sizes the note grows to fit instead of cutting the text off.
        let large = typeSize.isAccessibilitySize
        Text(text)
            .font(compact ? .headline : .title2.bold())
            .multilineTextAlignment(.center)
            .lineLimit(large ? nil : 2)
            .minimumScaleFactor(large ? 1 : 0.7)
            .fixedSize(horizontal: false, vertical: large)
            .foregroundStyle(fill.text.color)
            .padding(12)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: compact ? nil : 110)
            .frame(width: compact && !large ? 150 : nil, height: compact && !large ? 80 : nil)
            .frame(minWidth: compact ? 150 : nil, minHeight: compact ? 80 : nil)
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
    /// Two notes per row, or one at accessibility text sizes so the words fit.
    static func columns(for typeSize: DynamicTypeSize) -> [GridItem] {
        let count = typeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
}

#Preview {
    StickyNote(text: "Pick up", fill: Theme.standard.tap1)
        .padding()
}
