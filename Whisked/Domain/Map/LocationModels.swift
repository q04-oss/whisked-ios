// LocationModels defines the types that represent physical Whisked presence on the map.
//
// A location can be a permanent bar, a temporary popup, or a wholesale client
// stocking Whisked product. All three appear as bell pins on the map. The menu
// is attached to the location rather than being global so that popup-specific
// offerings (e.g. a collab item at a hair salon event) can differ from the bar.
//
// The Jasper Ave bar is seeded locally so the map is populated immediately on
// launch without a network call. Popups and wholesale clients are fetched from
// the backend when LocationStore.refresh() is called.
import CoreLocation
import Foundation

/// A physical location where Whisked matcha is present.
struct WhiskedLocation: Identifiable, Hashable {
    let id:         UUID
    let name:       String
    let type:       LocationType
    let coordinate: CLLocationCoordinate2D
    let address:    String
    let menu:       [MenuItem]

    static func == (lhs: WhiskedLocation, rhs: WhiskedLocation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum LocationType {
    case bar        // permanent bar
    case popup      // temporary popup
    case wholesale  // wholesale client stocking Whisked product

    var label: String {
        switch self {
        case .bar:       return "Matcha Bar"
        case .popup:     return "Pop-up"
        case .wholesale: return "Stockist"
        }
    }
}

struct MenuItem: Identifiable, Hashable {
    let id:    UUID
    let name:  String
    let price: Decimal
    let type:  MenuItemType
}

enum MenuItemType: CaseIterable {
    case matcha, hojicha, retail
}

// MARK: - Seed data

extension WhiskedLocation {
    /// The permanent Jasper Ave bar — always on the map.
    static let jasperAve = WhiskedLocation(
        id:         UUID(),
        name:       "Whisked",
        type:       .bar,
        coordinate: CLLocationCoordinate2D(latitude: 53.5342, longitude: -113.5161),
        address:    "11931 Jasper Ave, Edmonton, Alberta",
        menu:       MenuItem.fullMenu
    )
}

extension MenuItem {
    static let fullMenu: [MenuItem] = [
        MenuItem(id: UUID(), name: "Matcha Latte",                  price: 7.50,  type: .matcha),
        MenuItem(id: UUID(), name: "Vanilla Honey Matcha Latte",    price: 8.50,  type: .matcha),
        MenuItem(id: UUID(), name: "Toasted Marshmallow Matcha",    price: 8.50,  type: .matcha),
        MenuItem(id: UUID(), name: "Earl Grey Matcha Latte",        price: 8.50,  type: .matcha),
        MenuItem(id: UUID(), name: "Maple Sea Salt Matcha",         price: 8.50,  type: .matcha),
        MenuItem(id: UUID(), name: "Hojicha Latte",                 price: 7.50,  type: .hojicha),
        MenuItem(id: UUID(), name: "Banana Bread Hojicha",          price: 8.50,  type: .hojicha),
        MenuItem(id: UUID(), name: "Brown Sugar Cinnamon Hojicha",  price: 8.50,  type: .hojicha),
        MenuItem(id: UUID(), name: "Ceremonial Matcha (30g)",       price: 35.00, type: .retail),
    ]
}
