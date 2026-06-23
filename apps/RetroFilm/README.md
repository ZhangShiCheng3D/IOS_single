# RetroFilm 📷

> 复古胶片相机 · 端侧滤镜 · 出片即高级

真实胶片质感的相机加滤镜，所有图像处理在设备本地完成，无网络、无后端、无订阅。面向爱拍照的年轻人与 ins / 小红书风格内容创作者。

---

## ✨ 功能

| # | 功能 | 实现 |
|---|------|------|
| 1 | 实时取景预览 | AVFoundation（`AVCaptureVideoDataOutput` 逐帧滤镜，所见即所得） |
| 2 | 胶片滤镜 | Kodak Gold / Portra / 富士 Superia / 依尔福黑白 + 6 款高级胶片 |
| 3 | Core Image 滤镜链 | `FilmFilterEngine` 自研多级管线（非单一 CIFilter） |
| 4 | 胶片颗粒 | 随机噪声 → 去饱和 → Overlay 混合，强度可调 |
| 5 | 漏光 / 暗角 | 径向渐变 Screen 混合 + `CIVignetteEffect`，4 种漏光样式 |
| 6 | 日期戳 | 可选，复古橙字烧录到右下角 |
| 7 | 相册浏览 + 二次滤镜 | SwiftData 库，进详情可换胶片重新出片 |
| 8 | 高质量导出 | 全分辨率 `.export` 渲染，存系统相册 / 分享 |
| 9 | 滤镜参数微调 | 强度 / 颗粒 / 暗角 / 漏光 / 曝光 / 色温 |

## 🛠 技术栈

- **Swift 6.0+ / SwiftUI**，最低 **iOS 17**
- **MVVM + SwiftUI**
- **SwiftData** 持久化（元数据），像素落盘 `Documents/Photos`
- **AVFoundation** 取景与拍摄
- **Core Image / Metal** 自研胶片滤镜管线，共享 Metal `CIContext`
- **StoreKit 2** 内购
- 深色模式（语义色板）、Dynamic Type、中英文本地化

## 💰 定价

免费下载，单个**非消耗型**内购 `com.retrofilm.allfilmpacks`（¥30–68，配置示例 ¥45）一次买断解锁全部高级胶片与效果。免费胶片：原图、Kodak Gold、Portra 400、富士 Superia、依尔福黑白。

## 🚀 在 Xcode 中运行

> 本仓库为**纯源代码**，不含 `.xcodeproj`（需用 Xcode GUI 生成）。

1. Xcode → **File ▸ New ▸ Project ▸ iOS App**，命名 `RetroFilm`，Interface 选 SwiftUI，语言 Swift。
2. 删除模板生成的 `ContentView.swift` / `App.swift`，把本目录下所有 `.swift`、`Assets.xcassets`、`Resources/`、`Info.plist` 拖入工程（勾选 *Copy items if needed* 与 target）。
3. Target ▸ **Info** 合并 `Info.plist` 的隐私权限键（相机 / 相册）。
4. 把 `Products.storekit` 加入工程，Scheme ▸ Run ▸ Options ▸ **StoreKit Configuration** 选它，即可本地测试内购。
5. Signing 选你的开发者账号，**真机运行**（相机在模拟器不可用）。

## ✅ 上架检查清单

- [x] 1024×1024 App Icon ✅（已生成品牌镜头图标 `icon_1024.png`，无 alpha 通道；可后续替换为最终设计稿）
- [ ] App Store Connect 创建内购 `com.retrofilm.allfilmpacks`（非消耗型）并填写本地化与价格
- [x] 隐私政策 / 使用条款链接 ✅（隐私政策改为 App 内可访问 `PrivacyPolicyView`；条款指向 Apple 标准 EULA；已移除全部 `example.com`）
- [x] `Info.plist` 权限文案核对 ✅（移除未使用的麦克风 / 相册读取权限键，仅保留相机与相册写入；新增 `LSApplicationCategoryType`）
- [x] 付费墙含「恢复购买」入口 ✅（已实现）
- [x] StoreKit pending / Ask to Buy 状态 ✅（`PurchaseState.pending` + 用户可见提示）
- [ ] 真机验证各机型取景比例、前后摄旋转 / 镜像、Tap 对焦
- [ ] 截图 / 预览视频（建议展示同一场景多种胶片对比）
- [ ] App 隐私「数据未收集」声明（本应用不收集任何数据）
- [ ] Dynamic Type 与深色模式走查（VoiceOver 标签已补全，建议真机过一遍）
- [ ] 关闭网络后完整跑通拍摄 → 二次滤镜 → 导出（验证纯本地）

## 📁 项目结构

见 [`CLAUDE.md`](./CLAUDE.md) 的「目录结构」与「滤镜管线执行顺序」。

## 🔒 隐私

所有照片处理 **100% 在设备本地完成**，App 不联网、不上传、不收集任何用户数据。
