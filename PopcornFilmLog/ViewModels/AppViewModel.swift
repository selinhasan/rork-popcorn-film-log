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

    init() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = user
            isLoggedIn = true
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            loadDiary()
            loadBuddies()
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
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "diaryEntries")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func logFilm(_ film: Film, rating: Double, review: String, episodeInfo: String? = nil) {
        let entry = LogEntry(
            film: film,
            rating: rating,
            review: review,
            userId: currentUser?.id ?? "",
            username: currentUser?.username ?? "",
            episodeInfo: episodeInfo
        )
        diaryEntries.insert(entry, at: 0)
        saveDiary()
    }

    func updateProfile(username: String? = nil, profileImage: String? = nil, topFive: [Film]? = nil) {
        if let username { currentUser?.username = username }
        if let profileImage { currentUser?.profileImageName = profileImage }
        if let topFive { currentUser?.topFiveFilms = topFive }
        saveUser()
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

    func createPost(text: String) {
        let post = BuddyPost(
            userId: currentUser?.id ?? "",
            username: currentUser?.username ?? "",
            profileImageName: currentUser?.profileImageName ?? "avatar_1",
            text: text
        )
        posts.insert(post, at: 0)
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

    private func loadBuddies() {
        buddies = MockDataService.sampleBuddies
        buddyLogs = MockDataService.sampleBuddyLogs
        posts = MockDataService.samplePosts
    }
}
