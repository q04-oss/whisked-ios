import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if let profile = auth.profile {
                    Section {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 52, height: 52)
                                .overlay {
                                    Text(profile.displayName.prefix(1).uppercased())
                                        .font(.title2.bold())
                                        .foregroundStyle(.accent)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName.isEmpty ? "Whisked customer" : profile.displayName)
                                    .font(.headline)
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("About") {
                    LabeledContent("Member since") {
                        if let joined = auth.profile?.createdAt {
                            Text(joined, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Network") {
                        Text("Maison Fraise")
                            .foregroundStyle(.secondary)
                    }
                }

                if auth.profile?.verified == false {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Verify your email", systemImage: "envelope.badge")
                                .font(.subheadline.weight(.medium))
                            Text("Check your inbox to verify your account and unlock steeps across the Maison Fraise network.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Action required")
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
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    Task { await auth.logout() }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}
