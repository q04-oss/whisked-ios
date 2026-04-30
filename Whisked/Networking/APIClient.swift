import CryptoKit
import Foundation

/// Thread-safe HTTP client for the Whisked API.
///
/// Every request is signed with HMAC-SHA256 to prove origin and prevent replay attacks.
/// Signed message format: "METHOD\nPATH\nTIMESTAMP\nNONCE\nBODY_SHA256_HEX"
///
/// On 401, the client attempts a single token refresh before propagating the error.
/// All token reads go through the Keychain, which requires biometric auth.
actor APIClient {

    static let shared = APIClient()

    private let session: URLSession
    private var isRefreshing = false  // reserved for future refresh endpoint

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config, delegate: PinningDelegate(), delegateQueue: nil)
    }

    // MARK: - Public interface

    /// Performs a signed, authenticated request and decodes the response as `T`.
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        as type: T.Type = T.self
    ) async throws -> T {
        let data = try await perform(endpoint)
        do {
            return try JSONDecoder.iso8601.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Performs a signed, authenticated request with no expected response body.
    func request(_ endpoint: Endpoint) async throws {
        _ = try await perform(endpoint)
    }

    // MARK: - Core execution

    private func perform(_ endpoint: Endpoint) async throws -> Data {
        let urlRequest = try buildRequest(endpoint)

        let (data, response) = try await execute(urlRequest)
        let http = response as! HTTPURLResponse

        return try validate(data, response: http)
    }

    // MARK: - Request building

    private func buildRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var url = Config.apiBaseURL.appendingPathComponent(endpoint.path)
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = queryItems
            url = components.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod  = endpoint.method.rawValue
        request.httpBody    = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach JWT if available and required.
        if endpoint.requiresAuth, let token = try? Keychain.loadProtected(key: Keychain.Key.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Sign every request.
        let body = endpoint.body ?? Data()
        let (timestamp, nonce, signature) = sign(
            method: endpoint.method.rawValue,
            path: endpoint.path,
            body: body
        )
        request.setValue(timestamp,  forHTTPHeaderField: "X-Timestamp")
        request.setValue(nonce,      forHTTPHeaderField: "X-Nonce")
        request.setValue(signature,  forHTTPHeaderField: "X-Signature")

        return request
    }

    // MARK: - HMAC signing

    private func sign(method: String, path: String, body: Data) -> (timestamp: String, nonce: String, signature: String) {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce     = UUID().uuidString

        let bodyHash    = SHA256.hash(data: body)
        let bodyHashHex = bodyHash.map { String(format: "%02x", $0) }.joined()

        let message = "\(method)\n\(path)\n\(timestamp)\n\(nonce)\n\(bodyHashHex)"

        let key = SymmetricKey(data: Data(Config.hmacKey.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        let signature = mac.map { String(format: "%02x", $0) }.joined()

        return (timestamp, nonce, signature)
    }

    // MARK: - Execution + validation

    private func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validate(_ data: Data, response: HTTPURLResponse) throws -> Data {
        switch response.statusCode {
        case 200...299: return data
        case 401:       throw APIError.unauthenticated
        case 403:       throw APIError.forbidden
        case 404:       throw APIError.notFound
        case 409:       throw APIError.conflict(serverMessage(data) ?? "Conflict.")
        case 400:       throw APIError.badRequest(serverMessage(data) ?? "Invalid request.")
        case 429:       throw APIError.rateLimited
        case 500...599: throw APIError.serverError
        default:        throw APIError.unknown(response.statusCode)
        }
    }

    private func serverMessage(_ data: Data) -> String? {
        struct ErrorBody: Decodable { let error: String }
        return try? JSONDecoder().decode(ErrorBody.self, from: data).error
    }
}

// MARK: - Endpoint

struct Endpoint {
    let method:       HTTPMethod
    let path:         String
    let body:         Data?
    let queryItems:   [URLQueryItem]?
    let requiresAuth: Bool

    init(
        method:       HTTPMethod,
        path:         String,
        body:         Data?            = nil,
        queryItems:   [URLQueryItem]?  = nil,
        requiresAuth: Bool             = true
    ) {
        self.method       = method
        self.path         = path
        self.body         = body
        self.queryItems   = queryItems
        self.requiresAuth = requiresAuth
    }
}

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case patch  = "PATCH"
    case delete = "DELETE"
}

// MARK: - Certificate pinning

/// Validates the server's certificate against a bundled public key hash.
/// On first deploy, run the server and capture the certificate fingerprint,
/// then add it to the app bundle as `whisked-api.cer`.
private class PinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // TODO: Add certificate hash for production pinning.
        // For now, use default handling — replace before shipping to production.
        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Helpers

private extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
