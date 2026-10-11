import AppIntents
import SwiftUI
import WidgetKit

/// Control Center and the Action button: one press opens Nabbit ready to make a reminder.
struct NewReminderControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "CrankyNerdNew.Nabbit.NewReminder") {
            ControlWidgetButton(action: OpenCaptureIntent()) {
                Label("New reminder", systemImage: "note.text.badge.plus")
            }
        }
        .displayName("New reminder")
        .description("Opens Nabbit ready to make a reminder.")
    }
}
