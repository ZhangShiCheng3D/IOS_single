# CLAUDE.md — CalmBox 开发指南

> 本文件供 Claude / 开发者快速理解项目结构与约定。

## 项目概览

CalmBox 是一款**付费买断制单机 iOS 解压应用**（解压玩具 + 白噪音盒 / ASMR）。
面向焦虑、需要放松的年轻人，主打睡前场景。核心是「触觉 + 音效」的细腻解压体验。

- **定价**：免费下载 + 一次性内购 ¥25 解锁全部场景与声源
- **最低系统**：iOS 17
- **语言**：Swift 6.0+ / SwiftUI
- **架构**：MVVM + SwiftUI
- **持久化**：SwiftData（iOS 17+）
- **后端**：无，纯本地运行

## 技术栈

| 领域 | 技术 |
|------|------|
| UI | SwiftUI |
| 状态 | `@Observable`（Observation 框架）+ `@Environment` 注入 |
| 音频 | AVFoundation（`AVAudioPlayer` 混音 + 后台播放） |
| 触觉 | Core Haptics（`CHHapticEngine`）+ UIFeedbackGenerator 降级 |
| 内购 | StoreKit 2（`Product` / `Transaction`） |
| 持久化 | SwiftData（`@Model`） |

## 目录结构

```
CalmBox/
├── CalmBoxApp.swift          # @main 入口，注入环境对象、配置 SwiftData
├── ContentView.swift         # 主页：场景网格 + 收藏 + 导航
├── Models/
│   ├── RelaxScene.swift      # 解压场景静态目录（struct）
│   ├── SoundSource.swift     # 白噪音声源静态目录（struct）
│   └── SwiftDataModels.swift # @Model：收藏、冥想记录、混音预设
├── ViewModels/
│   ├── BubbleWrapViewModel.swift
│   ├── SpinnerViewModel.swift     # 陀螺物理（角速度 + 摩擦衰减）
│   ├── BreathingViewModel.swift   # 4-7-8 呼吸状态机
│   └── MeditationViewModel.swift  # 计时器 + 会话持久化
├── Views/
│   ├── SceneCard.swift            # 主页卡片组件
│   ├── BubbleWrapView.swift
│   ├── SpinnerView.swift
│   ├── WhiteNoiseView.swift       # 混音器 + 预设
│   ├── BreathingView.swift
│   ├── MeditationTimerView.swift
│   └── SettingsView.swift
├── Store/
│   ├── PurchaseManager.swift      # StoreKit 2 管理器（@Observable @MainActor）
│   └── PaywallView.swift          # 付费墙
├── Utils/
│   ├── HapticManager.swift        # Core Haptics 引擎 + 预设震动
│   ├── AudioManager.swift         # 多声源混音引擎
│   ├── SoundEffectPlayer.swift    # 短音效播放器池
│   ├── Color+Hex.swift
│   └── AppConstants.swift         # 产品 ID、Keys、设计常量
├── Resources/
│   ├── zh-Hans.lproj/Localizable.strings
│   ├── en.lproj/Localizable.strings
│   └── Sounds/                    # 音频资源（见该目录 README）
├── Assets.xcassets/              # AppIcon + AccentColor
├── Info.plist                    # 后台音频模式、本地化、竖屏
└── CalmBox.storekit             # StoreKit 本地测试配置
```

## 关键约定

### 环境对象注入
三个全局管理器通过 `.environment()` 注入，子视图用 `@Environment(Type.self)` 读取：
- `PurchaseManager`、`AudioManager`、`HapticManager`

### 付费内容判断
统一用 `PurchaseManager.isAvailable(_:)` 判断场景/声源是否可用。
锁定内容点击时弹出 `PaywallView`，**不要**在多处硬编码解锁逻辑。

### 触觉
所有震动走 `HapticManager`，它在不支持 Core Haptics 的设备上自动降级。
新增震动模式时在 `HapticManager` 内补一个预设方法，不要在视图里直接建引擎。

### 音频
白噪音用 `AudioManager`（循环 + 混音 + 后台），短音效用 `SoundEffectPlayer`（播放器池，支持重叠）。
两者均用 `.mixWithOthers`，可同时出声。

## 待办（上架前）

- [ ] 导入真实音频资源（见 `Resources/Sounds/README.md`）
- [ ] 设计并导入 1024×1024 App 图标
- [ ] 在 App Store Connect 创建内购产品 `com.calmbox.unlock.all`
- [ ] 替换 `AppConstants.Links` 中的隐私政策 / 条款 / 支持真实链接
- [ ] 在 Xcode 创建 .xcodeproj，配置 Bundle ID、Team、Capabilities（Background Audio）

## 编码风格

- 注释用中文，命名用英文，遵循 Apple HIG。
- 每个主要 View 带 `#Preview`。
- 新增 SwiftData 模型记得在 `CalmBoxApp` 的 `Schema` 中注册。
