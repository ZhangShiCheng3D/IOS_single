# PixelStudio — 开发指南

像素画创作 App（付费买断 + Pro 内购）。SwiftUI + SwiftData，纯本地、无后端。

## 架构总览

```
PixelStudioApp           @main，配置 SwiftData ModelContainer + 全局 PurchaseManager
└─ ContentView           根视图 → GalleryView
   ├─ GalleryView        作品库（@Query 列表、网格、新建/复制/删除/重命名）
   │  └─ NewProjectSheet 命名 + 选尺寸（>32 需 Pro）
   └─ EditorView         编辑器主界面，持有 EditorViewModel
      ├─ PixelCanvasView    UIViewRepresentable 自绘画布 + 触摸 → 笔触
      ├─ FrameTimelinePanel 时间轴 / 洋葱皮 / 动画预览
      ├─ ColorPalettePanel  调色板编辑
      ├─ ToolbarPanel       工具 / 笔刷 / 镜像 / 网格 / 撤销重做
      ├─ LayerPanel         图层增删改、可见性、不透明度、顺序
      └─ ExportSheet        PNG / GIF 导出 + 分享 + 存相册
```

## 数据流（关键）

- **持久层**：`PixelProject` → `PixelFrame` → `PixelLayer`（SwiftData @Model，级联删除）。
  图层像素以 RGBA8 原始字节存于 `PixelLayer.pixelData`（`.externalStorage`）。
- **编辑层**：`EditorViewModel` 启动时把模型解码为内存值类型 `WorkingFrame/WorkingLayer`
  （含 `PixelBuffer`）。所有高频绘制都在内存进行，1.2s 防抖后 `save()` 写回 SwiftData。
- **撤销/重做**：利用值类型 + 写时复制（COW），快照只是保留数组引用，
  真正改像素时才发生一次拷贝，因此快照极廉价。每次破坏性操作前 `pushUndo()`。

## 渲染管线

`PixelBuffer`（底层绘制原语：点/线/矩形/泛洪/镜像）
→ `PixelRenderer.compositePremultiplied`（自下而上 source-over 混合 + 图层不透明度）
→ `cgImage`（预乘 RGBA）
→ `PixelCanvasView` 以 `interpolationQuality = .none` 绘制，保持像素硬边缘。
`CanvasGeometry` 负责屏幕坐标 ↔ 像素坐标换算（等比居中、整像素对齐）。

## 付费模型

- 单一非消耗型产品 `com.pixelstudio.pro.unlock`（见 `StoreConfig`）。
- 免费档限制集中在 `FreeLimits`：最多 2 图层、单帧、画布 ≤32。
- 触发点统一通过 `EditorViewModel.pendingPaywallFeature`（`ProFeature`）弹 `PaywallView`。
- `PurchaseManager`（StoreKit 2）：`currentEntitlements` 校验 + `Transaction.updates` 监听 +
  UserDefaults 缓存。修改产品 ID 时记得同步 `PixelStudio.storekit`。

## 约定

- 所有用户可见文案走 `Localizable.strings`（en / zh-Hans），不要硬编码中文/英文。
- 颜色统一用 `PixelColor`（RGBA8）做运算，`hexString` 持久化，`.color` 转 SwiftUI。
- 新增工具：在 `DrawingTool` 加 case + 在 `EditorViewModel` 的笔触分支实现即可。
- 主要 View 均带 `#Preview`，使用 `PreviewData`（内存容器，不落盘）。

## 待办 / 扩展点

- AppIcon 已补：`Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`（像素画风格，
  由 `Tools/make_appicon.ps1` 生成，可重跑替换）。
- 隐私政策已改为 App 内 `PrivacyPolicyView`（纯本地、零数据采集），无外部 URL 依赖。
- 设计令牌与触觉反馈集中在 `Utils/DesignSystem.swift`（`AppMetrics` / `AppHaptics`）。
- 可扩展：导出 spritesheet、自定义画布长宽比、调色板导入/导出（.hex / .pal）。
