import SwiftData
import SwiftUI

/// Due today and slipped, then what's coming up. Tap a note when it's done.
struct TodayList: View {
    let reminders: [Reminder]
    let theme: Theme
    let onAction: (Reminder, ReminderAction) -> Void
    let onRemove: (Reminder) -> Void

    var body: some View {
        // Redraws each minute so notes flip to slipped on time.
        TimelineView(.everyMinute) { context in
            let tomorrow = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: context.date) ?? context.date)
            let today = reminders.filter { $0.dueDate < tomorrow }
            let later = reminders.filter { $0.dueDate >= tomorrow }.prefix(5)

            VStack(alignment: .leading, spacing: 20) {
                if !today.isEmpty {
                    section("Today", footer: "Tap when it's done. Press and hold for more.") {
                        ForEach(today) { row($0, time: $0.dueDate.formatted(date: .omitted, time: .shortened)) }
                    }
                }
                if !later.isEmpty {
                    section("Coming up") {
                        ForEach(Array(later)) { row($0, time: $0.dueDate.dueDescription(from: context.date)) }
                    }
                }
            }
        }
    }

    private func section<Rows: View>(_ title: String, footer: String? = nil,
                                     @ViewBuilder rows: () -> Rows) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            rows()
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func row(_ reminder: Reminder, time: String) -> some View {
        let slipped = reminder.isSlipped
        let fill = slipped ? theme.alert : theme.tap3
        return Button {
            onAction(reminder, .done)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(slipped ? "Slipped: \(reminder.text)" : reminder.text)
                    .font(.headline)
                Spacer(minLength: 8)
                Text(time)
                    .font(.subheadline)
            }
            .foregroundStyle(fill.text.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(fill.color, in: .rect(cornerRadius: 6))
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
        }
        .buttonStyle(NoteButtonStyle())
        .accessibilityHint("Marks it done")
        .contextMenu {
            Button(ReminderAction.snooze15.title, systemImage: "clock") { onAction(reminder, .snooze15) }
            Button(ReminderAction.tonight.title, systemImage: "moon") { onAction(reminder, .tonight) }
            Button("Remove", systemImage: "trash", role: .destructive) { onRemove(reminder) }
        }
    }
}
