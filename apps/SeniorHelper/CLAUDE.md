# SeniorHelper · 开发指南

银发友好工具集 —— **放大镜** + **用药提醒**。付费买断制单机 iOS App，无后端、纯本地运行。

---

## 技术栈与约束

| 项目 | 选择 |
|---|---|
| 语言 | Swift 6.0+ / SwiftUI |
| 最低系统 | iOS 17 |
| 架构 | MVVM + SwiftUI |
| 持久化 | SwiftData（`@Model`） |
| 内购 | StoreKit 2（买断制非消耗型） |
| 并发 | Swift Concurrency（`async/await`、`@MainActor`） |
| 观察 | Observation 框架（`@Observable`、`@Environment`） |

**核心原则：无服务器、无网络依赖（内购除外）、所有数据仅存本机。**

---

## 目录结构

```
SeniorHelper/
├── SeniorHelperApp.swift        # @main 入口，配置 SwiftData 容器与全局环境对象
├── ContentView.swift            # 3 标签 TabView（放大镜 / 用药 / 更多）
├── Models/                      # SwiftData 模型
│   ├── Medication.swift         # 用药计划
│   └── EmergencyContact.swift   # 紧急联系人
├── ViewModels/                  # @Observable @MainActor 业务逻辑
│   ├── MagnifierViewModel.swift
│   └── MedicationViewModel.swift
├── Views/                       # SwiftUI 页面
│   ├── MagnifierView.swift      # 放大镜（免费）
│   ├── MedicationListView.swift # 用药列表（付费）
│   ├── MedicationEditView.swift # 用药增改
│   ├── EmergencyContactView.swift
│   ├── EmergencyContactEditView.swift
│   ├── MoreView.swift           # 「更多」标签：快捷拨号 + 入口
│   └── SettingsView.swift       # 设置：语音/字号/通知/购买
├── Store/                       # StoreKit 2
│   ├── PurchaseManager.swift    # 购买/恢复/权益校验
│   └── PaywallView.swift        # 付费墙
├── Utils/                       # 管理器与扩展
│   ├── Theme.swift              # 设计令牌 + 按钮样式
│   ├── Extensions.swift         # ImageStore / Haptics / View 扩展
│   ├── SpeechManager.swift      # AVSpeechSynthesizer 语音播报
│   ├── NotificationManager.swift# 本地通知排程
│   ├── CameraManager.swift      # AVCaptureSession 放大镜
│   ├── CameraPreview.swift      # 预览层桥接
│   ├── ImagePicker.swift        # 拍照/相册
│   └── AppShortcuts.swift       # Siri App Intents
├── Resources/                   # 本地化
│   ├── zh-Hans.lproj/Localizable.strings
│   └── en.lproj/Localizable.strings
├── Assets.xcassets/             # AppIcon / AccentColor
└── Info.plist                   # 权限说明、方向、本地化
```

---

## 关键设计决策

### 商业模式
- **放大镜永久免费** —— 获客入口，降低下载门槛。
- **用药提醒 + 紧急联系人为付费** —— 解锁完整版（`com.seniorhelper.unlock.lifetime`）。
- 付费决策者常是子女，付费墙文案兼顾老人与子女双视角。

### 无障碍（核心壁垒）
- 全局 `dynamicTypeSize(.large ... .accessibility5)`，强制支持到最大辅助级字号。
- 触控区域远超 HIG：主按钮 `72pt`，最小可点击 `60pt`（见 `Theme`）。
- 所有功能配 `AVSpeechSynthesizer` 语音播报，可全局开关。
- 关键控件均有 `accessibilityLabel` / `accessibilityHint`。

### 数据
- 图片不入库：药盒照片以 JPEG 存 Documents 目录，模型仅存文件名（`ImageStore`）。
- 通知标识符规则：`med-<UUID>-<index>`，便于按计划撤销/重排。

---

## 编码约定

1. ViewModel 统一 `@Observable @MainActor`，通过 `@State` 持有，副作用（通知、文件、触觉）封装其中。
2. 视图读列表用 SwiftData `@Query`，**写操作**走 ViewModel。
3. 全局对象（`PurchaseManager`、`SpeechManager`）通过 `.environment(...)` 注入。
4. 所有用户可见文案走本地化（`Text("中文")` 或 `String(localized:)`），新增文案须同步两份 `Localizable.strings`。
5. 颜色/间距/圆角统一取自 `Theme`，按钮统一用 `.seniorPrimary` / `.seniorSecondary`。
6. 每个主要 View 保留 `#Preview`。

---

## 在 Xcode 中运行

本仓库不含 `.xcodeproj`（需 Xcode GUI 生成）。集成步骤：

1. Xcode → New Project → iOS App → SwiftUI / Swift，命名 `SeniorHelper`。
2. 删除模板生成的 `ContentView.swift` / `App.swift`，将本目录全部 `.swift`、`Assets.xcassets`、`Resources/`、`Info.plist` 拖入。
3. Target → Info 合并 `Info.plist` 的权限键（相机/相册/通知）。
4. Signing & Capabilities → 添加 **In-App Purchase**。
5. 新建 StoreKit 配置文件，添加非消耗型产品 `com.seniorhelper.unlock.lifetime` 用于本地测试。
6. 真机调试相机与手电筒（模拟器不支持）。
