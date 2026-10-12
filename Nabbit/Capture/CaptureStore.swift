import Foundation
import SwiftData

/// Saving a reminder, shared by the three-tap flow, the mic, and the watch.
enum CaptureStore {
    /// `id` is set by the watch, which shows the reminder before the iPhone has it.
    @discardableResult
    static func save(verb: Verb, thing: String, due: Date, id: UUID = UUID(),
                     in context: ModelContext) -> Reminder {
        let reminder = Reminder(verb: verb, thing: thing, dueDate: due)
        reminder.uuid = id
        context.insert(reminder)
        things(for: verb, in: context).first { $0.name == thing }?.markUsed()
        try? context.save()

        // Asked on the first save, when it's clear what the permission is for.
        Task {
            await Nudges.requestPermission()
            Nudges.shared.reschedule()
        }
        return reminder
    }

    /// The saved thing that matches what was said ("the kids" → "Kids", "med" → "Meds"),
    /// or a new one added under this verb.
    static func thing(matching spoken: String, verb: Verb, in context: ModelContext) -> String {
        let spoken = spoken.trimmingCharacters(in: .whitespacesAndNewlines)
        let same = { (a: String, b: String) in a.localizedCaseInsensitiveCompare(b) == .orderedSame }
        if let match = things(for: verb, in: context).first(where: {
            same($0.name, spoken) || same($0.name, spoken + "s") || same($0.name + "s", spoken)
        }) {
            return match.name
        }
        let name = spoken.prefix(1).uppercased() + spoken.dropFirst()
        context.insert(Thing(name: name, verb: verb))
        return name
    }

    private static func things(for verb: Verb, in context: ModelContext) -> [Thing] {
        let raw = verb.rawValue
        return (try? context.fetch(FetchDescriptor<Thing>(predicate: #Predicate { $0.verbRaw == raw }))) ?? []
    }
}
