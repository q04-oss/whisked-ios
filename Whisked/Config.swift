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

    /// The box fraise business ID this app is built for.
    /// Every app in the network has its own ID baked in at build time.
    static let businessID: Int = {
        guard let raw = Bundle.main.infoDictionary?["WHISKED_BUSINESS_ID"] as? String,
              let id  = Int(raw)
        else { fatalError("WHISKED_BUSINESS_ID missing or invalid in Info.plist") }
        return id
    }()
}
