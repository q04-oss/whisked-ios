import SwiftUI

/// Whisked brand color system.
/// Pale yellow primary — warm, sultry, pilates-studio energy.
/// Set AccentColor in Assets.xcassets to match whisked.yellow.
extension Color {
    enum whisked {
        /// Primary brand yellow — pale, warm, like morning light through linen.
        static let yellow  = Color(red: 0.969, green: 0.906, blue: 0.706)
        /// Deep yellow for text on light backgrounds.
        static let amber   = Color(red: 0.780, green: 0.620, blue: 0.200)
        /// Cream — primary background.
        static let cream   = Color(red: 0.969, green: 0.953, blue: 0.929)
        /// Beige — secondary background, cards.
        static let beige   = Color(red: 0.914, green: 0.875, blue: 0.831)
        /// Warm near-black for primary text.
        static let ink     = Color(red: 0.118, green: 0.098, blue: 0.075)
        /// Muted warm grey for secondary text.
        static let stone   = Color(red: 0.478, green: 0.443, blue: 0.408)
    }
}
