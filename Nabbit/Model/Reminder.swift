import Foundation
import SwiftData

@Model
final class Reminder {
    var verbRaw: String
    var thing: String
    var dueDate: Date
    var createdAt: Date
    var completedAt: Date?
    /// Nudges already fired for the current due date. Reset when snoozed.
    var nudgesSent: Int
    var snoozeCount: Int

    /// After this many nudges the alert goes quiet and the reminder shows as slipped.
    static let maxNudges = 3

    var verb: Verb { Verb(rawValue: verbRaw) ?? .call }
    var text: String { "\(verb.title) \(thing)" }
    var isDone: Bool { completedAt != nil }
    var isSlipped: Bool { !isDone && nudgesSent >= Self.maxNudges }

    init(verb: Verb, thing: String, dueDate: Date) {
        self.verbRaw = verb.rawValue
        self.thing = thing
        self.dueDate = dueDate
        self.createdAt = .now
        self.completedAt = nil
        self.nudgesSent = 0
        self.snoozeCount = 0
    }

    func complete() {
        completedAt = .now
    }

    func snooze(until date: Date) {
        dueDate = date
        nudgesSent = 0
        snoozeCount += 1
    }
}
