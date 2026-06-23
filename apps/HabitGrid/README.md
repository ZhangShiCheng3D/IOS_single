# HabitGrid

> 极简习惯打卡 · 像素格子风 · GitHub 贡献图式习惯热力图
> **每天点一下，纯本地，好看到想晒。**

HabitGrid 是一款付费买断制的单机 iOS 习惯打卡应用。核心是一张 GitHub 风格的习惯热力图：坚持得越久，格子越密、颜色越深，最终长成一张可以直接截图分享的「成就图」。

---

## ✨ 功能特性

| # | 功能 | 说明 |
|---|------|------|
| 1 | **习惯创建** | 名称 / 24 款 SF Symbol 图标 / 12 种颜色 / 目标频率（每天·工作日·周末·自定义） |
| 2 | **GitHub 风格热力图** | 53 周 × 7 天网格，月份与星期标签，自动滚动到最近一周 |
| 3 | **每日打卡** | 列表一键勾选；详情页点击任意格子补卡，弹簧动效 + 触感反馈 |
| 4 | **连续天数 Streak** | 实时火焰徽章，破纪录时成功触感反馈 |
| 5 | **习惯统计** | 当前连续 / 最长连续 / 累计打卡 / 完成率 |
| 6 | **Widget** | 主屏小/中尺寸组件展示今日习惯与完成进度，每日 0 点自动刷新 |
| 7 | **通知提醒** | 每个习惯可设每日提醒时间，本地通知 |
| 8 | **主题配色** | 7 套配色方案（GitHub / 午夜蓝 / 落日橙 / 樱花粉 / 海洋绿 / 葡萄紫 / 极简灰），含深色模式 |
| 9 | **导出分享** | 把热力图渲染为精美图片卡片（带统计与品牌水印）一键分享 |

---

## 🧱 技术架构

- **Swift 6.0+ / SwiftUI**，最低 **iOS 17**
- **MVVM**：`HabitViewModel` 承载打卡 / CRUD / 统计 / 提醒调度
- **SwiftData** 本地持久化（`Habit` / `HabitEntry`）
- **StoreKit 2** 买断式内购
- **WidgetKit** + **App Group** 共享数据
- **UserNotifications** 本地提醒
- 纯本地、无后端；可选 CloudKit 同步（默认关闭）
- 支持深色模式、Dynamic Type、中英文本地化、VoiceOver 无障碍

详见 [`CLAUDE.md`](./CLAUDE.md)。

---

## 💰 定价模型

- **免费版**：最多 3 个习惯，2 套免费配色
- **HabitGrid Pro（一次买断，¥25–40）**：
  - 无限习惯
  - 全部 7 套配色方案
  - 导出 / 分享热力图
  - 智能提醒
- 产品 ID：`com.habitgrid.pro.lifetime`（NonConsumable）

---

## 🚀 本地运行

> 本仓库仅含源代码，**不含 `.xcodeproj`**（需用 Xcode GUI 创建）。

1. Xcode 新建 iOS App「HabitGrid」，最低 iOS 17，启用 SwiftData。
2. 加入所有 `.swift` 与资源文件；`HabitGridWidget/` 建独立 Widget Extension Target。
3. 两个 Target 开启 **App Groups**：`group.com.habitgrid.shared`。
4. 主 Target 开启 **In-App Purchase**。
5. Run Scheme 的 StoreKit Configuration 选 `Products.storekit`。
6. 放入 1024×1024 App Icon。

详细装配步骤见 [`CLAUDE.md`](./CLAUDE.md)。

---

## ✅ App Store 上架检查清单

### 资料与素材
- [ ] 1024×1024 App Icon（无 Alpha 通道、无圆角）
- [ ] 6.7" / 6.5" / 5.5" iPhone 截图（突出热力图视觉）
- [ ] App 预览视频（可选，展示「点格子 → 变色」过程）
- [ ] 应用名称 / 副标题 / 关键词 / 描述（中英）
- [x] 使用条款指向 Apple 标准 EULA（`LegalLinks.appleStandardEULA`），无需自建条款页
- [x] 隐私政策已内置于 App（设置 / 付费墙 → 隐私，离线可读，`PrivacyPolicyView`）；如 App Store Connect 仍要求 URL，可托管同文案

### 功能与内购
- [ ] App Store Connect 创建内购 `com.habitgrid.pro.lifetime` 并填好本地化价格/描述
- [ ] 内购在沙盒账号下购买 / 恢复均验证通过
- [ ] 付费墙含「恢复购买」「条款」「隐私」入口（已实现）
- [ ] 免费额度（3 个习惯）触发付费墙逻辑验证

### 合规
- [ ] 通知权限弹窗文案合理（首次设置提醒时请求）
- [x] `ITSAppUsesNonExemptEncryption = false` 已在 Info.plist 声明
- [x] `UILaunchScreen`（空 dict）与 `LSApplicationCategoryType`（healthcare-fitness）已声明
- [ ] App Privacy「数据收集」如实填写（本应用不收集任何数据 → Data Not Collected）
- [ ] 若启用 CloudKit，补充 iCloud 能力与隐私说明

### 质量
- [ ] 深色 / 浅色模式逐屏检查
- [ ] Dynamic Type 最大字号无截断
- [ ] VoiceOver 走查热力图与打卡按钮
- [ ] 空状态 / 单习惯 / 多习惯 / 跨年热力图边界验证
- [ ] Widget 小/中尺寸在真机添加并验证刷新

---

## 📂 目录概览
```
Models/        SwiftData 模型
ViewModels/    业务逻辑
Views/         界面（核心：HeatmapView）
Store/         StoreKit 2 + 付费墙
Utils/         扩展 / 统计 / 通知 / Widget 桥 / 导出
HabitGridWidget/  桌面小组件
Resources/     中英本地化
```

---

## 📄 许可
© HabitGrid. 保留所有权利。独立开发者项目。
