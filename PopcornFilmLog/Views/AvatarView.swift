import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var customURL: String? = nil

    static let avatarURLs: [String: String] = [
        "avatar_1": "https://image.tmdb.org/t/p/w780/tSPT36ZKlP2WVHJLM4cQPLSzv3b.jpg",
        "avatar_2": "https://image.tmdb.org/t/p/w780/xRyINp9KfMLVjRiO5nCsoRDdvvF.jpg",
        "avatar_3": "https://image.tmdb.org/t/p/w780/96hiUXEuYsu4tcnvlaY8tEMFM0m.jpg",
        "avatar_4": "https://image.tmdb.org/t/p/w780/iffzIhuLAO38Po6sh1s6ZEVwlNL.jpg",
        "avatar_5": "https://image.tmdb.org/t/p/w780/AmR3JG1VQVxU8TfAvljUhfSFUOx.jpg",
        "avatar_6": "https://image.tmdb.org/t/p/w780/aYcnDyLMnpKce1FOYUpZrXtgUye.jpg",
        "avatar_7": "https://image.tmdb.org/t/p/w780/9uddYYTNcLWpzUkl5iw1RUYhLhY.jpg",
        "avatar_8": "https://image.tmdb.org/t/p/w780/jhk6D8pim3yaByu1801kMoxXFaX.jpg",
    ]

    static let avatarLabels: [String: String] = [
        "avatar_1": "Vito Corleone",
        "avatar_2": "Tyler Durden",
        "avatar_3": "Mia Wallace",
        "avatar_4": "The Bride",
        "avatar_5": "Ripley",
        "avatar_6": "Clarice Starling",
        "avatar_7": "Travis Bickle",
        "avatar_8": "Maximus",
    ]

    private var avatarImageURL: URL? {
        if let urlString = Self.avatarURLs[name] {
            return URL(string: urlString)
        }
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 8 {
            return URL(string: Self.avatarURLs["avatar_\(num)"] ?? "")
        }
        let index = (abs(name.hashValue) % 8) + 1
        return URL(string: Self.avatarURLs["avatar_\(index)"] ?? "")
    }

    var body: some View {
        if let url = customURL, !url.isEmpty {
            if url.hasPrefix("local://") {
                localPhotoView
            } else if let imageURL = URL(string: url) {
                remoteImageView(url: imageURL)
            } else {
                avatarImageView
            }
        } else {
            avatarImageView
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
            avatarImageView
        }
    }

    private func remoteImageView(url: URL) -> some View {
        Color(red: 0.94, green: 0.93, blue: 0.91)
            .frame(width: size, height: size)
            .overlay {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        avatarPlaceholder
                    } else {
                        ProgressView()
                            .tint(PopcornTheme.sepiaBrown)
                    }
                }
                .allowsHitTesting(false)
            }
            .clipShape(Circle())
    }

    private var avatarImageView: some View {
        Color(red: 0.94, green: 0.93, blue: 0.91)
            .frame(width: size, height: size)
            .overlay {
                if let url = avatarImageURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            avatarPlaceholder
                        } else {
                            avatarPlaceholder
                        }
                    }
                    .allowsHitTesting(false)
                } else {
                    avatarPlaceholder
                }
            }
            .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.4))
            .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.4))
    }
}
