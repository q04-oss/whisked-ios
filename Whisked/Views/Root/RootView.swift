import SwiftUI

/// Root view — MapKit fills the screen, the persistent sheet floats over it.
/// Auth is handled inside the sheet (profile panel) rather than as a separate
/// navigation stack. The map and bell pin are always visible.
struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @State private var detent: PresentationDetent = .height(88)

    var body: some View {
        ZStack {
            // Map fills the entire screen including safe areas.
            WhiskedMapView()
                .ignoresSafeArea()
        }
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                SheetContainerView(detent: $detent)
            }
            .presentationDetents([.height(88), .medium, .large], selection: $detent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
            .presentationCornerRadius(20)
            .presentationBackground(Color.whisked.cream)
        }
        .task { await auth.bootstrap() }
    }
}
