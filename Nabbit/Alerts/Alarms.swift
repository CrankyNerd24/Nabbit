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

        let theme = Theme.named(UserDefaults.standard.string(forKey: Theme.storageKey) ?? "")
        for reminder in reminders {
            if Task.isCancelled { return }
            let id = reminder.uuid
            // The system supplies Stop, which only silences the alarm: nudges keep
            // coming until it's marked done. Open goes to the full-screen alert.
            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: reminder.text),
                secondaryButton: AlarmButton(text: "Open", textColor: theme.alert.text.color,
                                             systemImageName: "arrow.up.forward.app"),
                secondaryButtonBehavior: .custom)
            let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alert),
                                             metadata: NabbitAlarm(),
                                             tintColor: theme.alert.color)
            let configuration = AlarmManager.AlarmConfiguration.alarm(
                schedule: .fixed(reminder.dueDate),
                attributes: attributes,
                stopIntent: nil,
                secondaryIntent: OpenAlarmIntent(reminderID: id.uuidString),
                sound: .default)
            _ = try? await manager.schedule(id: id, configuration: configuration)
        }
    }
}

nonisolated struct NabbitAlarm: AlarmMetadata {}

/// The alarm's Open button: launches Nabbit into the full-screen alert.
struct OpenAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Open reminder"
    /// Brings Nabbit forward before `perform` runs.
    static let supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Reminder")
    var reminderID: String

    init() {}

    init(reminderID: String) {
        self.reminderID = reminderID
    }

    func perform() async throws -> some IntentResult {
        if let uuid = UUID(uuidString: reminderID) {
            // Open handles it from here, so the alarm stops ringing.
            try? AlarmManager.shared.stop(id: uuid)
            await AlertCenter.shared.show(uuid)
        }
        return .result()
    }
}
