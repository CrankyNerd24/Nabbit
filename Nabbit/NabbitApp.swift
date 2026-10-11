import AppIntents
import SwiftData
import SwiftUI
import UserNotifications

@main
struct NabbitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(ThemeIntroView.shownKey, store: .nabbit) private var themeIntroShown = false

    init() {
        // Set before launch finishes so a button tapped on a notification is handled.
        UNUserNotificationCenter.current().delegate = Nudges.shared
        Nudges.registerCategories()
        NabbitShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .sheet(isPresented: Binding(get: { !themeIntroShown },
                                            set: { if !$0 { themeIntroShown = true } })) {
                    ThemeIntroView { themeIntroShown = true }
                }
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
