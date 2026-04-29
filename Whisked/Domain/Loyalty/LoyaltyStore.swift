import Foundation
import Observation

@Observable
@MainActor
final class LoyaltyStore {

    private(set) var balance:     LoyaltyBalance?
    private(set) var history:     [LoyaltyEvent] = []
    private(set) var isLoading    = false
    private(set) var isStamping   = false
    private(set) var isRedeeming  = false
    private(set) var error:       APIError?
    private(set) var lastStamped: Date?   // drives post-stamp celebration UI

    private let service = LoyaltyService()

    // MARK: - Load

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            async let b = service.balance()
            async let h = service.history()
            (balance, history) = try await (b, h)
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .networkError(error)
        }
        isLoading = false
    }

    func refreshBalance() async {
        do {
            balance = try await service.balance()
        } catch { }
    }

    // MARK: - Stamp

    func stamp() async {
        guard !isStamping else { return }
        isStamping = true
        error = nil
        do {
            balance     = try await service.stamp()
            lastStamped = Date()
            // Refresh history to show the new event.
            history     = try await service.history()
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .networkError(error)
        }
        isStamping = false
    }

    // MARK: - Redeem

    func redeem() async {
        guard !isRedeeming else { return }
        isRedeeming = true
        error = nil
        do {
            balance = try await service.redeem()
            history = try await service.history()
        } catch let e as APIError {
            error = e
        } catch {
            self.error = .networkError(error)
        }
        isRedeeming = false
    }
}
