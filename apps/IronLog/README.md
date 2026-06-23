# IronLog 🏋️

**力量训练记录 · 极速录组 · 自动算容量与 PR · 离线可用**

给认真练的人。买断制（¥48），纯本地运行——没有账号、没有订阅、没有广告，数据永远在你手机里。

---

## ✨ 功能

| 功能 | 说明 |
|------|------|
| **训练日志** | 动作 → 组数 → 重量 × 次数 → RPE，最少点击完成一组 |
| **自动容量 (Tonnage)** | 实时累计 Σ(重量 × 次数)，只计正式组 |
| **PR 自动追踪** | 最大重量 / 估算 1RM / 单组容量 / 最多次数，破纪录即时通知 |
| **训练模板** | 内置 5/3/1、PPL（推/拉/腿）、上/下肢、全身，可自建 |
| **组间休息计时** | 悬浮计时条，后台安全，±15s 快捷调整，结束本地通知 |
| **趋势图表** | Swift Charts 呈现每日容量、每周频次、单动作 1RM 走势 |
| **动作库** | 100+ 内置动作，按肌群分类、可搜索可收藏 |
| **自定义动作** | 自由添加，归入肌群与器械 |
| **导出日志** | 一键导出 UTF-8 CSV（兼容 Excel / Numbers） |
| **HealthKit** | 可选将训练写入 Apple Health |

## 🧱 技术栈

- **Swift 6 / SwiftUI**，MVVM 架构
- **SwiftData** 本地持久化（iOS 17+）
- **StoreKit 2** 买断式内购
- **Swift Charts** 趋势可视化
- **HealthKit** + 本地通知
- 深色模式、Dynamic Type、中英文本地化

## 💰 商业模式

一次性买断 **¥48**（`com.ironlog.pro.unlock`，非消耗型）。

- **免费版**：完整录入体验，保存最近 **5 次** 训练。
- **Pro**：无限训练记录 + 趋势图表 + 完整 PR 追踪 + 导出 + Health 同步，永久解锁、支持家庭共享。

## 🚀 在 Xcode 运行

1. 新建 **iOS App**（SwiftUI，最低部署 **iOS 17.0**），把本目录源码加入 target。
2. **Signing & Capabilities** 添加 **HealthKit**。
3. 关联 `Info.plist`（已含 Health 用途字符串、方向、本地化声明）。
4. Scheme → Run → Options 指定 `IronLog.storekit`，即可本地测试内购。
5. 运行——首启自动写入 100+ 动作与内置模板。

## ✅ 上架检查清单

### 内购与定价
- [ ] App Store Connect 创建非消耗型内购，Product ID = `com.ironlog.pro.unlock`
- [ ] 价格档位对应 ¥48（或目标区间），填齐多语言显示名与描述
- [ ] 实机沙盒验证：购买、**恢复购买**、家庭共享、断网后权益仍生效
- [ ] 付费墙含「恢复购买」入口与价格、买断说明（合规要求）

### 隐私与权限
- [x] `Info.plist` 含 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`
- [x] `Info.plist` 含 `LSApplicationCategoryType`（健康健美）
- [x] App 内隐私政策（`PrivacyPolicyView`），设置页与付费墙均可访问
- [x] 使用条款指向 Apple 标准 EULA（`AppLinks.termsOfUse`）
- [ ] App Store Connect 填写隐私清单：数据**不离开设备**、不收集、不追踪
- [ ] 通知权限文案合理，拒绝后核心功能不受影响
- [ ] HealthKit 为可选；未授权时 App 完整可用
- [ ] 将 `AppLinks.support` 占位邮箱替换为真实支持邮箱

### 质量
- [ ] 全部主要 View 的 `#Preview` 可正常渲染
- [ ] 深色 / 浅色模式逐屏检查
- [ ] 最大 Dynamic Type 字号下无截断、可操作
- [ ] 中 / 英文逐屏检查，无硬编码文案、无缺失键
- [ ] 免费版 5 次限制触发付费墙；Pro 购买后立即解锁
- [ ] 休息计时切后台/锁屏后回前台时间准确；通知按时送达
- [ ] 训练中途杀进程后重进可续练（未结束训练自动恢复）

### 素材
- [x] 1024×1024 App Icon（`AppIcon.png`，可在发布前替换为更精致的设计稿）
- [x] App 内法律入口已就位（隐私政策 + Apple EULA），不再依赖 example.com
- [ ] 6.7" / 6.1" / iPad 截图
- [ ] App 名称、副标题、关键词、描述（中英）

## 📂 项目结构

详见 [`CLAUDE.md`](./CLAUDE.md)。

## 📝 许可

© IronLog。独立开发者作品，保留所有权利。
