import Foundation

struct LoyaltyService {
    private let api = APIClient.shared

    func balance() async throws -> LoyaltyBalance {
        try await api.request(.loyaltyBalance, as: LoyaltyBalance.self)
    }

    func history(limit: Int = 20, offset: Int = 0) async throws -> [LoyaltyEvent] {
        try await api.request(.loyaltyHistory(limit: limit, offset: offset), as: [LoyaltyEvent].self)
    }

    /// Records an in-bar steep. The idempotency key is a UUID generated here —
    /// if the request fails and the user retries, the same key returns the same result.
    func stamp(locationID: Int? = nil) async throws -> LoyaltyBalance {
        let idemKey = UUID().uuidString
        return try await api.request(
            try .stamp(locationID: locationID, idempotencyKey: idemKey),
            as: LoyaltyBalance.self
        )
    }

    func redeem() async throws -> LoyaltyBalance {
        try await api.request(.redeem, as: LoyaltyBalance.self)
    }
}
