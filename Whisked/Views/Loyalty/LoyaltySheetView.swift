// LoyaltySheetView is the loyalty programme screen, presented inside the sheet.
//
// It shows the steep progress ring, the current balance, a stamp button (with
// confirmation dialog), a redeem button when rewards are available, and a
// truncated recent history list. Full history is available via the history
// endpoint but showing the last 5 events is sufficient for this surface.
//
// Stamp and redeem operations go through LoyaltyStore which handles idempotency
// keys and error state. This view only drives confirmations and celebrations.
import SwiftUI

struct LoyaltySheetView: View {
    @Environment(LoyaltyStore.self) private var loyalty
    let onDismiss: () -> Void

    @State private var showStampConfirm  = false
    @State private var showRedeemConfirm = false
    @State private var showCelebration   = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // ── Header ─────────────────────────────────────────────────
                HStack {
                    Text("Steeps")
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

                if let balance = loyalty.balance {
                    // ── Progress ───────────────────────────────────────────
                    VStack(spacing: 12) {
                        SteepProgressView(progress: balance.progress, total: 9)
                            .frame(width: 160, height: 160)

                        VStack(spacing: 4) {
                            Text("\(balance.steepsEarned)")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.whisked.ink)
                            Text(balance.steepsEarned == 1 ? "steep" : "steeps")
                                .font(.subheadline)
                                .foregroundStyle(Color.whisked.stone)
                        }

                        if balance.available > 0 {
                            Text(balance.available == 1 ? "1 free drink ready" : "\(balance.available) free drinks ready")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.whisked.amber)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.whisked.yellow.opacity(0.35), in: Capsule())
                        } else {
                            Text("\(balance.until) more \(balance.until == 1 ? "steep" : "steeps") until your next free drink")
                                .font(.footnote)
                                .foregroundStyle(Color.whisked.stone)
                        }
                    }

                    // ── Actions ────────────────────────────────────────────
                    VStack(spacing: 10) {
                        PrimaryButton(title: "Stamp my steep", isLoading: loyalty.isStamping) {
                            showStampConfirm = true
                        }

                        if balance.available > 0 {
                            Button("Redeem free drink") { showRedeemConfirm = true }
                                .font(.subheadline)
                                .foregroundStyle(Color.whisked.amber)
                        }
                    }
                    .padding(.horizontal, 16)

                    // ── History ────────────────────────────────────────────
                    if !loyalty.history.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.whisked.stone)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ForEach(loyalty.history.prefix(5)) { event in
                                    EventRow(event: event)
                                    if event.id != loyalty.history.prefix(5).last?.id {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.whisked.beige, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                        }
                    }

                } else if loyalty.isLoading {
                    ProgressView().padding(.top, 32)
                }

                Spacer(minLength: 32)
            }
        }
        .scrollIndicators(.hidden)
        .confirmationDialog("Stamp a steep?", isPresented: $showStampConfirm, titleVisibility: .visible) {
            Button("Stamp") {
                Task {
                    await loyalty.stamp()
                    if loyalty.error == nil { showCelebration = true }
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
        .overlay {
            if showCelebration {
                CelebrationOverlay { showCelebration = false }
            }
        }
    }
}

private struct EventRow: View {
    let event: LoyaltyEvent
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.isEarn ? "bell.fill" : "gift.fill")
                .foregroundStyle(event.isEarn ? Color.whisked.amber : Color.whisked.stone)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.whisked.ink)
                Text(event.sourceLabel)
                    .font(.caption)
                    .foregroundStyle(Color.whisked.stone)
            }
            Spacer()
            Text(event.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(Color.whisked.stone.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}
