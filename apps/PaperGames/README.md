# PaperGames · 纸笔游戏

> 离线无限生成、零广告的纸笔逻辑游戏合集。专为通勤、睡前打发时间，讨厌广告的用户打造。

![平台](https://img.shields.io/badge/iOS-17%2B-blue) ![语言](https://img.shields.io/badge/Swift-6.0-orange) ![架构](https://img.shields.io/badge/SwiftUI-MVVM-green)

## ✨ 特性

| 功能 | 说明 |
|------|------|
| 🔢 **数独** | 9×9 经典，程序**离线无限生成**，每题保证**唯一解** |
| 🎚 **四档难度** | 简单 / 中等 / 困难 / 地狱（按线索数量区分） |
| ✏️ **笔记模式** | 铅笔标记候选数字，填入时可自动清理关联笔记 |
| ⚠️ **错误提示** | 可开关；填入与解冲突的数字标红 |
| ⏱ **计时与最佳记录** | 每难度独立保存最佳用时（SwiftData） |
| 🎯 **辅助高亮** | 高亮同行/列/宫及相同数字，可关闭 |
| 💡 **提示 / 撤销 / 暂停** | 完整的对局操作 |
| ⭕️ **井字棋** | 内置不败 AI（Minimax），经典纸笔游戏 |
| 🌙 **深色模式** | 跟随系统 / 浅色 / 深色 |
| 🔠 **大字号模式** | Dynamic Type，照顾中老年用户 |
| 🌐 **中英双语** | 简体中文 + English |
| 🚫 **无广告 · 纯离线** | 无后端、无网络、无追踪 |

## 💰 定价模型

**免费 + ¥18 一次性买断**（非订阅）

- **免费**：数独 简单 / 中等 难度
- **¥18 解锁完整版**：困难 + 地狱难度、井字棋等全部玩法、永久无广告
- 内购产品：`com.papergames.unlockall`（StoreKit 2，NonConsumable）
- 支持「恢复购买」，同一 Apple ID 多设备通用

## 🏗 技术栈

- **Swift 6.0+ / SwiftUI**，最低 **iOS 17**
- **MVVM** 架构 + Observation（`@Observable`）
- **SwiftData** 持久化游戏记录
- **StoreKit 2** 内购
- 纯本地数独生成算法（回溯生成 + 唯一解校验）

详见 [`CLAUDE.md`](./CLAUDE.md)。

## 🚀 快速开始

本仓库仅含源代码（无 `.xcodeproj`）。在 Xcode 中：

1. 新建 iOS App 工程（SwiftUI），删除模板的 App/ContentView 文件。
2. 将本目录所有 `.swift`、`Assets.xcassets`、`Resources/`、`Info.plist`、`Configuration.storekit` 加入 Target。
3. 部署目标设为 iOS 17.0，开启 **In-App Purchase** Capability。
4. Run Scheme 选择 `Configuration.storekit` 进行内购本地测试。

完整步骤见 [`CLAUDE.md` → 在 Xcode 中运行](./CLAUDE.md)。

## ✅ 上架检查清单（App Store）

### 元数据与资源
- [ ] App 名称、副标题、关键词、描述（中英）
- [x] 1024×1024 App Icon（已提供 `Assets.xcassets/AppIcon/AppIcon.png`，无 Alpha 通道；可按需替换为定制设计）
- [ ] 各机型截图（6.7" / 6.5" / 5.5" + iPad，如支持）
- [ ] 隐私政策 URL（设置页已留链接位）

### 内购配置
- [ ] App Store Connect 创建内购 `com.papergames.unlockall`，价格档对应 ¥18
- [ ] 内购本地化（中英）名称与描述
- [ ] 提交内购供审核（首次随版本一起）
- [ ] 真机验证「购买」「恢复购买」「待批准(Ask to Buy)」流程

### 合规
- [ ] App 隐私「数据收集」填报：本应用**不收集任何数据**
- [ ] 出口合规：`ITSAppUsesNonExemptEncryption = NO`（已在 Info.plist 设置）
- [ ] 年龄分级问卷（4+）
- [ ] 测试深色模式、大字号、动态字体下布局正常
- [ ] 测试无网络环境下生成谜题与游玩正常

### 质量
- [ ] 各难度数独均可生成且**有唯一解**（可用 `SudokuGenerator.countSolutions` 断言）
- [ ] 计时、最佳记录、统计持久化正确
- [ ] 付费墙在锁定难度/玩法处正确触发
- [ ] VoiceOver 主要控件可读（已加 accessibilityLabel）

## 📂 项目结构

```
PaperGames/
├── PaperGamesApp.swift / ContentView.swift
├── Models/        领域模型 + SwiftData
├── ViewModels/    对局逻辑（@Observable, @MainActor）
├── Views/         SwiftUI 界面
├── Utils/         数独算法 / 主题 / 触觉
├── Store/         StoreKit 2 + 付费墙
├── Assets.xcassets / Resources/ / Info.plist
└── Configuration.storekit
```

## 📄 许可

© 独立开发者作品。源代码用于该 App 的开发与上架。
