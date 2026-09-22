import SwiftUI

/// Visual language borrowed from a bold red/black/white "fight card"
/// aesthetic — heavy uppercase type, thin red accent lines, a "LIVE" dot.
enum Theme {
    static let background = Color.black
    static let surface = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let border = Color.white.opacity(0.08)
    static let red = Color(red: 0.92, green: 0.11, blue: 0.16)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.5)
}
