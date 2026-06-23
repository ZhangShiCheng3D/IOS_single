# CLAUDE.md — ShotFrame 开发指南

给在本仓库工作的 AI / 开发者的上下文。先读这份，再动代码。

## 它是什么

ShotFrame 是一款 **iOS 17+ / Swift 6 / SwiftUI** 的截图美化工具：导入截图 → 加背景/外壳/阴影/文字 → 导出。**纯本地、无后端、无网络**。买断制内购（StoreKit 2）解锁专业版。

## 黄金法则：单一真相源 = `ShotCanvasView`

`Views/Canvas/ShotCanvasView.swift` 既驱动编辑器的**实时预览**，又被 `CanvasRenderer` 用 `ImageRenderer` 渲染成**导出图片**。

- 任何“截图长什么样”的改动都只改 `ShotCanvasView`，预览与导出会自动一致。
- 所有尺寸都用**相对比例**（相对画布短边 / 高度），所以同一份 `ShotSettings` 在缩略图、屏幕预览、4K 导出下表现一致。**不要写死像素值。**

## 数据模型

- `ShotSettings`（`Models/ShotSettings.swift`）是**编辑配方**，`Codable` 值类型，存进 `ShotProject`。改它就改了图。字段：`background` / `deviceFrame` / `aspect` / `padding` / `cornerRadius` / `shadowRadius` / `shadowOpacity` / `annotations`。
  - ⚠️ 目前**没有** rotation / 边框（border）字段。要加先在这里加，并同步 `ShotCanvasView` 的渲染。
- `RGBAColor`（`Models/ColorModels.swift`）是可持久化的颜色。SwiftUI `Color` 不是 `Codable`，所以颜色一律存 `RGBAColor`，用 `.color` 转 SwiftUI、`RGBAColor(_:)` 反向。
  - 全局**没有** `Color(hex:)`；`DeviceFrameView` 内有个 `private` 的。需要十六进制取色就用 `RGBAColor(hex:).color`。
- `ShotProject`（`@Model`）是 SwiftData 实体：`sourceImageData` / `backgroundImageData`（externalStorage）+ `settings`。
- `ShotTemplate` / `TemplateLibrary`：14 套手调模板，前 3 套免费，其余 `isPro`。**模板审美是核心壁垒**——调参要慎重、成套地调。

## 架构 / 约定

- **MVVM**：`EditorViewModel`（`@MainActor`，`ObservableObject`）持有单个项目的可变状态，`settings` 的 `didSet` 触发**防抖落库**（400ms `Task`）。View 直接 `$vm.settings.xxx` 绑定。
- Library 列表直接用 `@Query`，没单独 ViewModel——符合 SwiftData 惯例。
- `PurchaseManager` 用 `@EnvironmentObject` 全局注入（在 `ShotFrameApp` 建一次）。`isPro` 是所有付费门的唯一判断。
- 面板（`EditorPanels.swift`）通过 `requestPro` 闭包把“需要解锁”冒泡给 `EditorView` 去弹 `PaywallView`。

## 付费门规则

免费可用：3 套免费模板、None/iPhone 外壳、单张导出（带水印）。
专业版解锁：全部模板、iPad/MacBook/浏览器外壳（`DeviceFrameType.isPro`）、批量处理、去水印（`ShotCanvasView.showWatermark = !isPro`）。

加新付费功能时，记得：UI 上锁（`ProLockBadge`）+ 点击走 `requestPro()` + 真正的能力判断都要做，别只做其中一个。

## 渲染管线要点

- `CanvasRenderer` 是 `@MainActor`（`ImageRenderer` 必须在主线程）。`render(...)` 用 `scale = 1` + 显式 `proposedSize`，所以 `canvasSize` 即目标**像素**尺寸。
- 缩略图走 `render(..., longEdge: 420, ...)`，别用整档分辨率渲染再缩小。
- 模糊背景由 `ImageProcessing.blurred`（Core Image，带 `affineClamp` 防透明边）实时算。

## 并发（Swift 6）

- ViewModel / `PurchaseManager` / `CanvasRenderer` 都是 `@MainActor`。
- 防抖落库用 `Task`（在 `@MainActor` 上下文创建，自动继承隔离），**不要**用 `DispatchQueue.asyncAfter` 调用 `@MainActor` 方法。
- `PurchaseManager` 用 `Transaction.updates` 后台监听 Ask-to-Buy / 跨设备 / 退款。

## 本地化

所有面向用户的字符串走 `Localizable.strings`（`zh-Hans` + `en`），代码里用 `LocalizedStringKey`（SwiftUI）或 `NSLocalizedString`（VM/工具）。**新增文案两个语言都要加**，否则会显示成 key。带参数的 key 用 `%lld`（整数）/ `%@`（字符串）。

## 改动准则

- 精准改动：只动该动的，匹配现有风格，别顺手重构没坏的东西。
- 加功能优先复用 `ShotSettings` + `ShotCanvasView`，而不是另起渲染路径。
- 每个主要 View 保留 `#Preview`。
- 无 `.xcodeproj`（见 README 的工程搭建步骤）。
