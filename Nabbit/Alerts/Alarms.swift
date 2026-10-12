import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI

/// Rings a real alarm at each reminder's due time, through silent mode and Focus.
/// Only the first alert rings; the nudges after it stay as notifications.
enum Alarms {
    /// Alarms are scheduled for the soonest reminders only, like notifications.
    static let limit = 20

    static var isAuthorized: Bool {
        AlarmManager.shared.authorizationState == .authorized
    }

    static func requestPermission() async {
        _ = try? await AlarmManager.shared.requestAuthorization()
    }

    /// Replaces every scheduled alarm with one per upcoming reminder.
    static func sync(_ reminders: [Reminder]) async {
        guard isAuthorized else { return }
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] {
            try? manager.cancel(id: alarm.id)
        }

        let theme = Theme.named(UserDefaults.nabbit.string(forKey: Theme.storageKey) ?? "")
        for reminder in reminders {
            if Task.isCancelled { return }
            let id = reminder.uuid
            // The system supplies Stop, which only silences the alarm: nudges keep
            // coming until it's marked done. Done marks it done without opening
            // anything, so it works from the watch too.
            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: reminder.text),
                secondaryButton: AlarmButton(text: "Done", textColor: theme.alert.text.color,
                                             systemImageName: "checkmark"),
                secondaryButtonBehavior: .custom)
            let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alert),
                                             metadata: NabbitAlarm(),
                                             tintColor: theme.alert.color)
            let configuration = AlarmManager.AlarmConfiguration.alarm(
                schedule: .fixed(reminder.dueDate),
                attributes: attributes,
                stopIntent: nil,
                secondaryIntent: CompleteReminderIntent(reminderID: id),
                sound: .default)
            _ = try? await manager.schedule(id: id, configuration: configuration)
        }
    }
}

nonisolated struct NabbitAlarm: AlarmMetadata {}

extension Alarms {
    /// Silences a reminder's alarm if it's ringing.
    static func stop(_ id: UUID) {
        try? AlarmManager.shared.stop(id: id)
    }
}
