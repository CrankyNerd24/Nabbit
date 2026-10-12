import Foundation
import Observation
import SwiftData

/// What widget, control, and alarm buttons do, run inside the app.
enum WidgetActions {
    static func done(_ id: UUID) {
        Alarms.stop(id)
        let match = FetchDescriptor<Reminder>(predicate: #Predicate { $0.uuid == id })
        guard let reminder = try? Store.container.mainContext.fetch(match).first, !reminder.isDone else { return }
        Nudges.shared.perform(.done, on: reminder)
    }

    static func openCapture() {
        CaptureRequest.shared.count += 1
    }
}

/// Bumped when the New reminder control opens the app, so Home returns to the verb grid.
@Observable
final class CaptureRequest {
    static let shared = CaptureRequest()
    var count = 0
}
