import Foundation

nonisolated struct LogEntry: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let film: Film
    var rating: Double
    var isGoldenPopcorn: Bool
    var review: String
    let dateWatched: Date
    let userId: String
    let username: String
    var episodeInfo: String?

    init(id: String = UUID().uuidString, film: Film, rating: Double = 0, isGoldenPopcorn: Bool = false, review: String = "", dateWatched: Date = Date(), userId: String = "", username: String = "", episodeInfo: String? = nil) {
        self.id = id
        self.film = film
        self.rating = rating
        self.isGoldenPopcorn = isGoldenPopcorn
        self.review = review
        self.dateWatched = dateWatched
        self.userId = userId
        self.username = username
        self.episodeInfo = episodeInfo
    }
}
