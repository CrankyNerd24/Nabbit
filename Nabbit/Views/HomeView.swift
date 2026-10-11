import SwiftData
import SwiftUI

struct HomeView: View {
    @AppStorage(Theme.storageKey) private var themeID = Theme.ember.id
    @Environment(\.modelContext) private var context
    @Query(HomeView.recentReminders) private var recent: [Reminder]
    @Query(filter: #Predicate<Reminder> { $0.completedAt == nil }, sort: \Reminder.dueDate)
    private var open: [Reminder]
    @State private var alerts = AlertCenter.shared
    @State private var path: [CaptureStep] = []
    @State private var banner: Banner?
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
                    TodayList(reminders: open, theme: theme,
                              onAction: { act($1, on: $0) }, onRemove: remove)
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
                            banner = Banner(text: message)
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
                if let banner {
                    bannerView(banner)
                }
            }
            .task(id: banner?.id) {
                guard let banner else { return }
                try? await Task.sleep(for: .seconds(banner.undo == nil ? 2.5 : 4))
                withAnimation { self.banner = nil }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onChange(of: alerts.current) {
                // The alert can't show over Settings, so Settings steps aside.
                if alerts.current != nil {
                    showingSettings = false
                }
            }
            .fullScreenCover(item: $alerts.current) { item in
                if let reminder = open.first(where: { $0.uuid == item.id }) {
                    AlertView(reminder: reminder, theme: theme) { action in
                        alerts.current = nil
                        act(action, on: reminder)
                    }
                } else {
                    // Already handled somewhere else.
                    Color.clear.onAppear { alerts.current = nil }
                }
            }
            .task {
                Thing.seedIfNeeded(in: context)
            }
        }
    }

    private func act(_ action: ReminderAction, on reminder: Reminder) {
        Nudges.shared.perform(action, on: reminder)
        withAnimation {
            switch action {
            case .done:
                banner = Banner(text: "Handled.", undo: {
                    reminder.reopen()
                    Nudges.shared.saveAndReschedule()
                })
            case .snooze15, .tonight:
                banner = Banner(text: "\(reminder.thing) moved to \(reminder.dueDate.dueDescription()).")
            }
        }
    }

    /// No "are you sure". Undo brings it back.
    private func remove(_ reminder: Reminder) {
        let (verb, thing, due, uuid) = (reminder.verb, reminder.thing, reminder.dueDate, reminder.uuid)
        Nudges.shared.clearDelivered(for: reminder)
        context.delete(reminder)
        Nudges.shared.saveAndReschedule()
        withAnimation {
            banner = Banner(text: "\(thing) reminder's gone.", undo: {
                let restored = Reminder(verb: verb, thing: thing, dueDate: due)
                restored.uuid = uuid
                context.insert(restored)
                Nudges.shared.saveAndReschedule()
            })
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

    private func bannerView(_ banner: Banner) -> some View {
        HStack(spacing: 12) {
            Text(banner.text)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: banner.undo == nil ? .center : .leading)
            if let undo = banner.undo {
                Button("Undo") {
                    undo()
                    withAnimation { self.banner = nil }
                }
                .font(.headline.weight(.heavy))
            }
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(theme.done.text.color)
        .padding()
        .background(theme.done.color, in: .rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onTapGesture { withAnimation { self.banner = nil } }
    }
}

/// A short line at the bottom of Home, with Undo where it helps.
private struct Banner: Identifiable {
    let id = UUID()
    let text: String
    var undo: (() -> Void)? = nil
}

private struct AgainItem: Hashable {
    let verb: Verb
    let thing: String
}

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, Thing.self], inMemory: true)
}
