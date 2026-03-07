import Foundation

nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let user: ServerUserProfile
}

nonisolated struct ServerUserProfile: Codable, Sendable {
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
    let user: ServerUserProfile
}

nonisolated struct SyncResponse: Codable, Sendable {
    let success: Bool
}

nonisolated struct DataResponse: Codable, Sendable {
    let diaryEntries: [LogEntry]
    let filmLists: [FilmList]
    let watchlist: [Film]
}

nonisolated struct PasswordResetResponse: Codable, Sendable {
    let success: Bool
    let message: String
}

nonisolated struct DeleteResponse: Codable, Sendable {
    let success: Bool
}

nonisolated enum AuthError: Error, Sendable, LocalizedError {
    case emailExists
    case usernameExists
    case invalidCredentials
    case unauthorized
    case userNotFound
    case networkError(String)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .emailExists: return "This email is already connected to an account."
        case .usernameExists: return "This username is already taken."
        case .invalidCredentials: return "Incorrect email or password."
        case .unauthorized: return "Session expired. Please log in again."
        case .userNotFound: return "Account not found."
        case .networkError(let msg): return msg
        case .serverError(let msg): return msg
        }
    }
}

nonisolated final class AuthServiceClient: Sendable {
    static let shared = AuthServiceClient()

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
        if url.isEmpty {
            return ""
        }
        return url + "/api/trpc"
    }

    private func makeRequest(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]? = nil,
        token: String? = nil
    ) async throws -> Data {
        guard !baseURL.isEmpty else {
            throw AuthError.networkError("Server URL not configured")
        }

        let isMutation = method == "POST"
        var urlString = "\(baseURL)/\(endpoint)"

        if !isMutation, let body {
            let wrapped: [String: Any] = ["json": body]
            let jsonData = try JSONSerialization.data(withJSONObject: wrapped)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            let encoded = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "?input=\(encoded)"
        }

        guard let url = URL(string: urlString) else {
            throw AuthError.networkError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = isMutation ? "POST" : "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if isMutation, let body {
            let wrapped: [String: Any] = ["json": body]
            request.httpBody = try JSONSerialization.data(withJSONObject: wrapped)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("Invalid response")
        }

        if httpResponse.statusCode >= 400 {
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorObj = errorBody["error"] as? [String: Any],
                   let errorMsg = errorObj["message"] as? String {
                    throw mapServerError(errorMsg)
                }
                if let errorArray = errorBody as? [String: Any],
                   let firstError = (errorArray["error"] as? [String: Any]),
                   let jsonObj = firstError["json"] as? [String: Any],
                   let message = jsonObj["message"] as? String {
                    throw mapServerError(message)
                }
            }
            if let rawString = String(data: data, encoding: .utf8), rawString.contains("message") {
                throw mapServerError(rawString)
            }
            throw AuthError.serverError("Server error (\(httpResponse.statusCode))")
        }

        return data
    }

    private func mapServerError(_ message: String) -> AuthError {
        if message.contains("EMAIL_EXISTS") { return .emailExists }
        if message.contains("USERNAME_EXISTS") { return .usernameExists }
        if message.contains("INVALID_CREDENTIALS") { return .invalidCredentials }
        if message.contains("UNAUTHORIZED") { return .unauthorized }
        if message.contains("USER_NOT_FOUND") { return .userNotFound }
        return .serverError(message)
    }

    private nonisolated struct TRPCResult<T: Codable & Sendable>: Codable, Sendable {
        let result: TRPCData<T>
    }

    private nonisolated struct TRPCData<T: Codable & Sendable>: Codable, Sendable {
        let data: T
    }

    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "username": username,
            "email": email,
            "password": password,
        ]
        let data = try await makeRequest(endpoint: "auth.register", body: body)
        let result = try decoder.decode(TRPCResult<AuthResponse>.self, from: data)
        return result.result.data
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
        ]
        let data = try await makeRequest(endpoint: "auth.login", body: body)
        let result = try decoder.decode(TRPCResult<AuthResponse>.self, from: data)
        return result.result.data
    }

    func getProfile(token: String) async throws -> ProfileResponse {
        let data = try await makeRequest(endpoint: "auth.getProfile", method: "GET", token: token)
        let result = try decoder.decode(TRPCResult<ProfileResponse>.self, from: data)
        return result.result.data
    }

    func updateProfile(token: String, updates: [String: Any]) async throws -> ProfileResponse {
        let data = try await makeRequest(endpoint: "auth.updateProfile", body: updates, token: token)
        let result = try decoder.decode(TRPCResult<ProfileResponse>.self, from: data)
        return result.result.data
    }

    func syncData(token: String, diaryEntries: [[String: Any]]?, filmLists: [[String: Any]]?, watchlist: [[String: Any]]?) async throws {
        var body: [String: Any] = [:]
        if let diaryEntries { body["diaryEntries"] = diaryEntries }
        if let filmLists { body["filmLists"] = filmLists }
        if let watchlist { body["watchlist"] = watchlist }
        let _ = try await makeRequest(endpoint: "auth.syncData", body: body, token: token)
    }

    func getData(token: String) async throws -> DataResponse {
        let data = try await makeRequest(endpoint: "auth.getData", method: "GET", token: token)
        let result = try decoder.decode(TRPCResult<DataResponse>.self, from: data)
        return result.result.data
    }

    func changePassword(token: String, currentPassword: String, newPassword: String) async throws {
        let body: [String: Any] = [
            "currentPassword": currentPassword,
            "newPassword": newPassword,
        ]
        let _ = try await makeRequest(endpoint: "auth.changePassword", body: body, token: token)
    }

    func requestPasswordReset(email: String) async throws -> PasswordResetResponse {
        let body: [String: Any] = ["email": email]
        let data = try await makeRequest(endpoint: "auth.requestPasswordReset", body: body)
        let result = try decoder.decode(TRPCResult<PasswordResetResponse>.self, from: data)
        return result.result.data
    }

    func deleteAccount(token: String) async throws {
        let _ = try await makeRequest(endpoint: "auth.deleteAccount", body: [:], token: token)
    }
}
