import Foundation
import SwiftData

/// The one reminder store, shared by the UI, notification buttons, intents, and the widgets.
/// It lives in the app group so the widget extension can read it, and opens on first use
/// so an intent that launches the app in the background can reach it.
enum Store {
    static let container: ModelContainer = {
        do {
            let shared = ModelConfiguration(groupContainer: .identifier(UserDefaults.appGroup))
            return try ModelContainer(for: Reminder.self, Thing.self, configurations: shared)
        } catch {
            fatalError("Could not open the reminder store: \(error)")
        }
    }()
}
