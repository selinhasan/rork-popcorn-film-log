import Foundation

nonisolated struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var username: String
    var email: String
    var profileImageName: String
    var topFiveFilms: [Film]
    var buddyIds: [String]
    let joinDate: Date

    init(id: String = UUID().uuidString, username: String, email: String, profileImageName: String = "avatar_1", topFiveFilms: [Film] = [], buddyIds: [String] = [], joinDate: Date = Date()) {
        self.id = id
        self.username = username
        self.email = email
        self.profileImageName = profileImageName
        self.topFiveFilms = topFiveFilms
        self.buddyIds = buddyIds
        self.joinDate = joinDate
    }
}
