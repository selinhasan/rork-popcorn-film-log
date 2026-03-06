import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var customURL: String? = nil

    private static let avatarURLs: [String: String] = [
        "avatar_1": "https://r2-pub.rork.com/generated-images/bf0fe2a4-dcb6-4222-860b-cd6bd736a075.png",
        "avatar_2": "https://r2-pub.rork.com/generated-images/52f9d814-52e1-4430-b19c-41ea4bb4a2df.png",
        "avatar_3": "https://r2-pub.rork.com/generated-images/95bc10c1-4a86-460d-aa1d-1465813a588f.png",
        "avatar_4": "https://r2-pub.rork.com/generated-images/d81243c6-e8d5-4e1c-a5dd-555cd0dce722.png",
        "avatar_5": "https://r2-pub.rork.com/generated-images/848540ab-ca1c-4dc7-8bb0-381f7643872a.png",
        "avatar_6": "https://r2-pub.rork.com/generated-images/6309253c-5458-47a9-976c-86b8f8698605.png",
        "avatar_7": "https://r2-pub.rork.com/generated-images/158fa0e1-4016-4254-ada3-196bb9c57ea1.png",
        "avatar_8": "https://r2-pub.rork.com/generated-images/2ae44ece-0d61-447b-be14-0c49f84f7ea7.png",
        "avatar_9": "https://r2-pub.rork.com/generated-images/b547d028-e58c-4dd8-a7ea-834163d9c166.png",
        "avatar_10": "https://r2-pub.rork.com/generated-images/c892b966-9de3-4d2f-9f85-e680fe0f2d34.png",
    ]

    private var avatarImageURL: URL? {
        if let urlString = Self.avatarURLs[name] {
            return URL(string: urlString)
        }
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            return URL(string: Self.avatarURLs["avatar_\(num)"] ?? "")
        }
        let index = (abs(name.hashValue) % 10) + 1
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
