import Foundation
import Observation

/// Which reminder the full-screen alert is showing, if any.
@Observable
final class AlertCenter {
    static let shared = AlertCenter()

    var current: AlertItem?

    func show(_ id: UUID) {
        current = AlertItem(id: id)
    }
}

struct AlertItem: Identifiable, Equatable {
    let id: UUID
}
