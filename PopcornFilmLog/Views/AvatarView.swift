import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var customURL: String? = nil

    private static let avatarURLs: [String: String] = [
        "avatar_1": "https://r2-pub.rork.com/generated-images/c9b74e53-8fdb-496a-befa-bc8d1a09ca22.png",
        "avatar_2": "https://r2-pub.rork.com/generated-images/c82123f2-c0c7-4ed9-99ed-9853d00732f4.png",
        "avatar_3": "https://r2-pub.rork.com/generated-images/541c8e74-84be-4f8c-a442-ac001010d813.png",
        "avatar_4": "https://r2-pub.rork.com/generated-images/ce9a47a6-1bc4-4763-a678-617123a53d74.png",
        "avatar_5": "https://r2-pub.rork.com/generated-images/45a66c7e-5a08-43c8-9663-e4f5883167ff.png",
        "avatar_6": "https://r2-pub.rork.com/generated-images/21b41308-9001-42a1-bbec-b313261bdf06.png",
        "avatar_7": "https://r2-pub.rork.com/generated-images/2d30faa1-52a1-47f7-8f68-6cf7c1e596f2.png",
        "avatar_8": "https://r2-pub.rork.com/generated-images/4101e5ee-654c-47a2-ae21-3d33e83d42e8.png",
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
