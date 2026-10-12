import Foundation

/// When nudges fire, shared so the widgets can tell when something has slipped.
enum NudgeTiming {
    static let intervalKey = "nudgeMinutes"
    static let defaultMinutes = 10
    /// Nudges after the first alert. The last one is the final sound.
    static let count = 3

    static var interval: TimeInterval {
        let minutes = UserDefaults.nabbit.object(forKey: intervalKey) as? Int ?? defaultMinutes
        return TimeInterval(minutes * 60)
    }

    static func lastNudgeDate(after due: Date) -> Date {
        due.addingTimeInterval(Double(count) * interval)
    }
}
