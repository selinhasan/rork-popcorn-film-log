import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat

    private var avatarColors: (bg: Color, fg: Color) {
        let palettes: [(Color, Color)] = [
            (PopcornTheme.popcornYellow.opacity(0.25), PopcornTheme.sepiaBrown),
            (PopcornTheme.warmRed.opacity(0.2), PopcornTheme.warmRed),
            (PopcornTheme.freshGreen.opacity(0.2), PopcornTheme.freshGreen),
            (PopcornTheme.sepiaBrown.opacity(0.2), PopcornTheme.darkBrown),
            (Color(red: 0.9, green: 0.85, blue: 0.75), PopcornTheme.sepiaBrown),
            (PopcornTheme.popcornYellow.opacity(0.35), PopcornTheme.darkBrown),
            (PopcornTheme.warmRed.opacity(0.15), PopcornTheme.sepiaBrown),
            (PopcornTheme.freshGreen.opacity(0.15), PopcornTheme.darkBrown),
            (Color(red: 0.88, green: 0.82, blue: 0.72), PopcornTheme.warmRed),
            (PopcornTheme.cream, PopcornTheme.sepiaBrown),
        ]
        let index: Int
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            index = num - 1
        } else {
            index = abs(name.hashValue) % palettes.count
        }
        return palettes[index]
    }

    private var avatarSymbol: String {
        let symbols = [
            "person.fill", "person.crop.circle.fill", "face.smiling.inverse",
            "star.circle.fill", "heart.circle.fill", "theatermasks.fill",
            "film.fill", "sparkles", "camera.fill", "ticket.fill"
        ]
        let index: Int
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            index = num - 1
        } else {
            index = abs(name.hashValue) % symbols.count
        }
        return symbols[index]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColors.bg)
            Image(systemName: avatarSymbol)
                .font(.system(size: size * 0.4))
                .foregroundStyle(avatarColors.fg)
        }
        .frame(width: size, height: size)
    }
}
