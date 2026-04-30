// LoyaltySheetView is the steep passport — the record of the customer's practice.
//
// The number is the experience. Everything else is context. No history list,
// no secondary stats, no decorative cards. The stamp action and the redeem
// action when available. That is all.
import SwiftUI

struct LoyaltySheetView: View {
    @Environment(LoyaltyStore.self) private var loyalty
    let onDismiss: () -> Void
    var onShowQR: (() -> Void)? = nil

    @State private var showStampConfirm  = false
    @State private var showRedeemConfirm = false
    @State private var showStampConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Dismiss ───────────────────────────────────────────────
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

                if let balance = loyalty.balance {

                    // ── Ring ──────────────────────────────────────────────
                    SteepProgressView(progress: balance.progress, total: 9)
                        .frame(width: 140, height: 140)
                        .padding(.top, 32)

                    // ── Count ─────────────────────────────────────────────
                    VStack(spacing: 6) {
                        Text("\(balance.steepsEarned)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.whisked.ink)

                        Text(balance.steepsEarned == 1 ? "steep" : "steeps")
                            .font(.footnote)
                            .foregroundStyle(Color.whisked.stone)
                            .tracking(1.5)
                            .textCase(.uppercase)
                    }
                    .padding(.top, 24)

                    // ── Status ────────────────────────────────────────────
                    Group {
                        if balance.available > 0 {
                            Text(balance.available == 1 ? "One free drink ready" : "\(balance.available) free drinks ready")
                                .foregroundStyle(Color.whisked.amber)
                        } else {
                            Text("\(balance.until) until next")
                                .foregroundStyle(Color.whisked.stone)
                        }
                    }
                    .font(.footnote)
                    .padding(.top, 12)

                    // ── Actions ───────────────────────────────────────────
                    VStack(spacing: 14) {
                        // QR code — shown to staff after buying a drink.
                        // Replaces the self-stamp button for validated loyalty.
                        if let onShowQR {
                            PrimaryButton(title: "Show stamp code") {
                                onShowQR()
                            }
                        } else {
                            PrimaryButton(title: "Stamp", isLoading: loyalty.isStamping) {
                                showStampConfirm = true
                            }
                        }

                        if balance.available > 0 {
                            Button("Redeem free drink") { showRedeemConfirm = true }
                                .font(.footnote)
                                .foregroundStyle(Color.whisked.stone)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)

                } else if loyalty.isLoading {
                    ProgressView()
                        .padding(.top, 80)
                        .tint(Color.whisked.stone)
                }

                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .center) {
            if showStampConfirmation {
                StampConfirmation { showStampConfirmation = false }
            }
        }
        .confirmationDialog("Stamp a steep?", isPresented: $showStampConfirm, titleVisibility: .visible) {
            Button("Stamp") {
                Task {
                    await loyalty.stamp()
                    if loyalty.error == nil { showStampConfirmation = true }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Record a steep from your visit today.")
        }
        .confirmationDialog("Redeem a free drink?", isPresented: $showRedeemConfirm, titleVisibility: .visible) {
            Button("Redeem", role: .destructive) { Task { await loyalty.redeem() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Show this to a barista when you order.")
        }
    }
}
