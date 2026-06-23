# DocScanPro — 开发指南

> 端侧 OCR 文档扫描仪（隐私版）：拍照转 PDF + 完全本地 OCR，一个字都不上传云端。

## 一句话定位
注重隐私的职场人 / 律师 / 医生 / 财务 / 学生的本地文档扫描工具。**隐私是核心卖点**——任何代码改动都不得引入网络请求。

## 技术栈与约束
- Swift 6.0+ / SwiftUI，最低 **iOS 17**
- 架构：**MVVM + SwiftUI**
- 持久化：**SwiftData**（`ModelConfiguration` 显式 `cloudKitDatabase: .none`，纯本地）
- 扫描：VisionKit `VNDocumentCameraViewController`
- OCR：Vision `VNRecognizeTextRequest`（`accurate` + `zh-Hans/zh-Hant/en-US`）
- PDF：PDFKit / `UIGraphicsPDFRenderer`
- 内购：StoreKit 2（`Transaction` / `Product`）
- **无后端、无网络、无第三方 SDK**

## 目录结构
```
DocScanPro/
├── DocScanProApp.swift        # @main，构建本地 ModelContainer
├── ContentView.swift          # TabView 根视图 + 扫描悬浮按钮
├── Models/                    # SwiftData @Model：ScanDocument / ScannedPage / Folder / Tag
├── ViewModels/                # ScanWorkflow / DocumentDetail（@MainActor ObservableObject）
├── Views/                     # 各功能页面 + 复用组件
├── Store/                     # PurchaseManager + PaywallView（StoreKit 2）
├── Utils/                     # OCRService / PDFExporter / Scanner 封装 / 扩展 / 设置 / 预览数据
├── Resources/                 # zh-Hans + en Localizable.strings
└── Assets.xcassets/           # AppIcon / AccentColor
```

## 核心数据流
1. `ContentView` / `ScanFlowView` 调起 `DocumentScannerView`（VisionKit）。
2. 扫描图像 → `ScanWorkflowViewModel.saveScannedImages` 落库为 `ScanDocument` + `ScannedPage`。
3. 若解锁 OCR 且开启自动识别 → `OCRService`（actor）逐页本地识别，写回 `recognizedText`。
4. 详情页可导出 PDF（`PDFExporter`，可嵌入可搜索文本层）。

## 定价模型（免费扫描 + 内购解锁）
- 免费：单页扫描、导出 PDF、基础整理（标签 ≤ 3）。
- 专业版（一次性买断 `com.docscanpro.pro.lifetime`）：OCR、批量多页扫描、无限文件夹/标签。
- 权益真相来源：StoreKit `Transaction.currentEntitlements`，镜像到 `UserDefaults` 供离线快速读取。
- 功能门控统一走 `PurchaseManager.isUnlocked(_:)`。

## 开发铁律
1. **零网络**：禁止引入任何 URLSession / 第三方网络库；`Info.plist` 已禁用任意加载。
2. 新增用户可见文案 → 同时更新 `zh-Hans` 与 `en` 的 `Localizable.strings`。
3. 每个主要 View 保留 `#Preview`，使用 `PreviewData.container`（内存型，不落盘）。
4. 高级功能新增时，在 `PremiumFeature` 注册并通过 `isUnlocked` 门控。
5. 大二进制（图像）用 `@Attribute(.externalStorage)`，保持数据库轻量。

## 待办 / 可扩展
- 工程文件：仓库不含 `.xcodeproj`。在 macOS 上用根目录 `project.yml` 经 `xcodegen generate` 生成后再构建。
- 在 App Store Connect 配置与 `ProductID.pro` 一致的真实 Product ID（本地已有 `Configuration.storekit` 测试文件）。
- 失败页重试 UI：`ScannedPage.isOCRProcessed` 现已能区分「识别失败」（false）与「已识别但无文字」，可据此在详情页提示重跑。
- 可选：iCloud 备份开关（需在 UI 明确告知用户，默认关闭以守住隐私承诺）。
