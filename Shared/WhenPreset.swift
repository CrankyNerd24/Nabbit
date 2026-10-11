import Foundation

/// The third tap. Tapping a chip saves the reminder.
enum WhenPreset: String, CaseIterable, Identifiable {
    case inOneHour, tonight, tomorrowMorning, nextMonday, pickDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inOneHour: "In 1 hour"
        case .tonight: "Tonight"
        case .tomorrowMorning: "Tomorrow AM"
        case .nextMonday: "Next Monday"
        case .pickDay: "Pick a day"
        }
    }

    /// The due date for this chip, or nil for Pick a day, which needs a date picker.
    func date(from now: Date = .now, times: DefaultTimes = .current, calendar: Calendar = .current) -> Date? {
        switch self {
        case .inOneHour:
            return now.addingTimeInterval(60 * 60)
        case .tonight:
            // Already past tonight's time: an hour from now still reads as tonight.
            let tonight = calendar.date(bySettingHour: times.tonightHour, minute: 0, second: 0, of: now)!
            return tonight > now ? tonight : now.addingTimeInterval(60 * 60)
        case .tomorrowMorning:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            return calendar.date(bySettingHour: times.morningHour, minute: 0, second: 0, of: tomorrow)
        case .nextMonday:
            // Search from tomorrow so on a Monday this means a week out, not today.
            let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
            let monday = DateComponents(hour: times.morningHour, minute: 0, weekday: 2)
            return calendar.nextDate(after: tomorrow, matching: monday, matchingPolicy: .nextTime)
        case .pickDay:
            return nil
        }
    }
}

/// The hours each chip maps to, set once in Settings.
struct DefaultTimes {
    static let tonightHourKey = "tonightHour"
    static let morningHourKey = "morningHour"

    var tonightHour = 19
    var morningHour = 9

    static var current: DefaultTimes {
        let defaults = UserDefaults.nabbit
        var times = DefaultTimes()
        if defaults.object(forKey: tonightHourKey) != nil {
            times.tonightHour = defaults.integer(forKey: tonightHourKey)
        }
        if defaults.object(forKey: morningHourKey) != nil {
            times.morningHour = defaults.integer(forKey: morningHourKey)
        }
        return times
    }
}

extension Date {
    /// How a due date reads back: "tonight at 7:00 PM", "tomorrow at 9:00 AM",
    /// "Monday at 9:00 AM", or "Oct 20 at 9:00 AM".
    func dueDescription(from now: Date = .now, calendar: Calendar = .current) -> String {
        let time = formatted(date: .omitted, time: .shortened)
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                           to: calendar.startOfDay(for: self)).day ?? 0
        switch days {
        case 0: return calendar.component(.hour, from: self) >= 17 ? "tonight at \(time)" : "today at \(time)"
        case 1: return "tomorrow at \(time)"
        case 2..<7: return "\(formatted(.dateTime.weekday(.wide))) at \(time)"
        default: return "\(formatted(.dateTime.month(.abbreviated).day())) at \(time)"
        }
    }
}
