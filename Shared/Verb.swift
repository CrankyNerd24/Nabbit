import Foundation

/// The first tap: eight built in, plus any the person adds.
///
/// Reminders and things store a verb's `rawValue`: a built-in's key ("call"), or
/// "custom:" and the word ("custom:Text"). The word lives in the raw value, so a
/// reminder keeps its verb even after that verb is removed from the grid.
nonisolated struct Verb: Hashable, Identifiable, Sendable {
    let rawValue: String
    let title: String

    var id: String { rawValue }
    var isBuiltIn: Bool { !rawValue.hasPrefix(Self.customPrefix) }

    private static let customPrefix = "custom:"

    private init(raw: String, title: String) {
        self.rawValue = raw
        self.title = title
    }

    static let call = Verb(raw: "call", title: "Call")
    static let pickUp = Verb(raw: "pickUp", title: "Pick up")
    static let take = Verb(raw: "take", title: "Take")
    static let pay = Verb(raw: "pay", title: "Pay")
    static let buy = Verb(raw: "buy", title: "Buy")
    static let email = Verb(raw: "email", title: "Email")
    static let book = Verb(raw: "book", title: "Book")
    static let goTo = Verb(raw: "goTo", title: "Go to")

    static let builtIns: [Verb] = [call, pickUp, take, pay, buy, email, book, goTo]

    init?(rawValue: String) {
        if let builtIn = Self.builtIns.first(where: { $0.rawValue == rawValue }) {
            self = builtIn
        } else if rawValue.hasPrefix(Self.customPrefix), rawValue.count > Self.customPrefix.count {
            self.init(raw: rawValue, title: String(rawValue.dropFirst(Self.customPrefix.count)))
        } else {
            return nil
        }
    }

    /// A verb the person added, from the word they typed or said.
    static func custom(_ word: String) -> Verb {
        let word = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = word.prefix(1).uppercased() + word.dropFirst()
        return Verb(raw: customPrefix + title, title: title)
    }

    /// The question on the second tap, and Siri's follow-up when the thing is missing.
    var thingPrompt: String {
        switch rawValue {
        case "call", "email": "\(title) who?"
        case "goTo": "Go where?"
        default: "\(title) what?"
        }
    }

    /// The short push at the end of an alert.
    var push: String {
        switch rawValue {
        case "call": "It's a two-minute call."
        case "pickUp": "Keys, shoes, go."
        case "take": "Glass of water. Done."
        case "pay": "Two minutes and it's paid."
        case "buy": "Add it to the cart now."
        case "email": "Three lines is plenty."
        case "book": "One call or one click."
        case "goTo": "Shoes on. Out the door."
        default: "Two minutes, tops."
        }
    }

    /// Things offered on the second tap before the user has added any.
    var starterThings: [String] {
        switch rawValue {
        case "call": ["Dentist", "Mom", "Doctor", "Vet", "Pharmacy"]
        case "pickUp": ["Kids", "Prescription", "Dry cleaning"]
        case "take": ["Meds", "Vitamins"]
        case "pay": ["Rent", "Phone bill", "Credit card"]
        case "buy": ["Groceries", "Milk", "Gift"]
        case "email": ["Boss", "School", "Landlord"]
        case "book": ["Haircut", "Doctor", "Dentist"]
        case "goTo": ["Pharmacy", "Post office", "Gym"]
        default: []
        }
    }
}
