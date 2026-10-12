import SwiftUI

/// Where the watch goes on each tap: the three capture steps and a reminder's alert.
enum WatchRoute: Hashable {
    case verbs
    case things(verbRaw: String)
    case when(verbRaw: String, thing: String)
    case day(verbRaw: String, thing: String)
    case note(UUID)
}

/// + New first, then Again? hot keys, Today, and Coming up.
struct WatchHomeView: View {
    @State private var model = WatchModel.shared
    @State private var path: [WatchRoute] = []

    private var theme: Theme { model.theme }

    var body: some View {
        NavigationStack(path: $path) {
            // Redraws each minute so notes flip to slipped on time.
            TimelineView(.everyMinute) { context in
                list(at: context.date)
            }
            .navigationTitle("Nabbit")
            .navigationDestination(for: WatchRoute.self) { route in
                destination(for: route)
            }
        }
        .overlay {
            if let line = model.celebration {
                Banner(text: line, fill: theme.done)
            } else if let line = model.savedLine {
                Banner(text: line, fill: theme.tap1)
            }
        }
        .animation(.snappy, value: model.celebration)
        .animation(.snappy, value: model.savedLine)
    }

    private func list(at now: Date) -> some View {
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now)
        let today = model.snapshot.notes.filter { $0.due < tomorrow }
        let later = model.snapshot.notes.filter { $0.due >= tomorrow }.prefix(5)

        return List {
            NavigationLink(value: WatchRoute.verbs) {
                NoteLabel(text: "+ New", fill: theme.tap1, large: true)
            }
            .accessibilityLabel("New reminder")
            .listRowBackground(theme.tap1.color.clipShape(.rect(cornerRadius: 10)))

            if !model.snapshot.hotKeys.isEmpty {
                Section("Again?") {
                    ForEach(model.snapshot.hotKeys) { key in
                        NavigationLink(value: WatchRoute.when(verbRaw: key.verbRaw, thing: key.thing)) {
                            NoteLabel(text: key.text, fill: theme.tap2)
                        }
                        .listRowBackground(theme.tap2.color.clipShape(.rect(cornerRadius: 10)))
                    }
                }
            }

            Section("Today") {
                if today.isEmpty {
                    Text(model.snapshot.clearBoard)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(today) { note in
                        let slipped = note.isSlipped(at: now)
                        let fill = slipped ? theme.alert : theme.tap3
                        NavigationLink(value: WatchRoute.note(note.id)) {
                            NoteLabel(text: slipped ? "Slipped: \(note.text)" : note.text, fill: fill,
                                      detail: note.due.formatted(date: .omitted, time: .shortened))
                        }
                        .listRowBackground(fill.color.clipShape(.rect(cornerRadius: 10)))
                    }
                }
            }

            if !later.isEmpty {
                Section("Coming up") {
                    ForEach(Array(later)) { note in
                        NavigationLink(value: WatchRoute.note(note.id)) {
                            NoteLabel(text: note.text, fill: theme.tap3,
                                      detail: note.due.dueDescription(from: now))
                        }
                        .listRowBackground(theme.tap3.color.clipShape(.rect(cornerRadius: 10)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: WatchRoute) -> some View {
        switch route {
        case .verbs:
            VerbStep(theme: theme, verbs: model.snapshot.verbs) { path.append(.things(verbRaw: $0.raw)) }
        case .things(let raw):
            if let verb = model.verb(raw) {
                ThingStep(theme: theme, verb: verb) { path.append(.when(verbRaw: raw, thing: $0)) }
            }
        case .when(let raw, let thing):
            if let verb = model.verb(raw) {
                WhenStep(theme: theme, text: "\(verb.title) \(thing)") { due in
                    model.create(verb: verb, thing: thing, due: due)
                    path = []
                } onPickDay: {
                    path.append(.day(verbRaw: raw, thing: thing))
                }
            }
        case .day(let raw, let thing):
            if let verb = model.verb(raw) {
                DayStep(theme: theme) { due in
                    model.create(verb: verb, thing: thing, due: due)
                    path = []
                }
            }
        case .note(let id):
            if let note = model.snapshot.notes.first(where: { $0.id == id }) {
                NoteAlertView(note: note, theme: theme) { action in
                    path = []
                    model.perform(action, on: note)
                }
            } else {
                Text("Already handled.")
            }
        }
    }
}

/// A note's text in its automatic text color, with an optional time underneath.
struct NoteLabel: View {
    let text: String
    let fill: ThemeColor
    var detail: String?
    var large = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text)
                .font(large ? .title3.bold() : .headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let detail {
                Text(detail)
                    .font(.footnote)
            }
        }
        .foregroundStyle(fill.text.color)
        .frame(maxWidth: .infinity, minHeight: large ? 50 : 40, alignment: .leading)
    }
}

/// A line that shows for a moment over everything and never takes taps.
struct Banner: View {
    let text: String
    let fill: ThemeColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(fill.text.color)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(fill.color, in: .rect(cornerRadius: 12))
            .padding(.horizontal, 4)
            .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
            .allowsHitTesting(false)
    }
}
