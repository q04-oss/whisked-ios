import Foundation
import Observation

@Observable
@MainActor
final class LocationStore {
    private(set) var locations: [WhiskedLocation] = [.jasperAve]
    private(set) var selectedLocation: WhiskedLocation?

    func select(_ location: WhiskedLocation?) {
        selectedLocation = location
    }

    /// Fetches active popup and wholesale locations from the backend.
    /// Permanent bar is always seeded locally.
    func refresh() async {
        // TODO: fetch from /v1/locations when the endpoint is built
    }
}
