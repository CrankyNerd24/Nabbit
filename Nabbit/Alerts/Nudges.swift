import Foundation
import SwiftData
import UserNotifications

/// Schedules each reminder's alert and its follow-up nudges as local notifications,
/// and handles the Done / 15 min / Tonight buttons on them.
final class Nudges: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Nudges()

    static let intervalKey = "nudgeMinutes"
    static let defaultMinutes = 10
    /// Nudges after the first alert. The last one is the final sound.
    static let count = 3

    /// iOS keeps at most 64 pending notifications per app. The soonest ones are
    /// scheduled and the rest are added as the app reopens.
    private static let pendingLimit = 60
    private static let categoryID = "reminder"
    /// Read from the nonisolated delegate callbacks.
    nonisolated private static let reminderKey = "reminder"

    private enum Action: String {
        case done, snooze15, tonight
    }

    /// Set at launch so notification buttons can reach the store without the UI.
    var container: ModelContainer?

    static var interval: TimeInterval {
        let minutes = UserDefaults.standard.object(forKey: intervalKey) as? Int ?? defaultMinutes
        return TimeInterval(minutes * 60)
    }

    static func lastNudgeDate(after due: Date) -> Date {
        due.addingTimeInterval(Double(count) * interval)
    }

    static func registerCategories() {
        let actions = [
            UNNotificationAction(identifier: Action.done.rawValue, title: "Done"),
            UNNotificationAction(identifier: Action.snooze15.rawValue, title: "15 min"),
            UNNotificationAction(identifier: Action.tonight.rawValue, title: "Tonight"),
        ]
        let category = UNNotificationCategory(identifier: categoryID, actions: actions, intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    /// Replaces every pending notification with the soonest ones across all open reminders.
    func reschedule() {
        guard let container else { return }
        let open = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt == nil })
        let reminders = (try? container.mainContext.fetch(open)) ?? []
        let now = Date.now
        let upcoming = reminders
            .flatMap(Self.requests(for:))
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .prefix(Self.pendingLimit)

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for item in upcoming {
            center.add(item.request)
        }
    }

    /// The alert at the due time, then a nudge every interval.
    private static func requests(for reminder: Reminder) -> [(date: Date, request: UNNotificationRequest)] {
        (0...count).map { step in
            let date = reminder.dueDate.addingTimeInterval(Double(step) * interval)
            let content = UNMutableNotificationContent()
            content.title = reminder.text
            content.body = body(for: reminder, step: step)
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = categoryID
            content.threadIdentifier = reminder.uuid.uuidString
            content.userInfo = [reminderKey: reminder.uuid.uuidString]

            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: "\(reminder.uuid.uuidString)-\(step)",
                                                content: content, trigger: trigger)
            return (date, request)
        }
    }

    /// Gets more direct with each nudge.
    static func body(for reminder: Reminder, step: Int) -> String {
        switch step {
        case 0: "It's time."
        case 1: "\(reminder.text). Right now. \(reminder.verb.push)"
        case 2: "Still here. \(reminder.thing). Go."
        default: "Last one. Do it now or push it to tonight. No judgment."
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        guard let id = response.notification.request.content.userInfo[Self.reminderKey] as? String else { return }
        await handle(action: action, reminderID: id)
    }

    private func handle(action: String, reminderID: String) {
        guard let container,
              let action = Action(rawValue: action),
              let uuid = UUID(uuidString: reminderID) else { return }
        let context = container.mainContext
        let match = FetchDescriptor<Reminder>(predicate: #Predicate { $0.uuid == uuid })
        guard let reminder = try? context.fetch(match).first else { return }

        switch action {
        case .done:
            reminder.complete()
        case .snooze15:
            reminder.snooze(until: .now.addingTimeInterval(15 * 60))
        case .tonight:
            reminder.snooze(until: WhenPreset.tonight.date() ?? .now.addingTimeInterval(60 * 60))
        }
        try? context.save()
        reschedule()
    }
}
