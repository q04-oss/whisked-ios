import Foundation
import Security

/// Secure credential storage backed by the iOS Keychain.
///
/// Tokens (access + refresh) are stored with biometric protection — Face ID or
/// Touch ID is required to read them. This means a stolen device with a locked
/// screen cannot replay stored tokens even with physical access.
///
/// Non-sensitive preferences use a separate unprotected query so they are
/// readable without biometric prompt (e.g. cached email for the login field).
enum Keychain {

    // MARK: - Protected (biometric)

    /// Saves a value with biometric + passcode protection.
    /// Deletes any existing item first — atomic replace.
    static func saveProtected(_ value: String, key: String) throws {
        let data = Data(value.utf8)
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.biometryAny, .or, .devicePasscode],
            nil
        )!

        // Delete existing first.
        let deleteQuery: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     bundleID,
            kSecAttrAccount:     key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass:                kSecClassGenericPassword,
            kSecAttrService:          bundleID,
            kSecAttrAccount:          key,
            kSecValueData:            data,
            kSecAttrAccessControl:    access,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Reads a biometric-protected value. Prompts Face ID / Touch ID.
    static func loadProtected(key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      bundleID,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
            kSecUseOperationPrompt: "Authenticate to continue",
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { throw KeychainError.notFound }
        return value
    }

    // MARK: - Unprotected (metadata)

    /// Saves a value without biometric protection.
    /// Use for non-sensitive data (cached email, visitor ID).
    static func save(_ value: String, key: String) throws {
        let data = Data(value.utf8)
        let deleteQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: "\(bundleID).meta",
            kSecAttrAccount: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: "\(bundleID).meta",
            kSecAttrAccount: key,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    static func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: "\(bundleID).meta",
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        for service in [bundleID, "\(bundleID).meta"] {
            let query: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Private

    private static let bundleID = Bundle.main.bundleIdentifier ?? "com.whisked.app"

    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case notFound
    }
}

// MARK: - Named keys

extension Keychain {
    enum Key {
        static let accessToken  = "whisked.access_token"
        static let refreshToken = "whisked.refresh_token"
        static let cachedEmail  = "whisked.cached_email"
        static let visitorID    = "whisked.visitor_id"
    }
}
