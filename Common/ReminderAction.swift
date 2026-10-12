import Foundation

/// The three buttons on every alert. Nothing else.
nonisolated enum ReminderAction: String, CaseIterable, Sendable {
    case done, snooze15, tonight

    /// The notification category carrying the three buttons, on the iPhone and the watch.
    static let notificationCategory = "reminder"
    /// The reminder's UUID string in each notification's userInfo.
    static let reminderKey = "reminder"

    var title: String {
        switch self {
        case .done: "Done"
        case .snooze15: "15 min"
        case .tonight: "Tonight"
        }
    }
}
