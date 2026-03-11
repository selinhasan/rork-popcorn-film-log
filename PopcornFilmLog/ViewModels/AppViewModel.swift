import SwiftUI

@Observable
@MainActor
class AppViewModel {
    var isLoggedIn: Bool = false
    var hasCompletedOnboarding: Bool = false
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

    var authError: String?
    var isSyncing = false

    private let tmdb = TMDbService.shared
    private let auth = AuthClient.shared
    private let tokenKey = "auth_token"

    init() {
        if let token = KeychainService.load(key: tokenKey),
           let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
            isLoggedIn = true
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            loadLocalDiary()
            loadLocalLists()
            loadBuddies()
            Task { await refreshProfile(token: token) }
        }
        Task { await loadTMDbData() }
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

    // MARK: - Auth

    func signUp(username: String, email: String, password: String) async throws {
        authError = nil
        let response = try await auth.register(username: username, email: email, password: password)
        KeychainService.save(key: tokenKey, value: response.token)
        let user = mapServerUser(response.user)
        currentUser = user
        isLoggedIn = true
        saveUserLocally()
        loadBuddies()
    }

    func logIn(email: String, password: String) async throws {
        authError = nil
        let response = try await auth.login(email: email, password: password)
        KeychainService.save(key: tokenKey, value: response.token)
        let user = mapServerUser(response.user)
        currentUser = user
        isLoggedIn = true
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        diaryEntries = response.user.diaryEntries
        filmLists = response.user.filmLists

        saveUserLocally()
        saveLocalDiary()
        saveLocalLists()
        loadBuddies()
    }

