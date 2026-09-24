import Foundation
import Combine
import ServiceManagement

/// Persists the (max five) reminders to UserDefaults, manages the
/// "Launch at Login" system login item, and watches for daily-time
/// schedules coming due while the app is running.
final class TodoStore: ObservableObject {
    static let maxItems = 5
    private static let storageKey = "twodo.items"

    @Published var items: [TodoItem] {
        didSet { persist() }
    }

    @Published var launchAtLogin: Bool {
        didSet { updateLoginItem() }
    }

    /// Fired when a `.daily` time slot comes due while the app is
    /// running. AppDelegate wires this to `showPopover()`.
    var onScheduledTrigger: (() -> Void)?

    /// Fired when the user explicitly dismisses the popover (the "GOT IT"
    /// button) — the *only* thing that closes it. AppDelegate wires this
    /// to `closePopover()`.
    var onAcknowledge: (() -> Void)?

    private var scheduleTimer: Timer?
    /// Keyed by item + slot, so each of an item's daily times fires once
    /// per day independently.
    private var lastFiredDay: [String: String] = [:]
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            self.items = Array(decoded.prefix(Self.maxItems))
        } else {
            self.items = []
        }
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        startScheduleTimer()
    }

    deinit {
        scheduleTimer?.invalidate()
    }

    var canAddItem: Bool { items.count < Self.maxItems }

    func addItem() {
        guard canAddItem else { return }
        items.append(TodoItem())
    }

    func removeItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        lastFiredDay = lastFiredDay.filter { !$0.key.hasPrefix(item.id.uuidString) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func updateLoginItem() {
        do {
            switch (launchAtLogin, SMAppService.mainApp.status) {
            case (true, .notRegistered), (true, .notFound):
                try SMAppService.mainApp.register()
            case (false, .enabled), (false, .requiresApproval):
                try SMAppService.mainApp.unregister()
            default:
                break
            }
        } catch {
            NSLog("TwoDo: failed to update login item — \(error)")
        }
    }

    // MARK: - Scheduling

    private func startScheduleTimer() {
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkSchedules()
        }
        RunLoop.main.add(timer, forMode: .common)
        scheduleTimer = timer
    }

    private func checkSchedules() {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .minute], from: now)
        guard let currentHour = components.hour, let currentMinute = components.minute else { return }
        let todayKey = Self.dayFormatter.string(from: now)

        var shouldTrigger = false
        for item in items {
            for time in item.schedule.times {
                guard time.hour == currentHour, time.minute == currentMinute else { continue }
                let key = "\(item.id.uuidString)@\(time.hour):\(time.minute)"
                guard lastFiredDay[key] != todayKey else { continue }
                lastFiredDay[key] = todayKey
                shouldTrigger = true
            }
        }

        if shouldTrigger {
            onScheduledTrigger?()
        }
    }
}
