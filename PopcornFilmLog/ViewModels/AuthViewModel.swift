import SwiftUI

@Observable
@MainActor
class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var currentUser: UserProfile?

    private let authService = AuthService.shared

    init() {
        if authService.isLoggedIn {
            isAuthenticated = true
            if let data = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(UserProfile.self, from: data) {
                currentUser = user
            }
            Task { await refreshProfile() }
        }
    }

    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let user = try await authService.login(email: email, password: password)
            currentUser = user
            saveUserLocally(user)
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Connection failed. Please check your internet."
        }
        isLoading = false
    }

    func register(username: String, email: String, password: String) async {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let user = try await authService.register(username: username, email: email, password: password)
            currentUser = user
            saveUserLocally(user)
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch let urlError as URLError {
            errorMessage = "Connection failed: \(urlError.localizedDescription)"
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func refreshProfile() async {
        do {
            let user = try await authService.fetchProfile()
            currentUser = user
            saveUserLocally(user)
        } catch let error as AuthError where error == .invalidCredentials {
            logout()
        } catch {}
    }

    func logout() {
        authService.logout()
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "diaryEntries")
        UserDefaults.standard.removeObject(forKey: "filmLists")
    }

    private func saveUserLocally(_ user: UserProfile) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }
}

extension AuthError: Equatable {
    nonisolated static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
