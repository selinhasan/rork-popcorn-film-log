import SwiftUI

@main
struct PopcornFilmLogApp: App {
    @State private var appViewModel = AppViewModel()
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .environment(authViewModel)
        }
    }
}
