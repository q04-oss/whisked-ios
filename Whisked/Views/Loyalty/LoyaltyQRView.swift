// LoyaltyQRView displays the customer's stamp QR code.
//
// Staff scan this with their phone camera. The camera app opens a URL on
// the backend (/stamp?t=<token>) which validates the token, records the steep,
// and shows a simple HTML confirmation page.
//
// The token is short-lived (5 minutes). The view auto-refreshes silently
// before expiry so the code is always valid when shown at the counter.
// The customer does not need to do anything — just show the screen.
import CoreImage.CIFilterBuiltins
import SwiftUI

struct LoyaltyQRView: View {
    @Environment(LoyaltyStore.self) private var loyalty
    let onDismiss: () -> Void

    @State private var token:      StampToken?
    @State private var qrImage:    UIImage?
    @State private var isLoading   = false
    @State private var error:      APIError?
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {

            // ── Dismiss ───────────────────────────────────────────────────
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

            Spacer()

            if let qrImage {
                // ── QR code ───────────────────────────────────────────────
                VStack(spacing: 20) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))

                    Text("Show this to staff")
                        .font(.footnote)
                        .foregroundStyle(Color.whisked.stone)
                        .tracking(0.5)

                    if let token {
                        ExpiryIndicator(expiresIn: token.expiresIn, onExpiry: { Task { await refresh() } })
                    }
                }

            } else if isLoading {
                ProgressView()
                    .tint(Color.whisked.stone)

            } else if let error {
                VStack(spacing: 12) {
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundStyle(Color.whisked.stone)
                        .multilineTextAlignment(.center)
                    Button("Try again") { Task { await refresh() } }
                        .font(.footnote)
                        .foregroundStyle(Color.whisked.amber)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .task { await refresh() }
        .onDisappear { refreshTask?.cancel() }
    }

    // MARK: - Token management

    private func refresh() async {
        isLoading = true
        error     = nil
        do {
            let t = try await APIClient.shared.request(.qrToken, as: StampToken.self)
            token   = t
            qrImage = generateQR(for: t)
            scheduleRefresh(in: t.expiresIn)
        } catch let e as APIError {
            self.error = e
        } catch {
            self.error = .networkError(error)
        }
        isLoading = false
    }

    private func scheduleRefresh(in seconds: Int) {
        refreshTask?.cancel()
        // Refresh 30 seconds before expiry so there's always a valid code ready.
        let delay = max(seconds - 30, 10)
        refreshTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    // MARK: - QR generation

    private func generateQR(for stampToken: StampToken) -> UIImage? {
        let url = stampToken.stampURL(baseURL: Config.apiBaseURL)
        let context = CIContext()
        let filter  = CIFilter.qrCodeGenerator()
        filter.message        = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }

        // Scale up so the QR code renders crisply at display size.
        let scale      = 220.0 / output.extent.width
        let scaled     = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Expiry indicator

private struct ExpiryIndicator: View {
    let expiresIn: Int
    let onExpiry: () -> Void

    @State private var remaining: Int

    init(expiresIn: Int, onExpiry: @escaping () -> Void) {
        self.expiresIn = expiresIn
        self.onExpiry  = onExpiry
        _remaining     = State(initialValue: expiresIn)
    }

    var body: some View {
        Text(remaining > 0 ? "Refreshes in \(remaining)s" : "Refreshing...")
            .font(.caption2)
            .foregroundStyle(Color.whisked.stone.opacity(0.5))
            .monospacedDigit()
            .task {
                while remaining > 0 {
                    try? await Task.sleep(for: .seconds(1))
                    remaining -= 1
                }
                onExpiry()
            }
    }
}
