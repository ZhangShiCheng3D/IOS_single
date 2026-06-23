# BakeCalc 🧁

**烘焙换算 · 为烘焙爱好者与专业烘焙师打造的精确换算工具**

不是又一个通用计算器，而是垂直专业计算器：把烘焙台前真正高频的换算需求做到精准、好用、离线可用。买断制，一次购买永久使用，无订阅、无广告、无后端。

---

## ✨ 功能

| 功能 | 说明 | 版本 |
|------|------|------|
| 单位换算 | 重量（克/千克/盎司/磅）、体积（毫升/升/茶匙/大勺/杯/液量盎司）互换，并支持借助原料密度的「体积→重量」交叉换算 | 免费 |
| 温度换算 | 摄氏 ↔ 华氏，并提示最接近的烤箱档位 | 免费 |
| 烤箱参考表 | 摄氏 / 华氏 / 英式 Gas Mark / 火力描述对照 | 免费 |
| 配方按份数缩放 | 输入原始与目标份数，所有原料用量按比例实时换算 | 专业版 |
| 原料密度表 | 20+ 常见烘焙原料密度（g/mL、每杯克数、每大勺克数），支持搜索 | 专业版 |
| 配方保存与命名 | SwiftData 本地保存、编辑、搜索配方 | 专业版 |
| 模具尺寸换算 | 圆模/方模/矩形模按底面积比例换算配方用量 | 专业版 |
| 鸡蛋精确换算 | 个数 ↔ 重量双向换算，区分全蛋/蛋白/蛋黄与蛋的规格 | 专业版 |

## 🛠 技术栈

- **Swift 6 / SwiftUI**，最低 **iOS 17**
- **MVVM** 架构，计算逻辑与视图彻底分离
- **SwiftData** 持久化（配方保存）
- **StoreKit 2** 买断制内购（非消耗型）
- 深色模式（ColorAsset）、Dynamic Type、中英双语本地化
- 纯本地运行，**无后端、无网络请求、无数据收集**

## 📁 项目结构

详见 [`CLAUDE.md`](./CLAUDE.md)。核心思路：换算引擎与数据表集中在 `Utils/`，
免费/付费分流由 `AppFeature` 单点控制，整套架构可复用到矩阵内其他垂直计算器。

## 🚀 在 Xcode 中运行

1. 用 Xcode 16+ 新建 iOS App 工程（SwiftUI 生命周期，名称 `BakeCalc`）
2. 将本目录下所有 `.swift`、`Assets.xcassets`、`Resources/`、`Info.plist`、`.storekit` 加入工程
3. Target 设置：
   - Deployment Target = iOS 17
   - 勾选 In-App Purchase 能力
   - 本地化：添加「简体中文」「英文」
4. Scheme → Run → Options → **StoreKit Configuration** 选择 `BakeCalc.storekit`，即可在模拟器测试购买
5. ⌘R 运行

> 注：本仓库不含 `.xcodeproj`（需 Xcode GUI 生成）。所有源文件、资源、配置均已就绪。

## 💰 定价

一次性买断 **¥18**（区间 ¥12–25），解锁全部专业工具。产品 ID：`com.indie.bakecalc.pro`。

## ✅ 上架检查清单（App Store）

- [ ] 在 App Store Connect 创建非消耗型内购，ID = `com.indie.bakecalc.pro`，价格档位与本地一致
- [x] AppIcon 1024×1024 已就绪（`Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`，焦糖渐变 + 打蛋器，可按需替换为更精细设计）
- [ ] 准备各尺寸截图（6.7" / 6.5" / 5.5" / iPad）
- [x] 使用条款链接已指向 Apple 标准 EULA（`.../itunes/dev/stdeula/`）
- [ ] 隐私政策 URL：当前指向 Apple 法务页占位，上架前需替换为自有「不收集数据」声明页（GitHub Pages / Notion 均可）
- [ ] 填写 App 隐私「不收集数据」声明（本应用确实不收集）
- [x] `ITSAppUsesNonExemptEncryption = NO` 已在 Info.plist 声明
- [x] `LSApplicationCategoryType = food-and-drink` 已声明
- [ ] 真机验证购买、恢复购买、解锁状态持久化
- [ ] 中英文文案、深色模式、Dynamic Type 大字号下逐页检查
- [ ] 填写应用描述、关键词、分级（4+）
- [ ] 配置内购的审核截图与描述

## 📄 许可

© 独立开发者作品。保留所有权利。
