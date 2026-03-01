import SwiftUI

@main
struct PopcornFilmLogApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .animation(.spring(duration: 0.4), value: appViewModel.isLoggedIn)
                .animation(.spring(duration: 0.4), value: appViewModel.hasCompletedOnboarding)
        }
    }
}
