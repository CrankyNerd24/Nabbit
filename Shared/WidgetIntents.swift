import AppIntents
import Foundation

// Intents the widgets and controls trigger. Each target has its own `WidgetActions`:
// the app's does the work, the extension's is empty because these run in the app.

/// The Done button on a widget and on a ringing alarm. A LiveActivityIntent runs in the
/// app's process, so it clears nudges, alarms, and notifications like any other Done.
struct CompleteReminderIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Mark reminder done"
    static let isDiscoverable = false

    @Parameter(title: "Reminder")
    var reminderID: String

    init() {}

    init(reminderID: UUID) {
        self.reminderID = reminderID.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: reminderID) {
            await WidgetActions.done(id)
        }
        return .result()
    }
}

/// The New reminder control, also usable on the Action button: opens Nabbit on the verb grid.
struct OpenCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "New reminder"
    static let isDiscoverable = false
    /// Brings Nabbit forward before `perform` runs.
    static let supportedModes: IntentModes = .foreground(.immediate)

    func perform() async throws -> some IntentResult {
        await WidgetActions.openCapture()
        return .result()
    }
}

// Some system surfaces still look for this flag. Apple's documented way to keep it
// alongside supportedModes without a warning.
@available(*, deprecated)
extension OpenCaptureIntent {
    static var openAppWhenRun: Bool { true }
}
