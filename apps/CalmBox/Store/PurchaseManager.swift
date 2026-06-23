//
//  PurchaseManager.swift
//  CalmBox
//
//  StoreKit 2 内购管理器。负责加载商品、发起购买、监听交易更新、
//  恢复购买，并以 UserDefaults 缓存解锁状态供 UI 快速读取。
//

import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class PurchaseManager {

    /// 购买流程状态。
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case pending        // 等待外部批准（如「家长批准」/ Ask to Buy）
        case success
        case failed(String)
    }

    /// 已加载的可购买商品。
    private(set) var products: [Product] = []

    /// 是否已解锁全部内容。
    private(set) var hasUnlockedAll: Bool {
        didSet {
            UserDefaults.standard.set(hasUnlockedAll, forKey: AppConstants.DefaultsKey.hasUnlockedAll)
        }
    }

    /// 当前购买状态，驱动 PaywallView 的 UI。
    private(set) var state: PurchaseState = .idle

    /// 商品是否加载完成。
    private(set) var isLoaded = false

    private var updatesTask: Task<Void, Never>?

    init() {
        // 启动时先读取缓存，保证离线也能维持解锁状态。
        self.hasUnlockedAll = UserDefaults.standard.bool(forKey: AppConstants.DefaultsKey.hasUnlockedAll)
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - 生命周期

    /// 启动监听并加载商品、校验当前权益。
    func start() async {
        updatesTask = listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    /// 加载商品信息。
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [AppConstants.unlockAllProductID])
            self.products = storeProducts
            self.isLoaded = true
        } catch {
            self.state = .failed(error.localizedDescription)
            self.isLoaded = true
        }
    }

    /// 解锁商品（取第一个，即一次性买断）。
    var unlockProduct: Product? {
        products.first { $0.id == AppConstants.unlockAllProductID }
    }

    // MARK: - 购买

    /// 发起购买。
    func purchase() async {
        guard let product = unlockProduct else {
            state = .failed(String(localized: "paywall.error.noProduct"))
            return
        }
        await purchase(product)
    }

    func purchase(_ product: Product) async {
        state = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                hasUnlockedAll = true
                state = .success
            case .userCancelled:
                state = .idle
            case .pending:
                // 等待家长批准（Ask to Buy）等场景：明确告知用户交易待处理，
                // 实际解锁会由 Transaction.updates 监听到批准后自动完成。
                state = .pending
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// 恢复购买（重新校验权益）。
    func restore() async {
        state = .purchasing
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            state = hasUnlockedAll ? .success : .failed(String(localized: "paywall.error.nothingToRestore"))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// 重置状态到 idle（关闭弹窗等场景）。
    func resetState() {
        state = .idle
    }

    // MARK: - 权益校验

    /// 校验当前所有有效交易，更新解锁状态。
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == AppConstants.unlockAllProductID && transaction.revocationDate == nil {
                unlocked = true
            }
        }
        hasUnlockedAll = unlocked
    }

    // MARK: - 交易监听

    /// 监听后台交易更新（其他设备购买、家长批准等）。
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    // MARK: - 校验

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - 内容访问辅助

extension PurchaseManager {

    /// 判断某个场景是否可用（免费或已解锁）。
    func isAvailable(_ scene: RelaxScene) -> Bool {
        !scene.isPremium || hasUnlockedAll
    }

    /// 判断某个声源是否可用。
    func isAvailable(_ source: SoundSource) -> Bool {
        !source.isPremium || hasUnlockedAll
    }
}
