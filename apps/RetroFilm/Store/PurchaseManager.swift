//
//  PurchaseManager.swift
//  RetroFilm
//
//  StoreKit 2 purchase manager for the buy-once "All Film Packs" unlock.
//  Pricing model: free app, single non-consumable IAP (¥30–68) that unlocks
//  every premium film stock. Entitlement is derived live from StoreKit's
//  current entitlements (the source of truth) and mirrored to UserDefaults so
//  the UI can render instantly at launch before StoreKit finishes loading.
//

import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {

    /// The single non-consumable product. Must match the App Store Connect ID
    /// and the bundled `Products.storekit` configuration used for local testing.
    static let allPacksProductID = "com.retrofilm.allfilmpacks"

    @Published private(set) var products: [Product] = []
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var purchaseState: PurchaseState = .idle

    enum PurchaseState: Equatable {
        case idle, loading, purchasing, pending, success, failed(String)
    }

    private let unlockDefaultsKey = "com.retrofilm.unlocked"
    private var updatesTask: Task<Void, Never>?

    init() {
        // Optimistic read so premium UI doesn't flicker locked at cold start.
        self.isUnlocked = UserDefaults.standard.bool(forKey: unlockDefaultsKey)
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Product loading

    func loadProducts() async {
        purchaseState = .loading
        do {
            products = try await Product.products(for: [Self.allPacksProductID])
            purchaseState = .idle
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    /// Localized price string for the unlock, e.g. "¥45.00".
    var formattedPrice: String {
        products.first?.displayPrice ?? "¥45"
    }

    var allPacksProduct: Product? { products.first }

    // MARK: - Purchase

    func purchase() async {
        guard let product = allPacksProduct else {
            // Try a reload in case products weren't ready yet.
            await loadProducts()
            guard allPacksProduct != nil else {
                purchaseState = .failed(NSLocalizedString("paywall.error.noProduct", comment: ""))
                return
            }
            return await purchase()
        }

        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await setUnlocked(true)
                purchaseState = .success
                HapticManager.success()
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                // e.g. Ask to Buy / SCA — entitlement arrives later via the
                // transaction listener, which will flip `isUnlocked` on approval.
                purchaseState = .pending
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            HapticManager.warning()
        }
    }

    /// Restores prior purchases (App Store guideline requirement).
    func restore() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = isUnlocked ? .success : .idle
            if isUnlocked { HapticManager.success() }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Entitlements

    /// Re-derives `isUnlocked` from StoreKit's verified current entitlements.
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == Self.allPacksProductID && transaction.revocationDate == nil {
                unlocked = true
            }
        }
        await setUnlocked(unlocked)
    }

    /// Background listener that catches purchases/refunds made outside the app
    /// (Ask to Buy approvals, family sharing, refunds).
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? await self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private func setUnlocked(_ value: Bool) async {
        isUnlocked = value
        UserDefaults.standard.set(value, forKey: unlockDefaultsKey)
    }

    // MARK: - Verification

    enum StoreError: Error { case failedVerification }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }

    // MARK: - Convenience

    /// Whether a given stock is available to the user right now.
    func isAvailable(_ stock: FilmStock) -> Bool {
        !stock.isPremium || isUnlocked
    }
}
