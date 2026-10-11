import SwiftData

/// The one reminder store, shared by the UI, notification buttons, and alarm intents.
/// Opened on first use so an intent that launches the app in the background can reach it.
enum Store {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Reminder.self, Thing.self)
        } catch {
            fatalError("Could not open the reminder store: \(error)")
        }
    }()
}
