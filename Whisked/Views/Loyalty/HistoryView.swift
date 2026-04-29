import SwiftUI

struct HistoryView: View {
    @Environment(LoyaltyStore.self) private var loyalty

    var body: some View {
        NavigationStack {
            Group {
                if loyalty.history.isEmpty && !loyalty.isLoading {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "leaf",
                        description: Text("Your steeps will appear here after your first visit.")
                    )
                } else {
                    List(loyalty.history) { event in
                        EventRow(event: event)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .refreshable { await loyalty.load() }
        }
    }
}

private struct EventRow: View {
    let event: LoyaltyEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.isEarn ? "leaf.fill" : "gift.fill")
                .foregroundStyle(event.isEarn ? .accent : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayTitle)
                    .font(.subheadline.weight(.medium))
                Text(event.sourceLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(event.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
