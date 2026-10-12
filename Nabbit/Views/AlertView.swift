import SwiftUI

/// Full screen, theme-colored, task in huge text, three buttons only.
struct AlertView: View {
    let reminder: Reminder
    let theme: Theme
    let onAction: (ReminderAction) -> Void

    var body: some View {
        let ink = theme.alert.text.color
        VStack(spacing: 20) {
            Spacer()
            Text(reminder.text)
                .font(.system(size: 64, weight: .black))
                .minimumScaleFactor(0.4)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                // VoiceOver lands on the task first when the alert opens.
                .accessibilityAddTraits(.isHeader)
                .accessibilitySortPriority(1)
            Text(Nudges.body(for: reminder, step: Nudges.step(for: reminder)))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Spacer()

            Button {
                onAction(.done)
            } label: {
                Text(ReminderAction.done.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(theme.done.text.color)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(theme.done.color, in: .rect(cornerRadius: 16))
                    .overlay {
                        // Outlined when the Done color sits too close to the alert color.
                        if theme.done.contrast(with: theme.alert) < 3 {
                            RoundedRectangle(cornerRadius: 16).stroke(theme.alert.text.color, lineWidth: 3)
                        }
                    }
            }
            .buttonStyle(NoteButtonStyle())

            HStack(spacing: 12) {
                secondary(.snooze15)
                secondary(.tonight)
            }
        }
        .padding(24)
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.alert.color.ignoresSafeArea())
    }

    private func secondary(_ action: ReminderAction) -> some View {
        Button {
            onAction(action)
        } label: {
            Text(action.title)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, minHeight: 64)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.alert.text.color, lineWidth: 3))
                .contentShape(.rect)
        }
        .buttonStyle(NoteButtonStyle())
    }
}
