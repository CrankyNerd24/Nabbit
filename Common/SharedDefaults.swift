import Foundation

extension UserDefaults {
    static let appGroup = "group.CrankyNerdNew.Nabbit"

    /// Settings the app and its widgets both read: theme, default times, nudge timing.
    /// UserDefaults is thread-safe, so sharing one instance is fine.
    nonisolated(unsafe) static let nabbit = UserDefaults(suiteName: appGroup) ?? .standard
}
