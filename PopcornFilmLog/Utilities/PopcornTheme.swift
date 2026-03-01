import SwiftUI

enum PopcornTheme {
    static let popcornYellow = Color(red: 0.95, green: 0.82, blue: 0.35)
    static let sepiaBrown = Color(red: 0.62, green: 0.47, blue: 0.32)
    static let warmRed = Color(red: 0.82, green: 0.25, blue: 0.22)
    static let freshGreen = Color(red: 0.36, green: 0.68, blue: 0.42)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let darkBrown = Color(red: 0.18, green: 0.13, blue: 0.10)
    static let cardBackground = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let subtleGray = Color(red: 0.75, green: 0.72, blue: 0.68)

    static let backgroundGradient = LinearGradient(
        colors: [cream, Color(red: 0.95, green: 0.92, blue: 0.85)],
        startPoint: .top,
        endPoint: .bottom
    )
}
