import Foundation
import UserNotifications

/// The iPhone's alerts and nudges show up on the watch with Done, 15 min, and Tonight.
/// When one of those is tapped here, it goes to the iPhone like any other watch tap.
final class WatchNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WatchNotifications()

    static func register() {
        let actions = ReminderAction.allCases.map {
            UNNotificationAction(identifier: $0.rawValue, title: $0.title)
        }
        let category = UNNotificationCategory(identifier: ReminderAction.notificationCategory,
                                              actions: actions, intentIdentifiers: [])
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        center.delegate = shared
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        guard let action = ReminderAction(rawValue: response.actionIdentifier),
              let id = response.notification.request.content.userInfo[ReminderAction.reminderKey] as? String,
              let uuid = UUID(uuidString: id) else { return }
        await WatchNotifications.apply(action, to: uuid)
    }

    private static func apply(_ action: ReminderAction, to id: UUID) {
        let model = WatchModel.shared
        if let note = model.snapshot.notes.first(where: { $0.id == id }) {
            model.perform(action, on: note)
        } else {
            PhoneLink.shared.send(.act(action, reminder: id))
        }
    }
}
