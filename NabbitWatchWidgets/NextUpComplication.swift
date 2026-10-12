import Foundation
import SwiftUI
import WidgetKit

@main
struct NabbitWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NextUpComplication()
    }
}

/// What's next on the watch face, from the snapshot the watch app saved.
struct NextUpComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CrankyNerdNew.Nabbit.watch.NextUp", provider: Provider()) { entry in
            ComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Next up")
        .description("What's due next.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .accessoryCorner])
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let next: WatchSnapshot.Note?
    let dueToday: Int
    let theme: Theme

    static let sample = Entry(date: .now,
                              next: .init(id: UUID(), text: "Call Dentist", thing: "Dentist",
                                          due: .now.addingTimeInterval(1800), snoozeCount: 0),
                              dueToday: 2, theme: .standard)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(context.isPreview ? .sample : Self.entry(at: .now, from: .saved))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date.now
        let snapshot = WatchSnapshot.saved
        // Redraw as each one comes due and as each one slips. The watch app also
        // reloads the complication whenever the list changes.
        let moments = snapshot.notes
            .flatMap { [$0.due, NudgeTiming.lastNudgeDate(after: $0.due)] }
            .filter { $0 > now }
            .sorted()
            .prefix(12)
        let entries = ([now] + moments).map { Self.entry(at: $0, from: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private static func entry(at date: Date, from snapshot: WatchSnapshot) -> Entry {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: date) ?? date)
        return Entry(date: date, next: snapshot.notes.first,
                     dueToday: snapshot.notes.filter { $0.due < tomorrow }.count, theme: snapshot.theme)
    }
}

struct ComplicationView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    private var slipped: Bool { entry.next?.isSlipped(at: entry.date) ?? false }

    var body: some View {
        switch family {
        case .accessoryInline:
            if let next = entry.next {
                Text(slipped ? "Slipped: \(next.text)" : "\(next.text) \(time(next))")
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
        case .accessoryCorner:
            Text("\(entry.dueToday)")
                .font(.title2.bold())
                .widgetLabel(entry.next?.text ?? "Clear board")
        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(slipped ? "Slipped" : "Next up")
                    .font(.headline)
                    .foregroundStyle(entry.theme.tap1.color)
                    .widgetAccentable()
                if let next = entry.next {
                    Text(next.text)
                        .font(.headline)
                        .lineLimit(2)
                    Text(next.due.dueDescription(from: entry.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Clear board. Nothing left.")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func time(_ note: WatchSnapshot.Note) -> String {
        note.due.formatted(date: .omitted, time: .shortened)
    }
}
