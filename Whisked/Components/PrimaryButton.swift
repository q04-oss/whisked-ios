import SwiftUI

/// Full-width primary action button with loading state.
struct PrimaryButton: View {
    let title:     String
    let isLoading: Bool
    let action:    () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}
