import SwiftUI

struct PaywallView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "fuelpump.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)

                    Text("Subscriptions unavailable")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("You can browse forecourt locations. Verified pump prices and stock information are not currently available, so new subscriptions are paused.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Already subscribed? You can restore an existing purchase or manage your subscription in Settings.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)

                    Button("Restore Purchase") {
                        Task {
                            if await subscriptionManager.restore() {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(subscriptionManager.isLoading)

                    if subscriptionManager.isLoading {
                        ProgressView("Checking subscription…")
                    }

                    if let error = subscriptionManager.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
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
