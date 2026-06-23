# CleanAlbum — 开发指南

> 照片去重 / 相册瘦身（隐私版）。本地 AI 找出重复、相似、模糊照片，一键清理，零上传。

## 一句话定位
端侧 Vision 分析的相册清理工具。**隐私是第一卖点**：照片永不离开设备。

## 技术栈
- Swift 6 / SwiftUI，最低 **iOS 17**
- 架构：**MVVM**（`@Observable` ViewModel + SwiftUI View）
- 持久化：**SwiftData**（仅存设置与清理历史，不存照片）
- 图像分析：**Vision**（`VNGenerateImageFeaturePrintRequest` 相似度 + Laplacian 方差测模糊）
- 相册：**Photos / PhotoKit**
- 内购：**StoreKit 2**（买断制，非订阅）

## 目录结构
```
CleanAlbum/
├── CleanAlbumApp.swift        # @main 入口，配置 SwiftData 容器
├── ContentView.swift          # 主界面，编排扫描→结果→清理
├── Models/
│   ├── AppSettings.swift       # @Model 用户设置（阈值）
│   ├── CleanupRecord.swift     # @Model 清理历史
│   ├── PhotoItem.swift         # 运行期照片模型 + 特征向量包裹
│   └── PhotoGroup.swift        # 分组模型（重复/相似/模糊）
├── ViewModels/
│   └── ScanViewModel.swift     # 核心：权限→取图→分析→分组→删除
├── Views/
│   ├── WelcomeView.swift        # 扫描引导
│   ├── ScanProgressView.swift   # 进度
│   ├── CategoryCard.swift       # 分类入口卡
│   ├── GroupsListView.swift     # 某类下全部分组
│   ├── GroupDetailView.swift    # 单组网格 + 选择
│   ├── PhotoPreviewView.swift   # 全屏滑动浏览
│   ├── PhotoThumbnailView.swift # 异步缩略图组件
│   ├── StorageStatsView.swift   # 容量环形图
│   ├── SettingsView.swift       # 阈值/隐私/恢复购买
│   └── CleanupResultView.swift  # 清理成果 + 前后对比
├── Utils/
│   ├── PhotoLibraryManager.swift # PhotoKit 封装（actor）
│   ├── PhotoAnalyzer.swift       # Vision 引擎（actor）
│   ├── Formatters.swift          # 容量格式化
│   └── Color+Theme.swift         # 设计令牌
├── Store/
│   ├── PurchaseManager.swift     # StoreKit 2 权益管理
│   ├── PaywallView.swift         # 付费墙
│   └── Products.storekit         # 本地测试配置
├── Resources/                    # zh-Hans / en 本地化
├── Assets.xcassets/              # AccentColor / AppIcon
└── Info.plist
```

## 核心数据流
1. `ContentView` 调 `ScanViewModel.scan()`
2. `PhotoLibraryManager` 请求权限 → 抓取 `PHAsset`
3. 逐张取中等尺寸图 → `PhotoAnalyzer.featurePrint()` + `.sharpness()`
4. `PhotoAnalyzer.groupBySimilarity()` 按特征距离聚类；`blurryGroup()` 收集模糊照片
5. 用户选择 → `deleteSelected()` 调 `PHAssetChangeRequest.deleteAssets`（系统二次确认）

## 关键设计决策
- **特征向量不持久化**：相册是事实来源，每次扫描重建，避免数据陈旧与隐私残留。
- **actor 隔离**：`PhotoAnalyzer` 与 `PhotoLibraryManager` 用 actor 串行化，控制内存峰值。
- **阈值映射**：UI 的 0–1 阈值在 `ScanViewModel` 映射为 Vision 距离阈值（见注释）。
- **免费/付费边界**：扫描+浏览免费；批量删除需 `PurchaseManager.isPro`。

## 付费模型
- 产品 ID：`com.cleanalbum.pro.unlock`（NonConsumable，¥25–40）
- 解锁状态以 StoreKit `Transaction.currentEntitlements` 为准，`UserDefaults` 仅作冷启动兜底。

## 在 Xcode 中运行
1. 用 Xcode 新建 iOS App 项目（SwiftUI, iOS 17），将本目录所有源文件加入 target。
2. Signing & Capabilities 设好 Team。
3. Info.plist 已含相册权限文案。
4. Scheme → Run Options → StoreKit Configuration 选 `Store/Products.storekit` 以测试内购。
5. 真机测试相册功能（模拟器相册样本有限）。

## 编码约定
- 命名清晰、注释说明「为什么」而非「是什么」。
- 所有主要 View 带 `#Preview`。
- 用户可见文案一律走 `Localizable.strings`，禁止硬编码。
- 颜色走 `Color.brand` / Asset，支持深色模式与 Dynamic Type。
