import Foundation

extension Endpoint {
    static var me: Endpoint {
        Endpoint(method: .get, path: "/v1/customers/me")
    }

    static func updateMe(displayName: String) throws -> Endpoint {
        struct Body: Encodable { let display_name: String }
        return Endpoint(
            method: .patch,
            path: "/v1/customers/me",
            body: try JSONEncoder().encode(Body(display_name: displayName))
        )
    }

    static var deleteMe: Endpoint {
        Endpoint(method: .delete, path: "/v1/customers/me")
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
