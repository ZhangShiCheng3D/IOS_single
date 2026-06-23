//
//  PurchaseManager.swift
//  DocScanPro
//
//  StoreKit 2 购买管理。采用「免费扫描 + 内购解锁」的混合定价模型：
//    · 免费版：可扫描、导出 PDF（基础）。
//    · 专业版（一次性买断）：解锁 OCR 文字识别、批量扫描、无限文件夹/标签。
//
//  购买状态以 StoreKit 当前权益（current entitlements）为唯一真相来源，
//  并镜像到 UserDefaults 供离线快速读取。全程本地校验，无自建服务器。
//

import Foundation
import StoreKit

/// 应用内产品标识。需与 App Store Connect 中配置的 Product ID 一致。
enum ProductID {
    /// 专业版一次性买断（非消耗型）。
    static let pro = "com.docscanpro.pro.lifetime"

    static let all: Set<String> = [pro]
}

/// 解锁的高级功能。
enum PremiumFeature {
    case ocr            // OCR 文字识别
    case batchScan      // 批量扫描
    case unlimitedOrganization // 无限文件夹与标签
}

@MainActor
final class PurchaseManager: ObservableObject {

    static let shared = PurchaseManager()

    /// 可供购买的产品列表。
    @Published private(set) var products: [Product] = []

    /// 已购买的产品 ID 集合。
    @Published private(set) var purchasedProductIDs: Set<String> = []

    /// 是否正在加载产品 / 处理购买。
    @Published private(set) var isLoading: Bool = false

    /// 最近一次错误信息（供 UI 展示）。
    @Published var lastErrorMessage: String?

    /// 镜像到 UserDefaults 的 Pro 状态键，便于无 StoreKit 时快速读取。
    private let proCacheKey = "cached_isPro"

    private var updatesTask: Task<Void, Never>?

    private init() {
        // 启动时以缓存乐观地反映状态，随后由 start() 校验刷新。
        if UserDefaults.standard.bool(forKey: proCacheKey) {
            purchasedProductIDs.insert(ProductID.pro)
        }
    }

    // MARK: - 生命周期

    /// 在 App 启动时调用：监听交易更新并刷新当前权益。
    func start() async {
        updatesTask?.cancel()
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshPurchasedProducts()
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 产品加载

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let storeProducts = try await Product.products(for: ProductID.all)
            // 按价格排序，价格相同保持稳定。
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 购买

    /// 购买指定产品。
    /// - Returns: 购买是否成功解锁。
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateEntitlement(for: transaction.productID, revoked: transaction.revocationDate != nil)
                await transaction.finish()
                return purchasedProductIDs.contains(product.id)

            case .userCancelled:
                return false

            case .pending:
                // 例如家长批准（Ask to Buy），等待后续交易更新。
                lastErrorMessage = NSLocalizedString("store.purchase.pending", comment: "")
                return false

            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    /// 恢复购买（用户换机 / 重装后）。
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 权益查询

    /// 是否已解锁专业版。
    var isPro: Bool {
        purchasedProductIDs.contains(ProductID.pro)
    }

    /// 某项高级功能是否已解锁。
    func isUnlocked(_ feature: PremiumFeature) -> Bool {
        // 当前所有高级功能统一由 Pro 买断解锁。
        switch feature {
        case .ocr, .batchScan, .unlimitedOrganization:
            return isPro
        }
    }

    /// Pro 产品（用于付费墙展示价格）。
    var proProduct: Product? {
        products.first { $0.id == ProductID.pro }
    }

    // MARK: - Private

    /// 监听后台交易更新（含跨设备同步、家长批准、退款撤销）。
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                do {
                    let transaction = try await self.checkVerified(update)
                    await self.updateEntitlement(
                        for: transaction.productID,
                        revoked: transaction.revocationDate != nil
                    )
                    await transaction.finish()
                } catch {
                    await MainActor.run {
                        self.lastErrorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// 遍历当前所有有效权益，重建已购集合。
    private func refreshPurchasedProducts() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
        UserDefaults.standard.set(owned.contains(ProductID.pro), forKey: proCacheKey)
    }

    /// 更新单个产品权益并同步缓存。
    private func updateEntitlement(for productID: String, revoked: Bool) async {
        if revoked {
            purchasedProductIDs.remove(productID)
        } else {
            purchasedProductIDs.insert(productID)
        }
        UserDefaults.standard.set(purchasedProductIDs.contains(ProductID.pro), forKey: proCacheKey)
    }

    /// 校验交易签名（StoreKit 本地 JWS 验证）。
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}
