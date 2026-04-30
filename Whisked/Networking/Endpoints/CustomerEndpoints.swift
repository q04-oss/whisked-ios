import Foundation

extension Endpoint {
    static var me: Endpoint {
        Endpoint(method: .get, path: "/api/auth/me")
    }

    static func updateDisplayName(_ name: String) throws -> Endpoint {
        struct Body: Encodable { let display_name: String }
        return Endpoint(
            method: .patch,
            path: "/api/auth/display-name",
            body: try JSONEncoder().encode(Body(display_name: name))
        )
    }

    static func registerPushToken(_ token: String) throws -> Endpoint {
        struct Body: Encodable { let push_token: String }
        return Endpoint(
            method: .patch,
            path: "/api/auth/push-token",
            body: try JSONEncoder().encode(Body(push_token: token))
        )
    }
}
