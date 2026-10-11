import SwiftData
import SwiftUI
import UserNotifications

@main
struct NabbitApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Set before launch finishes so a button tapped on a notification is handled.
        UNUserNotificationCenter.current().delegate = Nudges.shared
        Nudges.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(Store.container)
        .onChange(of: scenePhase) {
            // Tops the rolling batch back up each time the app comes forward.
            if scenePhase == .active {
                Nudges.shared.reschedule()
                Nudges.shared.showDueAlert()
            }
        }
    }
}
