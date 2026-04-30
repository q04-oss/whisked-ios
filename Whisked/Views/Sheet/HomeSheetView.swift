// HomeSheetView is what the user sees when they first expand the sheet.
// It is a list of locations and nothing else. The loyalty programme is
// accessed through the profile or by stamping after a visit — it does not
// need to announce itself here. Presence on the map is the communication.
import SwiftUI

struct HomeSheetView: View {
    @Environment(LocationStore.self) private var locations

    let onLocationTap: (WhiskedLocation) -> Void
    var onShopTap:     (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(locations.locations) { location in
                    LocationRow(location: location)
                        .contentShape(Rectangle())
                        .onTapGesture { onLocationTap(location) }

                    Divider().padding(.leading, 32)
                }

                // Shop entry — quiet, last in the list.
                if let onShopTap {
                    Button(action: onShopTap) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Shop")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.whisked.ink)
                            Text("Ceremonial matcha, delivered")
                                .font(.footnote)
                                .foregroundStyle(Color.whisked.stone)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }
}

private struct LocationRow: View {
    let location: WhiskedLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(location.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.whisked.ink)

            Text(location.address)
                .font(.footnote)
                .foregroundStyle(Color.whisked.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }
}
