// StampConfirmation is the feedback shown after a steep is recorded.
//
// A modal overlay with text is too loud for this brand — the confirmation
// is a brief bell mark that appears centered in the sheet, fades out, and
// triggers a haptic. The status update in OrderStatusView is the
// real confirmation. This is the feeling, not the information.
import SwiftUI

struct StampConfirmation: View {
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale:   Double = 0.7

    var body: some View {
        Image(systemName: "bell.fill")
            .font(.system(size: 40, weight: .light))
            .foregroundStyle(Color.whisked.amber)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    opacity = 1
                    scale   = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.4)) { opacity = 0 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onDismiss() }
                }
            }
            .allowsHitTesting(false)
    }
}
