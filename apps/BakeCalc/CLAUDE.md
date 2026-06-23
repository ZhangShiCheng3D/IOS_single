# CLAUDE.md — BakeCalc 开发指南

> 本文件供 Claude Code 在本项目中工作时参考。BakeCalc 是「垂直专业计算器」矩阵的第一款，
> 架构刻意做成**可复用模板**：换数据表 + 换功能枚举即可派生下一款（如卤味/咖啡/调酒计算器）。

## 一句话定位

不做通用计算器，做**烘焙专用换算器**。买断制（¥18），无订阅、无广告、纯本地。

## 技术栈

- Swift 6 / SwiftUI，最低 iOS 17
- 架构：MVVM + SwiftUI
- 持久化：SwiftData（仅「我的配方」用到）
- 内购：StoreKit 2（非消耗型买断）
- 本地化：中文（zh-Hans）+ 英文（en）

## 目录结构

```
BakeCalc/
├── BakeCalcApp.swift          # @main 入口，配置 ModelContainer + 注入 PurchaseManager
├── ContentView.swift          # 主仪表盘（功能卡片网格 + 路由）
├── Models/                    # SwiftData @Model
│   ├── SavedRecipe.swift
│   └── SavedIngredient.swift
├── ViewModels/                # ObservableObject，纯计算逻辑
│   ├── UnitConversionViewModel.swift
│   ├── TemperatureViewModel.swift
│   ├── RecipeScalingViewModel.swift
│   ├── PanConversionViewModel.swift
│   └── EggConversionViewModel.swift
├── Views/                     # 各功能页面 + Components/
├── Utils/                     # 换算引擎 + 静态数据表 + 主题
│   ├── MeasurementUnits.swift # 重量/体积单位 + UnitConverter
│   ├── TemperatureConverter.swift
│   ├── BakingData.swift       # ★ 所有参考数据：密度/烤箱/模具/鸡蛋
│   ├── Formatting.swift
│   └── Theme.swift            # 颜色 + 卡片样式
├── Store/                     # StoreKit 2
│   ├── StoreConfig.swift      # 产品 ID + AppFeature 免费/付费划分
│   ├── PurchaseManager.swift
│   └── PaywallView.swift
├── Resources/                 # Localizable.strings (zh-Hans + en)
├── Assets.xcassets/           # 颜色集（BCAccent/BCSecondary/BCCard/BCBackground）+ AppIcon
├── Info.plist
└── BakeCalc.storekit          # 本地内购测试配置
```

## 核心约定

1. **换算逻辑全部在 Utils + ViewModel，View 不做计算。** 便于单元测试与跨产品复用。
2. **所有面向用户的文案走 Localizable.strings**，键名用点分命名（如 `feature.eggConversion`）。
   新增文案必须同时更新 zh-Hans 和 en 两份。
3. **静态参考数据集中在 `BakingData.swift`**。派生新产品时主要改这里。
4. **免费/付费分流由 `AppFeature.requiresPro` 单点控制**，页面用 `.proGate(_:titleKey:)` 修饰符即可。
   免费：单位换算、温度换算、烤箱参考。付费：配方缩放、密度表、配方保存、模具换算、鸡蛋换算。
5. **密度统一用 g/mL**，体积单位统一用美制（cup = 236.59 mL）。
6. **配方原料以「克」持久化**，份数缩放时无损按比例计算。

## 内购说明

- 产品 ID：`com.indie.bakecalc.pro`（非消耗型）
- 解锁状态：`Transaction.currentEntitlements` 为准，UserDefaults 仅作离线缓存兜底
- 本地调试：在 Scheme → Run → Options → StoreKit Configuration 选择 `BakeCalc.storekit`
- `PurchaseManager.debugSetPro(_:)` 仅在 DEBUG 下可用，便于预览付费态

## 派生下一款产品的步骤

1. 复制整个目录，重命名 target / bundle id / 产品 id
2. 改 `BakingData.swift` 为新领域的数据表
3. 改 `AppFeature` 枚举与 `ContentView` 的功能卡片清单
4. 替换 `Localizable.strings` 文案与 `Assets` 颜色
5. 其余（换算引擎骨架、StoreKit、ProGate、主题、组件）原样复用

## 待办 / 已知限制

- AppIcon 仅占位，需在 Xcode 中补 1024×1024 图片
- 模具换算假设深度一致（仅按底面积比例）
- 隐私政策/条款链接为占位 URL，上架前需替换为真实页面
