import Foundation

/// The first tap. A fixed set so Siri can match it as an enum.
enum Verb: String, CaseIterable, Codable, Identifiable {
    case call, pickUp, take, pay, buy, email, book, goTo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .call: "Call"
        case .pickUp: "Pick up"
        case .take: "Take"
        case .pay: "Pay"
        case .buy: "Buy"
        case .email: "Email"
        case .book: "Book"
        case .goTo: "Go to"
        }
    }

    /// The question on the second tap, and Siri's follow-up when the thing is missing.
    var thingPrompt: String {
        switch self {
        case .call, .email: "\(title) who?"
        case .goTo: "Go where?"
        default: "\(title) what?"
        }
    }

    /// The short push at the end of an alert.
    var push: String {
        switch self {
        case .call: "It's a two-minute call."
        case .pickUp: "Keys, shoes, go."
        case .take: "Glass of water. Done."
        case .pay: "Two minutes and it's paid."
        case .buy: "Add it to the cart now."
        case .email: "Three lines is plenty."
        case .book: "One call or one click."
        case .goTo: "Shoes on. Out the door."
        }
    }

    /// Things offered on the second tap before the user has added any.
    var starterThings: [String] {
        switch self {
        case .call: ["Dentist", "Mom", "Doctor", "Vet", "Pharmacy"]
        case .pickUp: ["Kids", "Prescription", "Dry cleaning"]
        case .take: ["Meds", "Vitamins"]
        case .pay: ["Rent", "Phone bill", "Credit card"]
        case .buy: ["Groceries", "Milk", "Gift"]
        case .email: ["Boss", "School", "Landlord"]
        case .book: ["Haircut", "Doctor", "Dentist"]
        case .goTo: ["Pharmacy", "Post office", "Gym"]
        }
    }
}
