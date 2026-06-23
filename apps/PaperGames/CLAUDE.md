# PaperGames — 开发指南

> 一款离线、无广告的纸笔逻辑游戏合集。当前内置 **数独**（核心玩法）与 **井字棋**（不败 AI）。
> 付费买断制：免费体验，¥18 解锁全部难度与全部玩法。

## 技术栈与约束

- **语言**：Swift 6.0+ / SwiftUI（声明式 UI）
- **最低系统**：iOS 17（依赖 Observation 框架与 SwiftData）
- **架构**：MVVM + SwiftUI
- **状态管理**：`@Observable`（Observation 框架），通过 `@Environment` 注入全局对象
- **持久化**：
  - 游戏记录/成绩 → **SwiftData**（`GameRecord` `@Model`）
  - 轻量偏好设置 → **UserDefaults**（`SettingsStore`）
  - 购买状态 → StoreKit 交易为准 + UserDefaults 缓存
- **内购**：StoreKit 2（`Product` / `Transaction` / `currentEntitlements`）
- **无后端、无网络依赖、纯本地运行**

## 目录结构

```
PaperGames/
├── PaperGamesApp.swift        # @main 入口，配置 ModelContainer 与环境对象
├── ContentView.swift          # 根 TabView：游戏 / 统计 / 设置
├── Models/
│   ├── GameType.swift         # GameType 与 Difficulty 枚举（含免费/付费标记）
│   ├── GameRecord.swift       # SwiftData @Model：完成记录
│   └── SudokuPuzzle.swift     # 数独谜题纯数据结构
├── ViewModels/
│   ├── SettingsStore.swift    # 全局设置（@Observable + UserDefaults）
│   ├── SudokuViewModel.swift  # 数独对局逻辑（选择/笔记/错误/计时/撤销/提示）
│   └── TicTacToeViewModel.swift # 井字棋 + Minimax AI
├── Views/
│   ├── HomeView.swift               # 游戏选择主页
│   ├── DifficultySelectionView.swift# 数独难度选择
│   ├── SudokuGameView.swift         # 数独主界面
│   ├── SudokuBoardView.swift        # 9x9 盘面渲染
│   ├── SudokuCellView.swift         # 单元格
│   ├── NumberPadView.swift          # 数字键盘
│   ├── SudokuCompletionView.swift   # 完成结算
│   ├── TicTacToeView.swift          # 井字棋界面
│   ├── SettingsView.swift           # 设置
│   └── StatsView.swift              # 统计
├── Utils/
│   ├── SudokuGenerator.swift  # ★ 数独生成/求解算法（唯一解保证）
│   ├── Theme.swift            # 颜色扩展与设计常量
│   └── Haptics.swift          # 触觉反馈封装
├── Store/
│   ├── PurchaseManager.swift  # StoreKit 2 购买管理
│   └── PaywallView.swift      # 付费墙
├── Assets.xcassets/           # 颜色集（深色模式自适配）+ AppIcon
├── Resources/
│   ├── zh-Hans.lproj/Localizable.strings
│   └── en.lproj/Localizable.strings
├── Configuration.storekit     # 本地内购测试配置
└── Info.plist
```

## 核心算法：数独生成（`SudokuGenerator`）

1. **`generateSolved`**：随机化回溯填出一个完整合法盘面。
2. **`dig`**：在完整盘面上按随机顺序挖空，每挖一格用 `countSolutions(limit: 2)` 校验
   仍为**唯一解**；若破坏唯一性则还原。逼近难度对应的线索数（`Difficulty.clueCount`）。
3. **`countSolutions`**：采用「最少候选优先」的回溯，统计解数（封顶 2，命中即返回），用于唯一性判定。
4. 生成结果同时返回 `givens`（谜题）与 `solution`（唯一解），可断言 *solution 是 givens 的唯一解*。

难度线索数：简单 42 / 中等 34 / 困难 28 / 地狱 24（均 ≥17，满足唯一解最小线索约束）。

> ⚠️ 生成在后台线程执行（`Task.detached`），避免地狱难度挖空时阻塞主线程。

## 商业模型与解锁逻辑

- 产品：`com.papergames.unlockall`（NonConsumable，¥18）。
- 免费内容：数独「简单 / 中等」难度。
- 付费解锁：数独「困难 / 地狱」+ 井字棋等全部玩法 + 无广告。
- 判断入口：`PurchaseManager.canPlay(_ game:)` / `canPlay(_ difficulty:)`。
- 解锁状态由 `Transaction.currentEntitlements` 校验，UserDefaults 仅作离线缓存。

## 在 Xcode 中运行（首次接入）

> 本仓库**只包含源代码**，不含 `.xcodeproj`（需用 Xcode GUI 创建）。

1. Xcode → File → New → Project → iOS App（Interface: SwiftUI，Language: Swift，Storage: 无）。
2. 删除模板生成的 `ContentView.swift` / `App.swift`，将本目录所有源文件拖入工程（勾选 Copy if needed，Target 勾选）。
3. 将 `Assets.xcassets` 替换/合并进工程；`Resources/*.lproj` 加入并在 Project → Info → Localizations 添加「英文 / 简体中文」。
4. Target → General：最低部署版本设为 **iOS 17.0**。
5. Target → Signing & Capabilities：勾选 **In-App Purchase**。
6. Scheme → Edit Scheme → Run → Options → StoreKit Configuration 选择 `Configuration.storekit`（本地测试内购）。
7. App Store Connect 中创建同名内购产品 `com.papergames.unlockall`。

## 编码约定

- 所有面向用户的文案使用 `Localizable.strings` 键（中英双语）。
- 颜色一律走 `Color("AppXxx")` 资源，禁止硬编码以保证深色模式。
- ViewModel 标注 `@MainActor`，UI 状态变更在主线程。
- 每个主要 View 提供 `#Preview`。
- 新增玩法：在 `GameType` 增加 case → 实现 ViewModel + View → 在 `HomeView.destination(for:)` 路由。
