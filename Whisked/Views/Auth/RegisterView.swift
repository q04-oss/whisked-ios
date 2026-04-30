import SwiftUI

struct RegisterView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email       = ""
    @State private var displayName = ""
    @State private var password    = ""
    @FocusState private var focus: Field?

    private enum Field { case email, name, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Join Whisked")
                        .font(.largeTitle.bold())
                    Text("Your account works across the box fraise network")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await submit() } }
                        .textFieldStyle(.roundedBorder)
                }

                if let error = auth.error {
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Create account", isLoading: auth.isLoading) {
                    await submit()
                }

                Text("By creating an account you agree to our terms and join the box fraise network.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        await auth.register(email: email, displayName: displayName, password: password)
    }
}
