import AppIntents
import Foundation

// Fixed lists Siri can match by name, and the reminders it can refer to.
// Kept nonisolated: App Intents reads these off the main actor.

/// A verb Siri can hear: the built-ins and any the person added. Dynamic, so added
/// verbs work in "Remind me in Nabbit to …" once the app refreshes its phrases.
nonisolated struct VerbEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static let defaultQuery = VerbQuery()

    /// The verb's raw value.
    let id: String
    let title: String

    init(_ verb: Verb) {
        id = verb.rawValue
        title = verb.title
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title.lowercased())")
    }
}

nonisolated struct VerbQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [VerbEntity] {
        identifiers.compactMap(Verb.init(rawValue:)).map(VerbEntity.init)
    }

    func entities(matching string: String) async throws -> [VerbEntity] {
        let said = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return VerbStore.visible()
            .filter { said.localizedCaseInsensitiveContains($0.title) || $0.title.localizedCaseInsensitiveContains(said) }
            .map(VerbEntity.init)
    }

    func suggestedEntities() async throws -> [VerbEntity] {
        VerbStore.visible().map(VerbEntity.init)
    }
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
