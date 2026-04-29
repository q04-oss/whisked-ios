import Foundation

/// Typed errors surfaced from the API client.
/// Handlers switch on these rather than inspecting raw HTTP status codes.
enum APIError: LocalizedError {
    case unauthenticated              // 401 — token invalid or expired
    case forbidden                    // 403 — authenticated but not permitted
    case notFound                     // 404
    case conflict(String)             // 409 — e.g. duplicate idempotency key
    case badRequest(String)           // 400 — validation failure
    case rateLimited                  // 429
    case serverError                  // 5xx
    case networkError(Error)          // connection failure
    case decodingError(Error)         // unexpected response shape
    case unknown(Int)                 // unhandled status code

    var errorDescription: String? {
        switch self {
        case .unauthenticated:          return "Please sign in again."
        case .forbidden:                return "You don't have permission to do that."
        case .notFound:                 return "Not found."
        case .conflict(let msg):        return msg
        case .badRequest(let msg):      return msg
        case .rateLimited:              return "Too many requests. Please slow down."
        case .serverError:              return "Something went wrong on our end. Try again shortly."
        case .networkError:             return "No connection. Check your network and try again."
        case .decodingError:            return "Unexpected response from server."
        case .unknown(let code):        return "Unexpected error (\(code))."
        }
    }
}
