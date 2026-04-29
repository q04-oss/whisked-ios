// PrimaryButton is the single primary action on any given sheet surface.
// It uses a dark fill on light backgrounds — decisive without being loud.
// There should be at most one PrimaryButton visible at a time.
import SwiftUI

struct PrimaryButton: View {
    let title:     String
    var isLoading: Bool = false
    let action:    () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.whisked.ink, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading)
    }
}
