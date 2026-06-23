# IronLog — 开发指南

> 力量训练记录 App。极速录组 · 自动算容量与 PR · 离线可用。
> 面向认真撸铁的硬核用户。买断制（¥48），纯本地、无后端、无订阅。

## 技术栈与约束

- **语言**：Swift 6.0+ / SwiftUI
- **最低系统**：iOS 17（依赖 SwiftData、Swift Charts、`@Observable`/StoreKit 2）
- **架构**：MVVM + SwiftUI
- **持久化**：SwiftData（`@Model`），本地存储，无 iCloud（可后续扩展）
- **付费**：StoreKit 2 买断（非续期内购 `com.ironlog.pro.unlock`）
- **集成**：HealthKit（写入力量训练 + 读体重，均可选）、本地通知（休息提醒 + PR 祝贺）
- **可访问性**：全程支持 Dynamic Type、深色模式（ColorAsset）

## 目录结构

```
IronLog/
├─ IronLogApp.swift          # @main 入口，装配 ModelContainer + 环境对象 + 首启 seed
├─ ContentView.swift         # TabView 根 + 全局休息计时浮层
├─ Models/                   # SwiftData @Model
│  ├─ Exercise.swift         # 动作 + MuscleGroup/Equipment 枚举
│  ├─ WorkoutSession.swift   # 一次训练（含容量/分组计算）
│  ├─ SetEntry.swift         # 单组（重量×次数+RPE，含 1RM/容量计算）
│  ├─ PersonalRecord.swift   # PR 记录 + PRType
│  ├─ WorkoutTemplate.swift  # 模板 + TemplateExercise
│  └─ SeedData.swift         # 100+ 内置动作 + 7 套内置模板，幂等写入
├─ ViewModels/
│  ├─ AppSettings.swift      # 单位/休息/Health 偏好（AppStorage）+ 免费版限制常量
│  ├─ ActiveWorkoutViewModel.swift  # 进行中训练状态机（核心录入逻辑）
│  └─ RestTimerViewModel.swift      # 组间休息计时（后台安全，基于绝对结束时间）
├─ Views/                    # 各页面与组件，均带 #Preview
├─ Store/
│  ├─ PurchaseManager.swift  # StoreKit 2：加载/购买/恢复/权益核验
│  └─ PaywallView.swift      # 付费墙
├─ Utils/                    # 纯函数与基础设施
│  ├─ StatsCalculator.swift  # 容量/1RM/趋势聚合（无副作用，可测）
│  ├─ PRTracker.swift        # 完成组 → 评估并刷新 PR
│  ├─ HealthKitManager.swift # HealthKit 读写封装
│  ├─ NotificationManager.swift
│  ├─ UnitPreference.swift   # kg/lb 换算（DB 统一存 kg）
│  ├─ Formatters.swift / Extensions.swift / PreviewData.swift
├─ Resources/                # zh-Hans + en Localizable.strings
├─ Assets.xcassets/          # AccentColor + 4 个肌群配色 + AppIcon 占位
├─ Info.plist                # HealthKit 用途说明、方向、本地化
└─ IronLog.storekit          # 本地 StoreKit 测试配置
```

## 核心设计原则

1. **录入速度是命门**。`SetEntry` 字段最少；加组默认复制上一组（`duplicateSet`）；
   加动作时自动用历史最近一组预填重量/次数（`lastSet`）。任何改动都不得增加完成一组的点击数。
2. **重量统一以 kg 存储**，仅在显示层经 `WeightUnit` 换算。新增涉及重量的 UI 必须走 `weightBinding` 模式。
3. **PR 与容量只计「已完成的正式组」**（`isCompleted && !isWarmup`）。新统计沿用此口径。
4. **休息计时基于绝对 `endTime`**，后台返回后用 `refreshFromBackground()` 重算，切勿改成「每秒自减」。
5. **Pro 门控**集中在 `PurchaseManager.isPro`；免费版限 `AppSettings.freeWorkoutLimit`（5 次完成训练）。
   趋势图、导出为 Pro 功能，用 `ProLockedRow` 统一引导。

## 关键约定

- 所有用户可见文案走 `Localizable.strings`（zh-Hans + en），不要硬编码中文/英文字面量。
- 新增 `@Model` 须同时登记到 `IronLogApp` 与 `PreviewData` 的 `Schema`。
- 内置动作/模板用稳定字符串 ID（`ex.*`），`SeedData` 据此幂等去重——升级新增内容只追加，勿改旧 ID。
- 每个主要 View 保留 `#Preview`，预览统一用 `PreviewData.container`（内存库）。

## 在 Xcode 中启用

1. 新建 iOS App 工程（SwiftUI 生命周期，最低 iOS 17），把本目录所有源文件加入 target。
2. Signing & Capabilities：添加 **HealthKit**；勾选 Background Modes 非必需。
3. Build Settings 引入 `Info.plist`（含 Health 用途字符串）。
4. 在 Scheme → Run → Options 里指定 `IronLog.storekit` 以便本地测试内购。
5. App Store Connect 创建非消耗型内购，Product ID 与 `PurchaseManager.proProductID` 一致。
