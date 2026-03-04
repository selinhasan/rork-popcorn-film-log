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

    init() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
            isLoggedIn = true
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            loadDiary()
            loadBuddies()
            loadLists()
        }
    }

    func signUp(username: String, email: String, password: String) {
        let user = UserProfile(id: "currentUser", username: username, email: email)
        currentUser = user
        isLoggedIn = true
        saveUser()
        loadBuddies()
    }

    func logIn(email: String, password: String) {
        let user = UserProfile(id: "currentUser", username: "popcornlover", email: email)
        currentUser = user
        isLoggedIn = true
        hasCompletedOnboarding = true
        saveUser()
        loadBuddies()
    }

    func logOut() {
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
        logOut()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

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
                saveLists()
            }
        }

        saveDiary()
        saveUser()
    }

    func updateProfile(username: String? = nil, profileImage: String? = nil, customImageURL: String? = nil, bio: String? = nil, topFive: [Film]? = nil) {
        if let username { currentUser?.username = username }
        if let profileImage { currentUser?.profileImageName = profileImage }
        if let customImageURL { currentUser?.customProfileImageURL = customImageURL }
        if let bio { currentUser?.bio = bio }
        if let topFive { currentUser?.topFiveFilms = topFive }
        saveUser()
    }

    func setGoldenPopcorn(filmId: String) {
        for i in diaryEntries.indices {
            if diaryEntries[i].film.id == filmId {
                diaryEntries[i].isGoldenPopcorn = true
            } else {
                diaryEntries[i].isGoldenPopcorn = false
            }
        }
        currentUser?.goldenPopcornFilmId = filmId
        saveDiary()
        saveUser()
    }

    func addToWatchlist(_ film: Film) {
        guard let user = currentUser else { return }
        guard !user.watchlist.contains(where: { $0.id == film.id }) else { return }
        currentUser?.watchlist.append(film)
        saveUser()

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
        saveUser()
    }

    func isInWatchlist(_ film: Film) -> Bool {
        currentUser?.watchlist.contains(where: { $0.id == film.id }) ?? false
    }

    func addBuddy(_ buddy: UserProfile) {
        guard !buddies.contains(where: { $0.id == buddy.id }) else { return }
        buddies.append(buddy)
        currentUser?.buddyIds.append(buddy.id)
        saveUser()
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
        saveUser()
    }

    static func loadLocalProfilePhoto() -> Data? {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_photo.jpg")
        return try? Data(contentsOf: path)
    }

    func createList(name: String, description: String = "", isPublic: Bool = true) {
        let list = FilmList(name: name, description: description, isPublic: isPublic)
        filmLists.append(list)
        saveLists()
    }

    func updateList(_ list: FilmList) {
        guard let idx = filmLists.firstIndex(where: { $0.id == list.id }) else { return }
        filmLists[idx] = list
        saveLists()
    }

    func deleteList(_ list: FilmList) {
        filmLists.removeAll { $0.id == list.id }
        saveLists()
    }

    func addFilmToList(_ film: Film, listId: String) {
        guard let idx = filmLists.firstIndex(where: { $0.id == listId }) else { return }
        guard !filmLists[idx].films.contains(where: { $0.id == film.id }) else { return }
        filmLists[idx].films.append(film)
        saveLists()
    }

    func removeFilmFromList(_ film: Film, listId: String) {
        guard let idx = filmLists.firstIndex(where: { $0.id == listId }) else { return }
        filmLists[idx].films.removeAll { $0.id == film.id }
        saveLists()
    }

    private func saveUser() {
        guard let user = currentUser, let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: "currentUser")
    }

    private func saveDiary() {
        guard let data = try? JSONEncoder().encode(diaryEntries) else { return }
        UserDefaults.standard.set(data, forKey: "diaryEntries")
    }

    private func loadDiary() {
        guard let data = UserDefaults.standard.data(forKey: "diaryEntries"),
              let entries = try? JSONDecoder().decode([LogEntry].self, from: data) else { return }
        diaryEntries = entries
    }

    private func saveLists() {
        guard let data = try? JSONEncoder().encode(filmLists) else { return }
        UserDefaults.standard.set(data, forKey: "filmLists")
    }

    private func loadLists() {
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
