# FastFlow — 开发指南

间歇性断食 + 喝水追踪 + 健康节律 iOS App。SwiftUI / SwiftData / StoreKit 2 / HealthKit / Live Activity，纯本地、买断制。

## 技术栈与约束

- **语言**：Swift 6.0+ / SwiftUI，最低 **iOS 17**
- **架构**：MVVM + SwiftUI（`@Observable` ViewModel）
- **持久化**：SwiftData（`@Model`）+ UserDefaults（轻量偏好）+ App Group（Widget 共享）
- **无后端**：所有数据本地存储，HealthKit 为可选增强
- **付费**：StoreKit 2，单个非消耗型内购 `com.fastflow.premium.unlock`

## 目录结构

```
FastFlow/
├─ FastFlowApp.swift          App 入口，配置 SwiftData 容器
├─ ContentView.swift          根视图 + TabView，创建并持有 ViewModel
├─ Models/                    SwiftData @Model：FastingPlan / FastingSession / WaterEntry
├─ ViewModels/                FastingViewModel（计时核心）/ WaterViewModel
├─ Views/                     各功能页 + Components/（CircularProgressRing、StatChip）
├─ Store/                     PurchaseManager（StoreKit 2）+ PaywallView
├─ Utils/                     Extensions / Notification / HealthKit / LiveActivity 管理器
├─ Shared/                    主 App 与 Widget 共享：ActivityAttributes、SharedStore（App Group）
├─ Widgets/                   Widget Extension：主屏 Widget + Live Activity UI
├─ Resources/                 zh-Hans / en Localizable.strings
├─ Assets.xcassets/           AccentColor、AppIcon
└─ Configuration/             FastFlow.storekit（本地内购测试配置）
```

## 关键设计

- **计时核心**：`FastingViewModel` 持有进行中的 `FastingSession`，用 `Timer`（`.common` RunLoop 模式）每秒刷新 `now` 驱动 UI。重启 App 会从 SwiftData 恢复未结束会话。
- **真实时长**：进度基于 `startTime` 与当前时间计算，不依赖 Timer 累加，后台/息屏不丢失。
- **Live Activity / Widget 走时**：使用 `Text(timerInterval:)` 与 `ProgressView(timerInterval:)` 由系统自动走时，无需后台推送。
- **Widget 数据**：`FastingViewModel` 在开始/结束/调整时通过 `SharedStore` 写入 `FastingSnapshot` 到 App Group，Widget 时间线读取。
- **付费门控**：`PurchaseManager.isPremiumUnlocked` 控制自定义方案、30 天趋势、体重趋势、Widget 文案。状态由 `Transaction.currentEntitlements` 校验。

## Xcode 工程配置（创建 .xcodeproj 时手动设置）

> 本仓库不含 `.xcodeproj`，需在 Xcode 新建工程后将源文件加入对应 Target。

1. **主 App Target**（FastFlow）：
   - Signing & Capabilities 添加 **HealthKit**、**App Groups**（`group.com.fastflow.shared`）、**Live Activities**（Info.plist `NSSupportsLiveActivities=YES`，已配置）。
   - 关联 `FastFlow.entitlements`、`Info.plist`。
   - Build Phase 加入除 `Widgets/`、`FastFlowWidget*.entitlements` 外的全部源文件，以及 `Shared/`。
2. **Widget Extension Target**（FastFlowWidget）：
   - 新建 Widget Extension，`@main` 用 `Widgets/FastFlowWidgetBundle.swift`。
   - 加入 `Widgets/`、`Shared/`（ActivityAttributes + SharedStore）、`Utils/Extensions.swift`。
   - App Groups 启用同一 ID，关联 `FastFlowWidget.entitlements`。
3. **StoreKit 测试**：Scheme → Run → Options → StoreKit Configuration 选 `Configuration/FastFlow.storekit`。
4. **本地化**：Project → Info → Localizations 添加「英文」「简体中文」，确认两个 `Localizable.strings` 已加入主 App Target。

## 编码规范

- ViewModel 用 `@Observable @MainActor`，通过构造器注入 `ModelContext`。
- 所有主要 View 含 `#Preview`，Preview 使用 `isStoredInMemoryOnly: true` 的内存容器。
- 用户可见文本一律走 `Localizable.strings`（`LocalizedStringKey` 或 `NSLocalizedString`）。
- 颜色用 `AccentColor` 资源 + `Color` 扩展，支持深色模式。
- 错误处理：StoreKit / HealthKit 失败降级，不崩溃，必要时通过 `lastErrorMessage` 提示。
