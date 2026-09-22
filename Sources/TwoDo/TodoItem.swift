import Foundation

/// A single focus item. TwoDo intentionally caps the list at two —
/// see `TodoStore.maxItems`.
struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isDone: Bool

    init(id: UUID = UUID(), text: String = "", isDone: Bool = false) {
        self.id = id
        self.text = text
        self.isDone = isDone
    }
}
