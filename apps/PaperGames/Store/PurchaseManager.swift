//
//  PurchaseManager.swift
//  PaperGames
//
//  StoreKit 2 内购管理。负责：加载商品、发起购买、监听交易更新、
//  校验交易、恢复购买，并对外暴露「是否已解锁完整版」状态。
//
//  商业模型：免费 + ¥18 一次性买断「解锁全部玩法」（非消耗型）。
//

import StoreKit
import SwiftUI
import Observation

@Observable
@MainActor
final class PurchaseManager {

    /// 商品标识符。需与 App Store Connect / Configuration.storekit 中一致。
    enum ProductID {
        static let unlockAll = "com.papergames.unlockall"
        static let all: [String] = [unlockAll]
    }

    /// 购买状态本地缓存键（用于离线快速读取，最终以交易校验为准）。
    private let unlockedKey = "purchase.unlockedAll"

    // MARK: - 公开状态

    /// 可供购买的商品。
    private(set) var products: [Product] = []
    /// 是否已解锁完整版。
    private(set) var isUnlocked: Bool
    /// 加载/购买进行中。
    private(set) var isLoading = false
    /// 最近一次错误信息（用于 UI 展示）。
    var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // 先读取本地缓存，保证离线/启动瞬间 UI 状态正确。
        self.isUnlocked = UserDefaults.standard.bool(forKey: unlockedKey)
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 生命周期

    /// 启动入口：监听交易更新、加载商品、刷新权益。
    func start() async {
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    /// 加载商品信息。
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let storeProducts = try await Product.products(for: ProductID.all)
            // 按价格排序，价格低的在前。
            self.products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = String(localized: "store.error.load")
        }
    }

    /// 完整版商品（便捷访问）。
    var unlockProduct: Product? {
        products.first { $0.id == ProductID.unlockAll }
    }

    // MARK: - 购买

    /// 发起购买。返回是否成功解锁。
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return isUnlocked
            case .userCancelled:
                return false
            case .pending:
                // 需家长批准等待中。
                errorMessage = String(localized: "store.error.pending")
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = String(localized: "store.error.purchase")
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
            if !isUnlocked {
                errorMessage = String(localized: "store.error.nothingToRestore")
            }
        } catch {
            errorMessage = String(localized: "store.error.restore")
        }
    }

    // MARK: - 权益刷新与校验

    /// 遍历当前有效交易，刷新解锁状态。
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == ProductID.unlockAll, transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setUnlocked(unlocked)
    }

    /// 持续监听交易更新（如他设备购买、退款等）。
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                guard let transaction = try? await self.checkVerifiedValue(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    /// 校验交易签名（主线程隔离版本）。
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// 非隔离上下文使用的校验（供后台监听任务调用）。
    private nonisolated func checkVerifiedValue<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func setUnlocked(_ value: Bool) {
        isUnlocked = value
        UserDefaults.standard.set(value, forKey: unlockedKey)
    }

    // MARK: - 权限判断

    /// 某游戏类型是否可玩。
    func canPlay(_ game: GameType) -> Bool {
        isUnlocked || !game.isPremiumGame
    }

    /// 某难度是否可玩。
    func canPlay(_ difficulty: Difficulty) -> Bool {
        isUnlocked || !difficulty.isPremium
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? {
            String(localized: "store.error.verification")
        }
    }
}
