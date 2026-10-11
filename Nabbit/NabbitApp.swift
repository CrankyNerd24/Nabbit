import SwiftData
import SwiftUI

@main
struct NabbitApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Reminder.self, Thing.self])
    }
}
