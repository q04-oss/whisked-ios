import Foundation

/// Handles registration, login, and logout. Persists tokens to the Keychain.
/// Called by AuthStore — not directly from views.
struct AuthService {
    private let api = APIClient.shared

    func register(email: String, displayName: String, password: String) async throws -> TokenPair {
        let pair = try await api.request(
            try .register(email: email, displayName: displayName, password: password),
            as: TokenPair.self
        )
        try persist(pair)
        return pair
    }

    func login(email: String, password: String) async throws -> TokenPair {
        let pair = try await api.request(
            try .login(email: email, password: password),
            as: TokenPair.self
        )
        try persist(pair)
        try? Keychain.save(email, key: Keychain.Key.cachedEmail)
        return pair
    }

    func logout() async {
        let refreshToken = try? Keychain.loadProtected(key: Keychain.Key.refreshToken)
        if let token = refreshToken {
            try? await api.request(try .logout(refreshToken: token))
        }
        Keychain.delete(key: Keychain.Key.accessToken)
        Keychain.delete(key: Keychain.Key.refreshToken)
    }

    func fetchProfile() async throws -> CustomerProfile {
        try await api.request(.me, as: CustomerProfile.self)
    }

    func registerPushToken(_ token: String) async throws {
        try await api.request(try .registerPushToken(token))
    }

    var hasStoredTokens: Bool {
        (try? Keychain.loadProtected(key: Keychain.Key.accessToken)) != nil
    }

    var cachedEmail: String? {
        Keychain.load(key: Keychain.Key.cachedEmail)
    }

    private func persist(_ pair: TokenPair) throws {
        try Keychain.saveProtected(pair.accessToken,  key: Keychain.Key.accessToken)
        try Keychain.saveProtected(pair.refreshToken, key: Keychain.Key.refreshToken)
    }
}
