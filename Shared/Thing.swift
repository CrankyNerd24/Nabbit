import Foundation
import SwiftData

/// The second tap: who or what the verb applies to. Most-used float to the front.
@Model
final class Thing {
    var name: String
    /// Stored raw so SwiftData predicates can filter on it.
    var verbRaw: String
    var useCount: Int
    var lastUsed: Date?
    var createdAt: Date
    /// Pinned to Again? as a one-tap repeat. Only ever set by the person, after an offer.
    var hotKey: Bool = false
    /// The hot key offer has been shown, so it isn't asked twice.
    var hotKeyOffered: Bool = false

    /// Uses before a hot key is offered.
    static let hotKeyThreshold = 3

    var verb: Verb { Verb(rawValue: verbRaw) ?? .call }

    init(name: String, verb: Verb) {
        self.name = name
        self.verbRaw = verb.rawValue
        self.useCount = 0
        self.lastUsed = nil
        self.createdAt = .now
    }

    func markUsed() {
        useCount += 1
        lastUsed = .now
    }

    /// Inserts each verb's starter things on first launch.
    static func seedIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Thing>())) ?? 0
        guard existing == 0 else { return }
        for verb in Verb.builtIns {
            for name in verb.starterThings {
                context.insert(Thing(name: name, verb: verb))
            }
        }
    }
}
