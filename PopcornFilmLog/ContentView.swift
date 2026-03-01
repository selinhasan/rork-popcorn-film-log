import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedTab = 0

    var body: some View {
        if !viewModel.isLoggedIn {
            AuthView()
                .transition(.opacity)
        } else if !viewModel.hasCompletedOnboarding {
            OnboardingView()
                .transition(.move(edge: .trailing))
        } else {
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
                    ProfileSettingsView()
                }
            }
            .tint(PopcornTheme.warmRed)
            .transition(.opacity)
        }
    }
}
