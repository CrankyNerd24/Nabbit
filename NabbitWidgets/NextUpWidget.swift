import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

/// What's next, with a Done button. Home Screen (small, medium) and Lock Screen.
struct NextUpWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CrankyNerdNew.Nabbit.NextUp", provider: NextUpProvider()) { entry in
            NextUpView(entry: entry)
        }
        .configurationDisplayName("Next up")
        .description("What's due next. Tap Done right on the widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Timeline

struct NoteSnapshot: Identifiable, Hashable {
    let id: UUID
    let text: String
    let due: Date
    let slipped: Bool
}

struct NextUpEntry: TimelineEntry {
    let date: Date
    /// Open reminders, soonest first, up to three.
    let notes: [NoteSnapshot]
    /// Open reminders due by the end of today, slipped ones included.
    let dueToday: Int
    let theme: Theme

    static let sample = NextUpEntry(
        date: .now,
        notes: [NoteSnapshot(id: UUID(), text: "Call Dentist", due: .now, slipped: false),
                NoteSnapshot(id: UUID(), text: "Take Meds", due: .now.addingTimeInterval(3600), slipped: false)],
        dueToday: 2,
        theme: .ember)
}

struct NextUpProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextUpEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (NextUpEntry) -> Void) {
        completion(context.isPreview ? .sample : Self.entry(at: .now, from: Self.openReminders()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextUpEntry>) -> Void) {
        let now = Date.now
        let reminders = Self.openReminders()
        // Redraw as each one comes due and as each one slips. The app also reloads
        // the widget whenever reminders change.
        let moments = reminders
            .flatMap { [$0.due, NudgeTiming.lastNudgeDate(after: $0.due)] }
            .filter { $0 > now }
            .sorted()
            .prefix(12)
        let entries = ([now] + moments).map { Self.entry(at: $0, from: reminders) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private struct Open {
        let id: UUID
        let text: String
        let due: Date
    }

    private static func openReminders() -> [Open] {
        let context = ModelContext(Store.container)
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt == nil },
                                                   sortBy: [SortDescriptor(\.dueDate)])
        let reminders = (try? context.fetch(descriptor)) ?? []
        return reminders.map { Open(id: $0.uuid, text: $0.text, due: $0.dueDate) }
    }

    private static func entry(at date: Date, from reminders: [Open]) -> NextUpEntry {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        let notes = reminders.prefix(3).map {
            NoteSnapshot(id: $0.id, text: $0.text, due: $0.due,
                         slipped: date >= NudgeTiming.lastNudgeDate(after: $0.due))
        }
        let theme = Theme.named(UserDefaults.nabbit.string(forKey: Theme.storageKey) ?? "")
        return NextUpEntry(date: date, notes: notes,
                           dueToday: reminders.filter { $0.due < tomorrow }.count, theme: theme)
    }
}

// MARK: - Views

struct NextUpView: View {
    let entry: NextUpEntry
    @Environment(\.widgetFamily) private var family

    private var theme: Theme { entry.theme }
    private var next: NoteSnapshot? { entry.notes.first }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                switch family {
                case .accessoryInline, .accessoryCircular, .accessoryRectangular:
                    Color.clear
                case .systemSmall:
                    fill(for: next).color
                default:
                    theme.tap1.color
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            if let next {
                Text("\(next.text) · \(label(for: next))")
            } else {
                Text("Clear board")
            }
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.dueToday)")
                        .font(.title2.bold())
                    Text("today")
                        .font(.caption2)
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Nabbit")
                    .font(.caption2.bold())
                    .widgetAccentable()
                if let next {
                    Text(next.text)
                        .font(.headline)
                        .lineLimit(1)
                    Text(label(for: next))
                        .font(.caption)
                } else {
                    Text("Clear board.")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .systemSmall:
            small
        default:
            medium
        }
    }

    // MARK: Home Screen

    private var small: some View {
        let ink = fill(for: next).text.color
        return VStack(alignment: .leading, spacing: 6) {
            if let next {
                Text(label(for: next))
                    .font(.caption.bold())
                Text(next.text)
                    .font(.title3.bold())
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                doneButton(for: next, wide: true)
            } else {
                clearBoard
            }
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.notes.isEmpty {
                clearBoard
                    .foregroundStyle(theme.tap1.text.color)
            } else {
                ForEach(entry.notes) { note in
                    let rowFill = fill(for: note)
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(note.text)
                                .font(.subheadline.bold())
                                .lineLimit(1)
                            Text(label(for: note))
                                .font(.caption2)
                        }
                        Spacer(minLength: 4)
                        doneButton(for: note, wide: false)
                    }
                    .foregroundStyle(rowFill.text.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(rowFill.color, in: .rect(cornerRadius: 6))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var clearBoard: some View {
        Text("Clear board.\nNothing left today.")
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func doneButton(for note: NoteSnapshot, wide: Bool) -> some View {
        Button(intent: CompleteReminderIntent(reminderID: note.id)) {
            Group {
                if wide {
                    Label("Done", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 34)
                } else {
                    Image(systemName: "checkmark")
                        .font(.subheadline.bold())
                        .frame(width: 30, height: 30)
                }
            }
            .foregroundStyle(theme.done.text.color)
            .background(theme.done.color, in: .rect(cornerRadius: wide ? 8 : 15))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Done: \(note.text)")
    }

    // MARK: Helpers

    private func fill(for note: NoteSnapshot?) -> ThemeColor {
        guard let note else { return theme.tap1 }
        return note.slipped ? theme.alert : theme.tap3
    }

    /// "Slipped", "Now", "3:00 PM", or "Mon 9:00 AM".
    private func label(for note: NoteSnapshot) -> String {
        if note.slipped { return "Slipped" }
        if note.due <= entry.date { return "Now" }
        let time = note.due.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDate(note.due, inSameDayAs: entry.date) { return time }
        return "\(note.due.formatted(.dateTime.weekday(.abbreviated))) \(time)"
    }
}

#Preview(as: .systemMedium) {
    NextUpWidget()
} timeline: {
    NextUpEntry.sample
}
