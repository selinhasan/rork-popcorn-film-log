import Foundation

nonisolated struct FilmList: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var description: String
    var films: [Film]
    var isPublic: Bool
    var coverFilmId: String?
    let createdDate: Date

    init(id: String = UUID().uuidString, name: String, description: String = "", films: [Film] = [], isPublic: Bool = true, coverFilmId: String? = nil, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.films = films
        self.isPublic = isPublic
        self.coverFilmId = coverFilmId
        self.createdDate = createdDate
    }

    var coverPosterURL: String? {
        if let coverId = coverFilmId, let film = films.first(where: { $0.id == coverId }) {
            return film.posterURL
        }
        return films.first?.posterURL
    }
}
