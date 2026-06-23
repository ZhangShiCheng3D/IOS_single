//
//  PurchaseManager.swift
//  HabitGrid
//
//  StoreKit 2 买断式内购管理。解锁“无限习惯 + 全部主题”。
//

import Foundation
import StoreKit
import Observation

/// 应用内产品标识。
enum ProductID {
    /// 一次性买断：解锁无限习惯与全部主题。
    static let pro = "com.habitgrid.pro.lifetime"

    static let all: [String] = [pro]
}

/// 免费版限制常量。
enum FreeTier {
    /// 免费版最多可创建的习惯数量。
    static let maxHabits = 3
}

/// 购买状态与逻辑的中心。使用 StoreKit 2 的 async API。
/// 全类 MainActor 隔离，所有 UI 状态读写都在主线程，满足 Swift 6 严格并发。
@Observable
@MainActor
final class PurchaseManager {

    /// 已加载的可购买产品。
    private(set) var products: [Product] = []

    /// 是否已解锁 Pro。
    private(set) var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: Keys.isPro) }
    }

    /// 购买流程进行中。
    private(set) var isPurchasing = false

    /// 最近一次错误信息（用于 UI 展示）。
    var lastErrorMessage: String?

    private enum Keys {
        static let isPro = "habitgrid.purchase.isPro"
    }

    /// 监听交易更新的后台任务。
    private var updatesTask: Task<Void, Never>?

    init() {
        // 先从本地缓存读取，保证离线/启动瞬间 UI 正确。
        self.isPro = UserDefaults.standard.bool(forKey: Keys.isPro)
        // 启动交易监听，处理 Ask to Buy、跨设备、退款等异步事件。
        updatesTask = listenForTransactions()
    }

    /// Pro 价格展示文案（本地化货币）。无法加载时返回 nil。
    var proDisplayPrice: String? {
        products.first(where: { $0.id == ProductID.pro })?.displayPrice
    }

    var proProduct: Product? {
        products.first(where: { $0.id == ProductID.pro })
    }

    // MARK: - 产品加载

    /// 从 App Store 加载产品信息。
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            lastErrorMessage = String(localized: "paywall.error.load")
        }
    }

    // MARK: - 购买

    /// 购买指定产品。
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        lastErrorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedState()
                return true

            case .userCancelled:
                return false

            case .pending:
                // 等待外部批准（如家长 Ask to Buy）。交易监听会在批准后处理。
                lastErrorMessage = String(localized: "paywall.error.pending")
                return false

            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = String(localized: "paywall.error.purchase")
            return false
        }
    }

    /// 恢复购买。
    func restore() async {
        isPurchasing = true
        lastErrorMessage = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updatePurchasedState()
        } catch {
            lastErrorMessage = String(localized: "paywall.error.restore")
        }
    }

    /// 刷新当前授权（启动时调用）。
    func refreshPurchasedProducts() async {
        await loadProducts()
        await updatePurchasedState()
    }

    // MARK: - 授权判定

    /// 遍历当前有效授权，更新 isPro。
    private func updatePurchasedState() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == ProductID.pro, transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isPro = unlocked
    }

    /// 持续监听交易更新流。
    private func listenForTransactions() -> Task<Void, Never> {
        // 普通 Task 继承 MainActor 隔离，避免在 detached 任务中捕获非 Sendable 的 self。
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.updatePurchasedState()
            }
        }
    }

    /// 校验交易签名。
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
