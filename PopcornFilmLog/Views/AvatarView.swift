import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var customURL: String? = nil

    private var avatarColors: (bg: Color, fg: Color, hair: Color, skin: Color) {
        let palettes: [(Color, Color, Color, Color)] = [
            (PopcornTheme.popcornYellow.opacity(0.25), PopcornTheme.sepiaBrown, Color(red: 0.3, green: 0.2, blue: 0.1), Color(red: 0.96, green: 0.84, blue: 0.72)),
            (PopcornTheme.warmRed.opacity(0.2), PopcornTheme.warmRed, Color(red: 0.15, green: 0.1, blue: 0.05), Color(red: 0.87, green: 0.72, blue: 0.58)),
            (PopcornTheme.freshGreen.opacity(0.2), PopcornTheme.freshGreen, Color(red: 0.6, green: 0.35, blue: 0.15), Color(red: 0.92, green: 0.78, blue: 0.65)),
            (PopcornTheme.sepiaBrown.opacity(0.2), PopcornTheme.darkBrown, Color(red: 0.2, green: 0.15, blue: 0.1), Color(red: 0.78, green: 0.6, blue: 0.45)),
            (Color(red: 0.9, green: 0.85, blue: 0.75), PopcornTheme.sepiaBrown, Color(red: 0.85, green: 0.65, blue: 0.3), Color(red: 0.95, green: 0.82, blue: 0.7)),
            (PopcornTheme.popcornYellow.opacity(0.35), PopcornTheme.darkBrown, Color(red: 0.1, green: 0.08, blue: 0.05), Color(red: 0.65, green: 0.48, blue: 0.35)),
            (PopcornTheme.warmRed.opacity(0.15), PopcornTheme.sepiaBrown, Color(red: 0.45, green: 0.25, blue: 0.1), Color(red: 0.9, green: 0.76, blue: 0.62)),
            (PopcornTheme.freshGreen.opacity(0.15), PopcornTheme.darkBrown, Color(red: 0.7, green: 0.5, blue: 0.25), Color(red: 0.94, green: 0.8, blue: 0.66)),
            (Color(red: 0.88, green: 0.82, blue: 0.72), PopcornTheme.warmRed, Color(red: 0.25, green: 0.18, blue: 0.1), Color(red: 0.82, green: 0.65, blue: 0.5)),
            (PopcornTheme.cream, PopcornTheme.sepiaBrown, Color(red: 0.55, green: 0.3, blue: 0.1), Color(red: 0.98, green: 0.86, blue: 0.74)),
        ]
        let index: Int
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            index = num - 1
        } else {
            index = abs(name.hashValue) % palettes.count
        }
        return palettes[index]
    }

    private var avatarIndex: Int {
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            return num - 1
        }
        return abs(name.hashValue) % 10
    }

    var body: some View {
        if let url = customURL, !url.isEmpty, let imageURL = URL(string: url) {
            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                .frame(width: size, height: size)
                .overlay {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            personAvatar
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Circle())
        } else {
            personAvatar
        }
    }

    private var personAvatar: some View {
        let colors = avatarColors
        return ZStack {
            Circle()
                .fill(colors.bg)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(colors.skin)
                        .frame(width: size * 0.38, height: size * 0.38)
                        .offset(y: size * 0.02)

                    hairStyle(color: colors.hair)
                }

                Capsule()
                    .fill(colors.fg.opacity(0.8))
                    .frame(width: size * 0.55, height: size * 0.28)
                    .offset(y: size * 0.04)
            }
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func hairStyle(color: Color) -> some View {
        let idx = avatarIndex
        switch idx % 5 {
        case 0:
            Capsule()
                .fill(color)
                .frame(width: size * 0.36, height: size * 0.2)
                .offset(y: -size * 0.1)
        case 1:
            Ellipse()
                .fill(color)
                .frame(width: size * 0.42, height: size * 0.24)
                .offset(y: -size * 0.12)
        case 2:
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(color)
                .frame(width: size * 0.34, height: size * 0.16)
                .offset(y: -size * 0.12)
        case 3:
            Circle()
                .fill(color)
                .frame(width: size * 0.44, height: size * 0.44)
                .offset(y: -size * 0.06)
        default:
            Capsule()
                .fill(color)
                .frame(width: size * 0.4, height: size * 0.22)
                .offset(y: -size * 0.11)
        }
    }
}
