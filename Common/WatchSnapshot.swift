import Foundation

/// Everything the watch shows, sent from the iPhone whenever it changes. The watch keeps
/// the latest one in `UserDefaults.nabbit` (the watch's own app group) for its complications.
/// Crosses between devices as JSON `Data`, decoded on the main actor.
struct WatchSnapshot: Codable, Equatable {
    /// The key for the encoded snapshot in the application context and in `UserDefaults.nabbit`.
    nonisolated static let key = "watchSnapshot"

    struct Note: Codable, Equatable, Identifiable {
        let id: UUID
        let text: String
        let thing: String
        var due: Date
        var snoozeCount: Int

        var isSlipped: Bool { isSlipped(at: .now) }

        func isSlipped(at date: Date) -> Bool {
            date >= NudgeTiming.lastNudgeDate(after: due)
        }
    }

    struct VerbOption: Codable, Equatable, Identifiable {
        let raw: String
        let title: String
        /// "Call who?", in the chosen tone.
        let prompt: String
        /// Most used first.
        let things: [String]

        var id: String { raw }
    }

    struct HotKey: Codable, Equatable, Identifiable {
        let verbRaw: String
        let verbTitle: String
        let thing: String

        var id: String { verbRaw + "/" + thing }
        var text: String { "\(verbTitle) \(thing)" }
    }

    /// Open reminders, soonest first.
    var notes: [Note] = []
    var verbs: [VerbOption] = []
    var hotKeys: [HotKey] = []
    /// Done lines in the chosen tone.
    var doneLines: [String] = ["Handled."]
    var clearBoard = "Clear board. Nothing left today."
    /// "Got it." in the chosen tone.
    var savedLead = "Got it."
    var themeID = Theme.standard.id
    var tonightHour = DefaultTimes().tonightHour
    var morningHour = DefaultTimes().morningHour
    var nudgeMinutes = NudgeTiming.defaultMinutes

    var theme: Theme { Theme.named(themeID) }

    func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(self)
    }

    init() {}

    init?(data: Data) {
        guard let snapshot = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return nil }
        self = snapshot
    }

    /// The last snapshot saved on this device.
    static var saved: WatchSnapshot {
        UserDefaults.nabbit.data(forKey: key).flatMap { WatchSnapshot(data: $0) } ?? WatchSnapshot()
    }

    /// Saves the snapshot, plus the settings `WhenPreset` and `NudgeTiming` read, so the
    /// watch works out times and slipped notes the same way the iPhone does.
    func save() {
        let defaults = UserDefaults.nabbit
        defaults.set(encoded(), forKey: Self.key)
        defaults.set(themeID, forKey: Theme.storageKey)
        defaults.set(tonightHour, forKey: DefaultTimes.tonightHourKey)
        defaults.set(morningHour, forKey: DefaultTimes.morningHourKey)
        defaults.set(nudgeMinutes, forKey: NudgeTiming.intervalKey)
    }
}

/// What the watch asks the iPhone to do. Sent as a property-list dictionary.
nonisolated enum WatchRequest: Sendable, Equatable {
    /// Done, 15 min, or Tonight on a reminder.
    case act(ReminderAction, reminder: UUID)
    /// A new reminder, with the time worked out on the watch when it was tapped.
    case create(id: UUID, verbRaw: String, thing: String, due: Date)
    /// Send the latest snapshot even if nothing changed.
    case refresh

    var dictionary: [String: Any] {
        switch self {
        case .act(let action, let id):
            ["kind": "act", "action": action.rawValue, "id": id.uuidString]
        case .create(let id, let verbRaw, let thing, let due):
            ["kind": "create", "id": id.uuidString, "verb": verbRaw, "thing": thing,
             "due": due.timeIntervalSince1970]
        case .refresh:
            ["kind": "refresh"]
        }
    }

    init?(dictionary: [String: Any]) {
        switch dictionary["kind"] as? String {
        case "act":
            guard let action = (dictionary["action"] as? String).flatMap(ReminderAction.init(rawValue:)),
                  let id = (dictionary["id"] as? String).flatMap(UUID.init(uuidString:)) else { return nil }
            self = .act(action, reminder: id)
        case "create":
            guard let id = (dictionary["id"] as? String).flatMap(UUID.init(uuidString:)),
                  let verb = dictionary["verb"] as? String,
                  let thing = dictionary["thing"] as? String,
                  let due = dictionary["due"] as? Double else { return nil }
            self = .create(id: id, verbRaw: verb, thing: thing, due: Date(timeIntervalSince1970: due))
        case "refresh":
            self = .refresh
        default:
            return nil
        }
    }
}
