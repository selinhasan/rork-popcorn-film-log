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
        case .accountLocked: return "Account temporarily locked due to too many failed attempts. Try again in 15 minutes."
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
    let profileImageName: String
    let customProfileImageURL: String?
    let bio: String
    let topFiveFilms: [Film]
    let goldenPopcornFilmId: String?
    let buddyIds: [String]
    let watchlist: [Film]
    let diaryEntries: [LogEntry]
    let filmLists: [FilmList]
    let joinDate: String
}

nonisolated struct ProfileResponse: Codable, Sendable {
    let user: ServerUser
}

nonisolated struct SuccessResponse: Codable, Sendable {
    let success: Bool
}

nonisolated struct ResetResponse: Codable, Sendable {
    let success: Bool
    let message: String
}

nonisolated struct DataResponse: Codable, Sendable {
    let diaryEntries: [LogEntry]
    let filmLists: [FilmList]
    let watchlist: [Film]
}

nonisolated final class AuthClient: Sendable {
    static let shared = AuthClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    private var baseURL: String {
        let url = Config.EXPO_PUBLIC_RORK_API_BASE_URL
        guard !url.isEmpty else { return "" }
        return url
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["username": username, "email": email, "password": password]
        return try await post("register", body: body)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["email": email, "password": password]
        return try await post("login", body: body)
    }

    func getProfile(token: String) async throws -> ProfileResponse {
        return try await get("get-profile", token: token)
    }

    func updateProfile(token: String, updates: [String: Any]) async throws -> ProfileResponse {
        return try await post("update-profile", body: updates, token: token)
    }

    func syncData(token: String, diaryEntries: [[String: Any]]?, filmLists: [[String: Any]]?, watchlist: [[String: Any]]?) async throws {
        var body: [String: Any] = [:]
        if let diaryEntries { body["diaryEntries"] = diaryEntries }
        if let filmLists { body["filmLists"] = filmLists }
        if let watchlist { body["watchlist"] = watchlist }
        let _: SuccessResponse = try await post("sync-data", body: body, token: token)
    }

    func getData(token: String) async throws -> DataResponse {
        return try await get("get-data", token: token)
    }

    func changePassword(token: String, currentPassword: String, newPassword: String) async throws {
        let body: [String: Any] = ["currentPassword": currentPassword, "newPassword": newPassword]
        let _: SuccessResponse = try await post("change-password", body: body, token: token)
    }

    func requestPasswordReset(email: String) async throws -> ResetResponse {
        let body: [String: Any] = ["email": email]
        return try await post("request-password-reset", body: body)
    }

    func deleteAccount(token: String) async throws {
        let _: SuccessResponse = try await post("delete-account", body: [:], token: token)
    }

    private func get<T: Codable & Sendable>(_ endpoint: String, token: String? = nil) async throws -> T {
        let data = try await request(endpoint: endpoint, method: "GET", body: nil, token: token)
        return try decoder.decode(T.self, from: data)
    }

    private func post<T: Codable & Sendable>(_ endpoint: String, body: [String: Any]? = nil, token: String? = nil) async throws -> T {
        let data = try await request(endpoint: endpoint, method: "POST", body: body, token: token)
        return try decoder.decode(T.self, from: data)
    }

    private func request(endpoint: String, method: String, body: [String: Any]?, token: String?) async throws -> Data {
        guard !baseURL.isEmpty else {
            throw AuthError.networkError("Server URL not configured")
        }

        let urlString = "\(baseURL)/\(endpoint)"

        guard let url = URL(string: urlString) else {
            throw AuthError.networkError("Invalid URL")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if method == "POST", let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response from server")
        }

        if httpResponse.statusCode >= 400 {
            throw parseError(from: data, statusCode: httpResponse.statusCode)
        }

        return data
    }

    private func parseError(from data: Data, statusCode: Int) -> AuthError {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .serverError("Server error (\(statusCode))")
        }

        let message = json["error"] as? String ?? json["message"] as? String ?? ""

        if message.contains("EMAIL_EXISTS") { return .emailExists }
        if message.contains("USERNAME_EXISTS") { return .usernameExists }
        if message.contains("INVALID_CREDENTIALS") { return .invalidCredentials }
        if message.contains("UNAUTHORIZED") { return .unauthorized }
        if message.contains("USER_NOT_FOUND") { return .userNotFound }
        if message.contains("ACCOUNT_LOCKED") { return .accountLocked }

        return .serverError("Server error (\(statusCode))")
    }
}
