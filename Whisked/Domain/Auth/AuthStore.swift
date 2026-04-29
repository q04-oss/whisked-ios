import Foundation
import Observation

/// Source of truth for authentication state across the app.
/// Owned by the root environment — never recreated during the session.
@Observable
@MainActor
final class AuthStore {

    // MARK: - State

    enum State: Equatable {
        case checking        // startup — determining if tokens exist
        case unauthenticated
        case authenticated(CustomerProfile)
    }

    private(set) var state: State = .checking
    private(set) var isLoading = false
    private(set) var error: APIError?

    var isAuthenticated: Bool {
        if case .authenticated = state { return true }
        return false
    }

    var profile: CustomerProfile? {
        if case .authenticated(let p) = state { return p }
        return nil
    }

    // MARK: - Private

    private let service = AuthService()

    // MARK: - Lifecycle

    /// Called once at app launch. Restores session if tokens are present.
    func bootstrap() async {
        guard service.hasStoredTokens else {
            state = .unauthenticated
            return
        }
        do {
            let profile = try await service.fetchProfile()
            state = .authenticated(profile)
        } catch {
            // Tokens may be expired — fall through to login.
            state = .unauthenticated
        }
    }

    // MARK: - Actions

    func register(email: String, displayName: String, password: String) async {
        await perform {
            _ = try await self.service.register(email: email, displayName: displayName, password: password)
            let profile = try await self.service.fetchProfile()
            self.state = .authenticated(profile)
        }
    }

    func login(email: String, password: String) async {
        await perform {
            _ = try await self.service.login(email: email, password: password)
            let profile = try await self.service.fetchProfile()
            self.state = .authenticated(profile)
        }
    }

    func logout() async {
        await service.logout()
        state = .unauthenticated
    }

    // MARK: - Helpers

    private func perform(_ action: () async throws -> Void) async {
        isLoading = true
        error = nil
        do {
            try await action()
        } catch let apiError as APIError {
            self.error = apiError
        } catch {
            self.error = .networkError(error)
        }
        isLoading = false
    }
}
