# PixelStudio

> 轻量、好上手的像素画创作工具。专注像素艺术，纯本地运行，付费买断。

PixelStudio 让像素艺术爱好者、独立游戏美术和手账/贴纸创作者，在 iPhone / iPad 上
快速画出干净的像素图与逐帧动画，并一键导出 PNG / GIF。

## ✨ 功能

| 功能 | 说明 |
|------|------|
| 🎨 可调画布 | 8×8 到 256×256 共 6 档预设 |
| 🖌️ 绘制工具 | 画笔、橡皮、填充、直线、矩形、取色器，笔刷 1–4px |
| 🪞 镜像绘制 | 水平 / 垂直，可同时开启，实时参考线 |
| 🧩 图层系统 | 增删、显隐、不透明度、上下移动、清空、缩略图 |
| 🎛️ 调色板 | 内置 16 色经典板，可增删改、取色入板 |
| ▦ 网格开关 | 放大时显示像素网格 |
| 🎞️ 逐帧动画 | 时间轴、空白/复制帧、每帧时长、循环预览 |
| 🧅 洋葱皮 | 半透明显示上一帧，方便对位 |
| 📤 本地导出 | PNG（单帧）/ GIF（动画），1×–32× 放大，分享或存相册 |

## 🛠️ 技术栈

- **语言**：Swift 6 / SwiftUI
- **最低系统**：iOS 17
- **架构**：MVVM + SwiftUI
- **持久化**：SwiftData（@Model 级联关系，像素数据 externalStorage）
- **渲染**：Core Graphics（最近邻合成，预乘 RGBA → CGImage）
- **导出**：ImageIO（PNG / GIF 编码），Photos 框架存相册
- **内购**：StoreKit 2（非消耗型买断 + 权益校验 + 交易监听）
- **本地化**：中文（zh-Hans）+ 英文（en）
- **无后端、无网络、无追踪**，支持深色模式与 Dynamic Type

## 📂 目录结构

```
PixelStudio/
├─ PixelStudioApp.swift        App 入口（ModelContainer + PurchaseManager）
├─ ContentView.swift           根视图
├─ Models/                     SwiftData 模型 + 工具枚举 + 内存文档
├─ ViewModels/                 EditorViewModel（核心状态机）
├─ Views/                      画布、面板、各功能页面
├─ Store/                      StoreKit 2 购买管理 + 付费墙 + 权益定义
├─ Utils/                      PixelBuffer / 渲染 / 几何 / 导出 / 颜色
├─ Resources/                  Localizable.strings（en / zh-Hans）
├─ Assets.xcassets/            AppIcon / AccentColor
├─ Info.plist                  权限与配置
└─ PixelStudio.storekit        StoreKit 本地测试配置
```

## 🚀 在 Xcode 中运行

本仓库只含源代码，不含 `.xcodeproj`（需用 Xcode GUI 创建）：

1. Xcode → **File ▸ New ▸ Project ▸ iOS App**，名称 `PixelStudio`，Interface 选 SwiftUI，
   Storage 选 **SwiftData**，语言 Swift。
2. 删除模板生成的 `ContentView.swift` / `*App.swift`，把本目录所有文件拖入工程
   （勾选 *Copy items if needed*，保持 Group 结构）。
3. 在 Target ▸ **Info** 中确认 `NSPhotoLibraryAddUsageDescription` 已存在（或使用本仓库 Info.plist）。
4. Target ▸ **General** 设置最低部署版本为 **iOS 17**。
5. 调试内购：Scheme ▸ Edit Scheme ▸ Run ▸ Options ▸ **StoreKit Configuration** 选
   `PixelStudio.storekit`。

## ✅ 上架检查清单

- [x] **AppIcon** 1024×1024 已生成（`Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`，
      像素画风格、取自内置调色板；如需替换可重跑 `Tools/make_appicon.ps1`）
- [x] 隐私政策改为 **App 内可访问**（`PrivacyPolicyView`，设置页与付费墙均可进入），
      不再依赖外部占位 URL；条款指向 Apple 标准 EULA
- [x] `Info.plist` 已含 `LSApplicationCategoryType = public.app-category.graphics-design`
- [ ] App Store Connect 创建非消耗型内购，Product ID = `com.pixelstudio.pro.unlock`，
      价格档对应 ¥18–40
- [ ] 确认 `StoreConfig.proProductID` 与 Connect 中一致
- [ ] 真机测试买断购买、**恢复购买**、家长审批（Ask to Buy）流程
- [ ] 验证免费档限制（图层 ≤2、单帧、画布 ≤32）与付费墙触发
- [ ] 测试 PNG / GIF 导出、分享、保存到相册（首次授权弹窗）
- [ ] 深色模式、Dynamic Type（最大字号）逐屏检查
- [ ] 中英文切换文案完整、无截断
- [ ] 填写 App Privacy：**不收集任何数据**（无网络）
- [ ] 准备 6.7" / 6.5" / iPad 截图与预览
- [x] 出口合规：`ITSAppUsesNonExemptEncryption = NO`（已在 Info.plist）

## 💴 定价

一次性买断 **¥18–40**（建议档位 ¥28）。免费可体验核心绘制；Pro 解锁大画布、
无限图层、逐帧动画与 GIF 导出。

## 📄 许可

© 2026 PixelStudio. 保留所有权利。
