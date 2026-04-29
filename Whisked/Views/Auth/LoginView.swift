import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var auth

    @State private var email    = ""
    @State private var password = ""
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Mark
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.accent)
                    Text("Whisked")
                        .font(.largeTitle.bold())
                    Text("Edmonton's ceremonial matcha bar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 48)

                // Fields
                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await submit() } }
                        .textFieldStyle(.roundedBorder)
                }

                // Error
                if let error = auth.error {
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // Actions
                VStack(spacing: 12) {
                    PrimaryButton(title: "Sign in", isLoading: auth.isLoading) {
                        await submit()
                    }

                    NavigationLink("Create account") {
                        RegisterView()
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
        .onAppear {
            email = auth.cachedEmail ?? ""
        }
    }

    private func submit() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        await auth.login(email: email, password: password)
    }
}

private extension AuthStore {
    var cachedEmail: String? { AuthService().cachedEmail }
}
