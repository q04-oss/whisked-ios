import SwiftUI

struct ProfileSheetView: View {
    @Environment(AuthStore.self) private var auth
    let onDismiss: () -> Void

    @State private var showSignOut = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.whisked.stone)
                            .padding(8)
                            .background(Color.whisked.stone.opacity(0.08), in: Circle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)

                switch auth.state {
                case .authenticated:
                    authenticatedContent
                        .padding(.top, 40)
                case .awaitingMagicLink(let email):
                    MagicLinkSentView(email: email, onReset: { auth.resetAuth() })
                        .padding(.top, 40)
                default:
                    MagicLinkForm()
                        .padding(.top, 40)
                }

                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
        .confirmationDialog("Sign out?", isPresented: $showSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { Task { await auth.logout() } }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var authenticatedContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let profile = auth.profile {
                Text(profile.displayName ?? "Whisked member")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.whisked.ink)
                Text(profile.email)
                    .font(.footnote)
                    .foregroundStyle(Color.whisked.stone)
                if !profile.verified {
                    Text("Verify your email to earn steeps")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
                Spacer().frame(height: 48)
                Button("Sign out") { showSignOut = true }
                    .font(.footnote)
                    .foregroundStyle(Color.whisked.stone)
            }
        }
        .padding(.horizontal, 32)
    }
}

private struct MagicLinkForm: View {
    @Environment(AuthStore.self) private var auth
    @State private var email = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sign in")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.whisked.ink)
                .padding(.horizontal, 32)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .font(.subheadline)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .padding(.top, 32)
            Divider().padding(.leading, 32)
            if let error = auth.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
            }
            PrimaryButton(title: "Continue", isLoading: auth.isLoading) {
                await auth.requestMagicLink(email: email)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            Text("We'll email you a sign-in link. No password needed.")
                .font(.caption)
                .foregroundStyle(Color.whisked.stone.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 16)
        }
    }
}

private struct MagicLinkSentView: View {
    let email:   String
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Check your email")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.whisked.ink)
                .padding(.horizontal, 32)
            Text("We sent a sign-in link to")
                .font(.subheadline)
                .foregroundStyle(Color.whisked.stone)
                .padding(.horizontal, 32)
                .padding(.top, 12)
            Text(email)
                .font(.subheadline.bold())
                .foregroundStyle(Color.whisked.ink)
                .padding(.horizontal, 32)
                .padding(.top, 2)
            Text("Tap the link in the email to sign in. It expires in 15 minutes.")
                .font(.caption)
                .foregroundStyle(Color.whisked.stone.opacity(0.6))
                .padding(.horizontal, 32)
                .padding(.top, 16)
            Button("Use a different email") { onReset() }
                .font(.footnote)
                .foregroundStyle(Color.whisked.stone)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        }
    }
}