    func logOut() {
        KeychainService.delete(key: tokenKey)
        currentUser = nil
        isLoggedIn = false
        hasCompletedOnboarding = false
        diaryEntries = []
        buddies = []
        buddyLogs = []
        posts = []
        filmLists = []
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "diaryEntries")
        UserDefaults.standard.removeObject(forKey: "filmLists")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    func deleteAccount() {
        guard let token = KeychainService.load(key: tokenKey) else {
            logOut()
            return
        }
        Task {
            try? await auth.deleteAccount(token: token)
            logOut()
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func requestPasswordReset(email: String) async -> Bool {
        do {
            let _ = try await auth.requestPasswordReset(email: email)
            return true
        } catch {
            return false
        }
    }

    func changePassword(current: String, new: String) async throws {
        guard let token = KeychainService.load(key: tokenKey) else {
            throw AuthError.unauthorized
        }
        try await auth.changePassword(token: token, currentPassword: current, newPassword: new)
    }

    // MARK: - Profile

    func updateProfile(username: String? = nil, profileImage: String? = nil, customImageURL: String? = nil, bio: String? = nil, topFive: [Film]? = nil) {
        if let username { currentUser?.username = username }
        if let profileImage { currentUser?.profileImageName = profileImage }
        if let customImageURL { currentUser?.customProfileImageURL = customImageURL }
        if let bio { currentUser?.bio = bio }
        if let topFive { currentUser?.topFiveFilms = topFive }
        saveUserLocally()
        syncProfileToServer()
    }

    func setGoldenPopcorn(filmId: String) {
        for i in diaryEntries.indices {
            diaryEntries[i].isGoldenPopcorn = diaryEntries[i].film.id == filmId
        }
        currentUser?.goldenPopcornFilmId = filmId
        saveLocalDiary()
        saveUserLocally()
        syncDataToServer()
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
        syncDataToServer()
    }

    // MARK: - Watchlist

    func addToWatchlist(_ film: Film) {
        guard let user = currentUser else { return }
        guard !user.watchlist.contains(where: { $0.id == film.id }) else { return }
        currentUser?.watchlist.append(film)
        saveUserLocally()
        syncProfileToServer()

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
        syncProfileToServer()
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
        syncDataToServer()
    }

    func updateList(_ list: FilmList) {
        guard let idx = filmLists.firstIndex(where: { $0.id == list.id }) else { return }
        filmLists[idx] = list
        saveLocalLists()
        syncDataToServer()
    }

    func deleteList(_ list: FilmList) {
        filmLists.removeAll { $0.id == list.id }
        saveLocalLists()
        syncDataToServer()
    }

    func addFilmToList(_ film: Film, listId: String) {
        guard let idx = filmLists.firstIndex(where: { $0.id == listId }) else { return }
        guard !filmLists[idx].films.contains(where: { $0.id == film.id }) else { return }
        filmLists[idx].films.append(film)
        saveLocalLists()
        syncDataToServer()
    }

    func removeFilmFromList(_ film: Film, listId: String) {
        guard let idx = filmLists.firstIndex(where: { $0.id == listId }) else { return }
        filmLists[idx].films.removeAll { $0.id == film.id }
        saveLocalLists()
        syncDataToServer()
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

    private func mapServerUser(_ serverUser: ServerUser) -> UserProfile {
        let dateFormatter = ISO8601DateFormatter()
        let joinDate = dateFormatter.date(from: serverUser.joinDate) ?? Date()

        return UserProfile(
            id: serverUser.id,
            username: serverUser.username,
            email: serverUser.email,
            profileImageName: serverUser.profileImageName,
            customProfileImageURL: serverUser.customProfileImageURL,
            bio: serverUser.bio,
            topFiveFilms: serverUser.topFiveFilms,
            goldenPopcornFilmId: serverUser.goldenPopcornFilmId,
            buddyIds: serverUser.buddyIds,
            watchlist: serverUser.watchlist,
            joinDate: joinDate
        )
    }

    private func refreshProfile(token: String) async {
        do {
            let response = try await auth.getProfile(token: token)
            let user = mapServerUser(response.user)
            currentUser = user
            saveUserLocally()

            let dataResponse = try await auth.getData(token: token)
            if !dataResponse.diaryEntries.isEmpty {
                diaryEntries = dataResponse.diaryEntries
                saveLocalDiary()
            }
            if !dataResponse.filmLists.isEmpty {
                filmLists = dataResponse.filmLists
                saveLocalLists()
            }
        } catch {
            // Keep using local data if server is unreachable
        }
    }

    private func syncProfileToServer() {
        guard let token = KeychainService.load(key: tokenKey), let user = currentUser else { return }
        Task {
            var updates: [String: Any] = [:]
            updates["username"] = user.username
            updates["profileImageName"] = user.profileImageName
            updates["bio"] = user.bio

            if let customURL = user.customProfileImageURL {
                updates["customProfileImageURL"] = customURL
            }
            if let goldenId = user.goldenPopcornFilmId {
                updates["goldenPopcornFilmId"] = goldenId
            }

            if !user.topFiveFilms.isEmpty {
                updates["topFiveFilms"] = user.topFiveFilms.map { filmToDict($0) }
            }

            if !user.watchlist.isEmpty {
                updates["watchlist"] = user.watchlist.map { filmToDict($0) }
            }

            updates["buddyIds"] = user.buddyIds

            let _ = try? await auth.updateProfile(token: token, updates: updates)
        }
    }

    private func syncDataToServer() {
        guard let token = KeychainService.load(key: tokenKey) else { return }
        Task {
            isSyncing = true
            let diaryData = diaryEntries.compactMap { entry -> [String: Any]? in
                guard let data = try? JSONEncoder().encode(entry),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
                return dict
            }
            let listsData = filmLists.compactMap { list -> [String: Any]? in
                guard let data = try? JSONEncoder().encode(list),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
                return dict
            }
            let watchlistData = (currentUser?.watchlist ?? []).compactMap { film -> [String: Any]? in
                guard let data = try? JSONEncoder().encode(film),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
                return dict
            }
            try? await auth.syncData(token: token, diaryEntries: diaryData, filmLists: listsData, watchlist: watchlistData)
            isSyncing = false
        }
    }

    private func filmToDict(_ film: Film) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(film),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return dict
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




