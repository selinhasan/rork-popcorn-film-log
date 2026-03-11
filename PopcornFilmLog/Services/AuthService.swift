import Foundation

nonisolated enum AuthError: Error, Sendable, LocalizedError {
    case emailExists
    case usernameExists
    case invalidCredentials
    case unauthorized
    case userNotFound
    case accountLocked
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emailExists: return "This email is already connected to an account."
        case .usernameExists: return "This username is already taken."
        case .invalidCredentials: return "Incorrect email or password."
        case .unauthorized: return "Session expired. Please log in again."
        case .userNotFound: return "Account not found."
        case .accountLocked: return "Account temporarily locked. Try again later."
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        }
    }
}

nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let user: RemoteUser
}

nonisolated struct RemoteUser: Codable, Sendable {
    let id: String
    let username: String
    let email: String
    let profileImageName: String?
    let customProfileImageURL: String?
    let bio: String?
    let topFiveFilms: [Film]?
    let goldenPopcornFilmId: String?
    let buddyIds: [String]?
    let watchlist: [Film]?
    let diaryEntries: [LogEntry]?
    let filmLists: [FilmList]?
    let joinDate: String?
}

nonisolated struct APIErrorResponse: Codable, Sendable {
    let error: String
    let message: String?
}

final class RemoteAuthService {
    static let shared = RemoteAuthService()

    private var baseURL: String {
        Config.EXPO_PUBLIC_RORK_API_BASE_URL
    }

    private init() {}

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/api/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "username": username,
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        }

        let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        let errorCode = errorResponse?.error ?? ""

        switch errorCode {
        case "EMAIL_EXISTS":
            throw AuthError.emailExists
        case "USERNAME_EXISTS":
            throw AuthError.usernameExists
        default:
            throw AuthError.serverError(errorResponse?.message ?? "Registration failed. Please try again.")
        }
    }

    func login(identifier: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/api/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "email": identifier,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        }

        let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        let errorCode = errorResponse?.error ?? ""

        switch errorCode {
        case "INVALID_CREDENTIALS":
            throw AuthError.invalidCredentials
        case "ACCOUNT_LOCKED":
            throw AuthError.accountLocked
        case "ACCOUNT_SUSPENDED", "ACCOUNT_DISABLED":
            throw AuthError.serverError("Your account has been disabled.")
        default:
            throw AuthError.serverError(errorResponse?.message ?? "Login failed. Please try again.")
        }
    }

    func changePassword(token: String, currentPassword: String, newPassword: String) async throws {
        let url = URL(string: "\(baseURL)/api/change-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            let errorCode = errorResponse?.error ?? ""
            if errorCode == "INVALID_CREDENTIALS" {
                throw AuthError.invalidCredentials
            }
            throw AuthError.serverError(errorResponse?.message ?? "Failed to change password.")
        }
    }

    func deleteAccount(token: String) async throws {
        let url = URL(string: "\(baseURL)/api/delete-account")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to delete account.")
        }
    }

    func syncData(token: String, diaryEntries: [LogEntry], filmLists: [FilmList]) async {
        guard let url = URL(string: "\(baseURL)/api/sync-data") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "diaryEntries": (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(diaryEntries))) ?? [],
            "filmLists": (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(filmLists))) ?? []
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        _ = try? await URLSession.shared.data(for: request)
    }

    func updateProfile(token: String, updates: [String: Any]) async {
        guard let url = URL(string: "\(baseURL)/api/update-profile") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        request.httpBody = try? JSONSerialization.data(withJSONObject: updates)

        _ = try? await URLSession.shared.data(for: request)
    }
}
