//
//  PurchaseManager.swift
//  CollageKit
//
//  StoreKit 2 买断式内购管理。单一非消耗型产品「CollageKit Pro」，
//  解锁全部模板、去除水印、开放全部导出比例。购买状态本地落地到 UserDefaults，
//  并以 Transaction.currentEntitlements 为权威来源。
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {

    /// 产品 ID —— 需与 App Store Connect / StoreKit 配置文件保持一致。
    static let proProductID = "com.collagekit.pro.lifetime"

    @Published private(set) var proProduct: Product?
    @Published private(set) var isPro: Bool
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseError: String?

    private let entitlementKey = "ck_is_pro_unlocked"
    private var updatesTask: Task<Void, Never>?

    init() {
        // 先用本地缓存即时反映 UI，再用交易校验刷新
        self.isPro = UserDefaults.standard.bool(forKey: entitlementKey)
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 加载商品

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: [Self.proProductID])
            self.proProduct = products.first
        } catch {
            self.purchaseError = error.localizedDescription
        }
    }

    /// 展示价格文本，加载中给出占位。
    var proDisplayPrice: String {
        proProduct?.displayPrice ?? "¥18"
    }

    // MARK: - 购买

    func purchasePro() async {
        guard let product = proProduct else {
            purchaseError = String(localized: "purchase_product_unavailable")
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                if isPro { DesignSystem.Haptics.success() }
            case .userCancelled:
                break
            case .pending:
                // 交易待批准（如「家人共享 / 购买请求」）。告知用户稍后自动解锁。
                purchaseError = String(localized: "purchase_pending")
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// 恢复购买。
    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - 权益校验

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setPro(unlocked)
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: entitlementKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
