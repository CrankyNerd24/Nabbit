import SwiftUI

/// Add verbs, hide the ones you never use, and drag them into your order.
/// Changes apply as they're made.
struct VerbEditorView: View {
    @AppStorage(VerbStore.key, store: .nabbit) private var layoutJSON = ""
    @State private var newVerb = ""

    private var layout: VerbStore.Layout { VerbStore.layout(from: layoutJSON) }

    var body: some View {
        List {
            Section {
                ForEach(VerbStore.all(in: layout)) { verb in
                    let hidden = layout.hidden.contains(verb.rawValue)
                    HStack {
                        Text(verb.title)
                            .foregroundStyle(hidden ? .secondary : .primary)
                        Spacer()
                        Button {
                            VerbStore.setHidden(!hidden, for: verb)
                        } label: {
                            Image(systemName: hidden ? "eye.slash" : "eye")
                                .foregroundStyle(hidden ? .secondary : .primary)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(hidden ? "Show \(verb.title)" : "Hide \(verb.title)")
                    }
                    .deleteDisabled(verb.isBuiltIn)
                }
                .onMove { source, destination in
                    var verbs = VerbStore.all(in: layout)
                    verbs.move(fromOffsets: source, toOffset: destination)
                    VerbStore.setOrder(verbs)
                }
                .onDelete { offsets in
                    let verbs = VerbStore.all(in: layout)
                    offsets.map { verbs[$0] }.forEach(VerbStore.remove)
                }
            } footer: {
                Text("Drag to reorder. Hidden verbs leave the grid, but their reminders stay. Verbs you add can be deleted.")
            }

            Section("Add a verb") {
                HStack {
                    TextField("Text, Clean, Water…", text: $newVerb)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(add)
                    Button("Add", action: add)
                        .disabled(newVerb.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Verbs")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func add() {
        VerbStore.add(newVerb)
        newVerb = ""
    }
}

#Preview {
    NavigationStack { VerbEditorView() }
}
