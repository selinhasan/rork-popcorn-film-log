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

    private var bgColor: Color {
        let colors: [Color] = [
            Color(red: 0.96, green: 0.89, blue: 0.76),
            Color(red: 0.88, green: 0.82, blue: 0.74),
            Color(red: 0.92, green: 0.85, blue: 0.72),
            Color(red: 0.85, green: 0.78, blue: 0.68),
            Color(red: 0.94, green: 0.87, blue: 0.78),
            Color(red: 0.93, green: 0.84, blue: 0.74),
            Color(red: 0.90, green: 0.86, blue: 0.78),
            Color(red: 0.95, green: 0.88, blue: 0.75),
            Color(red: 0.86, green: 0.80, blue: 0.72),
            Color(red: 0.91, green: 0.83, blue: 0.73),
        ]
        return colors[avatarIndex]
    }

    private var skinColor: Color {
        let skins: [Color] = [
            Color(red: 0.96, green: 0.87, blue: 0.77),
            Color(red: 0.90, green: 0.76, blue: 0.63),
            Color(red: 0.80, green: 0.64, blue: 0.50),
            Color(red: 0.70, green: 0.53, blue: 0.40),
            Color(red: 0.94, green: 0.84, blue: 0.74),
            Color(red: 0.96, green: 0.87, blue: 0.77),
            Color(red: 0.85, green: 0.70, blue: 0.56),
            Color(red: 0.75, green: 0.58, blue: 0.44),
            Color(red: 0.92, green: 0.80, blue: 0.68),
            Color(red: 0.88, green: 0.74, blue: 0.60),
        ]
        return skins[avatarIndex]
    }

    private var hairColor: Color {
        let hairs: [Color] = [
            Color(red: 0.22, green: 0.15, blue: 0.10),
            Color(red: 0.15, green: 0.10, blue: 0.06),
            Color(red: 0.55, green: 0.35, blue: 0.15),
            Color(red: 0.10, green: 0.08, blue: 0.05),
            Color(red: 0.40, green: 0.25, blue: 0.12),
            Color(red: 0.18, green: 0.12, blue: 0.08),
            Color(red: 0.60, green: 0.40, blue: 0.18),
            Color(red: 0.12, green: 0.08, blue: 0.05),
            Color(red: 0.50, green: 0.30, blue: 0.12),
            Color(red: 0.25, green: 0.18, blue: 0.10),
        ]
        return hairs[avatarIndex]
    }

    private var shirtColor: Color {
        let shirts: [Color] = [
            PopcornTheme.sepiaBrown,
            PopcornTheme.warmRed.opacity(0.85),
            PopcornTheme.freshGreen.opacity(0.85),
            PopcornTheme.darkBrown.opacity(0.8),
            PopcornTheme.popcornYellow.opacity(0.85),
            PopcornTheme.warmRed.opacity(0.75),
            PopcornTheme.sepiaBrown.opacity(0.85),
            PopcornTheme.freshGreen.opacity(0.75),
            PopcornTheme.darkBrown.opacity(0.7),
            PopcornTheme.warmRed.opacity(0.8),
        ]
        return shirts[avatarIndex]
    }

    private var isFeminine: Bool {
        avatarIndex >= 5
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
                                simpleAvatar
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
            } else {
                simpleAvatar
            }
        } else {
            simpleAvatar
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
            simpleAvatar
        }
    }

    private var simpleAvatar: some View {
        ZStack {
            Circle()
                .fill(bgColor)

            Circle()
                .fill(skinColor)
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(y: -size * 0.06)

            if isFeminine {
                feminineHair
            } else {
                masculineHair
            }

            HStack(spacing: size * 0.1) {
                Circle()
                    .fill(hairColor.opacity(0.85))
                    .frame(width: size * 0.06, height: size * 0.06)
                Circle()
                    .fill(hairColor.opacity(0.85))
                    .frame(width: size * 0.06, height: size * 0.06)
            }
            .offset(y: -size * 0.08)

            smilePath
                .stroke(hairColor.opacity(0.4), lineWidth: max(1, size * 0.02))
                .frame(width: size * 0.12, height: size * 0.06)
                .offset(y: size * 0.04)

            Capsule()
                .fill(shirtColor)
                .frame(width: size * 0.5, height: size * 0.22)
                .offset(y: size * 0.32)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var smilePath: Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 1, y: 0),
                control: CGPoint(x: 0.5, y: 1)
            )
        }
    }

    @ViewBuilder
    private var masculineHair: some View {
        let idx = avatarIndex
        switch idx {
        case 0:
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(hairColor)
                .frame(width: size * 0.44, height: size * 0.22)
                .offset(y: -size * 0.2)
        case 1:
            Capsule()
                .fill(hairColor)
                .frame(width: size * 0.46, height: size * 0.18)
                .offset(y: -size * 0.22)
        case 2:
            VStack(spacing: 0) {
                HStack(spacing: size * 0.04) {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(hairColor)
                            .frame(width: size * 0.1, height: size * 0.1)
                    }
                }
            }
            .offset(y: -size * 0.24)
        case 3:
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(hairColor)
                .frame(width: size * 0.42, height: size * 0.16)
                .offset(y: -size * 0.22)
        default:
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.46, height: size * 0.2)
                .offset(y: -size * 0.21)
        }
    }

    @ViewBuilder
    private var feminineHair: some View {
        let idx = avatarIndex - 5
        switch idx {
        case 0:
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.48, height: size * 0.26)
                .offset(y: -size * 0.2)
            HStack(spacing: size * 0.32) {
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.22)
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.08, height: size * 0.22)
            }
            .offset(y: -size * 0.02)
        case 1:
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.48, height: size * 0.28)
                .offset(y: -size * 0.19)
            HStack(spacing: size * 0.3) {
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.09, height: size * 0.18)
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.09, height: size * 0.18)
            }
            .offset(y: 0)
        case 2:
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.46, height: size * 0.24)
                .offset(y: -size * 0.2)
            Circle()
                .fill(hairColor)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(y: -size * 0.34)
        case 3:
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.48, height: size * 0.24)
                .offset(y: -size * 0.2)
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(hairColor)
                .frame(width: size * 0.42, height: size * 0.08)
                .offset(y: -size * 0.17)
            HStack(spacing: size * 0.34) {
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.07, height: size * 0.26)
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.07, height: size * 0.26)
            }
            .offset(y: -size * 0.01)
        default:
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.5, height: size * 0.28)
                .offset(y: -size * 0.19)
            HStack(spacing: size * 0.32) {
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.09, height: size * 0.24)
                Capsule()
                    .fill(hairColor)
                    .frame(width: size * 0.09, height: size * 0.24)
            }
            .offset(y: -size * 0.02)
        }
    }
}
