# LumenPuzzle（流光）— 开发指南

极简 3D 光影解谜游戏。买断制、无广告、无内购骚扰。Monument Valley / The Room 式精品解谜。

## 技术栈

- **语言**：Swift 6.0+，SwiftUI
- **最低系统**：iOS 17
- **架构**：MVVM + SwiftUI
- **3D 渲染**：SceneKit
- **持久化**：SwiftData（`@Model`）
- **内购**：StoreKit 2（`Product` / `Transaction`）

## 目录结构

```
LumenPuzzle/
├── LumenPuzzleApp.swift        # @main 入口；配置 SwiftData 容器与 PurchaseManager
├── ContentView.swift           # 主菜单 + NavigationStack 路由
├── Models/                     # 数据模型
│   ├── Level.swift             #   关卡几何定义（值类型）：障碍/目标/光源/范围
│   ├── LevelCatalog.swift      #   10 个内置关卡设计（由易到难）
│   ├── LevelProgress.swift     #   @Model 关卡进度（通关/最佳成绩）
│   ├── Achievement.swift       #   成就枚举（值类型常量）
│   └── AchievementRecord.swift #   @Model 已解锁成就
├── ViewModels/
│   ├── GameViewModel.swift     #   单关游玩状态机：计时/步数/照亮判定/通关
│   └── ProgressService.swift   #   SwiftData 读写服务（进度 + 成就解锁逻辑）
├── Views/
│   ├── PuzzleSceneView.swift   #   SCNView 的 UIViewRepresentable + 手势
│   ├── GameView.swift          #   游玩界面：3D 场景 + HUD + 结算
│   ├── CompletionView.swift    #   通关结算面板
│   ├── LevelSelectView.swift   #   关卡选择网格（三态：可玩/进度锁/付费锁）
│   ├── AchievementsView.swift  #   成就墙
│   ├── PrivacyPolicyView.swift #   应用内隐私政策（无数据收集声明，合规可访问）
│   └── SettingsView.swift      #   设置（购买状态/恢复/法律/关于）
├── Store/
│   ├── PurchaseManager.swift   #   StoreKit 2 购买管理（ObservableObject）
│   └── PaywallView.swift       #   付费墙（含使用条款/隐私入口）
├── Utils/
│   ├── PuzzleSceneController.swift # SceneKit 场景构建 + 光线遮挡判定核心
│   ├── Color+Lumen.swift       #   配色（引用 Assets ColorSet）
│   ├── DesignSystem.swift      #   设计令牌：间距/动效/阴影修饰符
│   ├── Haptics.swift           #   触觉反馈封装
│   ├── SCNVector3+Math.swift   #   向量数学
│   └── String+Localized.swift  #   本地化键辅助
├── Assets.xcassets/            #   AppIcon / AccentColor / 主题色
├── Resources/
│   ├── zh-Hans.lproj/Localizable.strings
│   └── en.lproj/Localizable.strings
├── Info.plist
├── PrivacyInfo.xcprivacy       #   隐私清单：无追踪、无数据收集
└── LumenPuzzle.storekit        #   本地内购测试配置
```

## 核心玩法实现

**目标**：拖动光源照亮场景中全部目标即通关。

判定链路（`PuzzleSceneController.isTargetLit`）：

1. **距离衰减**：光源到目标距离 ≤ `LightTarget.maxLitDistance`，否则光太弱。
2. **遮挡判定**：`scene.rootNode.hitTestWithSegment(from:to:)`，仅对障碍物分类
   （`obstacleCategory`）做线段命中。命中任一障碍即被遮挡，目标不亮。

两条同时满足 → 目标点亮，金光绽放（`emission` 动画）。全部点亮 → 通关。

**手势**（`PuzzleSceneView.Coordinator`）：

- 单指拖动 → 移动光源。屏幕坐标经 `unprojectPoint` 反投影到光源所在水平面
  （`y = lightBounds.height`）的射线-平面交点。
- 双指拖动 → 环绕旋转视角（旋转相机 pivot 的 euler 角）。

## 商业模式与解锁

- 买断制：免费试玩前 `PurchaseManager.freeLevelCount`（= 3）关。
- 一次性非消耗内购 `com.lumenpuzzle.unlock` 解锁全部 10 关，永久有效。
- 解锁状态来源：`Transaction.currentEntitlements`（权威），而非本地标记。
- 关卡进度解锁：第 1 关恒解锁，其余需前一关通关（`ProgressService.isUnlocked`）。

## 约定

- 所有用户可见文案走 `Localizable.strings`，键名用点分命名空间。
- 颜色一律引用 `Color.lumen*`（对应 ColorSet，支持深色模式）。
- 触觉反馈统一走 `Haptics`。
- 主要 View 均带 `#Preview`，并注入 `inMemory` 的 ModelContainer。
- 新增关卡：在 `LevelCatalog` 追加 `Level`，并在两个 strings 文件补 `level.N.name` /
  `level.N.hint`；`LevelCatalog.all` 会自动纳入。

## 在 Xcode 中装配（无 .xcodeproj）

本仓库只含源码与资源，需在 Xcode 手动建工程：

1. 新建 iOS App 工程，Interface = SwiftUI，Language = Swift，勾选 SwiftData 不必要（手动管理）。
2. 删除模板生成的 `ContentView.swift` / `App.swift`，将本目录全部 `.swift`、
   `Assets.xcassets`、`Resources/*.lproj`、`Info.plist` 拖入，勾选 Target。
3. Build Settings：iOS Deployment Target = 17.0；Swift Language Version = 6。
4. 在 Signing & Capabilities 配置开发者账号。
5. 调试内购：Scheme → Run → Options → StoreKit Configuration 选 `LumenPuzzle.storekit`。
6. App Store Connect 创建非消耗内购，Product ID = `com.lumenpuzzle.unlock`。
