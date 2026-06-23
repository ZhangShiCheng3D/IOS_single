# CollageKit — 开发指南

拼图 / 海报排版工具。把多张照片排成精致拼图 / 九宫格 / 杂志风海报，模板化一键出图。

## 技术栈

- Swift 6 / SwiftUI，最低 iOS 17
- 架构：MVVM + SwiftUI
- 持久化：SwiftData（`@Model`）
- 图像合成：Core Graphics（`UIGraphicsImageRenderer`）
- 内购：StoreKit 2（买断式非消耗型）
- 纯本地运行，无后端

## 目录结构

```
CollageKit/
├── CollageKitApp.swift        # @main，配置 SwiftData 容器 + 全局 PurchaseManager
├── ContentView.swift          # 根视图 → HomeView
├── Models/                    # 数据层
│   ├── CollageEnums.swift     # AspectRatio / TemplateCategory / BackgroundKind / TextWeight
│   ├── CollageTemplate.swift  # 模板与插槽（单位坐标矩形）
│   ├── TemplateLibrary.swift  # 14 套内置模板
│   └── CollageProject.swift   # SwiftData 模型：Project / Photo / Text / UserPreset
├── ViewModels/
│   └── EditorViewModel.swift  # 照片导入/替换/交换、文字增删、导出合成
├── Views/                     # 界面层
│   ├── HomeView.swift         # 作品库
│   ├── TemplatePickerView.swift
│   ├── EditorView.swift       # 编辑器主界面
│   ├── CollageCanvasView.swift# 实时画布（点选/拖拽交换/拖动文字）
│   ├── MiniCollageView.swift  # 只读缩略图
│   ├── TemplateThumbnailView.swift
│   ├── ExportPreviewView.swift
│   ├── ShareSheet.swift
│   ├── SettingsView.swift
│   └── Panels/                # 编辑器工具面板
│       ├── LayoutPanel.swift
│       ├── BackgroundPanel.swift
│       ├── TextPanel.swift
│       └── SlotAdjustPanel.swift
├── Store/
│   ├── PurchaseManager.swift  # StoreKit 2 权益管理
│   └── PaywallView.swift      # 付费墙
├── Utils/
│   ├── Color+Hex.swift        # 颜色 <-> Hex（用于持久化）
│   ├── ImageUtils.swift       # 降采样 / JPEG 编码
│   ├── CollageLayout.swift    # 插槽几何（预览与导出共用）
│   ├── CollageRenderer.swift  # Core Graphics 合成引擎
│   └── PhotoSaver.swift       # 保存到相册
├── Resources/                 # zh-Hans / en 本地化
├── Assets.xcassets/           # AppIcon / AccentColor
├── Info.plist
└── CollageKit.storekit        # StoreKit 本地测试配置
```

## 核心设计

### 几何系统（WYSIWYG 关键）
模板插槽用 **单位坐标矩形（0~1）** 定义，与画布尺寸解耦。外观参数（边框 / 间距 / 圆角）以「参考画布长边 = 360 点」为基准设定，任意画布按 `CollageLayout.scale(forCanvas:)` 等比缩放。
**预览（`CollageCanvasView`）与导出（`CollageRenderer`）调用同一套 `CollageLayout.frame(...)`**，保证所见即所得。

### 渲染流程
`CollageRenderer.render` 顺序绘制：背景（纯色/渐变）→ 各插槽照片（aspect-fill 裁切 + 用户缩放/平移 + 圆角裁剪）→ 文字 → 水印（未购买时）。

### 内购解锁逻辑
单一产品 `com.collagekit.pro.lifetime`。`PurchaseManager.isPro` 以 `Transaction.currentEntitlements` 为权威，本地 `UserDefaults` 缓存即时反映 UI。
未解锁限制：付费模板加锁、9:16 比例加锁、导出带水印。

## 约定

- 颜色统一用 Hex 字符串持久化（SwiftData 不直接存 `Color`）。
- 照片存入 SwiftData 前用 `ImageUtils.downsampledJPEGData` 降采样到 1600px，避免体积膨胀。
- 简单属性编辑用 `@Bindable` 直接改模型；涉及图像解码/渲染的重逻辑走 `EditorViewModel`。
- 所有用户可见文案走 `Localizable.strings`（zh-Hans + en）。

## 待办（上架前需在 Xcode 内完成）

- 用 Xcode GUI 创建 `.xcodeproj` / project，把以上源文件加入 target。
- 提供 1024×1024 AppIcon 图片。
- 在 Scheme 中关联 `CollageKit.storekit` 以便本地测试内购。
- App Store Connect 创建对应内购产品 ID。
