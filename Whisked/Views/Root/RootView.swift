// RootView is the single scene root.
//
// The map fills the entire screen at all times — there is no navigation stack,
// no tab bar, no splash screen after the first launch. The persistent sheet
// floats above the map and is never dismissible. Auth, loyalty, and location
// detail all surface through the sheet rather than as separate screens.
//
// SheetRouter is created here and injected into the environment so any
// descendant can trigger navigation without prop drilling.
import SwiftUI

struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @State private var router = SheetRouter()

    var body: some View {
        ZStack {
            WhiskedMapView()
                .ignoresSafeArea()

            FluidSheetView()
                .environment(router)
        }
        .environment(router)
        .task { await auth.bootstrap() }
    }
}
