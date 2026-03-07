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

private nonisolated struct TRPCWrapper<T: Codable & Sendable>: Codable, Sendable {
    let result: TRPCResultData<T>
}

private nonisolated struct TRPCResultData<T: Codable & Sendable>: Codable, Sendable {
    let data: TRPCJson<T>
}

private nonisolated struct TRPCJson<T: Codable & Sendable>: Codable, Sendable {
    let json: T
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
        return url + "/api/trpc"
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["username": username, "email": email, "password": password]
        return try await mutation("auth.register", body: body)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["email": email, "password": password]
        return try await mutation("auth.login", body: body)
    }

    func getProfile(token: String) async throws -> ProfileResponse {
        return try await query("auth.getProfile", token: token)
    }

    func updateProfile(token: String, updates: [String: Any]) async throws -> ProfileResponse {
        return try await mutation("auth.updateProfile", body: updates, token: token)
    }

    func syncData(token: String, diaryEntries: [[String: Any]]?, filmLists: [[String: Any]]?, watchlist: [[String: Any]]?) async throws {
        var body: [String: Any] = [:]
        if let diaryEntries { body["diaryEntries"] = diaryEntries }
        if let filmLists { body["filmLists"] = filmLists }
        if let watchlist { body["watchlist"] = watchlist }
        let _: SuccessResponse = try await mutation("auth.syncData", body: body, token: token)
    }

    func getData(token: String) async throws -> DataResponse {
        return try await query("auth.getData", token: token)
    }

    func changePassword(token: String, currentPassword: String, newPassword: String) async throws {
        let body: [String: Any] = ["currentPassword": currentPassword, "newPassword": newPassword]
        let _: SuccessResponse = try await mutation("auth.changePassword", body: body, token: token)
    }

    func requestPasswordReset(email: String) async throws -> ResetResponse {
        let body: [String: Any] = ["email": email]
        return try await mutation("auth.requestPasswordReset", body: body)
    }

    func deleteAccount(token: String) async throws {
        let _: SuccessResponse = try await mutation("auth.deleteAccount", body: [:], token: token)
    }

    private func query<T: Codable & Sendable>(_ endpoint: String, body: [String: Any]? = nil, token: String? = nil) async throws -> T {
        let data = try await request(endpoint: endpoint, method: "GET", body: body, token: token)
        let wrapper = try decoder.decode(TRPCWrapper<T>.self, from: data)
        return wrapper.result.data.json
    }

    private func mutation<T: Codable & Sendable>(_ endpoint: String, body: [String: Any]? = nil, token: String? = nil) async throws -> T {
        let data = try await request(endpoint: endpoint, method: "POST", body: body, token: token)
        let wrapper = try decoder.decode(TRPCWrapper<T>.self, from: data)
        return wrapper.result.data.json
    }

    private func request(endpoint: String, method: String, body: [String: Any]?, token: String?) async throws -> Data {
        guard !baseURL.isEmpty else {
            throw AuthError.networkError("Server URL not configured")
        }

        var urlString = "\(baseURL)/\(endpoint)"

        if method == "GET", let body, !body.isEmpty {
            let wrapped: [String: Any] = ["json": body]
            let jsonData = try JSONSerialization.data(withJSONObject: wrapped)
            if let jsonString = String(data: jsonData, encoding: .utf8),
               let encoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString += "?input=\(encoded)"
            }
        }

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
            let wrapped: [String: Any] = ["json": body]
            req.httpBody = try JSONSerialization.data(withJSONObject: wrapped)
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

        var message = ""

        if let error = json["error"] as? [String: Any] {
            if let jsonMsg = error["json"] as? [String: Any], let msg = jsonMsg["message"] as? String {
                message = msg
            } else if let msg = error["message"] as? String {
                message = msg
            }
        }

        if message.isEmpty, let rawString = String(data: data, encoding: .utf8) {
            message = rawString
        }

        if message.contains("EMAIL_EXISTS") { return .emailExists }
        if message.contains("USERNAME_EXISTS") { return .usernameExists }
        if message.contains("INVALID_CREDENTIALS") { return .invalidCredentials }
        if message.contains("UNAUTHORIZED") { return .unauthorized }
        if message.contains("USER_NOT_FOUND") { return .userNotFound }
        if message.contains("ACCOUNT_LOCKED") { return .accountLocked }

        return .serverError("Server error (\(statusCode))")
    }
}
