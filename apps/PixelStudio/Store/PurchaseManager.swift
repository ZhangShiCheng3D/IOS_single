//
//  PurchaseManager.swift
//  PixelStudio
//
//  StoreKit 2 买断式内购管理。单一非消耗型产品解锁全部 Pro 能力。
//  购买状态以当前权益（Transaction.currentEntitlements）为准，并缓存到
//  UserDefaults 以便离线快速读取。
//

import StoreKit
import SwiftUI

/// 产品配置。需与 App Store Connect / StoreKit 配置文件中的 Product ID 一致。
enum StoreConfig {
    /// 解锁全部功能的买断产品。
    static let proProductID = "com.pixelstudio.pro.unlock"
    static let allProductIDs: [String] = [proProductID]

    /// 离线缓存键。
    static let cacheKey = "pixelstudio.pro.unlocked"
}

@MainActor
final class PurchaseManager: ObservableObject {

    /// 是否已解锁 Pro。
    @Published private(set) var isProUnlocked: Bool
    /// 可售产品（用于付费墙展示价格）。
    @Published private(set) var products: [Product] = []
    /// 购买/恢复进行中。
    @Published var isProcessing = false
    /// 最近一次错误信息。
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // 先用缓存值给出乐观初值，避免冷启动闪烁。
        self.isProUnlocked = UserDefaults.standard.bool(forKey: StoreConfig.cacheKey)
        updatesTask = listenForTransactions()
    }

    /// 解锁 Pro 后的产品价格文案。
    var proProduct: Product? {
        products.first { $0.id == StoreConfig.proProductID }
    }

    var proPriceText: String {
        proProduct?.displayPrice ?? ""
    }

    // MARK: - 加载产品

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: StoreConfig.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        await refreshEntitlements()
    }

    // MARK: - 购买

    func purchasePro() async {
        guard let product = proProduct else {
            // 产品未加载时尝试即时拉取一次。
            await loadProducts()
            guard proProduct != nil else {
                lastErrorMessage = NSLocalizedString("store.error.noProduct", comment: "")
                return
            }
            await purchasePro()
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                setUnlocked(true)
            case .userCancelled:
                break
            case .pending:
                // 等待家长同意等异步审批，监听器会在批准后更新状态。
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - 恢复购买

    func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        await refreshEntitlements()
    }

    // MARK: - 权益校验

    /// 扫描当前权益，刷新解锁状态。
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == StoreConfig.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        setUnlocked(unlocked)
    }

    /// 监听交易更新（其它设备购买、家长审批通过、退款撤销等）。
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func setUnlocked(_ value: Bool) {
        // 仅在「未解锁 → 解锁」的跃迁时给一次成功反馈，避免重复触发。
        if value && !isProUnlocked {
            AppHaptics.success()
        }
        isProUnlocked = value
        UserDefaults.standard.set(value, forKey: StoreConfig.cacheKey)
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? {
            NSLocalizedString("store.error.verification", comment: "")
        }
    }
}
