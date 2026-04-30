import Foundation

struct AuthService {
    private let api = APIClient.shared

    func register(email: String, displayName: String, password: String) async throws -> AuthResponse {
        let resp = try await api.request(
            try .register(email: email, displayName: displayName, password: password),
            as: AuthResponse.self
        )
        try persist(resp.token)
        return resp
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let resp = try await api.request(
            try .login(email: email, password: password),
            as: AuthResponse.self
        )
        try persist(resp.token)
        try? Keychain.save(email, key: Keychain.Key.cachedEmail)
        return resp
    }

    func logout() async {
        try? await api.request(.logout)
        Keychain.delete(key: Keychain.Key.accessToken)
        Keychain.delete(key: Keychain.Key.cachedEmail)
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

    private func persist(_ token: String) throws {
        try Keychain.saveProtected(token, key: Keychain.Key.accessToken)
    }
}
