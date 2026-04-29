import MapKit
import SwiftUI

struct LocationDetailView: View {
    let location: WhiskedLocation
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ─────────────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.name)
                            .font(.title2.bold())
                            .foregroundStyle(Color.whisked.ink)
                        Text(location.type.label)
                            .font(.subheadline)
                            .foregroundStyle(Color.whisked.stone)
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.whisked.beige)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // ── Address + directions ───────────────────────────────────
                Button {
                    openInMaps()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.whisked.amber)
                        Text(location.address)
                            .font(.footnote)
                            .foregroundStyle(Color.whisked.stone)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.whisked.stone)
                    }
                    .padding(14)
                    .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }

                // ── Menu ──────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Menu")
                        .font(.headline)
                        .foregroundStyle(Color.whisked.ink)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    ForEach(MenuItemType.allCases, id: \.self) { type in
                        let items = location.menu.filter { $0.type == type }
                        if !items.isEmpty {
                            MenuSection(type: type, items: items)
                        }
                    }
                }

                Spacer(minLength: 32)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        item.name = location.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

// MARK: - Menu section

private struct MenuSection: View {
    let type:  MenuItemType
    let items: [MenuItem]

    var title: String {
        switch type {
        case .matcha:  return "Matcha"
        case .hojicha: return "Hojicha"
        case .retail:  return "Retail"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.whisked.stone)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(Color.whisked.ink)
                        Spacer()
                        Text(item.price, format: .currency(code: "CAD"))
                            .font(.subheadline)
                            .foregroundStyle(Color.whisked.stone)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)

                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}

extension MenuItemType: CaseIterable {}
