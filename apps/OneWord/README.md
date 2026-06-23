# OneWord · 一句话

> **微日记 / 一句话情绪记录** — 每天只记一句话 + 一个表情 + 一张图，零压力坚持，端侧 AI 给你情绪洞察。

OneWord 是一款 **付费买断制、纯本地运行** 的 iOS 情绪日记 App，面向"写不下去传统日记"的人和关注心理健康的年轻群体。所有情绪分析都在你的设备上完成，**没有账号、没有服务器、没有追踪**。

---

## ✨ 功能

| # | 功能 | 说明 |
|---|------|------|
| 1 | **每日一句** | 一句话文本 + 表情 emoji + 一张照片，30 秒完成记录 |
| 2 | **端侧情绪分析** | 基于 Apple NaturalLanguage `NLTagger` 的本地情绪打分，数据不出手机 |
| 3 | **情绪趋势图** | 周 / 月 / 年心情走势（Swift Charts） |
| 4 | **情绪日历** | 月历视图，每天按当日心情自动上色 |
| 5 | **心情标签建议** | 端侧关键词命中双语词库，自动建议工作/家人/健康等主题标签 |
| 6 | **年度回顾** | 自动生成属于你的"年度故事"叙事 + 心情分布 + 难忘的日子 |
| 7 | **关键词提取** | 词性分析 + 词形还原，提炼每条记录里最重要的词 |
| 8 | **导出** | 一键导出为 Markdown 或 JSON，数据归你所有 |
| 9 | **隐私锁** | Face ID / Touch ID + 4 位密码，退后台自动锁定 |

---

## 🧠 端侧 AI（隐私核心）

情绪分析全部由 `Utils/SentimentAnalyzer.swift` 在设备本地完成：

- **情绪打分**：`NLTagger(tagSchemes: [.sentimentScore])` 取段落级 -1~1 情绪值；
- **emoji 先验融合**：文本信号弱时，用所选表情的基线情绪做加权，保证短句也有合理读数；
- **关键词提取**：`NLTagger(.lexicalClass + .lemma)` 取名词/动词并做词形还原，兼容中英文；
- **标签建议**：关键词命中内置双语情感词库 → 生成主题标签。

> 全程零网络请求，无任何第三方 SDK。

---

## 🏗 技术栈

- **Swift 6 / SwiftUI**，最低 **iOS 17**
- **MVVM**（`@Observable` 宏）
- **SwiftData** 本地持久化
- **NaturalLanguage** 端侧 NLP
- **Swift Charts** 趋势可视化
- **StoreKit 2** 内购
- **LocalAuthentication + CryptoKit** 隐私锁
- 深色模式（颜色资源集）、Dynamic Type、中英双语本地化

---

## 💰 定价

- **买断制 App**：¥30–60 一次付费下载。
- **可选内购**：`AI Insights`（非消耗型，产品 ID `com.oneword.aiinsights.unlock`）解锁趋势图 / 年度回顾 / 高频主题 / 关键词卡片。
- 基础记录功能永久免费可用，无订阅、无广告。

---

## 🚀 在 Xcode 中运行

> 本仓库为纯源代码，不含 `.xcodeproj`（需用 Xcode GUI 创建）。

1. Xcode → New Project → **iOS App**，名称 `OneWord`，Interface = SwiftUI，Storage = SwiftData。
2. 将本目录所有 `.swift` 文件、`Assets.xcassets`、`Resources/`、`OneWord.storekit` 拖入工程（勾选 Copy items if needed）。
3. 用本目录 `Info.plist` 替换或合并默认配置（包含 Face ID / 相册权限文案）。
4. Target：iOS 17+，Swift Language Version = Swift 6。
5. 添加简体中文本地化：Project → Info → Localizations → +「Chinese, Simplified」。
6. Scheme → Edit Scheme → Run → Options → **StoreKit Configuration** 选 `OneWord.storekit`。
7. 真机调试隐私锁需在「设置」中开启 Face ID。

---

## ✅ 上架检查清单（App Store）

- [x] App 图标已补齐（`Assets.xcassets/AppIcon/AppIcon-1024.png`，1024×1024，全出血无透明）
- [x] `LSApplicationCategoryType = public.app-category.healthcare-fitness` 已在 Info.plist 声明
- [x] `ITSAppUsesNonExemptEncryption = false` 已在 Info.plist 声明
- [x] 隐私政策应用内可访问（设置 → 关于 → 隐私政策；付费墙底部亦有入口）
- [x] 使用条款链接（付费墙 + 设置）指向 Apple 标准 EULA
- [ ] 在 App Store Connect 创建非消耗型内购，产品 ID = `com.oneword.aiinsights.unlock`，价格与文案对齐
- [ ] 隐私清单（PrivacyInfo / App Privacy）：声明"不收集任何数据"（Data Not Collected）
- [ ] 截图：今天 / 日历 / 趋势 / 年度回顾 / 付费墙（中英两套）
- [ ] 真机测试内购沙盒购买 + 恢复购买 + Ask to Buy（pending）流程
- [ ] 验证 Face ID 文案、相册权限文案在中英环境下正确显示
- [ ] VoiceOver 走查：日历单元格、密码键盘、记录卡片均有可读标签
- [ ] Dynamic Type 大字号下各页面无截断
- [ ] 深色 / 浅色模式视觉检查
- [ ] 导出的 Markdown / JSON 在真机分享面板可正常导出
- [ ] 关键词 / 情绪分析在中英文混排下表现正常

---

## 📁 项目结构

详见 [`CLAUDE.md`](./CLAUDE.md) 中的完整目录说明与数据流文档。

---

## 🔒 隐私承诺

OneWord 不联网、不收集、不上传任何内容。你的每一句话、每一张照片、每一次情绪分析，都只存在于你的设备上。
