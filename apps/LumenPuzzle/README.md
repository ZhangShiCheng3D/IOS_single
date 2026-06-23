# 流光 LumenPuzzle

> 极简 3D 光影解谜游戏 —— 买断制、无广告、无内购骚扰。

拖动一束暖光，越过阴影，照亮散落的光球。10 个由易到难的关卡，一段静谧而完整的解谜之旅。灵感来自 *Monument Valley* 与 *The Room* —— 尊重你的时间，也尊重你的审美。

![平台](https://img.shields.io/badge/iOS-17%2B-black) ![语言](https://img.shields.io/badge/Swift-6.0-orange) ![架构](https://img.shields.io/badge/SwiftUI-MVVM-blue)

## ✨ 特性

- **3D 光影解谜核心玩法**：基于真实光线遮挡（射线命中）判定，所见即所得。
- **拖动光源照亮目标**：单指拖动移动光源，双指拖动环绕视角。
- **10 个内置关卡**：Easy → Medium → Hard，难度与解空间层层递进。
- **SceneKit 精致渲染**：实时阴影、HDR Bloom 辉光、暖金点光，Monument Valley 式克制美学。
- **通关动画与成就**：5 项成就（首通、全通、极简步数、极速、困难全通）。
- **零广告、零内购骚扰**：仅一个一次性买断解锁项，付费后永久无打扰。
- **深色模式美学**：全局 ColorSet，原生支持浅色/深色。
- **无障碍**：Dynamic Type、VoiceOver 标签。
- **本地化**：简体中文 + English。
- **纯本地运行**：无后端、无追踪、无网络依赖（除内购校验）。

## 🏗 技术栈

| 维度 | 选型 |
|------|------|
| 语言 | Swift 6.0+ |
| UI | SwiftUI |
| 3D | SceneKit |
| 架构 | MVVM |
| 持久化 | SwiftData（iOS 17+） |
| 内购 | StoreKit 2 |
| 最低系统 | iOS 17 |

## 🎮 玩法

1. 关卡中散落若干**光球（目标）**与**障碍方块**。
2. **拖动暖色光源**，使其与目标之间没有障碍遮挡、且距离足够近。
3. 目标被照亮时金光绽放。**点亮全部目标**即通关。
4. 障碍会投下真实阴影 —— 思考光从哪个角度才能"绕过"它们。

## 💰 定价

- **买断制**：¥18–40 区间，默认配置 ¥28。
- 商业落地：免费下载试玩前 3 关，一次性内购 `com.lumenpuzzle.unlock` 解锁全部内容，**永久有效，永不再打扰**。

## 🚀 构建运行

本仓库为**纯源码**（不含 `.xcodeproj`，需用 Xcode GUI 装配）。

1. Xcode 新建 **iOS App**（SwiftUI）。
2. 将本目录下所有 `.swift`、`Assets.xcassets`、`Resources/*.lproj`、`Info.plist` 加入 Target。
3. Deployment Target 设为 **iOS 17.0**，Swift Language Version 设为 **6**。
4. 调试内购：Edit Scheme → Run → Options → **StoreKit Configuration** 选 `LumenPuzzle.storekit`。
5. ⌘R 运行。

详见 [`CLAUDE.md`](./CLAUDE.md)。

## ✅ 上架检查清单

### 资源与配置
- [x] `Assets.xcassets/AppIcon` 已含 1024×1024 正式图标（24bpp 无 Alpha，暖金光晕主视觉）。可选：补深色/单色（tinted）变体。
- [ ] 准备 6.7" / 6.5" / 5.5" 及 iPad 截图与预览视频。
- [x] 确认 `Info.plist` 版本号、`CFBundleDisplayName`、方向、`ITSAppUsesNonExemptEncryption=false`、`LSApplicationCategoryType`。
- [x] 启动屏（`UILaunchScreen`）配置（背景色 `BackgroundBottom`）。
- [x] 隐私清单 `PrivacyInfo.xcprivacy`：声明无追踪、无数据收集、文件时间戳原因码 C617.1。

### 内购
- [ ] App Store Connect 创建非消耗内购，**Product ID = `com.lumenpuzzle.unlock`**，价格档对应 ¥28。
- [ ] 内购本地化（中/英）名称与描述完整。
- [ ] 沙盒账号实测：购买、恢复购买、家庭共享、断网降级。
- [x] 付费墙含"恢复购买"入口与清晰的一次性购买说明（非订阅），并附使用条款 / 隐私政策入口。
- [x] 恢复购买在设置页有结果反馈（成功 / 无可恢复 / 失败均有提示）。

### 合规
- [ ] 填写隐私"营养标签"：不收集数据（无追踪、无网络）。
- [x] 应用内可访问隐私政策（`PrivacyPolicyView`）与使用条款（Apple 标准 EULA）。
- [x] App 内提供恢复购买（Guideline 3.1.1）。

### 质量
- [ ] 各机型真机跑通 10 关，确认每关均可解。
- [ ] VoiceOver / Dynamic Type 抽查。
- [ ] 深色 / 浅色外观抽查。
- [ ] 无 TODO 占位、无 `print` 调试残留。
- [ ] Release 配置下无编译警告。

## 📂 项目结构

见 [`CLAUDE.md`](./CLAUDE.md) 的「目录结构」与「核心玩法实现」章节。

## 📄 许可

© 2026 独立开发者作品。保留所有权利。
