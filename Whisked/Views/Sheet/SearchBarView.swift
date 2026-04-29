import SwiftUI

/// The command bar at the top of the persistent sheet.
/// Regular text → brand chat (future Claude integration).
/// Text starting with "/" → command routing.
struct SearchBarView: View {
    @Binding var query: String
    let onCommand:  (String) -> Void
    let onSearch:   (String) -> Void
    let onProfileTap: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Bell mark — brand identifier
            Image(systemName: "bell.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.whisked.amber)
                .frame(width: 28)

            TextField("Whisked", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(Color.whisked.ink)
                .focused($focused)
                .submitLabel(.search)
                .onSubmit { submit() }
                .tint(Color.whisked.amber)

            if !query.isEmpty {
                Button {
                    query = ""
                    focused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.whisked.stone)
                }
                .transition(.opacity.combined(with: .scale))
            }

            Divider()
                .frame(height: 20)

            // Profile button
            Button(action: onProfileTap) {
                Image(systemName: "person.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.whisked.amber)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.whisked.cream, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.whisked.beige, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
    }

    private func submit() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if trimmed.hasPrefix("/") {
            onCommand(trimmed)
        } else {
            onSearch(trimmed)
        }
        focused = false
    }
}
