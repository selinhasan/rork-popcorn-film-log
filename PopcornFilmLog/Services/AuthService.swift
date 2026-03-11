import Foundation

nonisolated enum AuthError: LocalizedError, Sendable {
    case invalidURL
    case invalidCredentials
    case accountLocked
    case accountSuspended
    case accountDisabled
    case emailExists
    case usernameExists
    case invalidUsername
    case invalidPassword
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password."
        case .accountLocked: return "Account is locked. Try again in 15 minutes."
        case .accountSuspended: return "Account has been suspended."
        case .accountDisabled: return "Account is disabled."
        case .emailExists: return "This email is already connected to an account."
        case .usernameExists: return "This username is already taken."
        case .invalidUsername: return "Username must be 3-20 characters (letters, numbers, dots, underscores)."
        case .invalidPassword: return "Password must be between 6 and 128 characters."
        case .invalidURL: return "Invalid server URL."
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        }
    }
}

nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let user: ServerUser
}

nonisolated struct ServerUser: Codable, Sendable {
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

    func toUserProfile() -> UserProfile {
        let date: Date
        if let joinDate, let parsed = ISO8601DateFormatter().date(from: joinDate) {
            date = parsed
        } else {
            date = Date()
        }
        return UserProfile(
            id: id,
            username: username,
            email: email,
            profileImageName: profileImageName ?? "avatar_1",
            customProfileImageURL: customProfileImageURL,
            bio: bio ?? "",
            topFiveFilms: topFiveFilms ?? [],
            goldenPopcornFilmId: goldenPopcornFilmId,
            buddyIds: buddyIds ?? [],
            watchlist: watchlist ?? [],
            joinDate: date
        )
    }
}

nonisolated struct ProfileResponse: Codable, Sendable {
    let user: ServerUser
}

nonisolated struct ErrorResponse: Codable, Sendable {
    let error: String
    let message: String?
}

class AuthService {
    static let shared = AuthService()

    private var baseURL: String {
        Config.EXPO_PUBLIC_RORK_API_BASE_URL
    }

    private let decoder = JSONDecoder()

    private var tokenKey: String { "auth_token" }

    var storedToken: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }

    var isLoggedIn: Bool {
        storedToken != nil
    }

    func login(email: String, password: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/login") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 200 {
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            storedToken = authResponse.token
            return authResponse.user.toUserProfile()
        }

        throw mapError(data: data, statusCode: statusCode)
    }

    func register(username: String, email: String, password: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/api/register") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "username": username,
            "email": email,
            "password": password
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 201 {
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            storedToken = authResponse.token
            return authResponse.user.toUserProfile()
        }

        throw mapError(data: data, statusCode: statusCode)
    }

    func fetchProfile() async throws -> UserProfile {
        guard let token = storedToken else {
            throw AuthError.invalidCredentials
        }
        guard let url = URL(string: "\(baseURL)/api/get-profile") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode == 200 {
            let profileResponse = try decoder.decode(ProfileResponse.self, from: data)
            return profileResponse.user.toUserProfile()
        }

        if statusCode == 401 {
            storedToken = nil
            throw AuthError.invalidCredentials
        }

        throw mapError(data: data, statusCode: statusCode)
    }

    func logout() {
        storedToken = nil
    }

    private func mapError(data: Data, statusCode: Int) -> AuthError {
        if let errResp = try? decoder.decode(ErrorResponse.self, from: data) {
            switch errResp.error {
            case "INVALID_CREDENTIALS": return .invalidCredentials
            case "ACCOUNT_LOCKED": return .accountLocked
            case "ACCOUNT_SUSPENDED": return .accountSuspended
            case "ACCOUNT_DISABLED": return .accountDisabled
            case "EMAIL_EXISTS": return .emailExists
            case "USERNAME_EXISTS": return .usernameExists
            default:
                return .serverError(errResp.message ?? errResp.error)
            }
        }
        return .networkError("Something went wrong. Please try again.")
    }
}
