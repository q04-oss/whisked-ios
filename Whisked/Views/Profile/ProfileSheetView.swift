// ProfileSheetView serves two distinct audiences from the same route:
//
//   Authenticated — shows the customer's name, email, loyalty stats, and sign-out.
//   Unauthenticated — shows an inline login form.
//
// This dual behaviour is intentional: the profile route is the only entry point
// for auth in the app. There is no separate login screen — the map is always
// visible and auth happens inside the sheet. The unauthenticated state presents
// a minimal form rather than a full-screen takeover.
//
// The /business command (SheetCommand) also routes here, giving staff a discreet
// path to the dashboard login without any admin chrome on the public-facing app.
import SwiftUI

struct ProfileSheetView: View {
    @Environment(AuthStore.self)    private var auth
    @Environment(LoyaltyStore.self) private var loyalty
    let onDismiss: () -> Void

    @State private var showSignOut = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────────────
                HStack {
                    Text(auth.isAuthenticated ? "Profile" : "Sign in")
                        .font(.title2.bold())
                        .foregroundStyle(Color.whisked.ink)
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
                .padding(.bottom, 20)

                if auth.isAuthenticated {
                    authenticatedContent
                } else {
                    unauthenticatedContent
                }

                Spacer(minLength: 32)
            }
        }
        .scrollIndicators(.hidden)
        .confirmationDialog("Sign out?", isPresented: $showSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { Task { await auth.logout() } }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Authenticated

    private var authenticatedContent: some View {
        VStack(spacing: 16) {
            if let profile = auth.profile {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.whisked.yellow.opacity(0.4))
                        .frame(width: 72, height: 72)
                    Text(profile.displayName.prefix(1).uppercased())
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.whisked.amber)
                }

                VStack(spacing: 4) {
                    Text(profile.displayName.isEmpty ? "Whisked customer" : profile.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.whisked.ink)
                    Text(profile.email)
                        .font(.subheadline)
                        .foregroundStyle(Color.whisked.stone)
                }
            }

            // Stats
            if let balance = loyalty.balance {
                HStack(spacing: 0) {
                    statCell(value: "\(balance.steepsEarned)", label: "Steeps")
                    Divider().frame(height: 36)
                    statCell(value: "\(balance.rewardsRedeemed)", label: "Redeemed")
                }
                .padding(.vertical, 14)
                .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            }

            // Sign out
            Button(role: .destructive) {
                showSignOut = true
            } label: {
                Text("Sign out")
                    .font(.subheadline)
                    .foregroundStyle(Color.whisked.stone)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Unauthenticated

    @State private var email    = ""
    @State private var password = ""

    private var unauthenticatedContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(14)
                    .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding(14)
                    .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)

            if let error = auth.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            PrimaryButton(title: "Sign in", isLoading: auth.isLoading) {
                await auth.login(email: email, password: password)
            }
            .padding(.horizontal, 16)

            NavigationLink("Create account") {
                RegisterView()
            }
            .font(.subheadline)
            .foregroundStyle(Color.whisked.amber)
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.whisked.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.whisked.stone)
        }
        .frame(maxWidth: .infinity)
    }
}
