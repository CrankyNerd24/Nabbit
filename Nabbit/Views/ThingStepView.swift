import SwiftData
import SwiftUI

/// Second tap: pick who or what. Most-used things come first.
struct ThingStepView: View {
    let verb: Verb
    let theme: Theme
    let onPick: (String) -> Void

    @Environment(\.modelContext) private var context
    @Query private var things: [Thing]
    @State private var addingNew = false
    @State private var newName = ""

    init(verb: Verb, theme: Theme, onPick: @escaping (String) -> Void) {
        self.verb = verb
        self.theme = theme
        self.onPick = onPick
        let raw = verb.rawValue
        _things = Query(filter: #Predicate<Thing> { $0.verbRaw == raw },
                        sort: [SortDescriptor(\Thing.useCount, order: .reverse), SortDescriptor(\Thing.createdAt)])
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: NoteGrid.columns, spacing: 12) {
                ForEach(things) { thing in
                    Button {
                        onPick(thing.name)
                    } label: {
                        StickyNote(text: thing.name, fill: theme.tap2)
                    }
                    .buttonStyle(NoteButtonStyle())
                }
                Button {
                    newName = ""
                    addingNew = true
                } label: {
                    StickyNote(text: "+ New", fill: theme.tap2)
                }
                .buttonStyle(NoteButtonStyle())
            }
            .padding()
        }
        .navigationTitle(Copy.thingPrompt(for: verb))
        .alert(Copy.thingPrompt(for: verb), isPresented: $addingNew) {
            TextField("Name", text: $newName)
                .textInputAutocapitalization(.words)
            Button("Add", action: addNew)
            Button("Cancel", role: .cancel) {}
        }
    }

    /// Adds the thing and goes straight on to When, so a new thing costs no extra tap.
    private func addNew() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let existing = things.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            onPick(existing.name)
        } else {
            context.insert(Thing(name: name, verb: verb))
            onPick(name)
        }
    }
}
