import SwiftUI

struct PaywallView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "fuelpump.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)

                // Title
                VStack(spacing: 8) {
                    Text("Find the Cheapest Fuel")
                        .font(.title.bold())

                    Text("Save money on every fill-up")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "1.circle.fill", text: "See ALL stations ranked cheapest first")
                    FeatureRow(icon: "clock.fill", text: "Real-time price updates throughout the day")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Stock availability so you don't waste a trip")
                    FeatureRow(icon: "map.fill", text: "Map view with directions to cheapest station")
                    FeatureRow(icon: "bell.fill", text: "Price drop alerts (coming soon)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                Spacer()

                // Price
                VStack(spacing: 4) {
                    Text("Just \(SubscriptionManager.price)")
                        .font(.title2.bold())
                    Text("Less than a litre of fuel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Subscribe button
                Button {
                    Task {
                        await subscriptionManager.purchase()
                        if subscriptionManager.isSubscribed {
                            dismiss()
                        }
                    }
                } label: {
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Subscribe for \(SubscriptionManager.price)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(subscriptionManager.isLoading)

                // Restore
                Button("Restore Purchase") {
                    Task {
                        await subscriptionManager.restore()
                        if subscriptionManager.isSubscribed {
                            dismiss()
                        }
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)

                if let error = subscriptionManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // Legal
                Text("Auto-renewing subscription. Cancel anytime in Settings.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not Now") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15))
        }
    }
}
