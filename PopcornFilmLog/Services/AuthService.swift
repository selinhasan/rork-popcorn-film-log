import Foundation
import CryptoKit

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

nonisolated struct StoredAccount: Codable, Sendable {
    let id: String
    let username: String
    let email: String
    let passwordHash: String
    let salt: String
    let joinDate: Date
}

final class LocalAuthService {
    static let shared = LocalAuthService()
    private let accountsKey = "stored_accounts"

    private init() {}

    func register(username: String, email: String, password: String) throws -> StoredAccount {
        var accounts = loadAccounts()

        if accounts.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            throw AuthError.emailExists
        }
        if accounts.contains(where: { $0.username.lowercased() == username.lowercased() }) {
            throw AuthError.usernameExists
        }

        let salt = UUID().uuidString
        let hash = hashPassword(password, salt: salt)

        let account = StoredAccount(
            id: UUID().uuidString,
            username: username,
            email: email.lowercased(),
            passwordHash: hash,
            salt: salt,
            joinDate: Date()
        )

        accounts.append(account)
        saveAccounts(accounts)
        return account
    }

    func login(identifier: String, password: String) throws -> StoredAccount {
        let accounts = loadAccounts()
        let lowered = identifier.lowercased()

        guard let account = accounts.first(where: {
            $0.email.lowercased() == lowered || $0.username.lowercased() == lowered
        }) else {
            throw AuthError.invalidCredentials
        }

        let hash = hashPassword(password, salt: account.salt)
        guard hash == account.passwordHash else {
            throw AuthError.invalidCredentials
        }

        return account
    }

    func changePassword(accountId: String, currentPassword: String, newPassword: String) throws {
        var accounts = loadAccounts()

        guard let index = accounts.firstIndex(where: { $0.id == accountId }) else {
            throw AuthError.userNotFound
        }

        let account = accounts[index]
        let currentHash = hashPassword(currentPassword, salt: account.salt)
        guard currentHash == account.passwordHash else {
            throw AuthError.invalidCredentials
        }

        let newSalt = UUID().uuidString
        let newHash = hashPassword(newPassword, salt: newSalt)

        accounts[index] = StoredAccount(
            id: account.id,
            username: account.username,
            email: account.email,
            passwordHash: newHash,
            salt: newSalt,
            joinDate: account.joinDate
        )
        saveAccounts(accounts)
    }

    func deleteAccount(accountId: String) {
        var accounts = loadAccounts()
        accounts.removeAll { $0.id == accountId }
        saveAccounts(accounts)
    }

    private func hashPassword(_ password: String, salt: String) -> String {
        let input = Data((password + salt).utf8)
        let hashed = SHA256.hash(data: input)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func loadAccounts() -> [StoredAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let accounts = try? JSONDecoder().decode([StoredAccount].self, from: data) else {
            return []
        }
        return accounts
    }

    private func saveAccounts(_ accounts: [StoredAccount]) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: accountsKey)
    }
}
