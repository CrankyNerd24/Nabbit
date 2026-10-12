import SwiftUI

@main
struct NabbitWatchApp: App {
    init() {
        WatchNotifications.register()
        PhoneLink.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}
