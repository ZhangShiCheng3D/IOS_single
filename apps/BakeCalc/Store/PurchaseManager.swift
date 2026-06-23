//
//  PurchaseManager.swift
//  BakeCalc
//
//  StoreKit 2 购买管理器。负责加载产品、发起购买、监听交易更新、
//  恢复购买，并维护「是否已解锁专业版」的全局状态。
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {

    /// 已从 App Store 加载的产品列表。
    @Published private(set) var products: [Product] = []
    /// 是否已解锁专业版。
    @Published private(set) var isPro: Bool = false
    /// 是否正在加载产品 / 处理购买。
    @Published private(set) var isLoading: Bool = false
    /// 最近一次错误信息（供 UI 展示）。
    @Published var lastError: String?

    /// 交易监听任务。
    private var updatesTask: Task<Void, Never>?

    init() {
        // 启动即读取离线缓存的解锁状态，避免冷启动闪烁。
        isPro = UserDefaults.standard.bool(forKey: StoreConfig.unlockedDefaultsKey)
        // 监听交易更新（含其他设备 / 退款 / 家庭共享）。
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchasedState()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// 专业版产品（若已加载）。
    var proProduct: Product? {
        products.first { $0.id == StoreConfig.proProductID }
    }

    /// 专业版显示价格，如 "¥18.00"。
    var proPriceText: String {
        proProduct?.displayPrice ?? "—"
    }

    // MARK: - 加载产品

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let storeProducts = try await Product.products(for: StoreConfig.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            lastError = String(
                format: NSLocalizedString("store.error.load", comment: ""),
                error.localizedDescription
            )
        }
    }

    // MARK: - 购买

    /// 购买指定产品。返回是否成功解锁。
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
                await refreshPurchasedState()
                return isPro
            case .userCancelled:
                return false
            case .pending:
                lastError = NSLocalizedString("store.pending", comment: "")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = String(
                format: NSLocalizedString("store.error.purchase", comment: ""),
                error.localizedDescription
            )
            return false
        }
    }

    /// 便捷方法：购买专业版。
    @discardableResult
    func purchasePro() async -> Bool {
        guard let product = proProduct else {
            await loadProducts()
            guard let product = proProduct else {
                lastError = NSLocalizedString("store.error.no_product", comment: "")
                return false
            }
            return await purchase(product)
        }
        return await purchase(product)
    }

    // MARK: - 恢复购买

    /// 主动与 App Store 同步并恢复购买。
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchasedState()
            if !isPro {
                lastError = NSLocalizedString("store.restore.none", comment: "")
            }
        } catch {
            lastError = String(
                format: NSLocalizedString("store.error.restore", comment: ""),
                error.localizedDescription
            )
        }
    }

    // MARK: - 交易状态

    /// 遍历当前有效权益，刷新解锁状态。
    func refreshPurchasedState() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == StoreConfig.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setPro(unlocked)
    }

    /// 监听后台交易更新。
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshPurchasedState()
            }
        }
    }

    // MARK: - 工具

    /// 校验 StoreKit 签名结果。
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    /// 更新解锁状态并写入离线缓存。
    private func setPro(_ value: Bool) {
        if isPro != value { isPro = value }
        UserDefaults.standard.set(value, forKey: StoreConfig.unlockedDefaultsKey)
    }

    /// 判断某功能当前是否可用。
    func isUnlocked(_ feature: AppFeature) -> Bool {
        feature.requiresPro ? isPro : true
    }

    #if DEBUG
    /// 仅供预览 / 调试使用：强制设置解锁状态。
    func debugSetPro(_ value: Bool) { setPro(value) }
    #endif
}
