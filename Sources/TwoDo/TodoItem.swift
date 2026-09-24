import Foundation

/// A wall-clock time of day, e.g. 13:00.
struct TimeOfDay: Codable, Equatable, Hashable {
    var hour: Int
    var minute: Int

    /// The next slot to suggest after this one: an hour later, wrapping
    /// past midnight. Makes "1 PM, 2 PM, 3 PM" a couple of clicks.
    var nextHour: TimeOfDay {
        TimeOfDay(hour: (hour + 1) % 24, minute: minute)
    }
}

/// When a reminder should proactively pop the popover open.
enum ReminderSchedule: Equatable {
    /// Every time the app launches (i.e. every login, once "Launch at
    /// Login" is enabled).
    case atLogin
    /// Every day at each of these wall-clock times, checked while the app
    /// is running. Capped at `ReminderSchedule.maxDailyTimes`.
    case daily([TimeOfDay])

    static let maxDailyTimes = 12

    var isDaily: Bool {
        if case .daily = self { return true }
        return false
    }

    var times: [TimeOfDay] {
        if case .daily(let times) = self { return times }
        return []
    }
}

extension ReminderSchedule: Codable {
    private enum CodingKeys: String, CodingKey {
        case atLogin, daily
        /// Pre-multi-slot format: `{"dailyAt": {"hour": 9, "minute": 0}}`.
        case dailyAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.daily) {
            let times = try container.decode([TimeOfDay].self, forKey: .daily)
            self = .daily(Array(times.prefix(Self.maxDailyTimes)))
        } else if container.contains(.dailyAt) {
            self = .daily([try container.decode(TimeOfDay.self, forKey: .dailyAt)])
        } else {
            self = .atLogin
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .atLogin:
            try container.encode([String: String](), forKey: .atLogin)
        case .daily(let times):
            try container.encode(times, forKey: .daily)
        }
    }
}

/// A recurring reminder. TwoDo caps the list — see `TodoStore.maxItems`.
/// These aren't one-off tasks you check off; they're persistent nudges
/// that resurface on their schedule.
struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var schedule: ReminderSchedule

    init(id: UUID = UUID(), text: String = "", schedule: ReminderSchedule = .atLogin) {
        self.id = id
        self.text = text
        self.schedule = schedule
    }
}
