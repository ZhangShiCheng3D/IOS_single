//
//  PurchaseManager.swift
//  ShotFrame
//
//  StoreKit 2 buy-once unlock. ShotFrame ships a single non-consumable that
//  unlocks every Pro template and frame. Entitlement is the source of truth from
//  StoreKit; we also cache a boolean in UserDefaults for instant launch UI.
//

import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {

    /// The single non-consumable product identifier. Configure this exact ID in
    /// App Store Connect and in the bundled `Products.storekit` file.
    static let proProductID = "com.shotframe.pro.lifetime"

    private static let entitlementCacheKey = "shotframe.isPro"

    /// Loaded products keyed for easy access.
    @Published private(set) var proProduct: Product?
    /// Whether the user owns Pro. Drives every paywall gate in the app.
    @Published private(set) var isPro: Bool
    /// In-flight purchase indicator for the paywall button.
    @Published private(set) var isPurchasing = false
    /// User-facing error from the last store operation.
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Seed from cache so gated UI doesn't flicker on cold launch.
        self.isPro = UserDefaults.standard.bool(forKey: Self.entitlementCacheKey)
        // Listen for transactions arriving outside an explicit purchase
        // (Ask to Buy approvals, purchases on another device, refunds).
        updatesTask = listenForTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Loading

    /// Fetch product metadata and refresh entitlement. Call on launch / paywall.
    func load() async {
        await refreshEntitlement()
        do {
            let products = try await Product.products(for: [Self.proProductID])
            self.proProduct = products.first
        } catch {
            // A background metadata load failing (e.g. offline) is non-fatal:
            // the price has a fallback and an actual purchase tap surfaces its
            // own error. Don't set `lastError` here, or simply opening the
            // paywall after an offline launch would pop a spurious alert.
        }
    }

    /// Display price string, or a sensible fallback before products load.
    var displayPrice: String {
        proProduct?.displayPrice ?? "¥38"
    }

    // MARK: - Purchase

    /// Buy the Pro unlock. Returns true on a verified, finished purchase.
    @discardableResult
    func purchasePro() async -> Bool {
        guard let product = proProduct else {
            lastError = NSLocalizedString("error.store.unavailable", comment: "")
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await setPro(true)
                Haptics.success()
                return true
            case .userCancelled:
                return false
            case .pending:
                // e.g. Ask to Buy / SCA — entitlement will arrive via the
                // listener once approved. Tell the user so the dismissed sheet
                // doesn't read as a silent failure.
                lastError = NSLocalizedString("store.pending", comment: "")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            Haptics.warning()
            return false
        }
    }

    /// Restore purchases by syncing with the App Store.
    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if isPro { Haptics.success() }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Entitlement

    /// Walk current entitlements and update `isPro`.
    func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == Self.proProductID && transaction.revocationDate == nil {
                owned = true
            }
        }
        await setPro(owned)
    }

    private func setPro(_ value: Bool) async {
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.entitlementCacheKey)
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

    /// Continuously process transaction updates from outside the app.
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? await self.verify(result) {
                    await transaction.finish()
                    await self.refreshEntitlement()
                }
            }
        }
    }

    private nonisolated func verify<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? {
            NSLocalizedString("error.store.verification", comment: "")
        }
    }
}
