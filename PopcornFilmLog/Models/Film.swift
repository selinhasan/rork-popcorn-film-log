import Foundation

nonisolated struct Film: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let year: String
    let genre: [String]
    let director: String
    let cast: [String]
    let synopsis: String
    let posterURL: String
    let runtime: String
    let isTV: Bool

    init(id: String = UUID().uuidString, title: String, year: String, genre: [String] = [], director: String = "", cast: [String] = [], synopsis: String = "", posterURL: String = "", runtime: String = "", isTV: Bool = false) {
        self.id = id
        self.title = title
        self.year = year
        self.genre = genre
        self.director = director
        self.cast = cast
        self.synopsis = synopsis
        self.posterURL = posterURL
        self.runtime = runtime
        self.isTV = isTV
    }
}
