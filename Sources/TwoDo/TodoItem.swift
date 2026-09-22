import Foundation

/// When a reminder should proactively pop the popover open.
enum ReminderSchedule: Codable, Equatable {
    /// Every time the app launches (i.e. every login, once "Launch at
    /// Login" is enabled).
    case atLogin
    /// Every day at a specific wall-clock time, checked while the app is
    /// running.
    case dailyAt(hour: Int, minute: Int)

    var isDailyAt: Bool {
        if case .dailyAt = self { return true }
        return false
    }

    var hour: Int {
        if case .dailyAt(let h, _) = self { return h }
        return 9
    }

    var minute: Int {
        if case .dailyAt(_, let m) = self { return m }
        return 0
    }
}

/// A recurring reminder. TwoDo caps the list at two — see
/// `TodoStore.maxItems`. These aren't one-off tasks you check off; they're
/// persistent nudges that resurface on their schedule.
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
