import SwiftUI

@Observable
@MainActor
class AppViewModel {
    var currentUser: UserProfile?
    var diaryEntries: [LogEntry] = []
    var buddies: [UserProfile] = []
    var buddyLogs: [LogEntry] = []
    var posts: [BuddyPost] = []
    var filmLists: [FilmList] = []

    var trendingFilms: [Film] = []
    var popularFilms: [Film] = []
    var searchResults: [Film] = []
    var tmdbGenres: [TMDbGenre] = []
    var isLoadingTrending = false
    var isSearching = false

    private let tmdb = TMDbService.shared

    init() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
        }
        loadLocalDiary()
        loadLocalLists()
        loadBuddies()
        Task { await loadTMDbData() }
    }

    func setUser(_ user: UserProfile) {
        currentUser = user
        saveUserLocally()
    }

    func loadTMDbData() async {
        isLoadingTrending = true
        do {
            async let genresTask = tmdb.getGenres()
            async let trendingTask = tmdb.getTrending()
            async let popularTask = tmdb.getPopular()

            let (genres, trending, popular) = try await (genresTask, trendingTask, popularTask)
            tmdbGenres = genres
            trendingFilms = trending.results.map { tmdb.tmdbMovieToFilm($0, genres: genres) }
            popularFilms = popular.results.map { tmdb.tmdbMovieToFilm($0, genres: genres) }
        } catch {
            trendingFilms = MockDataService.popularFilms
            popularFilms = MockDataService.popularFilms
        }
        isLoadingTrending = false
    }

    func searchFilms(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            let response = try await tmdb.searchMulti(query: query)
            searchResults = response.results
                .filter { $0.posterPath != nil }
                .map { tmdb.tmdbMovieToFilm($0, genres: tmdbGenres) }
        } catch {
            searchResults = MockDataService.allContent.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
        }
        isSearching = false
    }

    func fetchFilmDetail(filmId: String) async -> Film? {
        guard let id = Int(filmId) else { return nil }
        do {
            let detail = try await tmdb.getMovieDetail(id: id)
            return detail.toFilm()
        } catch {
            return nil
        }
    }

    func discoverFilms(genreId: Int? = nil, sortBy: String = "popularity.desc", page: Int = 1) async -> [Film] {
        do {
            let response = try await tmdb.discoverMovies(genreId: genreId, sortBy: sortBy, page: page)
            return response.results.map { tmdb.tmdbMovieToFilm($0, genres: tmdbGenres) }
        } catch {
            return []
        }
    }

    // MARK: - Profile

    func updateProfile(username: String? = nil, profileImage: String? = nil, customImageURL: String? = nil, bio: String? = nil, topFive: [Film]? = nil) {
        if let username { currentUser?.username = username }
        if let profileImage { currentUser?.profileImageName = profileImage }
        if let customImageURL { currentUser?.customProfileImageURL = customImageURL }
        if let bio { currentUser?.bio = bio }
        if let topFive { currentUser?.topFiveFilms = topFive }
        saveUserLocally()
    }

    func setGoldenPopcorn(filmId: String) {
        for i in diaryEntries.indices {
            diaryEntries[i].isGoldenPopcorn = diaryEntries[i].film.id == filmId
        }
        currentUser?.goldenPopcornFilmId = filmId
        saveLocalDiary()
        saveUserLocally()
    }

    // MARK: - Film Logging

    func logFilm(_ film: Film, rating: Double, review: String, episodeInfo: String? = nil, isGoldenPopcorn: Bool = false, listId: String? = nil, watchDate: Date = Date()) {
        if isGoldenPopcorn {
            for i in diaryEntries.indices {
                diaryEntries[i].isGoldenPopcorn = false
            }
            currentUser?.goldenPopcornFilmId = film.id
        }

        let entry = LogEntry(
            film: film,
            rating: rating,
            isGoldenPopcorn: isGoldenPopcorn,
            review: review,
            dateWatched: watchDate,
            userId: currentUser?.id ?? "",
            username: currentUser?.username ?? "",
            episodeInfo: episodeInfo
        )
        diaryEntries.insert(entry, at: 0)

        removeFromWatchlist(film)

        if let listId, let idx = filmLists.firstIndex(where: { $0.id == listId }) {
            if !filmLists[idx].films.contains(where: { $0.id == film.id }) {
                filmLists[idx].films.append(film)
                saveLocalLists()
            }
        }

        saveLocalDiary()
        saveUserLocally()
    }

    // MARK: - Watchlist

    func addToWatchlist(_ film: Film) {
        guard let user = currentUser else { return }
        guard !user.watchlist.contains(where: { $0.id == film.id }) else { return }
        currentUser?.watchlist.append(film)
        saveUserLocally()

        let post = BuddyPost(
            userId: user.id,
            username: user.username,
            profileImageName: user.profileImageName,
            text: "\(user.username) added \(film.title) to their watchlist",
            postType: .watchlistAdd,
            relatedFilm: film
        )
        posts.insert(post, at: 0)
    }

    func removeFromWatchlist(_ film: Film) {
        currentUser?.watchlist.removeAll { $0.id == film.id }
        saveUserLocally()
    }

    func isInWatchlist(_ film: Film) -> Bool {
        currentUser?.watchlist.contains(where: { $0.id == film.id }) ?? false
    }

    // MARK: - Buddies & Posts

    func addBuddy(_ buddy: UserProfile) {
        guard !buddies.contains(where: { $0.id == buddy.id }) else { return }
        buddies.append(buddy)
        currentUser?.buddyIds.append(buddy.id)
        saveUserLocally()
    }

    func togglePostLike(_ post: BuddyPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
    }

    func addComment(to post: BuddyPost, text: String) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let comment = PostComment(userId: currentUser?.id ?? "", username: currentUser?.username ?? "", text: text)
        posts[index].comments.append(comment)
    }

    func createPost(text: String, photoURLs: [String] = [], mentionedFilm: Film? = nil) {
        let post = BuddyPost(
            userId: currentUser?.id ?? "",
            username: currentUser?.username ?? "",
            profileImageName: currentUser?.profileImageName ?? "avatar_1",
            text: text,
            photoURLs: photoURLs,
            mentionedFilm: mentionedFilm
        )
        posts.insert(post, at: 0)
    }

    func saveProfilePhoto(_ data: Data) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
        try? data.write(to: path)
        currentUser?.customProfileImageURL = "local://profile_photo"
        saveUserLocally()
    }

    static func loadLocalProfilePhoto() -> Data? {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
        return try? Data(contentsOf: path)
    }

    // MARK: - Lists

    func createList(name: String, description: String = "", isPublic: Bool = true) {
        let list = FilmList(name: name, description: description, isPublic: isPublic)
        filmLists.append(list)
        saveLocalLists()
    }

    func updateList(_ list: FilmList) {
        guard let idx = filmLists.firstIndex(where: { $0.id == list.id }) else { return }
        filmLists[idx] = list
        saveLocalLists()
    }

    func deleteList(_ list: FilmList) {
        filmLists.removeAll { $0.id == list.id }
        saveLocalLists()
    }

    func addFilmToList(_ film: Film, listId: String) {
        guard let idx = filmLists.firstIndex(where: { $0.id == listId }) else { return }
        guard !filmLists[idx].films.contains(where: { $0.id == film.id }) else { return }
        filmLists[idx].films.append(film)
        saveLocalLists()
    }

    func removeFilmFromList(_ film: Film, listId: String) {
        guard let idx = filmLists.firstIndex(where: { $0.id == listId }) else { return }
        filmLists[idx].films.removeAll { $0.id == film.id }
        saveLocalLists()
    }

    func shareableListText(for list: FilmList) -> String {
        var text = "\(list.name)\n"
        if !list.description.isEmpty {
            text += "\(list.description)\n"
        }
        text += "\n"
        for (index, film) in list.films.enumerated() {
            text += "\(index + 1). \(film.title) (\(film.year))\n"
        }
        text += "\nShared from Popcorn Film Log 🍿"
        return text
    }

    // MARK: - Stats

    var userStats: UserStats {
        let films = diaryEntries.map(\.film)
        let filmsWatched = diaryEntries.count

        var totalMinutes = 0
        for film in films {
            totalMinutes += parseRuntime(film.runtime)
        }

        var actorCounts: [String: Int] = [:]
        for film in films {
            for actor in film.cast {
                actorCounts[actor, default: 0] += 1
            }
        }
        let topActors = actorCounts.sorted { $0.value > $1.value }.prefix(10).map {
            ActorStat(id: $0.key, name: $0.key, count: $0.value)
        }

        var directorCounts: [String: Int] = [:]
        for film in films {
            let dir = film.director
            guard !dir.isEmpty else { continue }
            directorCounts[dir, default: 0] += 1
        }
        let topDirectors = directorCounts.sorted { $0.value > $1.value }.prefix(10).map {
            DirectorStat(id: $0.key, name: $0.key, count: $0.value)
        }

        var genreCounts: [String: Int] = [:]
        for film in films {
            for genre in film.genre {
                genreCounts[genre, default: 0] += 1
            }
        }
        let topGenres = genreCounts.sorted { $0.value > $1.value }.prefix(10).map {
            GenreStat(id: $0.key, name: $0.key, count: $0.value)
        }

        return UserStats(
            filmsWatched: filmsWatched,
            totalMinutes: totalMinutes,
            topActors: Array(topActors),
            topDirectors: Array(topDirectors),
            topGenres: Array(topGenres)
        )
    }

    // MARK: - Private

    private func parseRuntime(_ runtime: String) -> Int {
        var minutes = 0
        let lower = runtime.lowercased()
        if let hRange = lower.range(of: "h") {
            let hStr = lower[lower.startIndex..<hRange.lowerBound].trimmingCharacters(in: .whitespaces)
            minutes += (Int(hStr) ?? 0) * 60
        }
        if let mRange = lower.range(of: "m") {
            var start = lower.startIndex
            if let hRange = lower.range(of: "h") {
                start = hRange.upperBound
            }
            let mStr = lower[start..<mRange.lowerBound].trimmingCharacters(in: .whitespaces)
            minutes += Int(mStr) ?? 0
        }
        if minutes == 0 {
            minutes = Int(runtime) ?? 0
        }
        return minutes
    }

    private func saveUserLocally() {
        guard let user = currentUser, let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: "currentUser")
    }

    private func saveLocalDiary() {
        guard let data = try? JSONEncoder().encode(diaryEntries) else { return }
        UserDefaults.standard.set(data, forKey: "diaryEntries")
    }

    private func loadLocalDiary() {
        guard let data = UserDefaults.standard.data(forKey: "diaryEntries"),
              let entries = try? JSONDecoder().decode([LogEntry].self, from: data) else { return }
        diaryEntries = entries
    }

    private func saveLocalLists() {
        guard let data = try? JSONEncoder().encode(filmLists) else { return }
        UserDefaults.standard.set(data, forKey: "filmLists")
    }

    private func loadLocalLists() {
        guard let data = UserDefaults.standard.data(forKey: "filmLists"),
              let lists = try? JSONDecoder().decode([FilmList].self, from: data) else { return }
        filmLists = lists
    }

    private func loadBuddies() {
        buddies = MockDataService.sampleBuddies
        buddyLogs = MockDataService.sampleBuddyLogs
        posts = MockDataService.samplePosts
    }
}
