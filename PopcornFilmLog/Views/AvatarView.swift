import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var customURL: String? = nil

    private var avatarIndex: Int {
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            return num - 1
        }
        return abs(name.hashValue) % 10
    }

    private var skinColor: Color {
        let skins: [Color] = [
            Color(red: 0.93, green: 0.80, blue: 0.68),
            Color(red: 0.87, green: 0.73, blue: 0.60),
            Color(red: 0.96, green: 0.85, blue: 0.74),
            Color(red: 0.80, green: 0.65, blue: 0.52),
            Color(red: 0.94, green: 0.82, blue: 0.70),
            Color(red: 0.91, green: 0.78, blue: 0.65),
            Color(red: 0.85, green: 0.70, blue: 0.56),
            Color(red: 0.96, green: 0.84, blue: 0.72),
            Color(red: 0.88, green: 0.75, blue: 0.62),
            Color(red: 0.93, green: 0.81, blue: 0.69),
        ]
        return skins[avatarIndex]
    }

    private var hairColor: Color {
        let hairs: [Color] = [
            Color(red: 0.20, green: 0.16, blue: 0.13),
            Color(red: 0.35, green: 0.22, blue: 0.12),
            Color(red: 0.14, green: 0.11, blue: 0.08),
            Color(red: 0.55, green: 0.35, blue: 0.18),
            Color(red: 0.22, green: 0.15, blue: 0.10),
            Color(red: 0.65, green: 0.30, blue: 0.15),
            Color(red: 0.18, green: 0.13, blue: 0.09),
            Color(red: 0.42, green: 0.28, blue: 0.15),
            Color(red: 0.12, green: 0.09, blue: 0.06),
            Color(red: 0.50, green: 0.32, blue: 0.16),
        ]
        return hairs[avatarIndex]
    }

    private var shirtColor: Color {
        let shirts: [Color] = [
            Color(red: 0.36, green: 0.53, blue: 0.58),
            Color(red: 0.72, green: 0.32, blue: 0.32),
            Color(red: 0.28, green: 0.42, blue: 0.52),
            Color(red: 0.45, green: 0.35, blue: 0.50),
            Color(red: 0.90, green: 0.78, blue: 0.30),
            Color(red: 0.55, green: 0.22, blue: 0.28),
            Color(red: 0.30, green: 0.48, blue: 0.42),
            Color(red: 0.38, green: 0.38, blue: 0.52),
            Color(red: 0.70, green: 0.38, blue: 0.30),
            Color(red: 0.32, green: 0.45, blue: 0.55),
        ]
        return shirts[avatarIndex]
    }

    private var shirtAccentColor: Color {
        let accents: [Color] = [
            .white.opacity(0.0),
            .white,
            .white.opacity(0.0),
            .white.opacity(0.0),
            .white.opacity(0.0),
            .white.opacity(0.0),
            .white.opacity(0.0),
            Color(red: 0.85, green: 0.55, blue: 0.20),
            .white.opacity(0.0),
            .white.opacity(0.0),
        ]
        return accents[avatarIndex]
    }

    private var bgColor: Color {
        Color(red: 0.94, green: 0.93, blue: 0.91)
    }

    private var isFeminine: Bool {
        [0, 2, 4, 5, 7, 9].contains(avatarIndex)
    }

    private var hasGlasses: Bool {
        [3, 6, 8].contains(avatarIndex)
    }

    var body: some View {
        if let url = customURL, !url.isEmpty {
            if url.hasPrefix("local://") {
                localPhotoView
            } else if let imageURL = URL(string: url) {
                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay {
                        AsyncImage(url: imageURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                flatAvatar
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
            } else {
                flatAvatar
            }
        } else {
            flatAvatar
        }
    }

    @ViewBuilder
    private var localPhotoView: some View {
        if let data = AppViewModel.loadLocalProfilePhoto(),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            flatAvatar
        }
    }

    private var flatAvatar: some View {
        ZStack {
            Circle()
                .fill(bgColor)

            shirtShape

            neckShape

            headShape

            hairShape

            if hasGlasses {
                glassesShape
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var headShape: some View {
        Ellipse()
            .fill(skinColor)
            .frame(width: size * 0.38, height: size * 0.42)
            .offset(y: -size * 0.08)
    }

    private var neckShape: some View {
        Rectangle()
            .fill(skinColor)
            .frame(width: size * 0.16, height: size * 0.14)
            .offset(y: size * 0.16)
    }

    private var shirtShape: some View {
        ZStack {
            Ellipse()
                .fill(shirtColor)
                .frame(width: size * 0.7, height: size * 0.5)
                .offset(y: size * 0.42)

            if avatarIndex == 1 {
                VShape(size: size)
                    .fill(shirtAccentColor)
                    .frame(width: size * 0.14, height: size * 0.12)
                    .offset(y: size * 0.26)
            }

            if avatarIndex == 7 {
                Circle()
                    .fill(shirtAccentColor)
                    .frame(width: size * 0.06, height: size * 0.06)
                    .offset(y: size * 0.30)
            }
        }
    }

    @ViewBuilder
    private var hairShape: some View {
        switch avatarIndex {
        case 0:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.42, height: size * 0.28)
                    .offset(y: -size * 0.24)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.30)
                    .offset(x: -size * 0.22, y: -size * 0.04)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.30)
                    .offset(x: size * 0.22, y: -size * 0.04)
            }
        case 1:
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(hairColor)
                .frame(width: size * 0.40, height: size * 0.18)
                .offset(y: -size * 0.24)
        case 2:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.44, height: size * 0.30)
                    .offset(y: -size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.07, height: size * 0.34)
                    .offset(x: -size * 0.21, y: -size * 0.02)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.07, height: size * 0.34)
                    .offset(x: size * 0.21, y: -size * 0.02)
                Circle()
                    .fill(Color(red: 0.75, green: 0.25, blue: 0.25))
                    .frame(width: size * 0.10, height: size * 0.10)
                    .offset(x: size * 0.12, y: -size * 0.32)
            }
        case 3:
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.10)
                    .fill(hairColor)
                    .frame(width: size * 0.42, height: size * 0.20)
                    .offset(y: -size * 0.23)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.44, height: size * 0.06)
                    .offset(y: -size * 0.17)
            }
        case 4:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.44, height: size * 0.26)
                    .offset(y: -size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.38)
                    .offset(x: -size * 0.22, y: -size * 0.02)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.38)
                    .offset(x: size * 0.22, y: -size * 0.02)
            }
        case 5:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.46, height: size * 0.30)
                    .offset(y: -size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.28)
                    .offset(x: -size * 0.22, y: -size * 0.04)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.28)
                    .offset(x: size * 0.22, y: -size * 0.04)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(Color(red: 0.85, green: 0.35, blue: 0.30))
                    .frame(width: size * 0.38, height: size * 0.04)
                    .offset(y: -size * 0.30)
            }
        case 6:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.42, height: size * 0.24)
                    .offset(y: -size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.06, height: size * 0.28)
                    .offset(x: -size * 0.20, y: -size * 0.04)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.06, height: size * 0.28)
                    .offset(x: size * 0.20, y: -size * 0.04)
            }
        case 7:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.44, height: size * 0.28)
                    .offset(y: -size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.07, height: size * 0.32)
                    .offset(x: -size * 0.21, y: -size * 0.02)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.07, height: size * 0.32)
                    .offset(x: size * 0.21, y: -size * 0.02)
            }
        case 8:
            ZStack {
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.44, height: size * 0.22)
                    .offset(y: -size * 0.24)
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.14, height: size * 0.10)
                    .offset(x: -size * 0.06, y: -size * 0.30)
            }
        default:
            ZStack {
                Ellipse()
                    .fill(hairColor)
                    .frame(width: size * 0.46, height: size * 0.28)
                    .offset(y: -size * 0.22)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.36)
                    .offset(x: -size * 0.22, y: -size * 0.02)
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.36)
                    .offset(x: size * 0.22, y: -size * 0.02)
                Circle()
                    .fill(Color(red: 0.90, green: 0.55, blue: 0.60))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(x: -size * 0.16, y: -size * 0.30)
            }
        }
    }

    private var glassesShape: some View {
        HStack(spacing: size * 0.04) {
            RoundedRectangle(cornerRadius: size * 0.03)
                .stroke(Color(red: 0.25, green: 0.25, blue: 0.30), lineWidth: max(1, size * 0.02))
                .frame(width: size * 0.14, height: size * 0.10)
            RoundedRectangle(cornerRadius: size * 0.03)
                .stroke(Color(red: 0.25, green: 0.25, blue: 0.30), lineWidth: max(1, size * 0.02))
                .frame(width: size * 0.14, height: size * 0.10)
        }
        .offset(y: -size * 0.08)
    }
}

struct VShape: Shape {
    let size: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.25))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY))
            path.closeSubpath()
        }
    }
}
