import Foundation
import Combine
import ServiceManagement

/// Persists the (max two) focus items to UserDefaults and manages the
/// "Launch at Login" system login item via ServiceManagement.
final class TodoStore: ObservableObject {
    static let maxItems = 2
    private static let storageKey = "twodo.items"

    @Published var items: [TodoItem] {
        didSet { persist() }
    }

    @Published var launchAtLogin: Bool {
        didSet { updateLoginItem() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            self.items = Array(decoded.prefix(Self.maxItems))
        } else {
            self.items = []
        }
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    var canAddItem: Bool { items.count < Self.maxItems }

    func addItem() {
        guard canAddItem else { return }
        items.append(TodoItem())
    }

    func removeItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
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
}
