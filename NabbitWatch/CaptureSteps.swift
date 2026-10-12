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

/// Third tap: a when chip. Tapping one saves.
struct WhenStep: View {
    let theme: Theme
    let text: String
    let onPick: (Date) -> Void

    /// Pick a day needs a calendar, which is the iPhone's job.
    private let presets = WhenPreset.allCases.filter { $0 != .pickDay }

    var body: some View {
        List {
            ForEach(presets) { preset in
                Button {
                    if let date = preset.date() { onPick(date) }
                } label: {
                    NoteLabel(text: preset.title, fill: theme.tap3, large: true)
                }
                .listRowBackground(theme.tap3.color.clipShape(.rect(cornerRadius: 10)))
            }
        }
        .navigationTitle(text)
    }
}
