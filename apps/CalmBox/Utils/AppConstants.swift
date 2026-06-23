//
//  AppConstants.swift
//  CalmBox
//
//  全局常量：产品 ID、UserDefaults 键、设计参数。
//

import Foundation
import SwiftUI

enum AppConstants {

    /// StoreKit 2 内购产品 ID（非消耗型，解锁全部场景与声源）。
    static let unlockAllProductID = "com.calmbox.unlock.all"

    /// UserDefaults 键。
    enum DefaultsKey {
        static let hasUnlockedAll = "hasUnlockedAll"
        static let hapticsEnabled = "hapticsEnabled"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    /// 设计常量（统一转发到 Theme 设计令牌，避免双重来源）。
    enum Design {
        static let cornerRadius = Theme.Radius.large
        static let cardSpacing = Theme.Spacing.md
        static let contentPadding: CGFloat = 20
    }

    /// 隐私政策与支持链接。
    /// 上架前请将 privacyPolicy / support 替换为你自己的真实页面；
    /// terms 默认使用 Apple 标准 EULA（适用于未自带条款的 App）。
    enum Links {
        static let privacyPolicy = "https://calmbox.app/privacy"
        static let support = "https://calmbox.app/support"
        static let terms = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    }
}
