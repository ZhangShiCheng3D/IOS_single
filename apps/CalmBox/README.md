# CalmBox 🫧

> 解压玩具 + 白噪音盒（ASMR）— 捏泡泡、转陀螺、雨声炉火，配合细腻震动，伴你放松入眠。

CalmBox 是一款 **纯本地、付费买断制** 的 iOS 解压应用，面向焦虑、需要放松的年轻人，主打睡前场景。

## ✨ 核心功能

| 功能 | 说明 | 免费/付费 |
|------|------|-----------|
| 🫧 泡泡纸 | 点击/滑动捏破，清脆音效 + Core Haptics 震动 | 免费 |
| 🌀 解压陀螺 | 拖动旋转，真实物理摩擦衰减，转速联动触觉 | 免费 |
| 🌊 白噪音 | 雨声 / 炉火（免费）+ 海浪 / 森林 / 雷雨 / 风声 / 溪流 / 夏夜虫鸣 | 部分付费 |
| 🎛️ 混音器 | 多声源叠加、独立音量、保存专属混音预设 | 免费叠加，付费声源需解锁 |
| 🫁 呼吸引导 | 4-7-8 助眠呼吸法，引导圆 + 触觉同步 | 付费 |
| 🧘 冥想计时 | 多时长选择、环形进度、可叠加背景音、记录统计 | 付费 |
| ❤️ 收藏主页 | 收藏常用场景，快捷入口 | 免费 |
| 🔊 后台播放 | 锁屏 / 切后台持续播放白噪音 | 免费 |

## 💰 定价

- 免费下载，含泡泡纸、陀螺、雨声、炉火等基础内容
- **一次性内购 ¥25** 解锁全部声源与高级功能（无订阅、无广告）
- 产品 ID：`com.calmbox.unlock.all`（非消耗型）

## 🛠️ 技术栈

- **Swift 6.0+ / SwiftUI**，最低 **iOS 17**
- **MVVM** 架构，`@Observable` + `@Environment` 状态管理
- **SwiftData** 本地持久化（收藏 / 冥想记录 / 混音预设）
- **AVFoundation** 音频混音与后台播放
- **Core Haptics** 自定义震动，设备不支持时自动降级
- **StoreKit 2** 内购（`Product` / `Transaction`）
- 深色模式、Dynamic Type、中英双语本地化

## 📂 项目结构

详见 [`CLAUDE.md`](./CLAUDE.md)。核心目录：`Models / ViewModels / Views / Store / Utils / Resources`。

## 🚀 在 Xcode 中运行

> 本仓库仅含源码，**不含 `.xcodeproj`**（需用 Xcode GUI 创建）。

1. 打开 Xcode → **File ▸ New ▸ Project ▸ iOS App**
   - Product Name: `CalmBox`，Interface: SwiftUI，Language: Swift，Storage: SwiftData
2. 将本目录下的 `Models / ViewModels / Views / Store / Utils` 等源文件拖入工程（勾选 Target）。
3. 将 `Resources/Sounds`（导入真实音频后）以 **folder reference** 方式加入。
4. 将 `zh-Hans.lproj` / `en.lproj` 的 `Localizable.strings` 加入，并在 Project ▸ Localizations 添加简体中文与英文。
5. 合并 `Info.plist` 配置（或在 Target ▸ Signing & Capabilities 添加 **Background Modes ▸ Audio**）。
6. 添加 `CalmBox.storekit` 到工程，并在 Scheme ▸ Options ▸ StoreKit Configuration 选中，便于本地测试内购。
7. 运行到真机以体验 Core Haptics（模拟器无震动）。

## ✅ 上架检查清单

- [ ] **音频资源**：导入无缝循环白噪音与短音效（见 `Resources/Sounds/README.md`），确认商用授权
- [ ] **App 图标**：导入 1024×1024 图标到 `Assets.xcassets/AppIcon`
- [ ] **内购配置**：App Store Connect 创建 `com.calmbox.unlock.all`，价格档对应 ¥25
- [ ] **隐私**：填写隐私清单（本 App 不收集数据），替换 `AppConstants.Links.privacyPolicy / support` 为真实页面（`terms` 已默认使用 Apple 标准 EULA）
- [x] **App 分类**：`Info.plist` 已设置 `LSApplicationCategoryType`（健康健美）
- [x] **出口合规 / 启动屏**：`Info.plist` 已含 `ITSAppUsesNonExemptEncryption=false` 与空 `UILaunchScreen`
- [ ] **能力**：Signing & Capabilities 启用 Background Modes ▸ Audio
- [ ] **真机测试**：触觉、后台播放、购买/恢复流程、深色模式、Dynamic Type
- [ ] **本地化**：检查中英文文案完整，无缺键
- [ ] **截图 & 元数据**：准备 App Store 截图、描述、关键词
- [ ] **测试支付**：用 Sandbox 账号验证购买与恢复

## 📄 许可

© CalmBox。源码用于独立开发者商业项目，音频资源需自备商用授权。
