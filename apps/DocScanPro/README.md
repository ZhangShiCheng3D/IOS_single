# DocScanPro

**端侧 OCR 文档扫描仪（隐私版）** — 拍照转 PDF + 完全本地 OCR 文字识别，一个字都不上传云端。

![Platform](https://img.shields.io/badge/iOS-17%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-success)

## 简介

DocScanPro 是一款面向**注重隐私的职场人、律师 / 医生 / 财务等敏感行业从业者及学生**的本地文档扫描工具。所有扫描、文字识别、PDF 导出全部在设备端完成，**零网络、零上传**。

## 功能

| 功能 | 说明 | 版本 |
| --- | --- | --- |
| 文档扫描 | VisionKit 自动边缘检测 + 透视校正 | 免费 |
| PDF 导出 | PDFKit 生成，可嵌入可搜索文本层 | 免费 |
| 文档管理 | 文件夹 / 标签 / 全文搜索 | 免费（标签 ≤ 3） |
| 本地 OCR | Vision 框架中英文识别，文本可复制 / 编辑 | 专业版 |
| 批量扫描 | 一次会话采集多页文档 | 专业版 |
| 无限整理 | 无限文件夹与标签 | 专业版 |
| 隐私声明 | 零网络、零上传，清晰可查 | 免费 |

## 技术栈

- **语言/UI**：Swift 6.0+ / SwiftUI，最低 iOS 17
- **架构**：MVVM + SwiftUI
- **持久化**：SwiftData（显式关闭 CloudKit，纯本地）
- **扫描**：VisionKit `VNDocumentCameraViewController`
- **OCR**：Vision `VNRecognizeTextRequest`（accurate，中英文）
- **PDF**：PDFKit / `UIGraphicsPDFRenderer`
- **内购**：StoreKit 2
- **依赖**：无（零第三方 SDK）

## 隐私架构

> 隐私不是功能，而是根基。

- `Info.plist` 中 `NSAppTransportSecurity → NSAllowsArbitraryLoads = false`，且代码不含任何网络调用。
- SwiftData `ModelConfiguration(cloudKitDatabase: .none)`，数据仅存本地沙盒。
- OCR 通过 `OCRService`（actor）在设备神经网络引擎上运行。
- 无统计分析、无广告、无追踪。

## 在 Xcode 中运行

> 本仓库提供完整 Swift 源码，但不含 `.xcodeproj`（需用 Xcode GUI 创建）。

1. 打开 Xcode → File → New → Project → **App**（Interface: SwiftUI，Language: Swift）。
2. 将本目录下所有 `.swift`、`Assets.xcassets`、`Resources/`、`Info.plist` 拖入工程，勾选 *Copy items if needed*。
3. Target → Info：设置 `NSCameraUsageDescription`（或直接使用提供的 `Info.plist`）。
4. Signing & Capabilities：配置开发者团队。
5. 真机运行（文档相机需真实设备，模拟器无相机）。

### StoreKit 本地测试

1. File → New → File → **StoreKit Configuration File**。
2. 添加非消耗型产品，Product ID：`com.docscanpro.pro.lifetime`。
3. Scheme → Run → Options → StoreKit Configuration 选中该文件，即可在模拟器测试购买/恢复。

## 项目结构

```
DocScanPro/
├── DocScanProApp.swift     # App 入口（本地 ModelContainer）
├── ContentView.swift       # 根 TabView
├── Models/                 # SwiftData 模型
├── ViewModels/             # MVVM 视图模型
├── Views/                  # 页面与组件
├── Store/                  # StoreKit 2 + 付费墙
├── Utils/                  # OCR / PDF / 扫描封装 / 扩展
├── Resources/              # 中英文本地化
└── Assets.xcassets/        # 图标与主题色
```

## 上架检查清单（App Store）

- [ ] 配置真实 Bundle ID 与签名证书
- [ ] App Store Connect 创建非消耗型内购 `com.docscanpro.pro.lifetime` 并填写本地化价格
- [x] 1024×1024 App Icon 已内置（`Assets.xcassets/AppIcon.appiconset/icon-1024.png`，单尺寸即满足现代 Xcode 要求）；如需更精细的品牌视觉可替换
- [ ] 准备中英文应用截图（6.7" / 6.5" / iPad）
- [ ] 填写隐私营养标签：**不收集任何数据**（Data Not Collected）
- [x] 使用条款指向 Apple 官方标准 EULA（`AppLinks.termsOfUse`）；隐私政策在 App 内原生呈现（`PrivacyView`）。支持邮箱 `AppLinks.support` 请替换为真实地址
- [ ] 测试购买 / 恢复购买 / 家长批准（Ask to Buy）流程
- [ ] 测试深色模式、Dynamic Type、横竖屏（iPad）
- [ ] 真机验证相机权限弹窗文案
- [ ] 确认无任何网络请求（可用 Network Link Conditioner / 抓包验证）
- [ ] 本地化审校（zh-Hans / en）

## 定价

¥18–40 一次性买断，或**免费扫描 + 内购解锁** OCR / 批量 / 无限整理（当前实现采用后者混合模型）。

## 许可

© DocScanPro. 独立开发者项目，保留所有权利。
