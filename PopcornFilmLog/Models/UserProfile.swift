import Foundation

nonisolated struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var username: String
    var email: String
    var profileImageName: String
    var customProfileImageURL: String?
    var bio: String
    var topFiveFilms: [Film]
    var goldenPopcornFilmId: String?
    var buddyIds: [String]
    var watchlist: [Film]
    let joinDate: Date

    init(id: String = UUID().uuidString, username: String, email: String, profileImageName: String = "avatar_1", customProfileImageURL: String? = nil, bio: String = "", topFiveFilms: [Film] = [], goldenPopcornFilmId: String? = nil, buddyIds: [String] = [], watchlist: [Film] = [], joinDate: Date = Date()) {
        self.id = id
        self.username = username
        self.email = email
        self.profileImageName = profileImageName
        self.customProfileImageURL = customProfileImageURL
        self.bio = bio
        self.topFiveFilms = topFiveFilms
        self.goldenPopcornFilmId = goldenPopcornFilmId
        self.buddyIds = buddyIds
        self.watchlist = watchlist
        self.joinDate = joinDate
    }
}
