import Foundation

extension Endpoint {
    static func register(email: String, displayName: String, password: String) throws -> Endpoint {
        struct Body: Encodable {
            let email: String
            let display_name: String
            let password: String
        }
        return Endpoint(
            method: .post,
            path: "/api/auth/register",
            body: try JSONEncoder().encode(Body(email: email, display_name: displayName, password: password)),
            requiresAuth: false
        )
    }

    static func login(email: String, password: String) throws -> Endpoint {
        struct Body: Encodable { let email: String; let password: String }
        return Endpoint(
            method: .post,
            path: "/api/auth/login",
            body: try JSONEncoder().encode(Body(email: email, password: password)),
            requiresAuth: false
        )
    }

    static var logout: Endpoint {
        Endpoint(method: .post, path: "/api/auth/logout")
    }
}
