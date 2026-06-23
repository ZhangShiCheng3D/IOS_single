# CleanAlbum · 相册瘦身（隐私版）

> 本地 AI 找出重复、相似、模糊照片，一键清理腾空间。**零上传，全程端侧。**

[![Platform](https://img.shields.io/badge/iOS-17%2B-blue)]()
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)]()
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)]()

---

## ✨ 功能

| 功能 | 说明 |
|---|---|
| 🔍 端侧相似度比对 | `VNGenerateImageFeaturePrintRequest` 生成特征向量，按距离聚类 |
| 📑 重复照片分组 | 自动识别几乎完全相同的照片 |
| 🌫️ 模糊检测 | Laplacian 方差测清晰度，揪出废片 |
| 🎚️ 相似度阈值可调 | 滑杆调节分组严格程度与模糊灵敏度 |
| ✅ 批量预览与确认 | 网格选择 + 全屏滑动浏览 + 安全二次确认 |
| 📊 空间统计 | 清理前可释放预估、清理后前后对比 |
| ⭐ 智能保留 | 每组自动推荐保留最清晰、最高清的一张 |

## 🔐 隐私即卖点

- **照片永不上传**：所有 Vision 分析在设备本地完成。
- **无需联网**：取图时禁用 iCloud 网络下载（`isNetworkAccessAllowed = false`）。
- **无追踪、无广告、无后端**：纯单机 App。
- 特征向量不落盘，扫描结果用完即弃。

## 💰 定价模型

**免费扫描 + 买断解锁批量清理**

- 免费：完整扫描、查看所有重复/相似/模糊照片。
- 付费（¥25–40 一次买断）：解锁一键批量删除。
- 产品 ID：`com.cleanalbum.pro.unlock`（NonConsumable）。

## 🏗️ 技术架构

- **Swift 6 / SwiftUI**，最低 iOS 17
- **MVVM**：`@Observable` ViewModel
- **SwiftData**：持久化设置与清理历史
- **Vision**：相似度（FeaturePrint）+ 模糊（Laplacian 方差）
- **PhotoKit**：相册读写
- **StoreKit 2**：内购

详见 [CLAUDE.md](./CLAUDE.md)。

## 🚀 在 Xcode 中构建

```text
1. Xcode → New Project → iOS App（SwiftUI，iOS 17）
2. 将本目录所有 .swift / .xcassets / .strings / Info.plist 加入 target
3. 配置 Signing Team
4. Scheme → Run → Options → StoreKit Configuration = Store/Products.storekit
5. 用真机测试（相册分析、内购）
```

> ⚠️ 本仓库不含 `.xcodeproj`，需用 Xcode GUI 创建工程后导入源文件。

## ✅ 上架检查清单（App Store）

### 配置
- [ ] Bundle ID 与 App Store Connect 一致
- [ ] 版本号 / Build 号已设置
- [x] AppIcon 1024×1024 已提供（`AppIcon-1024.png`，iOS 17 单尺寸 appiconset，Xcode 自动派生其余尺寸）
- [x] `LSApplicationCategoryType` 已设为 `public.app-category.photo-video`
- [x] `UILaunchScreen` 已配置（空 dict，纯色启动）

### 权限与隐私
- [x] `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription` 文案清晰（已含）
- [x] `ITSAppUsesNonExemptEncryption=false` 已声明
- [ ] App 隐私清单（Privacy Nutrition Label）：勾选「不收集数据」
- [x] 隐私政策页已提供 `PRIVACY.html`（声明零收集，可托管 GitHub Pages）；App 内「设置 → 法律」可访问
- [ ] 将 `AppLinks.privacyPolicy` 替换为正式托管地址，并与 App Store Connect 填写一致
- [x] 使用条款指向 Apple 标准 EULA（App 内「设置 → 法律」可访问）

### 内购
- [ ] App Store Connect 创建 `com.cleanalbum.pro.unlock`，定价 Tier 对应 ¥25–40
- [ ] 内购本地化（中/英）名称与描述
- [ ] 沙盒账号测试购买 + 恢复购买流程
- [ ] 「恢复购买」入口可用（设置页 + 付费墙）

### 功能与体验
- [ ] 真机扫描大相册性能可接受
- [x] 扫描支持中途取消（大相册友好）
- [x] 删除走系统确认，照片进入「最近删除」；成果页以「预计可用空间」诚实呈现
- [x] 关键交互均有触觉反馈（选择 / 清理 / 解锁）
- [x] 深色模式语义色已配置（AccentColor 浅/深双色）
- [x] 照片网格、容量环已加 VoiceOver 无障碍标签
- [ ] Dynamic Type 大字号布局不破版（需真机/模拟器验证）
- [x] 中 / 英 本地化完整（已交叉校验，无缺失 key）
- [x] 无权限 / 空相册等边界状态有合理 UI

### 审核合规
- [ ] 截图 / 预览体现真实功能
- [ ] 描述中隐私卖点与实际一致（不夸大）
- [ ] 无占位 TODO、无测试代码残留

## 📄 许可

私有项目 · 矩阵产品之一。
