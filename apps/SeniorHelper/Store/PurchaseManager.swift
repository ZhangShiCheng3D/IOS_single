//
//  PurchaseManager.swift
//  SeniorHelper
//
//  StoreKit 2 买断制内购管理。
//  单一非消耗型产品：解锁全部高级功能（用药提醒、紧急联系人等）。
//

import Foundation
import StoreKit
import Observation

/// 买断制内购管理器。
///
/// 采用「免费试用放大镜 + 买断解锁完整功能」的策略：
/// 放大镜永久免费（吸引下载），用药提醒与紧急联系人为付费功能。
@Observable
@MainActor
final class PurchaseManager {

    /// 解锁完整版的非消耗型产品 ID（需与 App Store Connect 一致）。
    static let unlockProductID = "com.seniorhelper.unlock.lifetime"

    /// 已加载的可售产品。
    private(set) var products: [Product] = []

    /// 是否已解锁完整版。
    private(set) var isUnlocked = false

    /// 是否正在进行购买/恢复，用于禁用按钮、显示进度。
    private(set) var isProcessing = false

    /// 最近一次错误的可读描述，供 UI 提示。
    var errorMessage: String?

    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    init() {
        // 监听交易更新（如家庭共享、退款、跨设备同步）。
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedState()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// 解锁产品对象（如已加载）。
    var unlockProduct: Product? {
        products.first { $0.id == Self.unlockProductID }
    }

    /// 本地化价格文案，如「¥30.00」。
    var displayPrice: String {
        unlockProduct?.displayPrice ?? "¥30"
    }

    // MARK: - 加载产品

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [Self.unlockProductID])
            products = storeProducts
        } catch {
            errorMessage = String(localized: "无法加载商品信息，请检查网络后重试")
            print("加载产品失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 购买

    /// 购买解锁产品。返回是否成功。
    @discardableResult
    func purchase() async -> Bool {
        guard let product = unlockProduct else {
            errorMessage = String(localized: "商品暂不可用，请稍后再试")
            return false
        }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedState()
                return isUnlocked
            case .userCancelled:
                return false
            case .pending:
                errorMessage = String(localized: "购买正在等待批准（如家长同意）")
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = String(localized: "购买失败，请稍后重试")
            print("购买失败: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 恢复购买

    /// 恢复历史购买。换机或重装后使用。
    @discardableResult
    func restore() async -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
            await updatePurchasedState()
            if !isUnlocked {
                errorMessage = String(localized: "未找到可恢复的购买记录")
            }
            return isUnlocked
        } catch {
            errorMessage = String(localized: "恢复购买失败，请稍后重试")
            print("恢复购买失败: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 校验与状态

    /// 遍历当前权益，更新解锁状态。
    func updatePurchasedState() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.unlockProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlocked = unlocked
    }

    /// 监听交易更新流。
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchasedState()
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

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? {
            String(localized: "交易校验失败")
        }
    }
}
