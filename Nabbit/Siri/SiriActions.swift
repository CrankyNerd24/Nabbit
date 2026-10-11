import Foundation
import SwiftData

/// What Siri's intents do to the store, and what Siri says back.
/// Replies lead with the task, stay under about 12 words, and carry one encouraging beat at most.
enum SiriActions {
    private static var context: ModelContext { Store.container.mainContext }

    static func openEntities() -> [ReminderEntity] {
        openReminders().map {
            ReminderEntity(id: $0.uuid, title: $0.text, thing: $0.thing, due: $0.dueDate.dueDescription())
        }
    }

    // MARK: Create

    /// "Call, pick up, take, …": the verbs on the grid, for Siri's first question.
    static func verbChoices() -> String {
        let words = VerbStore.visible().map { $0.title.lowercased() }
        guard words.count > 1 else { return words.first ?? "" }
        return words.dropLast().joined(separator: ", ") + ", or " + (words.last ?? "")
    }

    static func thingPrompt(verb: VerbEntity) -> String {
        resolve(verb).thingPrompt
    }

    /// Adds the thing if it's new, so the follow-up question can say so.
    static func whenPrompt(verb: VerbEntity, thing: String) -> String {
        let verb = resolve(verb)
        if existingThing(named: thing, verb: verb) == nil {
            context.insert(Thing(name: thing, verb: verb))
            try? context.save()
            return "\(thing)'s new. Added it. When do you need to \(verb.title.lowercased())?"
        }
        return "\(verb.title) \(thing). When? In an hour, tonight, tomorrow, or next Monday."
    }

    static func create(verb: VerbEntity, thing: String, when: WhenOption) -> String {
        let verb = resolve(verb)
        let preset = WhenPreset(rawValue: when.rawValue) ?? .inOneHour
        let due = preset.date() ?? .now.addingTimeInterval(60 * 60)
        let name = existingThing(named: thing, verb: verb)?.name ?? thing
        if existingThing(named: name, verb: verb) == nil {
            context.insert(Thing(name: name, verb: verb))
        }
        existingThing(named: name, verb: verb)?.markUsed()

        let reminder = Reminder(verb: verb, thing: name, dueDate: due)
        context.insert(reminder)
        Nudges.shared.saveAndReschedule()
        return "Got it. \(reminder.text), \(due.dueDescription()). I'll make sure it happens."
    }

    // MARK: Done, snooze, move, cancel

    /// Done with a named reminder, or with whatever's due now.
    static func done(_ id: UUID?) -> String {
        guard let reminder = find(id) ?? dueNow() else { return "Nothing's due right now. You're clear." }
        Nudges.shared.perform(.done, on: reminder)
        return "Handled. Nice work."
    }

    static func snooze(_ id: UUID?) -> String {
        guard let reminder = find(id) ?? dueNow() else { return "Nothing's due right now." }
        Nudges.shared.perform(.snooze15, on: reminder)
        return "\(reminder.thing) moved to \(reminder.dueDate.dueDescription()). No dodging that one."
    }

    static func move(_ id: UUID, to when: WhenOption) -> String {
        guard let reminder = find(id) else { return "Missed that. Say it like this: move dentist to tomorrow." }
        let preset = WhenPreset(rawValue: when.rawValue) ?? .tonight
        reminder.snooze(until: preset.date() ?? .now.addingTimeInterval(60 * 60))
        Nudges.shared.clearDelivered(for: reminder)
        Nudges.shared.saveAndReschedule()
        return "\(reminder.thing) moved to \(reminder.dueDate.dueDescription()). No dodging that one."
    }

    static func cancel(_ id: UUID) -> String {
        guard let reminder = find(id) else { return "Missed that. Say it like this: cancel the dentist reminder." }
        let thing = reminder.thing
        Nudges.shared.clearDelivered(for: reminder)
        context.delete(reminder)
        Nudges.shared.saveAndReschedule()
        return "\(thing) reminder's gone."
    }

    // MARK: Check

    /// The top three, ending with which to do first.
    static func check() -> String {
        let top = openReminders().prefix(3).map(\.text)
        switch top.count {
        case 0: return "Nothing on the list. Clear board."
        case 1: return "Just one: \(top[0]). Do it now."
        case 2: return "\(top[0]) and \(top[1]). Start with \(top[0])."
        default: return "\(top[0]), \(top[1]), and \(top[2]). Start with \(top[0])."
        }
    }

    // MARK: Lookups

    private static func resolve(_ entity: VerbEntity) -> Verb {
        Verb(rawValue: entity.id) ?? .call
    }

    private static func openReminders() -> [Reminder] {
        let open = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt == nil },
                                             sortBy: [SortDescriptor(\.dueDate)])
        return (try? context.fetch(open)) ?? []
    }

    private static func find(_ id: UUID?) -> Reminder? {
        guard let id else { return nil }
        return openReminders().first { $0.uuid == id }
    }

    /// The earliest open reminder that's already come due.
    private static func dueNow() -> Reminder? {
        openReminders().first { $0.dueDate <= .now }
    }

    private static func existingThing(named name: String, verb: Verb) -> Thing? {
        let raw = verb.rawValue
        let things = (try? context.fetch(FetchDescriptor<Thing>(predicate: #Predicate { $0.verbRaw == raw }))) ?? []
        return things.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}
