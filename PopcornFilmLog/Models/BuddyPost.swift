import Foundation

nonisolated struct BuddyPost: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let userId: String
    let username: String
    let profileImageName: String
    var text: String
    var likeCount: Int
    var isLiked: Bool
    var comments: [PostComment]
    let date: Date

    init(id: String = UUID().uuidString, userId: String, username: String, profileImageName: String = "avatar_1", text: String, likeCount: Int = 0, isLiked: Bool = false, comments: [PostComment] = [], date: Date = Date()) {
        self.id = id
        self.userId = userId
        self.username = username
        self.profileImageName = profileImageName
        self.text = text
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.comments = comments
        self.date = date
    }
}

nonisolated struct PostComment: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let userId: String
    let username: String
    let text: String
    let date: Date

    init(id: String = UUID().uuidString, userId: String, username: String, text: String, date: Date = Date()) {
        self.id = id
        self.userId = userId
        self.username = username
        self.text = text
        self.date = date
    }
}
