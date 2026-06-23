# CollageKit · 拼图海报排版工具

把多张照片排成精致拼图 / 九宫格 / 杂志风海报，模板化一键出图。面向发社交动态、做电商图、记录生活的人群。

> 付费买断制单机 App ·  iOS 17+ · SwiftUI · 纯本地运行

---

## ✨ 功能

| # | 功能 | 说明 |
|---|------|------|
| 1 | 多模板选择 | 九宫格 / 杂志风 / 胶片风 / 自由，共 14 套精排模板 |
| 2 | 拖拽替换照片 | 长按插槽拖动到另一插槽即可交换 |
| 3 | 边框 / 间距 / 圆角 | 实时滑杆调整，所见即所得 |
| 4 | 背景颜色 / 渐变 | 预设色板 + 自定义取色 + 渐变角度 |
| 5 | 文字叠加 | 内容 / 字号 / 粗细 / 颜色 / 旋转，可拖动定位 |
| 6 | 多比例导出 | 1:1 / 4:5 / 9:16 |
| 7 | 模板预览 | 缩略图实时呈现排版 |
| 8 | 保存模板为预设 | 把当前模板 + 外观参数存为可复用预设 |

## 🧱 技术架构

- **语言**：Swift 6 / SwiftUI
- **最低系统**：iOS 17
- **架构**：MVVM + SwiftUI
- **持久化**：SwiftData（`@Model`）
- **图像合成**：Core Graphics（`UIGraphicsImageRenderer`），本地完成，无需网络
- **内购**：StoreKit 2，买断式非消耗型
- **能力支持**：深色模式（AccentColor）、Dynamic Type、中英文本地化

详见 [CLAUDE.md](./CLAUDE.md)。

## 💰 定价模型

免费使用基础模板；**一次性买断 ¥18** 解锁 **CollageKit Pro**：

- 全部精美模板（杂志风 / 胶片风等付费模板）
- 去除导出水印
- 解锁全部导出比例（含 9:16）
- 未来新增模板免费享用

产品 ID：`com.collagekit.pro.lifetime`

## 📁 项目结构

```
Models/ · ViewModels/ · Views/(+Panels/) · Store/ · Utils/ · Resources/ · Assets.xcassets/
```

## 🚀 在 Xcode 中运行

1. 新建 iOS App 工程（SwiftUI 生命周期，iOS 17+），或将本目录源文件加入已有 target。
2. 把全部 `.swift`、`Assets.xcassets`、`Resources/*.lproj`、`Info.plist` 加入 target。
3. 把 `Info.plist` 设为工程的 Info.plist（或将其中键值合并到自动生成的 plist）。
4. Scheme → Run → Options → StoreKit Configuration 选择 `CollageKit.storekit`，即可本地测试内购。
5. 运行。

## ✅ 上架检查清单

### 资源与配置
- [ ] 提供 1024×1024 App Icon（替换 `Assets.xcassets/AppIcon.appiconset`）
- [ ] 确认 `CFBundleShortVersionString` / `CFBundleVersion`
- [ ] 配置 Bundle Identifier 与签名 Team
- [ ] `NSPhotoLibraryAddUsageDescription` 文案已就绪（保存到相册）

### 内购
- [ ] App Store Connect 创建非消耗型内购：`com.collagekit.pro.lifetime`，价格 ¥18
- [ ] 内购本地化（中/英）名称与描述
- [ ] 真机沙盒账号测试购买 + 恢复购买
- [x] 付费墙含「恢复购买」「使用条款」「隐私政策」链接（已实现）
- [x] 购买流程处理 pending / 待批准（Ask to Buy）状态

### 合规
- [x] 使用条款指向 Apple 标准 EULA；隐私政策内置于 App 内（`PrivacyPolicyView`）可随时访问
- [ ] 把「设置 → 联系我们」邮箱替换为正式的开发者支持邮箱（当前为占位账号邮箱）
- [x] App 隐私清单：本 App 不收集任何数据（纯本地）
- [x] `LSApplicationCategoryType = public.app-category.photography`
- [x] 出口合规：`ITSAppUsesNonExemptEncryption = false`

### 质量
- [ ] 深色模式逐屏检查
- [ ] Dynamic Type 最大字号布局检查
- [ ] 多机型（小屏 SE / 大屏 Pro Max / iPad）画布比例检查
- [ ] 导出图清晰度与水印位置检查
- [ ] 截图与预览视频（1:1 / 4:5 / 9:16 三种比例展示）

### App Store 元数据
- [ ] 应用名称、副标题、关键词、描述（中/英）
- [ ] 分级、分类（摄影与录像）
- [ ] 5 张以上截图（各机型尺寸）

---

© CollageKit. 单机付费 App，无后端、无数据采集。
