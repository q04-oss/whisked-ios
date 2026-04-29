import SwiftUI

/// Shown after a successful stamp. Auto-dismisses after 2 seconds.
struct CelebrationOverlay: View {
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale:   Double = 0.8

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.accent)

                Text("Steep earned!")
                    .font(.title2.bold())

                Text("Your matcha journey continues.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(32)
            .scaleEffect(scale)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1
                scale   = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
    }
}
