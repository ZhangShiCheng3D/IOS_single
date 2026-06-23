//
//  PurchaseManager.swift
//  OneWord
//
//  StoreKit 2 purchase manager. OneWord ships as a low-cost paid app with an
//  optional in-app purchase that unlocks the AI insight suite (trends, year
//  review, keyword extraction). Purchase state is cached in UserDefaults and
//  re-verified against StoreKit's current entitlements on launch.
//

import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class PurchaseManager {

    /// Product identifiers configured in App Store Connect / .storekit file.
    enum ProductID {
        /// Non-consumable that unlocks the full AI insight suite.
        static let aiInsights = "com.oneword.aiinsights.unlock"

        static let all: Set<String> = [aiInsights]
    }

    /// Loaded products, keyed by id.
    private(set) var products: [Product] = []

    /// Whether the AI insight suite is unlocked.
    private(set) var isPremiumUnlocked: Bool

    /// True while a purchase or restore is in flight (for spinner UI).
    var isProcessing = false

    /// Surfaced to the UI when a user-facing error occurs.
    var lastError: String?

    private var updatesTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard
    private let premiumKey = "purchase.premiumUnlocked"

    init() {
        // Optimistic local cache; corrected by `refreshEntitlements()` shortly.
        self.isPremiumUnlocked = defaults.bool(forKey: premiumKey)
        updatesTask = listenForTransactions()

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Product loading

    @MainActor
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            self.products = loaded.sorted { $0.price < $1.price }
        } catch {
            self.lastError = String(localized: "store.error.load")
        }
    }

    /// Convenience accessor for the single insight-unlock product.
    var insightsProduct: Product? {
        products.first { $0.id == ProductID.aiInsights }
    }

    // MARK: - Purchasing

    @MainActor
    func purchase(_ product: Product) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                Haptics.success()
            case .userCancelled:
                break
            case .pending:
                // Deferred / interrupted (e.g. Ask to Buy) — the entitlement will
                // arrive later via Transaction.updates; keep the user informed.
                Haptics.warning()
                lastError = String(localized: "store.error.pending")
            @unknown default:
                break
            }
        } catch {
            Haptics.error()
            lastError = String(localized: "store.error.purchase")
        }
    }

    /// Restores purchases by syncing with the App Store.
    @MainActor
    func restore() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = String(localized: "store.error.restore")
        }
    }

    // MARK: - Entitlements

    /// Re-derives `isPremiumUnlocked` from StoreKit's current entitlements.
    @MainActor
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == ProductID.aiInsights,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setPremium(unlocked)
    }

    private func setPremium(_ value: Bool) {
        isPremiumUnlocked = value
        defaults.set(value, forKey: premiumKey)
    }

    // MARK: - Transaction listening

    private func listenForTransactions() -> Task<Void, Never> {
        // Runs on the main actor (the manager is @MainActor); each iteration
        // suspends on `await`, so it never blocks the UI. Capturing `self`
        // weakly is safe here because the task inherits actor isolation.
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
