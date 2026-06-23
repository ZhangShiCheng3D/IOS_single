# FastFlow ⏳💧

> 间歇性断食计时 · 喝水追踪 · 健康节律。简洁、顺滑、纯本地。

FastFlow 是一款面向 16:8 断食、控糖与健康管理人群的 iOS App。专注当下，记录每一次断食与每一杯水，用清晰的趋势图看见自己的坚持。买断制，无订阅，无广告，数据全部留在你的设备。

## ✨ 功能

| | 功能 | 说明 |
|---|---|---|
| ⏳ | **断食计时器** | 16:8 / 18:6 / 20:4 / OMAD，圆环实时计时，可回填开始时间 |
| 📲 | **Live Activity** | 锁屏与灵动岛实时显示断食进度，系统自动走时 |
| 💧 | **喝水追踪** | 每日目标 + 快捷记录（100/200/300/500ml）+ 自定义 |
| 🔔 | **喝水提醒** | 自定义时间段与间隔的本地定时提醒 |
| 📊 | **断食趋势图** | Swift Charts 绘制每日断食时长、连续达标、平均时长 |
| ⚖️ | **体重趋势** | 接入 HealthKit，绘制体重曲线（高级） |
| 🗂️ | **断食历史** | 全部已完成会话记录，可删除 |
| 🧩 | **桌面小组件** | 主屏 / 锁屏小组件展示当前断食进度 |
| 🎛️ | **自定义方案** | 任意断食/进食窗口（高级） |

## 💰 定价

**免费下载** + **¥30 一次性买断**解锁高级版：

- 高级图表（30 天趋势）
- 自定义断食方案
- 桌面小组件
- 体重趋势（HealthKit）

产品 ID：`com.fastflow.premium.unlock`（非消耗型）。

## 🏗️ 技术栈

- **SwiftUI** + **MVVM**（`@Observable` ViewModel），最低 **iOS 17**
- **SwiftData** 本地持久化
- **StoreKit 2** 内购（`Transaction` / `Product`）
- **HealthKit** 体重/饮水读写
- **ActivityKit** Live Activity + **WidgetKit** 桌面小组件
- **Swift Charts** 趋势可视化
- 深色模式、Dynamic Type、中英双语本地化

## 📂 工程结构

见 [`CLAUDE.md`](./CLAUDE.md) 的「目录结构」与「Xcode 工程配置」章节。本仓库为纯源码，需用 Xcode 新建工程并按指南加入两个 Target（主 App + Widget Extension）。

## 🚀 本地运行

1. Xcode 16+ 新建 iOS App 工程（SwiftUI / SwiftData），Bundle ID 建议 `com.fastflow`。
2. 将本目录源文件按 [`CLAUDE.md`](./CLAUDE.md) 指引加入对应 Target。
3. 添加 Capabilities：HealthKit、App Groups（`group.com.fastflow.shared`）、Live Activities。
4. Scheme 选用 `Configuration/FastFlow.storekit` 进行内购联调。
5. 真机运行体验 Live Activity 与 HealthKit（模拟器对二者支持有限）。

## ✅ 上架检查清单

### 工程与签名
- [ ] Bundle ID、版本号、Build 号已设置
- [ ] 主 App 与 Widget Extension 的 App Group ID 一致
- [ ] HealthKit / App Groups / Live Activities Capability 已开启
- [ ] 真机签名与 Provisioning Profile 正常

### 资源与内容
- [x] AppIcon 1024×1024 已提供（`Assets.xcassets/AppIcon/AppIcon-1024.png`，可按需替换为定制设计）
- [x] `Info.plist` 含 `UILaunchScreen`、`LSApplicationCategoryType`（健康健身）
- [x] `PrivacyInfo.xcprivacy` 隐私清单已提供（无追踪、无数据收集、UserDefaults Required Reason）
- [ ] 启动后中英文显示正确，无缺失 key
- [ ] 深色 / 浅色模式视觉正常
- [ ] Dynamic Type 放大不破版

### 功能验证
- [ ] 断食开始/结束、回填时间、跨重启恢复会话正常
- [ ] Live Activity 在锁屏与灵动岛走时正确，结束后消失
- [ ] 桌面小组件三种尺寸显示进度正确
- [ ] 喝水记录、目标、提醒通知按设定触发
- [ ] 趋势图与统计数据正确，空数据有占位
- [ ] HealthKit 授权流程与体重曲线正常（授权被拒时降级）

### 内购（StoreKit 2）
- [ ] App Store Connect 创建非消耗型内购 `com.fastflow.premium.unlock`，价格 ¥30
- [ ] 购买成功后高级功能解锁，重启后状态保留
- [ ] 「恢复购买」可用
- [ ] 沙盒账号完整走通购买 / 恢复

### 合规与隐私
- [x] 隐私政策内置 App 内（`PrivacyPolicyView`），使用条款指向 Apple 标准 EULA（不再有 `example.com` 占位）
- [x] App 隐私清单（`PrivacyInfo.xcprivacy`：本地存储、不收集、无追踪）
- [x] HealthKit 用途说明文案准确（`Info.plist`）
- [x] `ITSAppUsesNonExemptEncryption=false` 已声明
- [ ] 通知权限按需请求（已实现：开启提醒/连接健康时请求；可在真机复核）

## 📄 许可

© FastFlow. 保留所有权利。
