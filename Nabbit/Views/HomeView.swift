import SwiftData
import SwiftUI

struct HomeView: View {
    @AppStorage(Theme.storageKey) private var themeID = Theme.ember.id
    @Environment(\.modelContext) private var context
    @Query(HomeView.recentReminders) private var recent: [Reminder]
    @State private var path: [CaptureStep] = []
    @State private var confirmation: String?
    @State private var showingSettings = false

    private var theme: Theme { Theme.named(themeID) }

    private static var recentReminders: FetchDescriptor<Reminder> {
        var descriptor = FetchDescriptor<Reminder>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 30
        return descriptor
    }

    /// The latest distinct verb and thing pairs, for one-tap repeats.
    private var againItems: [AgainItem] {
        var seen = Set<AgainItem>()
        return recent
            .map { AgainItem(verb: $0.verb, thing: $0.thing) }
            .filter { seen.insert($0).inserted }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !againItems.isEmpty {
                        againStrip
                    }
                    LazyVGrid(columns: NoteGrid.columns, spacing: 12) {
                        ForEach(Verb.allCases) { verb in
                            Button {
                                path.append(.thing(verb))
                            } label: {
                                StickyNote(text: verb.title, fill: theme.tap1)
                            }
                            .buttonStyle(NoteButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Nabbit")
            .navigationDestination(for: CaptureStep.self) { step in
                switch step {
                case .thing(let verb):
                    ThingStepView(verb: verb, theme: theme) { thing in
                        path.append(.when(verb, thing: thing))
                    }
                case .when(let verb, let thing):
                    WhenStepView(verb: verb, thing: thing, theme: theme) { message in
                        withAnimation {
                            confirmation = message
                            path = []
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showingSettings = true
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let confirmation {
                    banner(confirmation)
                }
            }
            .task(id: confirmation) {
                guard confirmation != nil else { return }
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation { confirmation = nil }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                Thing.seedIfNeeded(in: context)
            }
        }
    }

    private var againStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Again?")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(againItems, id: \.self) { item in
                        Button {
                            path.append(.when(item.verb, thing: item.thing))
                        } label: {
                            StickyNote(text: "\(item.verb.title) \(item.thing)", fill: theme.tap2, compact: true)
                        }
                        .buttonStyle(NoteButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func banner(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(theme.done.text.color)
            .padding()
            .frame(maxWidth: .infinity)
            .background(theme.done.color, in: .rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture { withAnimation { confirmation = nil } }
    }
}

private struct AgainItem: Hashable {
    let verb: Verb
    let thing: String
}

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, Thing.self], inMemory: true)
}
