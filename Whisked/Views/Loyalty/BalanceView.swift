import SwiftUI

/// The main loyalty screen — the customer's steep passport.
/// Shows their progress toward the next free drink and provides the stamp button.
struct BalanceView: View {
    @Environment(LoyaltyStore.self) private var loyalty
    @State private var showStampConfirmation = false
    @State private var showRedeemConfirmation = false
    @State private var showCelebration = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if let balance = loyalty.balance {
                        // Progress ring + count
                        VStack(spacing: 16) {
                            SteepProgressView(progress: balance.progress, total: 9)
                                .frame(width: 200, height: 200)

                            VStack(spacing: 4) {
                                Text("\(balance.steepsEarned)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text(balance.steepsEarned == 1 ? "steep" : "steeps")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)

                        // Next reward progress
                        VStack(spacing: 8) {
                            if balance.available > 0 {
                                Label(
                                    balance.available == 1
                                        ? "1 free drink ready"
                                        : "\(balance.available) free drinks ready",
                                    systemImage: "gift.fill"
                                )
                                .font(.headline)
                                .foregroundStyle(.accent)
                            } else {
                                Text("\(balance.until) steep\(balance.until == 1 ? "" : "s") until your next free drink")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Actions
                        VStack(spacing: 12) {
                            PrimaryButton(
                                title: "Stamp my steep",
                                isLoading: loyalty.isStamping
                            ) {
                                showStampConfirmation = true
                            }

                            if balance.available > 0 {
                                Button("Redeem free drink") {
                                    showRedeemConfirmation = true
                                }
                                .font(.subheadline)
                                .foregroundStyle(.accent)
                            }
                        }

                    } else if loyalty.isLoading {
                        ProgressView()
                            .padding(.top, 64)

                    } else if let error = loyalty.error {
                        ContentUnavailableView {
                            Label("Couldn't load", systemImage: "wifi.slash")
                        } description: {
                            Text(error.localizedDescription)
                        } actions: {
                            Button("Try again") { Task { await loyalty.load() } }
                        }
                        .padding(.top, 32)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Steeps")
            .refreshable { await loyalty.load() }
            // Stamp confirmation
            .confirmationDialog("Stamp a steep?", isPresented: $showStampConfirmation, titleVisibility: .visible) {
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
            // Redeem confirmation
            .confirmationDialog("Redeem a free drink?", isPresented: $showRedeemConfirmation, titleVisibility: .visible) {
                Button("Redeem", role: .destructive) {
                    Task { await loyalty.redeem() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Show this to a barista when you order your free drink.")
            }
            // Celebration overlay
            .overlay {
                if showCelebration {
                    CelebrationOverlay {
                        showCelebration = false
                    }
                }
            }
        }
    }
}
