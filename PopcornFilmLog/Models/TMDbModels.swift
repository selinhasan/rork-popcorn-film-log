import Foundation

nonisolated struct TMDbSearchResponse: Codable, Sendable {
    let page: Int
    let results: [TMDbMovie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

nonisolated struct TMDbMovie: Codable, Sendable, Identifiable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let genreIds: [Int]?
    let voteAverage: Double?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case genreIds = "genre_ids"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }

    var displayTitle: String {
        title ?? name ?? "Unknown"
    }

    var displayYear: String {
        let dateStr = releaseDate ?? firstAirDate ?? ""
        return String(dateStr.prefix(4))
    }

    var posterURL: String {
        guard let path = posterPath else { return "" }
        return "https://image.tmdb.org/t/p/w500\(path)"
    }

    var backdropURL: String {
        guard let path = backdropPath else { return "" }
        return "https://image.tmdb.org/t/p/w780\(path)"
    }

    var isTV: Bool {
        mediaType == "tv" || title == nil && name != nil
    }

    var rating5Scale: Double {
        guard let vote = voteAverage else { return 0 }
        return (vote / 2.0 * 10).rounded() / 10
    }
}

nonisolated struct TMDbMovieDetail: Codable, Sendable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let genres: [TMDbGenre]?
    let runtime: Int?
    let voteAverage: Double?
    let credits: TMDbCredits?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview, genres, runtime, credits
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
    }

    var displayTitle: String {
        title ?? name ?? "Unknown"
    }

    var displayYear: String {
        let dateStr = releaseDate ?? firstAirDate ?? ""
        return String(dateStr.prefix(4))
    }

    var posterURL: String {
        guard let path = posterPath else { return "" }
        return "https://image.tmdb.org/t/p/w500\(path)"
    }

    var directorName: String {
        credits?.crew?.first(where: { $0.job == "Director" })?.name ?? ""
    }

    var castNames: [String] {
        credits?.cast?.prefix(10).map(\.name) ?? []
    }

    var genreNames: [String] {
        genres?.map(\.name) ?? []
    }

    var runtimeString: String {
        guard let rt = runtime, rt > 0 else { return "" }
        let hours = rt / 60
        let mins = rt % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    var rating5Scale: Double {
        guard let vote = voteAverage else { return 0 }
        return (vote / 2.0 * 10).rounded() / 10
    }

    func toFilm() -> Film {
        Film(
            id: "\(id)",
            title: displayTitle,
            year: displayYear,
            genre: genreNames,
            director: directorName,
            cast: castNames,
            synopsis: overview ?? "",
            posterURL: posterURL,
            runtime: runtimeString,
            isTV: title == nil && name != nil,
            averageRating: rating5Scale
        )
    }
}

nonisolated struct TMDbGenre: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
}

nonisolated struct TMDbCredits: Codable, Sendable {
    let cast: [TMDbCastMember]?
    let crew: [TMDbCrewMember]?
}

nonisolated struct TMDbCastMember: Codable, Sendable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }

    var profileURL: String {
        guard let path = profilePath else { return "" }
        return "https://image.tmdb.org/t/p/w185\(path)"
    }
}

nonisolated struct TMDbCrewMember: Codable, Sendable {
    let id: Int
    let name: String
    let job: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, job
        case profilePath = "profile_path"
    }
}

nonisolated struct TMDbGenreList: Codable, Sendable {
    let genres: [TMDbGenre]
}
