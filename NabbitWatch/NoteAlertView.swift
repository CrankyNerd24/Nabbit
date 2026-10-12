import SwiftUI

/// The watch's version of the full-screen alert: the task in big text and three buttons.
struct NoteAlertView: View {
    let note: WatchSnapshot.Note
    let theme: Theme
    let onAction: (ReminderAction) -> Void

    private var fill: ThemeColor { theme.alert }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(note.text)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(fill.text.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)

                button(.done, fill: theme.done)
                HStack(spacing: 8) {
                    button(.snooze15, fill: theme.tap1)
                    button(.tonight, fill: theme.tap2)
                }
            }
        }
        .containerBackground(fill.color.gradient, for: .navigation)
    }

    private func button(_ action: ReminderAction, fill: ThemeColor) -> some View {
        Button { onAction(action) } label: {
            Text(action.title)
                .font(.headline)
                .foregroundStyle(fill.text.color)
                .frame(maxWidth: .infinity, minHeight: action == .done ? 48 : 40)
        }
        .buttonStyle(.plain)
        .background(fill.color, in: .rect(cornerRadius: 10))
    }
}
