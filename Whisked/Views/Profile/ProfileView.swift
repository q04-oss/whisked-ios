// ProfileView is the simplest possible account surface: email, display
// name, and a sign-out button. Nothing else lives here yet — the MVP
// doesn't yet expose order history or saved payment methods.
import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if let profile = auth.profile {
                    Section("Account") {
                        LabeledContent("Email", value: profile.email)
                        LabeledContent("Name", value: profile.displayName ?? "—")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Sign out?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive) {
                    Task { await auth.logout() }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}
