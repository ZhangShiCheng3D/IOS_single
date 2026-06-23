# HabitGrid — 开发指南

> 极简习惯打卡（像素格子风）· GitHub 贡献图式的习惯热力图 · 纯本地 · SwiftUI

## 一句话定位
每天点一下格子，把坚持变成一张好看到想晒的热力图。付费买断制单机 iOS App。

---

## 技术栈与约束
- **语言**：Swift 6.0+ / SwiftUI
- **最低系统**：iOS 17
- **架构**：MVVM + SwiftUI
- **持久化**：SwiftData（`@Model`）
- **后端**：无。纯本地运行，可选 CloudKit 同步（默认关闭）
- **内购**：StoreKit 2（买断式 NonConsumable）
- **Widget**：WidgetKit，经 App Group 共享快照
- **通知**：UserNotifications 本地通知

---

## 目录结构
```
HabitGrid/
├── HabitGridApp.swift          # @main 入口，配置 SwiftData / 注入全局环境
├── ContentView.swift           # 根视图：习惯列表 + 今日进度
├── Models/
│   ├── Habit.swift             # @Model 习惯 + HabitFrequency 枚举
│   ├── HabitEntry.swift        # @Model 每日打卡记录（按天唯一）
│   └── Theme.swift             # ColorPalette 配色方案 + ThemeManager
├── ViewModels/
│   └── HabitViewModel.swift    # 打卡/CRUD/统计/提醒调度
├── Views/
│   ├── HeatmapView.swift       # ★ 核心：GitHub 风格热力图 + 图例
│   ├── HabitDetailView.swift   # 完整热力图 + 统计 + 导出分享
│   ├── HabitFormView.swift     # 新建/编辑习惯表单
│   ├── SettingsView.swift      # 外观/主题/通知/Pro/关于
│   ├── ThemePickerView.swift   # 配色方案选择（付费锁）
│   └── Components/
│       ├── StatCard.swift      # 统计卡片 + StreakBadge
│       └── HabitRowView.swift  # 列表行 + 行内迷你热力图
├── Store/
│   ├── PurchaseManager.swift   # StoreKit 2 购买/恢复/授权
│   └── PaywallView.swift       # 付费墙
├── Utils/
│   ├── Color+Hex.swift         # hex 互转 + heatLevels 同色系四级
│   ├── Date+Extensions.swift   # 日期归一化 + HeatmapCalendar 网格
│   ├── HabitStatistics.swift   # ★ 纯函数统计：streak/完成率/最长
│   ├── NotificationManager.swift
│   ├── WidgetDataBridge.swift  # App Group 共享快照
│   ├── ImageRenderer+Export.swift # 导出截图 + ShareSheet
│   ├── HapticFeedback.swift
│   ├── HabitAssets.swift       # 可选图标/颜色预设
│   └── PreviewData.swift       # #Preview 内存数据
├── HabitGridWidget/            # Widget Extension（独立 Target）
│   ├── HabitGridWidgetBundle.swift
│   └── HabitGridWidget.swift
├── Resources/
│   ├── en.lproj/Localizable.strings
│   └── zh-Hans.lproj/Localizable.strings
├── Assets.xcassets/            # AppIcon / AccentColor
├── Products.storekit          # StoreKit 本地测试配置
├── Info.plist
└── HabitGrid.entitlements      # App Group 能力
```

---

## 关键设计决策

### 1. 热力图数据流
- `HeatmapView` 不持有数据，只接收 `intensity: (Date) -> Int` 闭包与 `palette`，纯展示组件，可在列表行 / 详情 / 导出卡片复用。
- `HeatmapCalendar.buildGrid` 生成「列=周、行=星期」的二维日期网格，末列对齐当前周（与 GitHub 一致，每周从周日起）。

### 2. 打卡模型
- 每个习惯每天至多一条 `HabitEntry`，`day` 归一化到当天 00:00 作唯一日键。
- `intensity`（1...4）支持「多次完成 = 更深颜色」。

### 3. 统计计算
- 全部在 `HabitStatistics`（纯函数、无 SwiftData 依赖），便于单元测试。
- 当前连续：今天未打卡时从昨天起算，不惩罚「今天还没到」。

### 4. 配色与习惯色
- 7 套全局 `ColorPalette`（前 2 套免费）。
- 列表/详情里每个习惯用自身颜色，经 `Color.heatLevels(fromHex:)` 在 HSB 空间生成同色系四级深浅。

### 5. 付费墙逻辑（StoreKit 2）
- 产品：`com.habitgrid.pro.lifetime`（NonConsumable 买断）。
- 免费限制：最多 `FreeTier.maxHabits = 3` 个习惯；付费主题与导出锁定。
- `PurchaseManager` 监听 `Transaction.updates`，本地用 UserDefaults 缓存 `isPro` 保证离线/启动即时正确。

### 6. Widget 数据
- Widget **不**直接读 SwiftData。主 App 每次写入后经 `WidgetDataBridge.sync` 把 `HabitSnapshot` 写入 App Group，并 `reloadTimelines`。

---

## Xcode 工程装配（无 .xcodeproj，需 GUI 创建）
1. 新建 iOS App，命名 **HabitGrid**，最低 iOS 17，勾选 SwiftData。
2. 把本目录所有 `.swift` 与资源加入主 Target；`HabitGridWidget/` 单独建 Widget Extension Target。
3. 两个 Target 均开启 **App Groups** 能力，组 ID：`group.com.habitgrid.shared`。
4. 主 Target 开启 **In-App Purchase** 能力。
5. Widget Target 需共享这些源文件：`WidgetDataBridge.swift`、`Color+Hex.swift`、`Theme.swift`、`HabitStatistics.swift`、`Date+Extensions.swift`、`Habit.swift`、`HabitEntry.swift`（勾选 Target Membership）。
6. Scheme → Run → Options → StoreKit Configuration 选 `Products.storekit` 以便本地测试购买。
7. 准备 1024×1024 `AppIcon-1024.png` 放入 `Assets.xcassets/AppIcon.appiconset/`。

---

## 编码约定
- 所有面向用户文案走 `Localizable.strings`（中/英），新增文案两个文件同步。
- 主要 View 都带 `#Preview`，依赖 `PreviewData` 内存容器，不污染真机数据。
- 触感反馈统一走 `Haptics`，颜色统一走 `Color(hex:)` / `ColorPalette`。
- 业务写操作集中在 `HabitViewModel`，写库后调用 `WidgetDataBridge.sync`。
