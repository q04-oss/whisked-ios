// ProfileSheetView serves two states: authenticated and unauthenticated.
//
// Authenticated — customer name, join date, quiet sign-out. No stats, no cards.
// Unauthenticated — minimal login with inline register. Fields separated by
// dividers only — no background colors. The /business command routes here;
// staff sign in with staff credentials. No separate admin entry point exists.
import SwiftUI

struct ProfileSheetView: View {
    @Environment(AuthStore.self)   private var auth
    let onDismiss: () -> Void

    @State private var showSignOut  = false
    @State private var showRegister = false

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

                if auth.isAuthenticated {
                    authenticatedContent
                } else if showRegister {
                    RegisterForm(onSuccess: { showRegister = false })
                        .padding(.top, 40)
                } else {
                    LoginForm(onRegisterTap: { showRegister = true })
                        .padding(.top, 40)
                }

                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
        .confirmationDialog("Sign out?", isPresented: , titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { Task { await auth.logout() } }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var authenticatedContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let profile = auth.profile {
                Text(profile.displayName.isEmpty ? "Whisked" : profile.displayName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.whisked.ink)
                    .padding(.top, 32)
                Text(profile.email)
                    .font(.footnote)
                    .foregroundStyle(Color.whisked.stone)
                Text("Member since (profile.createdAt.formatted(.dateTime.month(.wide).year()))")
                    .font(.footnote)
                    .foregroundStyle(Color.whisked.stone.opacity(0.6))
                    .padding(.top, 4)
                Spacer().frame(height: 48)
                Button("Sign out") { showSignOut = true }
                    .font(.footnote)
                    .foregroundStyle(Color.whisked.stone)
            }
        }
        .padding(.horizontal, 32)
    }
}

private struct LoginForm: View {
    @Environment(AuthStore.self) private var auth
    let onRegisterTap: () -> Void
    @State private var email    = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sign in")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.whisked.ink)
                .padding(.horizontal, 32)
            VStack(spacing: 0) {
                TextField("Email", text: )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .font(.subheadline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                Divider().padding(.leading, 32)
                SecureField("Password", text: )
                    .textContentType(.password)
                    .font(.subheadline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
            .padding(.top, 32)
            if let error = auth.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
            }
            PrimaryButton(title: "Continue", isLoading: auth.isLoading) {
                await auth.login(email: email, password: password)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            Button("Create an account") { onRegisterTap() }
                .font(.footnote)
                .foregroundStyle(Color.whisked.stone)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }
}

private struct RegisterForm: View {
    @Environment(AuthStore.self) private var auth
    let onSuccess: () -> Void
    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Join Whisked")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.whisked.ink)
                .padding(.horizontal, 32)
            VStack(spacing: 0) {
                TextField("Name", text: )
                    .textContentType(.name).font(.subheadline)
                    .padding(.horizontal, 32).padding(.vertical, 16)
                Divider().padding(.leading, 32)
                TextField("Email", text: )
                    .textContentType(.emailAddress).keyboardType(.emailAddress)
                    .autocapitalization(.none).font(.subheadline)
                    .padding(.horizontal, 32).padding(.vertical, 16)
                Divider().padding(.leading, 32)
                SecureField("Password", text: )
                    .textContentType(.newPassword).font(.subheadline)
                    .padding(.horizontal, 32).padding(.vertical, 16)
            }
            .padding(.top, 32)
            if let error = auth.error {
                Text(error.localizedDescription)
                    .font(.caption).foregroundStyle(.red)
                    .padding(.horizontal, 32).padding(.top, 12)
            }
            PrimaryButton(title: "Create account", isLoading: auth.isLoading) {
                await auth.register(email: email, displayName: name, password: password)
                if auth.isAuthenticated { onSuccess() }
            }
            .padding(.horizontal, 32).padding(.top, 28)
        }
    }
}
