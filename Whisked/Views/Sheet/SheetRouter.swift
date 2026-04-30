// SheetRouter owns all navigation state for the persistent sheet.
//
// It is injected into the SwiftUI environment from RootView and read by any
// view that needs to navigate or respond to the current route. Keeping route
// state here — rather than scattered across individual views — means the full
// navigation state of the app is inspectable from one place.
//
// It also owns the sheet height fraction so that programmatic navigation
// (e.g. tapping a map pin) can expand the sheet without the call site
// knowing about snap points.
import SwiftUI

@Observable
@MainActor
final class SheetRouter {

    // MARK: - State

    var route:         SheetRoute = .home
    /// Current resting height of the sheet as a fraction of screen height.
    /// The gesture layer adds a live delta on top of this during drag.
    /// Snap points: 0.08 (handle), 0.42 (list), 0.92 (full).
    var sheetFraction: CGFloat    = 0.08

    var isCollapsed: Bool { sheetFraction < 0.15 }

    // MARK: - Navigation

    /// Navigates to a route, expanding the sheet to an appropriate height.
    func navigate(to destination: SheetRoute) {
        withAnimation(.easeInOut(duration: 0.2)) { route = destination }
        let target: CGFloat
        switch destination {
        case .home:              target = 0.42
        case .location:         target = 0.55
        case .loyalty:          target = 0.55
        case .qrCode:           target = 0.92
        case .profile:          target = 0.92
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            sheetFraction = target
        }
    }

    /// Parses a command string from the search bar and routes accordingly.
    /// Returns true if the command was recognised and handled.
    @discardableResult
    func handle(command: String) -> Bool {
        guard let cmd = SheetCommand(command) else { return false }
        switch cmd {
        case .businessLoyalty: navigate(to: .loyalty)   // check longer prefix first
        case .business:        navigate(to: .profile)
        }
        return true
    }
}

// MARK: - Route

/// The set of views the sheet can display.
enum SheetRoute: Equatable {
    case home
    case location(WhiskedLocation)
    case loyalty
    case qrCode   // customer's stamp QR — shown to staff at the bar
    case profile
}

// MARK: - Commands

/// Typed search-bar commands. Each command maps a known prefix to a navigation target.
/// Longer prefixes are matched before shorter ones — /business/loyalty before /business.
enum SheetCommand: CaseIterable {
    case business           // /business        → profile / staff login
    case businessLoyalty    // /business/loyalty → loyalty view

    var prefix: String {
        switch self {
        case .business:        return "/business"
        case .businessLoyalty: return "/business/loyalty"
        }
    }

    /// Initialises from raw search input.
    /// Matches the longest prefix first to prevent /business swallowing /business/loyalty.
    init?(_ input: String) {
        let normalised = input.lowercased().trimmingCharacters(in: .whitespaces)
        let sorted = SheetCommand.allCases.sorted { $0.prefix.count > $1.prefix.count }
        for command in sorted where normalised.hasPrefix(command.prefix) {
            self = command
            return
        }
        return nil
    }
}
