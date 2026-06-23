//
//  PurchaseManager.swift
//  CleanAlbum
//
//  StoreKit 2 购买管理。买断制：一次性解锁批量清理。
//

import Foundation
import StoreKit
import Observation

/// 内购产品标识符。
enum ProductID {
    /// 解锁"批量清理"的非消耗型内购（¥25–40 区间，于 App Store Connect 配置价格）。
    static let proUnlock = "com.cleanalbum.pro.unlock"

    static let all: [String] = [proUnlock]
}

/// 全局购买状态管理器。
///
/// 免费功能：完整扫描、查看所有重复/相似/模糊照片。
/// 付费解锁：批量选择并一键删除。
@MainActor
@Observable
final class PurchaseManager {

    /// 可购买产品。
    private(set) var products: [Product] = []

    /// 是否已解锁 Pro（批量清理）。
    private(set) var isPro: Bool = false

    /// 加载/购买中状态。
    private(set) var isLoading: Bool = false

    /// 最近一次错误信息（用于 UI 展示）。
    var lastError: String?

    /// 本地缓存键（StoreKit 校验失败时的离线兜底）。
    private let unlockCacheKey = "cleanalbum.isPro"

    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    init() {
        // 启动时先读缓存，避免冷启动闪现"未解锁"。
        isPro = UserDefaults.standard.bool(forKey: unlockCacheKey)
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 生命周期

    /// 启动：监听交易更新 + 加载产品 + 校验权益。
    func start() async {
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    /// 加载产品信息。
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
        } catch {
            lastError = String(localized: "purchase.error.load")
        }
    }

    // MARK: - 购买

    /// 购买指定产品。
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await applyEntitlement(from: transaction)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                lastError = String(localized: "purchase.error.pending")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = String(localized: "purchase.error.failed")
            return false
        }
    }

    /// 恢复购买。
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = String(localized: "purchase.error.restore")
        }
    }

    // MARK: - 权益校验

    /// 遍历当前权益，更新解锁状态。
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == ProductID.proUnlock,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        // 以 StoreKit 当前权益为准：若曾退款 / 未购买则为 false。
        setPro(unlocked)
    }

    private func applyEntitlement(from transaction: Transaction) async {
        if transaction.productID == ProductID.proUnlock {
            setPro(true)
        }
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: unlockCacheKey)
    }

    // MARK: - 交易监听

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await self.applyEntitlement(from: transaction)
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - 校验

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

    /// 便捷：取 Pro 产品本地化价格字符串。
    var proPriceText: String {
        products.first(where: { $0.id == ProductID.proUnlock })?.displayPrice ?? "¥30"
    }
}
