# ShotFrame

把随手截图一键变成社交 / 作品集级别的美图。为截图加上漂亮的背景、设备外壳、边框、阴影与文字标注，一键导出到相册或分享。

> 工具效率 · 纯本地运行 · 免费试用 + ¥38 买断解锁全部功能

---

## ✨ 功能

| 功能 | 说明 |
|---|---|
| 导入截图 | 系统照片选择器（PHPicker，免相册读权限），支持即时截屏 |
| 多种背景 | 纯色 / 渐变 / 模糊（截图自身模糊）/ 自定义图片 |
| 设备外壳 | iPhone / iPad / MacBook / 浏览器窗口（纯代码绘制，任意分辨率不糊） |
| 调整 | 留白、圆角、阴影强度、画面比例（自动 / 1:1 / 4:5 / 9:16 / 16:9） |
| 文字标注 | 多条文字叠加，画布上拖动定位，字号 / 颜色 / 加粗 / 阴影可调 |
| 模板系统 | 14 套手工调校模板（3 免费 + 11 专业版） |
| 导出 | 标准 / 高清两档，保存到相册或系统分享 |
| 批量处理 | 一次选多张截图套用同一模板批量导出（专业版） |

## 🧱 技术栈

- **Swift 6 / SwiftUI**，最低 **iOS 17**
- **MVVM**：View ↔ `EditorViewModel` ↔ SwiftData 模型
- **SwiftData** 持久化已保存的项目（`ShotProject`）
- **Core Image** 负责像素级模糊背景（`ImageProcessing`）
- **SwiftUI `ImageRenderer`**（Core Graphics 支撑）负责最终合成
- **StoreKit 2** 本地非续期买断内购
- 深色模式（`AccentColor` 含暗色变体）、Dynamic Type、中英双语本地化

## 🏗 架构概览

合成的**唯一真相源**是 `ShotCanvasView`：编辑器实时预览与导出共用同一个视图，因此**所见即所得**——预览长什么样，导出就是什么像素。

```
ShotFrameApp ──► ContentView ──► LibraryView ──► EditorView
                                       │              │
                                       │              ├─ ShotCanvasView (预览)
                                       │              └─ Template/Background/Frame/Adjust/Text 面板
                                       │
                       ┌───────────────┴───────────────┐
                  ShotProject (SwiftData)        PurchaseManager (StoreKit2)
                       │
                  ShotSettings (Codable 编辑配方)
                       ├─ BackgroundConfig + RGBAColor
                       ├─ DeviceFrameType / CanvasAspect
                       └─ [Annotation]

ShotCanvasView ──► CanvasRenderer (ImageRenderer) ──► UIImage ──► Photos / ShareLink
```

| 目录 | 内容 |
|---|---|
| `Models/` | `ShotProject`(@Model)、`ShotSettings`、`ShotTemplate`、`ColorModels` |
| `ViewModels/` | `EditorViewModel`（单个项目的可变编辑状态） |
| `Views/` | `LibraryView`、`EditorView`、`ExportView`、`BatchView`、`SettingsView` 及画布/面板 |
| `Store/` | `PurchaseManager`、`PaywallView` |
| `Utils/` | `CanvasRenderer`、`ImageProcessing`、`PhotoLibrary`、`Extensions` |
| `Resources/` | `zh-Hans` / `en` 本地化 |

## 🛠 在 Xcode 中创建工程

本仓库只包含源代码，不含 `.xcodeproj`（需用 Xcode GUI 创建）：

1. Xcode → File → New → Project → **App**，名称 `ShotFrame`，Interface **SwiftUI**，Language **Swift**，Storage **None**（我们自己接 SwiftData）。
2. 删除模板生成的 `ContentView.swift` / `App.swift`，把本目录所有 `.swift`、`Assets.xcassets`、`Resources/`、`Products.storekit` 拖入工程（勾选 *Copy if needed* 与 target）。
3. Target → General → 最低部署版本设为 **iOS 17.0**。
4. Build Settings → **Swift Language Version = Swift 6**。
5. Info：使用本仓库 `Info.plist`（或把其中的 `NSPhotoLibraryAddUsageDescription` 等键合并进生成的 Info）。
6. 本地化：Project → Info → Localizations 添加 **Chinese (Simplified)** 与 **English**；确认 `Localizable.strings` / `InfoPlist.strings` 被勾选进 target。
7. StoreKit 测试：Edit Scheme → Run → Options → **StoreKit Configuration** 选 `Products.storekit`。

## 💳 内购配置

- 产品类型：**非消耗型（Non-Consumable）**
- Product ID：`com.shotframe.pro.lifetime`（见 `PurchaseManager.proProductID`）
- 在 App Store Connect 中创建同名产品，价格档位约 ¥38。
- 解锁后：全部模板、全部设备外壳、批量处理、去除水印。
- 购买状态来自 StoreKit `currentEntitlements`，并缓存到 `UserDefaults` 以避免冷启动闪烁。

## ✅ 上架检查清单

- [x] `AppIcon` 1024×1024 已提供（`AppIcon-1024.png`，单尺寸通用图标，Xcode 自动派生其余尺寸）
- [x] `LSApplicationCategoryType` 已设为 `public.app-category.photography`
- [x] 法务链接集中到 `AppLinks`：条款 → Apple 标准 EULA；隐私/支持见下方待办
- [ ] **隐私政策页**：`AppLinks.privacy` 现指向 `https://shotframe.app/privacy`，送审前需真实托管该页面
- [ ] **支持邮箱**：`AppLinks.support` 现为 `support@shotframe.app`，替换为真实收件箱
- [ ] 截图 / 预览图（可用本 App 自己做 😄）
- [ ] App Store Connect 创建内购产品 `com.shotframe.pro.lifetime` 并送审
- [ ] 隐私清单：本 App 仅**写入**相册（add-only），不读取、无网络、无追踪
- [ ] 真机验证：导入 → 套模板 → 拖动文字 → 导出/分享 → 购买 → 恢复购买（含 Ask-to-Buy 待批准态）
- [ ] 验证深色模式、最大字体（Dynamic Type）、iPad 布局
- [ ] App Privacy 申报：Data Not Collected

## 📄 许可

商业项目，保留所有权利。
