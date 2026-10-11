import SwiftData
import SwiftUI

struct HomeView: View {
    @AppStorage(Theme.storageKey, store: .nabbit) private var themeID = Theme.ember.id
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Reminder> { $0.completedAt == nil }, sort: \Reminder.dueDate, animation: .snappy)
    private var open: [Reminder]
    @Query(HomeView.recentlyDone) private var recentlyDone: [Reminder]
    @Query private var things: [Thing]
    @State private var alerts = AlertCenter.shared
    @State private var capture = CaptureRequest.shared
    @State private var path: [CaptureStep] = []
    @State private var banner: Banner?
    @State private var celebration: Celebration?
    @State private var showingSettings = false

    private var theme: Theme { Theme.named(themeID) }

    private static var recentlyDone: FetchDescriptor<Reminder> {
        var descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt != nil },
                                                   sortBy: [SortDescriptor(\.dueDate, order: .reverse)])
        descriptor.fetchLimit = 40
        return descriptor
    }

    /// Finished today, newest first. No counts, no streaks.
    private var winsToday: [Reminder] {
        let today = Calendar.current.startOfDay(for: .now)
        return recentlyDone
            .filter { ($0.completedAt ?? .distantPast) >= today }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// Hot keys the person said yes to, most used first.
    private var hotKeys: [Thing] {
        things.filter(\.hotKey).sorted { $0.useCount > $1.useCount }
    }

    /// The most used combination that's earned a hot key offer and hasn't had one.
    private var hotKeyOffer: Thing? {
        things
            .filter { $0.useCount >= Thing.hotKeyThreshold && !$0.hotKey && !$0.hotKeyOffered }
            .max { $0.useCount < $1.useCount }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TodayList(reminders: open, theme: theme,
                              onAction: { act($1, on: $0) }, onRemove: remove)
                    if let offer = hotKeyOffer {
                        hotKeyCallout(offer)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    MicButton(theme: theme,
                              hints: Verb.allCases.map(\.title) + things.map(\.name),
                              onHeard: heard)
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
                    if !hotKeys.isEmpty {
                        againStrip
                    }
                    if !winsToday.isEmpty {
                        winsStrip
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
            .overlay {
                if let celebration {
                    CelebrationOverlay(celebration: celebration, theme: theme)
                        .id(celebration.id)
                        .transition(.identity)
                }
            }
            .task(id: celebration?.id) {
                guard let celebration else { return }
                try? await Task.sleep(for: .seconds(CelebrationOverlay.duration(for: celebration.size)))
                self.celebration = nil
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
                        // Gone at once, so the celebration plays in full view on Home.
                        var instant = Transaction()
                        instant.disablesAnimations = true
                        withTransaction(instant) { alerts.current = nil }
                        act(action, on: reminder)
                    }
                } else {
                    // Already handled somewhere else.
                    Color.clear.onAppear { alerts.current = nil }
                }
            }
            .onChange(of: capture.count) {
                // The New reminder control: back to the verb grid.
                showingSettings = false
                path = []
            }
            .task {
                Thing.seedIfNeeded(in: context)
            }
        }
    }

    private func act(_ action: ReminderAction, on reminder: Reminder) {
        // Sized before it's marked done, while slipped and nudge state still apply.
        let size = Celebration.size(for: reminder)
        Nudges.shared.perform(action, on: reminder)
        withAnimation {
            switch action {
            case .done:
                let done = Celebration.make(for: reminder, size: clearsBoard(after: reminder) ? .clearBoard : size)
                celebration = done
                Haptics.play(done.size)
                banner = Banner(text: done.line, undo: {
                    reminder.reopen()
                    Nudges.shared.saveAndReschedule()
                })
            case .snooze15, .tonight:
                banner = Banner(text: "\(reminder.thing) moved to \(reminder.dueDate.dueDescription()).")
            }
        }
    }

    /// Saves a spoken reminder outright when it has all three parts, or opens the
    /// three-tap flow at the first missing one.
    private func heard(_ text: String) {
        let spoken = VoiceParser.parse(text)
        guard let verb = spoken.verb else {
            withAnimation {
                banner = Banner(text: "Missed that. Say it like this: call the dentist tomorrow.")
            }
            return
        }
        guard let said = spoken.thing else {
            path = [.thing(verb)]
            return
        }
        let thing = CaptureStore.thing(matching: said, verb: verb, in: context)
        guard let due = spoken.due else {
            path = [.thing(verb), .when(verb, thing: thing)]
            return
        }
        let reminder = CaptureStore.save(verb: verb, thing: thing, due: due, in: context)
        withAnimation {
            banner = Banner(text: "Got it. \(reminder.text), \(due.dueDescription()).", undo: {
                Nudges.shared.clearDelivered(for: reminder)
                context.delete(reminder)
                Nudges.shared.saveAndReschedule()
            })
        }
    }

    /// True when this was the last thing due today.
    private func clearsBoard(after reminder: Reminder) -> Bool {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
        guard reminder.dueDate < tomorrow else { return false }
        return !open.contains { !$0.isDone && $0.dueDate < tomorrow }
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
                    ForEach(hotKeys) { thing in
                        Button {
                            path.append(.when(thing.verb, thing: thing.name))
                        } label: {
                            StickyNote(text: "\(thing.verb.title) \(thing.name)", fill: theme.tap2, compact: true)
                        }
                        .buttonStyle(NoteButtonStyle())
                        .contextMenu {
                            Button("Remove hot key", systemImage: "minus.circle") {
                                withAnimation { thing.hotKey = false }
                                try? context.save()
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Offered once per combination after it's been made three times. Yes pins it to
    /// Again?; no means it's never asked about again.
    private func hotKeyCallout(_ thing: Thing) -> some View {
        let fill = theme.tap2
        return VStack(alignment: .leading, spacing: 12) {
            Text("You've added \(thing.verb.title) \(thing.name) \(thing.useCount) times. Want a hot key for it?")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button {
                    withAnimation {
                        thing.hotKey = true
                        thing.hotKeyOffered = true
                    }
                    try? context.save()
                } label: {
                    Text("Add hot key")
                        .font(.headline)
                        .foregroundStyle(theme.done.text.color)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(theme.done.color, in: .rect(cornerRadius: 8))
                }
                Button {
                    withAnimation { thing.hotKeyOffered = true }
                    try? context.save()
                } label: {
                    Text("No thanks")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(fill.text.color, lineWidth: 2))
                        .contentShape(.rect)
                }
            }
            .buttonStyle(NoteButtonStyle())
        }
        .foregroundStyle(fill.text.color)
        .padding(16)
        .background(fill.color, in: .rect(cornerRadius: 6))
        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }

    /// Small crumpled notes for what's done today.
    private var winsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wins today")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(winsToday.enumerated()), id: \.element.id) { index, reminder in
                        Text(reminder.text)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.done.text.color)
                            .padding(8)
                            .frame(width: 90, height: 54)
                            .background(theme.done.color.opacity(0.85), in: .rect(cornerRadius: 4))
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -4 : 3))
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .accessibilityElement(children: .combine)
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

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, Thing.self], inMemory: true)
}
