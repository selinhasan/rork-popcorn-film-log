import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    Tab("Diary", systemImage: "book.fill", value: 0) {
                        DiaryView()
                    }
                    Tab("Buddies", systemImage: "person.2.fill", value: 1) {
                        BuddiesView()
                    }
                    Tab("Browse", systemImage: "magnifyingglass", value: 2) {
                        BrowseView()
                    }
                    Tab("Profile", systemImage: "person.crop.circle.fill", value: 3) {
                        ProfileView()
                    }
                }
                .tint(PopcornTheme.warmRed)
            } else {
                LoginView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            if isAuth, let user = authViewModel.currentUser {
                viewModel.setUser(user)
            }
        }
        .onChange(of: authViewModel.currentUser) { _, user in
            if let user {
                viewModel.setUser(user)
            }
        }
    }
}
