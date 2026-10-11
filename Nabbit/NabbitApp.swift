import SwiftData
import SwiftUI
import UserNotifications

@main
struct NabbitApp: App {
    private let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            container = try ModelContainer(for: Reminder.self, Thing.self)
        } catch {
            fatalError("Could not open the reminder store: \(error)")
        }
        // Set before launch finishes so a button tapped on a notification is handled.
        Nudges.shared.container = container
        UNUserNotificationCenter.current().delegate = Nudges.shared
        Nudges.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) {
            // Tops the rolling batch back up each time the app comes forward.
            if scenePhase == .active {
                Nudges.shared.reschedule()
            }
        }
    }
}
