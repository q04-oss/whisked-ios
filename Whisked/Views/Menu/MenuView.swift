// MenuView lists every drink the bar serves. Tapping the + button adds a
// drink to the cart; the cart total updates live in the Cart tab.
//
// Menu source is the box-fraise-platform endpoint `GET /api/whisked/menu`,
// fetched via OrderStore on first appearance.
import SwiftUI

struct MenuView: View {
    @Environment(OrderStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.menu.isEmpty {
                    ContentUnavailableView(
                        "Loading menu…",
                        systemImage: "list.bullet.rectangle"
                    )
                } else if let error = store.error, store.menu.isEmpty {
                    ContentUnavailableView(
                        "Couldn't load menu",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if store.menu.isEmpty {
                    ContentUnavailableView(
                        "Menu is empty",
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
                    .refreshable { await store.fetchMenu() }
                }
            }
            .navigationTitle("Menu")
            .task { await store.fetchMenu() }
        }
    }
}

// MARK: - Row

private struct MenuRow: View {
    let item: WhiskedMenuItemRow
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
            .disabled(!item.available)
            .opacity(item.available ? 1 : 0.4)
        }
        .padding(.vertical, 6)
    }
}
