import Foundation
import SwiftData

@Model
final class Reminder {
    /// Ties notifications and their Done / 15 min / Tonight buttons back to this reminder.
    var uuid: UUID = UUID()
    var verbRaw: String
    var thing: String
    var dueDate: Date
    var createdAt: Date
    var completedAt: Date?
    var snoozeCount: Int

    var verb: Verb { Verb(rawValue: verbRaw) ?? .call }
    var text: String { "\(verb.title) \(thing)" }
    var isDone: Bool { completedAt != nil }

    /// Past the last nudge and still open. Worked out from the clock, since
    /// nudges fire while the app isn't running.
    var isSlipped: Bool {
        !isDone && Date.now >= NudgeTiming.lastNudgeDate(after: dueDate)
    }

    init(verb: Verb, thing: String, dueDate: Date) {
        self.uuid = UUID()
        self.verbRaw = verb.rawValue
        self.thing = thing
        self.dueDate = dueDate
        self.createdAt = .now
        self.completedAt = nil
        self.snoozeCount = 0
    }

    func complete() {
        completedAt = .now
    }

    func reopen() {
        completedAt = nil
    }

    func snooze(until date: Date) {
        dueDate = date
        snoozeCount += 1
    }
}
