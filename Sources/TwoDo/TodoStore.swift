import Foundation
import Combine
import ServiceManagement

/// Persists the (max two) reminders to UserDefaults, manages the
/// "Launch at Login" system login item, and watches for daily-time
/// schedules coming due while the app is running.
final class TodoStore: ObservableObject {
    static let maxItems = 2
    private static let storageKey = "twodo.items"

    @Published var items: [TodoItem] {
        didSet { persist() }
    }

    @Published var launchAtLogin: Bool {
        didSet { updateLoginItem() }
    }

    /// Fired when a `.dailyAt` schedule comes due while the app is
    /// running. AppDelegate wires this to `showPopover()`.
    var onScheduledTrigger: (() -> Void)?

    /// Fired when the user explicitly dismisses the popover (the "GOT IT"
    /// button) — the *only* thing that closes it. AppDelegate wires this
    /// to `closePopover()`.
    var onAcknowledge: (() -> Void)?

    private var scheduleTimer: Timer?
    private var lastFiredDay: [UUID: String] = [:]
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
        lastFiredDay.removeValue(forKey: item.id)
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
            guard case .dailyAt(let hour, let minute) = item.schedule else { continue }
            guard hour == currentHour, minute == currentMinute else { continue }
            guard lastFiredDay[item.id] != todayKey else { continue }
            lastFiredDay[item.id] = todayKey
            shouldTrigger = true
        }

        if shouldTrigger {
            onScheduledTrigger?()
        }
    }
}
