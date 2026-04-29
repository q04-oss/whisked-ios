// SearchBarView is always visible at the top of the sheet regardless of detent.
// It is the primary surface through which the user speaks to Whisked —
// both as a brand (search, questions) and as a command interface (/business).
//
// The bell mark is intentionally small and left-aligned — it identifies the
// brand without competing with the input field. The profile button is the
// only other element. Nothing else belongs here.
import SwiftUI

struct SearchBarView: View {
    @Binding var query: String
    let onCommand:    (String) -> Void
    let onSearch:     (String) -> Void
    let onProfileTap: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.whisked.amber)

            TextField("Whisked", text: $query)
                .font(.system(size: 16))
                .foregroundStyle(Color.whisked.ink)
                .focused($focused)
                .submitLabel(.search)
                .onSubmit { submit() }
                .tint(Color.whisked.amber)

            if !query.isEmpty {
                Button { query = ""; focused = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.whisked.stone.opacity(0.5))
                        .font(.system(size: 14))
                }
                .transition(.opacity)
            }

            Button(action: onProfileTap) {
                Image(systemName: "person.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.whisked.stone)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .animation(.easeInOut(duration: 0.15), value: query.isEmpty)
    }

    private func submit() {
        let input = query.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return }
        input.hasPrefix("/") ? onCommand(input) : onSearch(input)
        focused = false
    }
}
