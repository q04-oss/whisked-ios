import Foundation

/// Runtime configuration loaded from Info.plist, which is populated at build
/// time from Secrets.xcconfig. Values are never hardcoded or committed.
enum Config {
    /// Base URL for all API requests.
    static let apiBaseURL: URL = {
        guard let raw = Bundle.main.infoDictionary?["WHISKED_API_BASE_URL"] as? String,
              let url = URL(string: raw)
        else { fatalError("WHISKED_API_BASE_URL missing from Info.plist") }
        return url
    }()

    /// HMAC shared key used to sign all iOS requests.
    /// Injected at build time — never stored in source.
    static let hmacKey: String = {
        guard let key = Bundle.main.infoDictionary?["WHISKED_HMAC_KEY"] as? String,
              !key.isEmpty
        else { fatalError("WHISKED_HMAC_KEY missing from Info.plist") }
        return key
    }()
}
