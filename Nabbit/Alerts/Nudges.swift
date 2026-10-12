import AppIntents
import Foundation
import SwiftData
import UserNotifications
import WidgetKit

/// Schedules each reminder's alert and its follow-up nudges as local notifications
/// (the first alert rings through `Alarms` when allowed), and handles the
/// Done / 15 min / Tonight buttons on them.
final class Nudges: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Nudges()

    /// iOS keeps at most 64 pending notifications per app. The soonest ones are
    /// scheduled and the rest are added as the app reopens.
    private static let pendingLimit = 60
    private static let categoryID = ReminderAction.notificationCategory
    /// Read from the nonisolated delegate callbacks.
    nonisolated private static let reminderKey = ReminderAction.reminderKey

    private var container: ModelContainer { Store.container }
    private var alarmTask: Task<Void, Never>?

    static func registerCategories() {
        let actions = ReminderAction.allCases.map {
            UNNotificationAction(identifier: $0.rawValue, title: $0.title)
        }
        let category = UNNotificationCategory(identifier: categoryID, actions: actions, intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Notifications for the nudges, then alarms for the first alert.
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await Alarms.requestPermission()
    }

    /// The nudge a reminder is on right now: 0 for the first alert, up to `NudgeTiming.count`.
    static func step(for reminder: Reminder, at now: Date = .now) -> Int {
        let elapsed = now.timeIntervalSince(reminder.dueDate)
        return min(max(Int(elapsed / NudgeTiming.interval), 0), NudgeTiming.count)
    }

    /// Applies a button press from anywhere: a notification, the alert, or the Today list.
    func perform(_ action: ReminderAction, on reminder: Reminder) {
        switch action {
        case .done:
            reminder.complete()
        case .snooze15:
            reminder.snooze(until: .now.addingTimeInterval(15 * 60))
        case .tonight:
            reminder.snooze(until: WhenPreset.tonight.date() ?? .now.addingTimeInterval(60 * 60))
        }
        clearDelivered(for: reminder)
        saveAndReschedule()
    }

    func saveAndReschedule() {
        try? container.mainContext.save()
        reschedule()
    }

    /// Takes a reminder's alerts out of Notification Center once it's handled.
    func clearDelivered(for reminder: Reminder) {
        let ids = (0...NudgeTiming.count).map { "\(reminder.uuid.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// Brings up the full-screen alert for the earliest reminder that's due and not yet slipped.
    func showDueAlert() {
        guard AlertCenter.shared.current == nil else { return }
        let now = Date.now
        let due = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt == nil && $0.dueDate <= now },
                                            sortBy: [SortDescriptor(\.dueDate)])
        let reminders = (try? container.mainContext.fetch(due)) ?? []
        if let first = reminders.first(where: { !$0.isSlipped }) {
            AlertCenter.shared.show(first.uuid)
        }
    }

    /// Replaces every pending notification and alarm with the soonest ones across all open reminders.
    func reschedule() {
        let open = FetchDescriptor<Reminder>(predicate: #Predicate { $0.completedAt == nil },
                                             sortBy: [SortDescriptor(\.dueDate)])
        let reminders = (try? container.mainContext.fetch(open)) ?? []
        let now = Date.now

        // Reminders whose first alert rings as an alarm skip the matching notification.
        let alarmed = Alarms.isAuthorized
            ? Array(reminders.filter { $0.dueDate > now }.prefix(Alarms.limit))
            : []
        let alarmedIDs = Set(alarmed.map(\.uuid))
        let previous = alarmTask
        alarmTask = Task {
            previous?.cancel()
            await previous?.value
            await Alarms.sync(alarmed)
        }

        let upcoming = reminders
            .flatMap { Self.requests(for: $0, skipFirst: alarmedIDs.contains($0.uuid)) }
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .prefix(Self.pendingLimit)

        // Lets Siri match phrases like "done with dentist" against current reminders.
        NabbitShortcuts.updateAppShortcutParameters()
        WidgetCenter.shared.reloadAllTimelines()
        WatchLink.shared.send()

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for item in upcoming {
            center.add(item.request)
        }
    }

    /// The alert at the due time, then a nudge every interval.
    private static func requests(for reminder: Reminder,
                                 skipFirst: Bool) -> [(date: Date, request: UNNotificationRequest)] {
        ((skipFirst ? 1 : 0)...NudgeTiming.count).map { step in
            let date = reminder.dueDate.addingTimeInterval(Double(step) * NudgeTiming.interval)
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

    /// Gets more direct with each nudge, in the person's chosen tone.
    static func body(for reminder: Reminder, step: Int) -> String {
        Copy.nudge(for: reminder, step: step)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// With the app open, the full-screen alert takes over instead of a banner.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard let id = notification.request.content.userInfo[Self.reminderKey] as? String,
              let uuid = UUID(uuidString: id) else { return [.banner, .list, .sound] }
        await AlertCenter.shared.show(uuid)
        return [.list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        guard let id = response.notification.request.content.userInfo[Self.reminderKey] as? String else { return }
        await handle(action: action, reminderID: id)
    }

    private func handle(action: String, reminderID: String) {
        guard let uuid = UUID(uuidString: reminderID) else { return }
        // Tapping the notification itself opens the full-screen alert.
        guard let action = ReminderAction(rawValue: action) else {
            if action == UNNotificationDefaultActionIdentifier {
                AlertCenter.shared.show(uuid)
            }
            return
        }
        let match = FetchDescriptor<Reminder>(predicate: #Predicate { $0.uuid == uuid })
        guard let reminder = try? container.mainContext.fetch(match).first else { return }
        perform(action, on: reminder)
    }
}
