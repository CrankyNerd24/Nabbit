import Foundation

/// The three buttons on every alert. Nothing else.
enum ReminderAction: String, CaseIterable {
    case done, snooze15, tonight

    var title: String {
        switch self {
        case .done: "Done"
        case .snooze15: "15 min"
        case .tonight: "Tonight"
        }
    }
}
