// AuthView is the magic-link sign-in surface. We only support magic link in
// the MVP — box-fraise-platform's auth supports both Apple Sign In and magic
// link, but Apple Sign In requires entitlement plumbing and a paid developer
// team; magic link is sufficient to ship.
//
// Two states are visible here: the email-entry form, and a "we sent you a
// link" confirmation. The actual link-tap → token exchange happens in
// `WhiskedApp.swift::onOpenURL` via the `whisked://auth?token=...` deep link.
import SwiftUI

struct AuthView: View {
    @Environment(AuthStore.self) private var auth
    @State private var email = ""

    var body: some View {
        VStack {
            switch auth.state {
            case .awaitingMagicLink(let sent):
                MagicLinkSent(email: sent) { auth.resetAuth() }
            default:
                MagicLinkRequest(
                    email:     $email,
                    isLoading: auth.isLoading,
                    error:     auth.error
                ) {
                    await auth.requestMagicLink(email: email)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.whisked.cream.ignoresSafeArea())
    }
}

// MARK: - Email entry

private struct MagicLinkRequest: View {
    @Binding var email: String
    let isLoading:   Bool
    let error:       APIError?
    let onSubmit:    () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 40)

            Text("Welcome to Whisked")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.whisked.ink)
            Text("Enter your email and we'll send a sign-in link.")
                .font(.subheadline)
                .foregroundStyle(Color.whisked.stone)

            TextField("you@example.com", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 12))

            if let error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            PrimaryButton(title: "Send link", isLoading: isLoading, action: onSubmit)
                .padding(.top, 4)

            Spacer()
        }
    }
}

// MARK: - Confirmation

private struct MagicLinkSent: View {
    let email:   String
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer().frame(height: 40)

            Text("Check your email")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.whisked.ink)

            (Text("We sent a sign-in link to ")
                .foregroundStyle(Color.whisked.stone)
             + Text(email).bold().foregroundStyle(Color.whisked.ink))
                .font(.subheadline)

            Text("Tap the link to finish signing in. The link expires in 15 minutes.")
                .font(.footnote)
                .foregroundStyle(Color.whisked.stone)
                .padding(.top, 4)

            Button("Use a different email", action: onReset)
                .font(.footnote)
                .foregroundStyle(Color.whisked.amber)
                .padding(.top, 16)

            Spacer()
        }
    }
}
