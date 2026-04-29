import Foundation

struct LoyaltyBalance: Decodable, Equatable {
    let customerID:      Int
    let steepsEarned:    Int
    let rewardsRedeemed: Int
    let available:       Int      // free drinks ready to use
    let progress:        Int      // steeps toward next reward
    let until:           Int      // steeps needed for next reward

    enum CodingKeys: String, CodingKey {
        case customerID      = "customer_id"
        case steepsEarned    = "steeps_earned"
        case rewardsRedeemed = "rewards_redeemed"
        case available       = "available_rewards"
        case progress        = "steeps_progress"
        case until           = "steeps_until_next"
    }
}

struct LoyaltyEvent: Decodable, Identifiable {
    let id:         Int
    let eventType:  String
    let source:     String
    let locationID: Int?
    let createdAt:  Date

    enum CodingKeys: String, CodingKey {
        case id
        case eventType  = "event_type"
        case source
        case locationID = "location_id"
        case createdAt  = "created_at"
    }

    var isEarn:   Bool { eventType == "steep_earned" }
    var isRedeem: Bool { eventType == "reward_redeemed" }

    var displayTitle: String {
        switch eventType {
        case "steep_earned":    return "Steep earned"
        case "reward_redeemed": return "Free drink redeemed"
        case "bonus_earned":    return "Bonus steep"
        default:                return eventType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var sourceLabel: String {
        switch source {
        case "in_bar":  return "In bar"
        case "shopify": return "Online order"
        default:        return source.capitalized
        }
    }
}
