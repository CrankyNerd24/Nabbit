import AppIntents
import Foundation

/// "Remind me in Nabbit to call…" Asks for whatever's missing, one question at a time.
struct CreateReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "New reminder"
    static let description = IntentDescription("Make a reminder: what to do, who or what, and when.")

    @Parameter(title: "Do")
    var verb: VerbOption?

    @Parameter(title: "Who or what")
    var thing: String?

    @Parameter(title: "When")
    var when: WhenOption?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let verb else {
            throw $verb.needsValueError("What's the task? Call, pick up, take, pay, buy, email, book, or go to.")
        }
        let name = (thing ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            let prompt = await SiriActions.thingPrompt(verb: verb)
            throw $thing.needsValueError("\(prompt)")
        }
        guard let when else {
            let prompt = await SiriActions.whenPrompt(verb: verb, thing: name)
            throw $when.needsValueError("\(prompt)")
        }
        let reply = await SiriActions.create(verb: verb, thing: name, when: when)
        return .result(dialog: "\(reply)")
    }
}

/// "Nabbit, done with meds." With no reminder named, it's whatever's due now.
struct DoneReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark done"
    static let description = IntentDescription("Mark a reminder done.")

    @Parameter(title: "Reminder")
    var reminder: ReminderEntity?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reply = await SiriActions.done(reminder?.id)
        return .result(dialog: "\(reply)")
    }
}

/// "Nabbit, snooze that." Pushes it back 15 minutes.
struct SnoozeReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Snooze 15 minutes"
    static let description = IntentDescription("Push a reminder back 15 minutes.")

    @Parameter(title: "Reminder")
    var reminder: ReminderEntity?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reply = await SiriActions.snooze(reminder?.id)
        return .result(dialog: "\(reply)")
    }
}

/// "Move dentist in Nabbit." Asks when.
struct MoveReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Move reminder"
    static let description = IntentDescription("Move a reminder to a new time.")

    @Parameter(title: "Reminder")
    var reminder: ReminderEntity?

    @Parameter(title: "When")
    var when: WhenOption?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let reminder else { throw $reminder.needsValueError("Move which one?") }
        guard let when else {
            throw $when.needsValueError("\(reminder.title). When? In an hour, tonight, tomorrow, or next Monday.")
        }
        let reply = await SiriActions.move(reminder.id, to: when)
        return .result(dialog: "\(reply)")
    }
}

/// "What's on my Nabbit list?" Top three, then which to do first.
struct CheckListIntent: AppIntent {
    static let title: LocalizedStringResource = "What's on my list"
    static let description = IntentDescription("Hear the next three reminders.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reply = await SiriActions.check()
        return .result(dialog: "\(reply)")
    }
}

/// "Nabbit, cancel the dentist reminder." No "are you sure".
struct CancelReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Cancel reminder"
    static let description = IntentDescription("Remove a reminder.")

    @Parameter(title: "Reminder")
    var reminder: ReminderEntity?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let reminder else { throw $reminder.needsValueError("Cancel which one?") }
        let reply = await SiriActions.cancel(reminder.id)
        return .result(dialog: "\(reply)")
    }
}
