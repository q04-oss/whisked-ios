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
            path: "/v1/auth/register",
            body: try JSONEncoder().encode(Body(email: email, display_name: displayName, password: password)),
            requiresAuth: false
        )
    }

    static func login(email: String, password: String) throws -> Endpoint {
        struct Body: Encodable { let email: String; let password: String }
        return Endpoint(
            method: .post,
            path: "/v1/auth/login",
            body: try JSONEncoder().encode(Body(email: email, password: password)),
            requiresAuth: false
        )
    }

    static func refresh(token: String) throws -> Endpoint {
        struct Body: Encodable { let refresh_token: String }
        return Endpoint(
            method: .post,
            path: "/v1/auth/refresh",
            body: try JSONEncoder().encode(Body(refresh_token: token)),
            requiresAuth: false
        )
    }

    static func logout(refreshToken: String) throws -> Endpoint {
        struct Body: Encodable { let refresh_token: String }
        return Endpoint(
            method: .post,
            path: "/v1/auth/logout",
            body: try JSONEncoder().encode(Body(refresh_token: refreshToken)),
            requiresAuth: false
        )
    }
}
