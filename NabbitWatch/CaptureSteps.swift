import SwiftUI

/// First tap: the verbs from the iPhone's grid, in the same order.
struct VerbStep: View {
    let theme: Theme
    let verbs: [WatchSnapshot.VerbOption]
    let onPick: (WatchSnapshot.VerbOption) -> Void

    var body: some View {
        List {
            if verbs.isEmpty {
                Text("Open Nabbit on your iPhone once to bring your verbs over.")
                    .foregroundStyle(.secondary)
            }
            ForEach(verbs) { verb in
                Button { onPick(verb) } label: {
                    NoteLabel(text: verb.title, fill: theme.tap1, large: true)
                }
                .listRowBackground(theme.tap1.color.clipShape(.rect(cornerRadius: 10)))
            }
        }
        .navigationTitle("New")
    }
}

/// Second tap: who or what, most used first, or + New by dictation or Scribble.
struct ThingStep: View {
    let theme: Theme
    let verb: WatchSnapshot.VerbOption
    let onPick: (String) -> Void

    @State private var newName = ""

    var body: some View {
        List {
            ForEach(verb.things, id: \.self) { thing in
                Button { onPick(thing) } label: {
                    NoteLabel(text: thing, fill: theme.tap2, large: true)
                }
                .listRowBackground(theme.tap2.color.clipShape(.rect(cornerRadius: 10)))
            }
            TextField("+ New", text: $newName)
                .accessibilityLabel("Add new")
                .onSubmit {
                    let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    newName = ""
                    onPick(name.prefix(1).uppercased() + name.dropFirst())
                }
        }
        .navigationTitle(verb.prompt)
    }
}

/// Third tap: a when chip. Tapping one saves; Pick a day opens the next two weeks.
struct WhenStep: View {
    let theme: Theme
    let text: String
    let onPick: (Date) -> Void
    let onPickDay: () -> Void

    var body: some View {
        List {
            ForEach(WhenPreset.allCases) { preset in
                Button {
                    if let date = preset.date() {
                        onPick(date)
                    } else {
                        onPickDay()
                    }
                } label: {
                    NoteLabel(text: preset.title, fill: theme.tap3, large: true)
                }
                .listRowBackground(theme.tap3.color.clipShape(.rect(cornerRadius: 10)))
            }
        }
        .navigationTitle(text)
    }
}

/// Pick a day: tomorrow through two weeks out, each at the morning time. Tapping one saves.
struct DayStep: View {
    let theme: Theme
    let onPick: (Date) -> Void

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let hour = DefaultTimes.current.morningHour
        return (1...14).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
                .flatMap { calendar.date(bySettingHour: hour, minute: 0, second: 0, of: $0) }
        }
    }

    var body: some View {
        List {
            ForEach(days, id: \.self) { day in
                Button { onPick(day) } label: {
                    NoteLabel(text: title(for: day), fill: theme.tap3, large: true)
                }
                .listRowBackground(theme.tap3.color.clipShape(.rect(cornerRadius: 10)))
            }
        }
        .navigationTitle("Pick a day")
    }

    private func title(for day: Date) -> String {
        Calendar.current.isDateInTomorrow(day)
            ? "Tomorrow"
            : day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}
