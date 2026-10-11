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
