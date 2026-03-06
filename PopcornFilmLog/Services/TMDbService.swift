import Foundation

class TMDbService {
    static let shared = TMDbService()

    private let baseURL = "https://api.themoviedb.org/3"

    private var apiKey: String {
        Config.EXPO_PUBLIC_TMDB_API_KEY
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + path)
        var items = queryItems
        items.append(URLQueryItem(name: "api_key", value: apiKey))
        components?.queryItems = items
        return components?.url
    }

    func searchMovies(query: String, page: Int = 1) async throws -> TMDbSearchResponse {
        guard let url = makeURL(path: "/search/movie", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "include_adult", value: "false")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbSearchResponse.self, from: data)
    }

    func searchMulti(query: String, page: Int = 1) async throws -> TMDbSearchResponse {
        guard let url = makeURL(path: "/search/multi", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "include_adult", value: "false")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbSearchResponse.self, from: data)
    }

    func getTrending(page: Int = 1) async throws -> TMDbSearchResponse {
        guard let url = makeURL(path: "/trending/movie/week", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbSearchResponse.self, from: data)
    }

    func getPopular(page: Int = 1) async throws -> TMDbSearchResponse {
        guard let url = makeURL(path: "/movie/popular", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbSearchResponse.self, from: data)
    }

    func getTopRated(page: Int = 1) async throws -> TMDbSearchResponse {
        guard let url = makeURL(path: "/movie/top_rated", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbSearchResponse.self, from: data)
    }

    func getMovieDetail(id: Int) async throws -> TMDbMovieDetail {
        guard let url = makeURL(path: "/movie/\(id)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbMovieDetail.self, from: data)
    }

    func getTVDetail(id: Int) async throws -> TMDbMovieDetail {
        guard let url = makeURL(path: "/tv/\(id)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits")
        ]) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbMovieDetail.self, from: data)
    }

    func getGenres() async throws -> [TMDbGenre] {
        guard let url = makeURL(path: "/genre/movie/list") else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(TMDbGenreList.self, from: data)
        return response.genres
    }

    func discoverMovies(genreId: Int? = nil, sortBy: String = "popularity.desc", page: Int = 1) async throws -> TMDbSearchResponse {
        var items = [
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        if let genreId {
            items.append(URLQueryItem(name: "with_genres", value: "\(genreId)"))
        }
        guard let url = makeURL(path: "/discover/movie", queryItems: items) else {
            throw TMDbError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(TMDbSearchResponse.self, from: data)
    }

    func tmdbMovieToFilm(_ movie: TMDbMovie, genres: [TMDbGenre] = []) -> Film {
        let genreNames = movie.genreIds?.compactMap { id in
            genres.first(where: { $0.id == id })?.name
        } ?? []

        return Film(
            id: "\(movie.id)",
            title: movie.displayTitle,
            year: movie.displayYear,
            genre: genreNames,
            director: "",
            cast: [],
            synopsis: movie.overview ?? "",
            posterURL: movie.posterURL,
            runtime: "",
            isTV: movie.isTV,
            averageRating: movie.rating5Scale
        )
    }
}

nonisolated enum TMDbError: Error, Sendable {
    case invalidURL
    case networkError
    case decodingError
    case noResults
}
