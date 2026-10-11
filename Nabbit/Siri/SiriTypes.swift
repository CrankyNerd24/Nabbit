import AppIntents
import Foundation

// Fixed lists Siri can match by name, and the reminders it can refer to.
// Kept nonisolated: App Intents reads these off the main actor.

nonisolated enum VerbOption: String, AppEnum {
    case call, pickUp, take, pay, buy, email, book, goTo

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static let caseDisplayRepresentations: [VerbOption: DisplayRepresentation] = [
        .call: "call",
        .pickUp: "pick up",
        .take: "take",
        .pay: "pay",
        .buy: "buy",
        .email: "email",
        .book: "book",
        .goTo: "go to",
    ]
}

nonisolated enum WhenOption: String, AppEnum {
    case inOneHour, tonight, tomorrowMorning, nextMonday

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "When"
    static let caseDisplayRepresentations: [WhenOption: DisplayRepresentation] = [
        .inOneHour: "in an hour",
        .tonight: "tonight",
        .tomorrowMorning: "tomorrow",
        .nextMonday: "next Monday",
    ]
}

nonisolated struct ReminderEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder"
    static let defaultQuery = ReminderQuery()

    let id: UUID
    /// "Call Dentist"
    let title: String
    /// "Dentist": what people say ("done with dentist").
    let thing: String
    let due: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(thing)", subtitle: "\(title), \(due)")
    }
}

/// Open reminders, matched by what they say ("dentist", "call dentist").
nonisolated struct ReminderQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [ReminderEntity] {
        await SiriActions.openEntities().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [ReminderEntity] {
        await SiriActions.openEntities().filter { $0.title.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [ReminderEntity] {
        await SiriActions.openEntities()
    }
}
