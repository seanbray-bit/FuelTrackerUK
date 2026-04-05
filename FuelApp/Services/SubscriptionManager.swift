import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Product ID — set this in App Store Connect
    static let productID = "uk.fuelapp.monthly"
    static let price = "99p/month"

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task {
            await listenForTransactions()
        }
        Task {
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updateTask?.cancel()
    }

    // MARK: - Purchase

    func purchase() async {
        isLoading = true
        errorMessage = nil

        do {
            let products = try await Product.products(for: [Self.productID])
            guard let product = products.first else {
                errorMessage = "Subscription not available. Try again later."
                isLoading = false
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isSubscribed = true
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isLoading = false
    }

    // MARK: - Restore

    func restore() async {
        isLoading = true
        try? await AppStore.sync()
        await checkSubscriptionStatus()
        isLoading = false
    }

    // MARK: - Check status

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
    }

    // MARK: - Listen for updates

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await checkSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let value):
            return value
        }
    }
}

enum SubscriptionError: Error {
    case verificationFailed
}
