import Foundation

/// What happens the moment something's marked done. Scales with effort, never blocks a tap.
struct Celebration: Identifiable {
    enum Size {
        /// Routine things and things done ahead of time: a pop and a light tap.
        case small
        /// Done on the first alert or nudge.
        case medium
        /// Slipped or pushed back more than once: full-screen confetti.
        case big
        /// Nothing left today: the empty-fridge screen.
        case clearBoard
    }

    let id = UUID()
    let size: Size
    let line: String

    /// Works out the size before the reminder is marked done, while slipped and nudge state still apply.
    static func size(for reminder: Reminder, at now: Date = .now) -> Size {
        if reminder.isSlipped || reminder.snoozeCount >= 2 { return .big }
        if reminder.verb == .take { return .small }
        if reminder.dueDate <= now && reminder.snoozeCount == 0 && Nudges.step(for: reminder, at: now) <= 1 {
            return .medium
        }
        return .small
    }

    static func make(for reminder: Reminder, size: Size) -> Celebration {
        let line: String = switch size {
        case .clearBoard: "Clear board. Nothing left today."
        case .big: "Finally handled. That one's been hanging around."
        case .medium: "First try. Look at you."
        case .small: CelebrationLines.next(for: reminder)
        }
        return Celebration(size: size, line: line)
    }
}

/// Rotating lines, never the same one twice in a row.
enum CelebrationLines {
    private static var last: String?

    private static let general = [
        "Handled.",
        "Done and gone.",
        "That's off your plate.",
        "One less thing in your head.",
        "Off the fridge.",
        "Crossed off.",
        "Nice. Next.",
        "Sorted.",
        "That's taken care of.",
        "Done. Breathe.",
        "Look at you go.",
        "Checked off.",
        "Out of your head, off the list.",
        "Done is done.",
        "Nailed it.",
        "Boom. Handled.",
        "Brain space freed.",
        "That one's history.",
        "Clean.",
        "Small win. Real win.",
    ]

    static func next(for reminder: Reminder) -> String {
        var pool = general
        // About one in three is about the task itself.
        if Int.random(in: 0..<3) == 0 {
            pool = [taskLine(for: reminder)]
        }
        let choices = pool.filter { $0 != last }
        let line = choices.randomElement() ?? general.first { $0 != last } ?? "Handled."
        last = line
        return line
    }

    private static func taskLine(for reminder: Reminder) -> String {
        let thing = reminder.thing
        if reminder.verb == .call && thing.localizedCaseInsensitiveContains("dentist") {
            return "Dentist called. Your teeth thank you."
        }
        return switch reminder.verb.rawValue {
        case "call": "\(thing) called. Done."
        case "pickUp": "\(thing) picked up."
        case "take": "\(thing) taken. Good."
        case "pay": "\(thing) paid. Money stuff handled."
        case "buy": "\(thing) bought."
        case "email": "\(thing) emailed. Sent and done."
        case "book": "\(thing) booked."
        case "goTo": "Made it to \(thing)."
        default: "\(reminder.text). Done and gone."
        }
    }
}
