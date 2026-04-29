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
}
