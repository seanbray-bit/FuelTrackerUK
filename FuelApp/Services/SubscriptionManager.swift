import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isSubscribed = false
    // Premium data fail closed while StoreKit entitlements are being verified.
    @Published private(set) var isRevalidating = true
    var canRevealPremium: Bool { isSubscribed && !isRevalidating }
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Product ID — set this in App Store Connect
    static let productID = "uk.fuelapp.monthly"
    static let price = "99p/month"
    // Release gate: no verified forecourt price/stock provider is integrated.
    // Re-enable only after data, localized StoreKit pricing and claims are verified.
    static let newPurchasesAvailable = false

    private var updateTask: Task<Void, Never>?
    // Only the most recently started check may publish an entitlement result.
    private var latestEntitlementCheck = UUID()

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
        guard Self.newPurchasesAvailable else {
            errorMessage = "New subscriptions are unavailable while verified fuel prices are not available."
            return
        }
        guard !isLoading else { return }
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
                // Reconcile against verified current entitlements rather than
                // trusting a cached Bool or a single purchase callback.
                await checkSubscriptionStatus()
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

    // A successful sync and a verified entitlement are both required to
    // dismiss the restore screen. A failed sync must not revoke an existing
    // entitlement merely because the account prompt or network failed.
    @discardableResult
    func restore() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            guard !Task.isCancelled else {
                errorMessage = "Restore cancelled. You can try again."
                return false
            }
            if canRevealPremium { return true }
            errorMessage = isRevalidating
                ? "Subscription verification is still in progress. Try again shortly."
                : "No active subscription was found for this Apple Account."
        } catch StoreKitError.userCancelled {
            errorMessage = "Restore cancelled. You can try again."
            await checkSubscriptionStatus()
        } catch is CancellationError {
            errorMessage = "Restore cancelled. You can try again."
        } catch {
            errorMessage = "Unable to restore purchases. Check your connection and Apple Account, then try again."
            await checkSubscriptionStatus()
        }
        return false
    }

    // MARK: - Check status

    @discardableResult
    func beginEntitlementRevalidation() -> UUID {
        let checkID = UUID()
        latestEntitlementCheck = checkID
        // Called synchronously on foreground entry, BEFORE the async check.
        isRevalidating = true
        return checkID
    }

    func checkSubscriptionStatus() async {
        let checkID = beginEntitlementRevalidation()
        await completeEntitlementRevalidation(for: checkID)
    }

    func completeEntitlementRevalidation(for checkID: UUID) async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard !Task.isCancelled else { return }
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                hasEntitlement = true
                break
            }
        }
        // Async entitlement iteration can suspend; an older result must not
        // overwrite the outcome of a newer check.
        guard !Task.isCancelled, latestEntitlementCheck == checkID else { return }
        isSubscribed = hasEntitlement
        isRevalidating = false
    }

    // MARK: - Listen for updates

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            // Hide premium content as soon as StoreKit reports a change.
            let checkID = beginEntitlementRevalidation()
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
            }
            await completeEntitlementRevalidation(for: checkID)
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
