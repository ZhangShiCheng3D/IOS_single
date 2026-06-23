# OneWord — 开发指南 (CLAUDE.md)

> 微日记 / 一句话情绪记录 · 付费买断制单机 iOS App
> 每天只记一句话 + 一个表情 + 一张图，端侧 AI 给情绪洞察。

## 一句话定位
写不下去传统日记的人，也能坚持的"零压力"情绪记录。所有数据 **100% 本地**，端侧 NLP 分析，隐私是核心卖点。

## 技术栈
- **语言**：Swift 6.0+ / SwiftUI
- **最低系统**：iOS 17
- **架构**：MVVM + SwiftUI（`@Observable` 宏）
- **持久化**：SwiftData（`@Model DiaryEntry`）
- **端侧 AI**：NaturalLanguage 框架（`NLTagger` 情绪打分 + 词性/词形还原做关键词提取）
- **图表**：Swift Charts
- **付费**：StoreKit 2（`Product` / `Transaction` / `currentEntitlements`）
- **隐私锁**：LocalAuthentication（Face ID / Touch ID）+ CryptoKit（密码 SHA-256 加盐哈希）
- **无后端、无网络请求、无第三方 SDK**

## 目录结构
```
OneWord/
├── OneWordApp.swift            # @main 入口，配置 ModelContainer + 注入环境对象
├── ContentView.swift           # 主 TabView（今天/日历/趋势/设置）
├── Models/
│   ├── DiaryEntry.swift        # SwiftData 模型：一句话+emoji+照片+情绪分+关键词+标签
│   ├── Sentiment.swift         # 情绪分桶枚举（-1~1 → 5 档）+ 配色
│   └── MoodEmoji.swift         # 表情调色板 + 情绪先验基线
├── ViewModels/
│   ├── EntryEditorViewModel.swift   # 编辑器状态 + 端侧分析 + 落库
│   └── InsightsViewModel.swift      # 趋势点/概览/连续天数/年度叙事聚合
├── Views/
│   ├── RootView.swift          # 隐私锁覆盖层 + 退后台自动锁定
│   ├── TodayView.swift         # 首页：今日记录/连续天数/最近历史
│   ├── EntryEditorView.swift   # 零压力编辑器（实时情绪预览）
│   ├── EntryDetailView.swift   # 单条详情（编辑/删除）
│   ├── CalendarView.swift      # 情绪日历（按心情上色）
│   ├── TrendsView.swift        # 趋势图（内购门控）
│   ├── YearReviewView.swift    # 年度回顾（自动生成）
│   ├── SettingsView.swift      # 设置：内购/隐私锁/导出/关于
│   ├── LockView.swift          # 解锁界面（生物识别+密码键盘）
│   ├── PasscodeSetupView.swift # 4 位密码设置
│   └── Components/             # MoodPicker / EntryCard / PhotoPickerButton
├── Utils/
│   ├── SentimentAnalyzer.swift # ★ 端侧情绪分析核心（NLTagger）
│   ├── AppLock.swift           # 隐私锁逻辑
│   ├── ExportManager.swift     # Markdown / JSON 导出
│   ├── ShareSheet.swift        # UIActivityViewController 封装
│   ├── Date+Extensions.swift   # 日历计算
│   ├── Theme.swift             # 设计令牌（颜色/间距/圆角/按钮样式）
│   └── PreviewData.swift       # 预览用内存容器
├── Store/
│   ├── PurchaseManager.swift   # StoreKit 2 购买管理（@Observable）
│   └── PaywallView.swift       # 付费墙
├── Assets.xcassets/            # 颜色集（支持深色模式）+ AppIcon
├── Resources/                  # en.lproj / zh-Hans.lproj Localizable.strings
├── Info.plist                  # 权限文案（FaceID/相册）+ 配置
└── OneWord.storekit            # StoreKit 本地测试配置
```

## 核心数据流
1. 用户在 `EntryEditorView` 输入一句话 + 选 emoji + 可选照片。
2. `EntryEditorViewModel.updatePreview()` 实时调用 `SentimentAnalyzer.analyze()`：
   - `NLTagger(.sentimentScore)` 取段落情绪分（-1~1）
   - 文本分太弱时用 emoji 基线（`MoodEmoji.baseline`）做先验融合
   - `NLTagger(.lexicalClass/.lemma)` 提取名词/动词关键词
   - 关键词命中本地双语词库 → 建议心情标签
3. 保存时写入 SwiftData（同一天只保留一条，编辑即更新）。
4. `TrendsView` / `YearReviewView` / `CalendarView` 通过 `@Query` 读取并由 `InsightsViewModel` 聚合。

## 付费模型
- **买断制 App**（¥30-60 上架价）+ **可选内购**解锁 AI 洞察套件。
- 内购产品 ID：`com.oneword.aiinsights.unlock`（非消耗型 NonConsumable）。
- 解锁状态：`Transaction.currentEntitlements` 校验 + `UserDefaults` 缓存。
- 门控范围：趋势图、年度回顾、高频主题、关键词卡片。基础记录功能永久免费可用。

## 编码约定
- 所有用户可见文案走 `Localizable.strings`，键名用点分命名（`tab.today`）。
- 颜色一律走 `Color("…")` 资源集，**禁止硬编码十六进制**（保证深色模式）。
- 间距/圆角用 `Theme.Spacing` / `Theme.Radius`。
- ViewModel 用 `@Observable`（不用旧的 `ObservableObject`）。
- 每个主要 View 都带 `#Preview`，依赖 `PreviewData.container`。
- 端侧分析逻辑只放在 `SentimentAnalyzer`，View/VM 不直接碰 `NLTagger`。

## 隐私原则（卖点，务必守住）
- 不发起任何网络请求；不集成分析/广告 SDK。
- 照片用 `@Attribute(.externalStorage)` 外部存储，落库前压缩到最长边 1280px。
- 密码只存加盐 SHA-256 哈希，绝不存明文。
- `Info.plist` 中 `ITSAppUsesNonExemptEncryption = false`。

## 在 Xcode 中装配（本仓库不含 .xcodeproj）
1. 新建 iOS App 工程，命名 OneWord，Interface 选 SwiftUI，勾选 SwiftData。
2. 把本目录所有 `.swift`、`Assets.xcassets`、`Resources/`、`OneWord.storekit` 拖入工程。
3. 用本目录的 `Info.plist` 替换默认，或合并其中的权限键。
4. Target ≥ iOS 17，Swift Language Version = Swift 6。
5. 添加本地化：Project → Info → Localizations 增加「Chinese, Simplified」。
6. Scheme → Run → Options → StoreKit Configuration 选 `OneWord.storekit`。
7. 在 App Store Connect 创建对应的非消耗型内购，产品 ID 与代码一致。

## 测试要点
- 端侧分析对中英文混排、超短文本、纯 emoji 的鲁棒性。
- 同一天重复记录应更新而非新增。
- 退后台立即上锁；密码错误清空重输；生物识别失败回退键盘。
- 内购成功/恢复后趋势页即时解锁；卸载重装后「恢复购买」可还原。
