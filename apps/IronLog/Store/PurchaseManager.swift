//
//  PurchaseManager.swift
//  IronLog
//
//  StoreKit 2 买断式内购管理。
//  产品：一次性解锁 Pro（com.ironlog.pro.unlock）。
//  解锁状态以「当前权益(currentEntitlements)」为准，并缓存到 UserDefaults
//  以便离线快速判定。
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {

    /// 买断产品 ID。需与 App Store Connect / StoreKit 配置文件一致。
    static let proProductID = "com.ironlog.pro.unlock"

    /// 已加载的可售产品。
    @Published private(set) var products: [Product] = []
    /// 是否已解锁 Pro。
    @Published private(set) var isPro: Bool = false
    /// 加载/购买进行中。
    @Published private(set) var isLoading = false
    /// 最近一次错误信息（供 UI 展示）。
    @Published var errorMessage: String?

    private let entitlementKey = "ironlog.isPro"
    private var updatesTask: Task<Void, Never>?

    init() {
        // 先用缓存乐观显示，避免冷启动闪烁。
        isPro = UserDefaults.standard.bool(forKey: entitlementKey)
        // 监听交易更新（如其他设备购买、家庭共享）。
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 产品加载

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.proProductID])
        } catch {
            errorMessage = String(localized: "store.error.load")
        }
    }

    /// 便捷取 Pro 产品。
    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }

    /// 本地化价格字符串（含货币符号）。
    var displayPrice: String {
        proProduct?.displayPrice ?? "¥48"
    }

    // MARK: - 购买

    func purchasePro() async {
        guard let product = proProduct else {
            errorMessage = String(localized: "store.error.unavailable")
            return
        }
        await purchase(product)
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                errorMessage = String(localized: "store.error.pending")
            @unknown default:
                break
            }
        } catch {
            errorMessage = String(localized: "store.error.purchase")
        }
    }

    /// 恢复购买（App Store 会同步当前权益）。
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro {
                errorMessage = String(localized: "store.error.norestore")
            }
        } catch {
            errorMessage = String(localized: "store.error.restore")
        }
    }

    // MARK: - 权益核验

    /// 扫描当前权益，更新解锁状态。
    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == Self.proProductID, transaction.revocationDate == nil {
                owned = true
            }
        }
        setPro(owned)
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: entitlementKey)
    }

    /// 持续监听后台交易更新。
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    /// 校验交易签名，未通过则抛错。
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
