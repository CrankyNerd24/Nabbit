import Foundation
import SwiftData
import WatchConnectivity

/// The iPhone's side of the watch connection. Sends the watch a `WatchSnapshot` whenever
/// something it shows changes, and applies what's tapped on the watch through the same
/// paths as the app's own buttons.
final class WatchLink: NSObject, WCSessionDelegate {
    static let shared = WatchLink()

    /// The last snapshot sent, so an unchanged one isn't sent again.
    private var lastSent: Data?

    private var context: ModelContext { Store.container.mainContext }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(force: Bool = false) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled,
              let data = snapshot().encoded(), force || data != lastSent else { return }
        lastSent = data
        let payload = [WatchSnapshot.key: data]
        try? session.updateApplicationContext(payload)
        // With a Nabbit complication on the watch face, this wakes the watch to redraw it.
        if session.isComplicationEnabled && session.remainingComplicationUserInfoTransfers > 0 {
            session.transferCurrentComplicationUserInfo(payload)
        }
    }

    private func snapshot() -> WatchSnapshot {
        let open = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt == nil },
                                             sortBy: [SortDescriptor(\.dueDate)])
        let reminders = (try? context.fetch(open)) ?? []
        let things = (try? context.fetch(FetchDescriptor<Thing>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse), SortDescriptor(\.createdAt)]))) ?? []
        let times = DefaultTimes.current

        var snapshot = WatchSnapshot()
        snapshot.notes = reminders.prefix(30).map {
            WatchSnapshot.Note(id: $0.uuid, text: $0.text, thing: $0.thing, due: $0.dueDate,
                               snoozeCount: $0.snoozeCount)
        }
        snapshot.verbs = VerbStore.visible().map { verb in
            WatchSnapshot.VerbOption(raw: verb.rawValue, title: verb.title,
                                     prompt: Copy.thingPrompt(for: verb),
                                     things: things.filter { $0.verbRaw == verb.rawValue }.prefix(12).map(\.name))
        }
        snapshot.hotKeys = things.filter(\.hotKey).map {
            WatchSnapshot.HotKey(verbRaw: $0.verbRaw, verbTitle: $0.verb.title, thing: $0.name)
        }
        snapshot.doneLines = Copy.doneLines
        snapshot.clearBoard = Copy.clearBoard
        snapshot.savedLead = Copy.savedLead
        snapshot.themeID = Theme.named(UserDefaults.nabbit.string(forKey: Theme.storageKey) ?? "").id
        snapshot.tonightHour = times.tonightHour
        snapshot.morningHour = times.morningHour
        snapshot.nudgeMinutes = Int(NudgeTiming.interval / 60)
        return snapshot
    }

    private func handle(_ request: WatchRequest) {
        switch request {
        case .act(let action, let uuid):
            let match = FetchDescriptor<Reminder>(predicate: #Predicate { $0.uuid == uuid })
            guard let reminder = try? context.fetch(match).first, !reminder.isDone else {
                send(force: true)
                return
            }
            Nudges.shared.perform(action, on: reminder)
        case .create(let id, let verbRaw, let thing, let due):
            // A request sent twice (once live, once queued) is only saved once.
            let match = FetchDescriptor<Reminder>(predicate: #Predicate { $0.uuid == id })
            guard ((try? context.fetchCount(match)) ?? 0) == 0 else { return }
            let verb = Verb(rawValue: verbRaw) ?? .call
            let name = CaptureStore.thing(matching: thing, verb: verb, in: context)
            CaptureStore.save(verb: verb, thing: name, due: due, id: id, in: context)
        case .refresh:
            send(force: true)
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: (any Error)?) {
        Task { @MainActor in WatchLink.shared.send(force: true) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// Switching to another watch: start over with the new one.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in WatchLink.shared.send(force: true) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receive(userInfo)
    }

    nonisolated private func receive(_ dictionary: [String: Any]) {
        guard let request = WatchRequest(dictionary: dictionary) else { return }
        Task { @MainActor in WatchLink.shared.handle(request) }
    }
}
