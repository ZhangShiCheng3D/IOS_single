# SeniorHelper（长辈助手）

> 银发友好工具集 —— 放大镜读字 + 拍照确认式用药提醒。
> 超大字号、极简导航、语音优先。一款为父母准备、子女买单的付费买断单机 App。

![Platform](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Architecture](https://img.shields.io/badge/Arch-MVVM%20%2B%20SwiftUI-green)

---

## ✨ 功能

| 功能 | 说明 | 计费 |
|---|---|---|
| 🔍 **放大镜** | 实时摄像头放大、捏合/滑块变焦、手电筒补光、画面定格 | 免费 |
| 💊 **用药提醒** | 拍下药盒照片、设置每日多次提醒、本地通知、一键朗读 | 付费 |
| 📞 **紧急联系人** | 大号一键拨号，「更多」页置顶 | 付费 |
| 🔊 **语音播报** | `AVSpeechSynthesizer` 中文播报，全局可开关 | 免费 |
| 🗣️ **Siri 快捷指令** | 「打开放大镜」「我的用药提醒」语音直达 | 免费 |
| 🔠 **超大字号** | 适配 Dynamic Type 至 `accessibility5` 辅助级 | 免费 |

---

## 🧱 技术架构

- **Swift 6.0 / SwiftUI**，最低 **iOS 17**
- **MVVM**：`@Observable @MainActor` ViewModel + SwiftUI View
- **SwiftData** 持久化用药计划与联系人；图片落地沙盒 Documents
- **StoreKit 2** 买断制内购（非消耗型，`AppStore.sync()` 恢复）
- **AVFoundation**：`AVCaptureSession` 放大镜 + 手电筒
- **UserNotifications**：`UNCalendarNotificationTrigger` 每日重复提醒
- **App Intents**：Siri 快捷指令
- 纯本地、无后端、无网络依赖（内购除外）

详见 [`CLAUDE.md`](./CLAUDE.md) 的目录结构与设计决策。

---

## 💰 定价模型

- 单一非消耗型产品：`com.seniorhelper.unlock.lifetime`
- 建议定价 **¥25–50 买断**（子女为父母付费场景）
- 策略：**放大镜免费获客 → 用药提醒/紧急联系人解锁**
- 一次购买、永久使用，无订阅、无广告

---

## 🚀 集成步骤（无 .xcodeproj）

1. Xcode 新建 iOS App（SwiftUI / Swift），命名 `SeniorHelper`
2. 删除模板的 `ContentView` / `App`，拖入本目录全部源码与资源
3. 合并 `Info.plist` 权限键（相机 / 相册 / 通知）
4. Capabilities 添加 **In-App Purchase**
5. 创建 StoreKit 配置文件，添加产品 `com.seniorhelper.unlock.lifetime`
6. **真机**调试相机 / 手电筒 / 通知

---

## ✅ 上架检查清单（App Store）

### 资料与合规
- [ ] App 名称、副标题、关键词（突出「放大镜 老人 用药提醒」）
- [ ] 4.7"/5.5"/6.5"/6.7" 及 iPad 截图（含超大字号实拍）
- [x] 隐私政策已内置于 App 内（`PrivacyPolicyView`，设置页与付费墙均可访问，无外部失效链接）
- [ ] 将「联系与帮助」的 `mailto:support@seniorhelper.app` 替换为真实支持邮箱
- [ ] App 隐私「数据不收集」声明（本地运行，无采集）
- [ ] 年龄分级、版权信息

### 功能与权限
- [ ] `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` 文案清晰
- [ ] 通知权限申请时机合理（进入用药编辑前）
- [ ] 放大镜在无相机权限时有引导而非崩溃
- [ ] 手电筒在不支持设备上优雅降级

### 内购
- [ ] App Store Connect 创建非消耗型产品并提交审核
- [ ] 产品 ID 与代码 `unlockProductID` 一致
- [ ] **恢复购买**按钮可用（审核硬性要求）
- [ ] 付费墙含「使用条款」「隐私政策」链接
- [ ] 沙盒账号实测购买 / 恢复 / 跨设备权益

### 无障碍与体验
- [ ] VoiceOver 通读主要流程
- [ ] Dynamic Type 拉满（`accessibility5`）布局不破版
- [ ] 深色 / 浅色模式均验证
- [ ] 仅竖屏锁定生效

### 资源
- [ ] 放入 1024×1024 `AppIcon` PNG（`Assets.xcassets/AppIcon.appiconset`，当前仅占位）
- [ ] `AccentColor` / `CallAction` 颜色已含浅色 + 深色定义 ✅

### 稳定性
- [ ] 真机覆盖 iPhone SE ~ Pro Max
- [ ] 无 TODO / 占位、无控制台报错
- [ ] 冷启动 < 2s

---

## 📁 许可与隐私

所有用户数据（用药计划、照片、联系人）**仅保存在设备本地**，不上传、不联网、不收集。
