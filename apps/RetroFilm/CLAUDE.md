# RetroFilm — 开发指南 (CLAUDE.md)

复古胶片相机 · 端侧滤镜 · 付费买断单机 App。本文件供后续在此项目工作的 AI / 开发者快速理解架构与约定。

## 一句话定位
真实胶片质感的相机 + 滤镜，**所有处理本地完成**，主打「出片即高级」。

## 技术栈与约束
- Swift 6.0+ / SwiftUI，最低 **iOS 17**
- 架构：**MVVM + SwiftUI**
- 持久化：**SwiftData**（`CapturedPhoto` @Model），像素字节落盘到 `Documents/Photos`，库里只存元数据 + 文件名
- 取景：**AVFoundation**（`AVCaptureVideoDataOutput` 逐帧 → 滤镜 → 实时预览；`AVCapturePhotoOutput` 高清拍摄）
- 滤镜：**Core Image / Metal 自研管线**（`FilmFilterEngine`），共享一个 Metal `CIContext`
- 内购：**StoreKit 2**，单个非消耗型解锁 `com.retrofilm.allfilmpacks`
- 无后端、无网络、纯本地

## 目录结构
```
RetroFilm/
├─ RetroFilmApp.swift        # @main，注入 ModelContainer + PurchaseManager
├─ ContentView.swift         # TabView：相机 / 相册
├─ Models/
│  ├─ FilmStock.swift        # 胶片配方（纯数据 + 内置 catalog）
│  ├─ FilterSettings.swift   # 每张照片可调参数
│  └─ CapturedPhoto.swift    # SwiftData @Model
├─ ViewModels/
│  ├─ CameraViewModel.swift  # AVCaptureSession + 实时滤镜预览 + 拍摄
│  └─ PhotoEditViewModel.swift # 二次滤镜重渲染 + 导出
├─ Views/
│  ├─ CameraView.swift       # 取景主界面
│  ├─ FilmWheelView.swift    # 胶片转盘选择器（带锁）
│  ├─ AdjustmentPanel.swift  # 参数微调 sheet
│  ├─ GalleryView.swift      # 相册网格（@Query）
│  ├─ PhotoDetailView.swift  # 大图 + 二次滤镜 + 导出/分享/删除
│  └─ SettingsView.swift     # 设置 + 购买入口
├─ Store/
│  ├─ PurchaseManager.swift  # StoreKit 2 解锁/恢复/权益
│  └─ PaywallView.swift      # 付费墙
├─ Utils/
│  ├─ FilmFilterEngine.swift # ★核心：胶片滤镜链
│  ├─ PhotoStorage.swift     # 磁盘读写 + 缩略图
│  ├─ HapticManager.swift    # 触感
│  └─ Theme.swift            # 设计 token
├─ Assets.xcassets/          # AppIcon / AccentColor / 语义色板
├─ Resources/                # zh-Hans + en Localizable.strings
├─ Products.storekit         # 本地 StoreKit 测试配置
└─ Info.plist
```

## 滤镜管线（FilmFilterEngine）执行顺序
1. 曝光（用户）→ 2. 白平衡（胶片色温/色调 + 用户暖度）→ 3. 黑白转换（如适用）→ 4. 饱和/对比/亮度 → 5. **胶片色调曲线**（抬阴影、压高光、褪色）→ 6. **分离色调**（阴影/高光分别染色）→ 7. **颗粒** → 8. **暗角** → 9. **漏光** → 10. 整体强度与原图交叉淡化 → 11. **日期戳**（烧录）。

预览用 `.preview`（复用缓存噪声，省算力）；导出用 `.export`（全质量）。两条路径共用同一管线，保证**所见即所得**。

## 关键约定
- 新增胶片：在 `FilmStock.catalog` 加一条，并在 **两个** `Localizable.strings` 里加 `film.<id>` 文案；`isPremium = true` 即自动进付费墙。
- `FilmStock.id` 同时是：catalog 主键、SwiftData 存储键、本地化文案 key。三者必须一致。
- 所有用户可见文案走 `Localizable.strings`，不要硬编码中英文。
- 颜色用 `Theme` 里的语义色（Assets 色板，自动适配深色模式）。
- 权益判断统一用 `PurchaseManager.isAvailable(_:)` / `isUnlocked`，不要各处读 UserDefaults。

## 待办 / 上架前
- ~~替换 `AppIcon`~~ ✅ 已生成品牌镜头图标 `icon_1024.png`（无 alpha）；如有最终设计稿可替换
- ~~`example.com` 占位链接~~ ✅ 隐私政策改为 App 内 `PrivacyPolicyView`，条款指向 Apple 标准 EULA（见 `Theme.swift` 的 `Legal`）
- App Store Connect 创建对应内购项 `com.retrofilm.allfilmpacks` 并与 `Products.storekit` 对齐
- 真机验证 AVFoundation 旋转/镜像与各机型取景比例
- 隐私政策「联系我们」目前指向 App Store 开发者支持页；如需邮箱可在 `privacy.section.contact.body` 补充
