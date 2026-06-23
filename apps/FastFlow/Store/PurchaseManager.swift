//
//  PurchaseManager.swift
//  FastFlow
//
//  StoreKit 2 内购管理。产品：高级解锁（买断），解锁自定义方案 + 高级图表。
//

import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class PurchaseManager {
    /// 高级解锁产品 ID（需与 App Store Connect / StoreKit 配置一致）。
    static let premiumProductID = "com.fastflow.premium.unlock"

    /// 已加载的产品列表。
    private(set) var products: [Product] = []

    /// 是否已解锁高级功能。
    private(set) var isPremiumUnlocked: Bool = false

    /// 加载 / 购买过程中的状态。
    private(set) var isLoading = false

    /// 最近一次错误信息（供 UI 展示）。
    var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // 监听交易更新（如其他设备购买、家庭共享、退款）。本管理器随 App 全程存活，
        // 任务无需显式取消。
        updatesTask = listenForTransactions()
    }

    /// 高级解锁产品（便捷访问）。
    var premiumProduct: Product? {
        products.first { $0.id == Self.premiumProductID }
    }

    /// 展示价格，如 "¥30.00"。
    var premiumDisplayPrice: String {
        premiumProduct?.displayPrice ?? "¥30"
    }

    // MARK: - 产品加载

    /// 从 App Store 拉取产品信息。
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.premiumProductID])
        } catch {
            lastErrorMessage = NSLocalizedString("store.error.load", comment: "")
        }
    }

    // MARK: - 购买

    /// 购买高级解锁。返回是否成功。
    @discardableResult
    func purchasePremium() async -> Bool {
        guard let product = premiumProduct else {
            await loadProducts()
            guard premiumProduct != nil else {
                lastErrorMessage = NSLocalizedString("store.error.unavailable", comment: "")
                return false
            }
            return await purchasePremium()
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPremiumUnlocked = true
                Haptics.success()
                return true
            case .userCancelled:
                return false
            case .pending:
                lastErrorMessage = NSLocalizedString("store.info.pending", comment: "")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = NSLocalizedString("store.error.purchase", comment: "")
            return false
        }
    }

    /// 恢复购买。
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchasedState()
        } catch {
            lastErrorMessage = NSLocalizedString("store.error.restore", comment: "")
        }
    }

    // MARK: - 解锁状态

    /// 根据当前权益刷新解锁状态。
    func refreshPurchasedState() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isPremiumUnlocked = unlocked
    }

    // MARK: - 私有

    /// 监听交易更新流。
    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshPurchasedState()
                }
            }
        }
    }

    /// 校验交易签名，失败抛错。
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
