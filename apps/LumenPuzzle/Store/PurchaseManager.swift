//
//  PurchaseManager.swift
//  LumenPuzzle
//
//  StoreKit 2 购买管理（买断解锁全部关卡）。
//
//  商业模式：本作为"买断制"。App 可免费下载并试玩前 3 关，
//  一次性内购（非消耗型）解锁全部 10 关与全部内容，永不再打扰。
//  这同时满足"零广告、零内购骚扰"的承诺：只有一个解锁项，购买后即终身有效。
//

import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {

    /// 唯一的非消耗型解锁项产品 ID。需与 App Store Connect / .storekit 配置一致。
    static let unlockProductID = "com.lumenpuzzle.unlock"

    /// 免费试玩的关卡数（其余需购买解锁）。
    static let freeLevelCount = 3

    /// 是否已购买解锁全部内容。
    @Published private(set) var isUnlocked: Bool = false
    /// 从商店加载到的产品（通常只有解锁项）。
    @Published private(set) var products: [Product] = []
    /// 加载/购买中。
    @Published private(set) var isProcessing: Bool = false
    /// 最近一次的用户可见错误信息（nil 表示无错误）。
    @Published var errorMessage: String?

    /// 后台监听交易更新的任务。
    private var transactionListener: Task<Void, Never>?

    init() {
        // 启动即监听交易更新（处理跨设备购买、家庭共享、退款等）。
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 产品加载

    /// 从 App Store 拉取产品信息。
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [Self.unlockProductID])
            products = storeProducts
        } catch {
            errorMessage = String(
                format: NSLocalizedString("store.error.load", comment: ""),
                error.localizedDescription
            )
        }
    }

    /// 解锁项产品（若已加载）。
    var unlockProduct: Product? {
        products.first { $0.id == Self.unlockProductID }
    }

    /// 解锁项的本地化价格文本（如 "¥28.00"）。
    var displayPrice: String? {
        unlockProduct?.displayPrice
    }

    // MARK: - 购买

    /// 发起购买。返回是否成功解锁。
    @discardableResult
    func purchase() async -> Bool {
        guard let product = unlockProduct else {
            await loadProducts()
            guard unlockProduct != nil else {
                errorMessage = NSLocalizedString("store.error.unavailable", comment: "")
                return false
            }
            return await purchase()
        }

        isProcessing = true
        defer { isProcessing = false }

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
                // 等待外部操作（如家长批准）。结果将由监听器处理。
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = String(
                format: NSLocalizedString("store.error.purchase", comment: ""),
                error.localizedDescription
            )
            return false
        }
    }

    /// 恢复购买（StoreKit 2 通过同步当前权益实现）。
    func restore() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await AppStore.sync()
        } catch {
            // sync 失败不一定代表没有权益，仍尝试刷新。
            errorMessage = String(
                format: NSLocalizedString("store.error.restore", comment: ""),
                error.localizedDescription
            )
        }
        await refreshEntitlements()
    }

    // MARK: - 权益校验

    /// 扫描当前权益，更新解锁状态。
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.unlockProductID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        isUnlocked = unlocked
    }

    /// 校验交易签名，确保来自 App Store。
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    /// 监听交易更新流。
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? await self.checkVerified(update) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    // MARK: - 业务查询

    /// 给定关卡是否可游玩（免费关或已解锁）。
    func canPlay(levelID: Int) -> Bool {
        isUnlocked || levelID <= Self.freeLevelCount
    }

    /// 给定关卡是否因未购买而锁定。
    func isLocked(levelID: Int) -> Bool {
        !canPlay(levelID: levelID)
    }
}
