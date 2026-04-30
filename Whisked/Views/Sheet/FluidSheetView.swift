// FluidSheetView replaces the native .sheet modifier with a custom overlay
// that follows the user's finger continuously — no fixed snap grid.
//
// Behaviour:
//   • During drag: live offset = router.sheetFraction + gestureState.delta
//   • On release:  velocity is factored into the projected landing position;
//     the sheet springs to whichever snap point that projection is closest to.
//   • Programmatic navigation (SheetRouter.navigate) animates sheetFraction
//     directly — the gesture layer is idle so the spring takes full effect.
//
// Snap fractions (proportion of screen height):
//   0.08  collapsed — handle and search bar only
//   0.42  list      — home list, location detail
//   0.92  full      — loyalty, QR code, profile
import SwiftUI

private let kSnaps: [CGFloat] = [0.08, 0.42, 0.92]
private let kMinFraction: CGFloat = 0.06
private let kMaxFraction: CGFloat = 0.97

struct FluidSheetView: View {
    @Environment(SheetRouter.self) private var router

    /// Live drag expressed as a fraction of screen height (negative = dragging up).
    @GestureState private var dragDelta: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            // Clamp so the sheet never shrinks below the handle or overscrolls.
            let liveFraction = (router.sheetFraction - dragDelta).clamped(to: kMinFraction...kMaxFraction)
            let sheetHeight  = h * liveFraction

            VStack(spacing: 0) {
                dragHandle
                SheetContainerView()
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: sheetHeight, alignment: .top)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.12), radius: 12, y: -3)
            // Position flush with the bottom of the screen.
            .frame(maxHeight: .infinity, alignment: .bottom)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .updating($dragDelta) { value, state, _ in
                        // Translate points → fraction. Dragging up is negative translation.
                        state = value.translation.height / h
                    }
                    .onEnded { value in
                        let velocityFraction = value.predictedEndTranslation.height / h
                        // Project where the sheet would land based on release velocity.
                        let projected = router.sheetFraction - velocityFraction * 0.25
                        let target    = kSnaps.nearest(to: projected.clamped(to: kMinFraction...kMaxFraction))
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            router.sheetFraction = target
                        }
                    }
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 4)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }
}

// MARK: - Helpers

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension [CGFloat] {
    func nearest(to value: CGFloat) -> CGFloat {
        self.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }
}
