import SwiftUI

/// Default sheet content — list of locations.
/// Tapping a location expands the sheet and shows detail.
struct HomeSheetView: View {
    @Environment(LocationStore.self) private var locations
    @Environment(LoyaltyStore.self)  private var loyalty
    @Environment(AuthStore.self)     private var auth

    let onLocationTap: (WhiskedLocation) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Loyalty nudge (authenticated) ──────────────────────────
                if auth.isAuthenticated, let balance = loyalty.balance {
                    LoyaltyNudgeView(balance: balance)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                // ── Locations ──────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("Locations")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.whisked.stone)
                        .padding(.horizontal, 16)

                    ForEach(locations.locations) { location in
                        LocationRow(location: location)
                            .contentShape(Rectangle())
                            .onTapGesture { onLocationTap(location) }
                    }
                }
                .padding(.top, auth.isAuthenticated ? 0 : 16)
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Loyalty nudge

private struct LoyaltyNudgeView: View {
    let balance: LoyaltyBalance

    var body: some View {
        HStack(spacing: 12) {
            SteepProgressView(progress: balance.progress, total: 9)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                if balance.available > 0 {
                    Text("Free drink ready")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.whisked.ink)
                    Text("Show this at the bar to redeem")
                        .font(.caption)
                        .foregroundStyle(Color.whisked.stone)
                } else {
                    Text("\(balance.progress) of 9 steeps")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.whisked.ink)
                    Text("\(balance.until) more until your next free drink")
                        .font(.caption)
                        .foregroundStyle(Color.whisked.stone)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Location row

private struct LocationRow: View {
    let location: WhiskedLocation

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.whisked.yellow.opacity(0.4))
                    .frame(width: 40, height: 40)
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.whisked.amber)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.whisked.ink)
                Text(location.address)
                    .font(.caption)
                    .foregroundStyle(Color.whisked.stone)
                    .lineLimit(1)
            }

            Spacer()

            Text(location.type.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.whisked.amber)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.whisked.yellow.opacity(0.3), in: Capsule())

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.whisked.stone)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
