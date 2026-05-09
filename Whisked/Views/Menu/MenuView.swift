// MenuView lists every drink the bar serves. Tapping the + button adds a
// drink to the cart; the cart total updates live in the Cart tab.
//
// The menu source is OrderStore, which currently returns a hardcoded set
// (see MenuItem.placeholders). Real fetch lands when GET /api/whisked/menu
// ships on box-fraise-platform.
import SwiftUI

struct MenuView: View {
    @Environment(OrderStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.menu.isEmpty {
                    ContentUnavailableView(
                        "Loading menu",
                        systemImage: "list.bullet.rectangle"
                    )
                } else {
                    List(store.menu) { item in
                        MenuRow(item: item) { store.addToCart(item) }
                            .listRowBackground(Color.whisked.cream)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.whisked.cream)
                }
            }
            .navigationTitle("Menu")
            .task { await store.fetchMenu() }
        }
    }
}

// MARK: - Row

private struct MenuRow: View {
    let item: MenuItem
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.whisked.ink)
                if let description = item.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.whisked.stone)
                }
                Text(item.price, format: .currency(code: "CAD"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.whisked.ink)
                    .padding(.top, 2)
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.whisked.amber)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}
