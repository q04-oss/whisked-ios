// LocationStore is the source of truth for all Whisked locations shown on the map.
//
// The permanent Jasper Ave bar is seeded locally so the map is populated on
// first launch without waiting for a network call. Popups and wholesale clients
// are fetched from the backend — the refresh() stub will be filled in when the
// /v1/locations endpoint is built on whisked-platform.
//
// selectedLocation is the bridge between the map and the sheet: WhiskedMapView
// writes to it when the user taps a pin, and SheetContainerView reads it to
// trigger navigation to the location detail route via SheetRouter.
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
