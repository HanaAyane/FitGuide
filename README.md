<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/readme/hero.svg">
  <img alt="FitGuide · 健身动作指导 — 1324 个动作中英双语离线字典" src="assets/readme/hero.svg" width="100%">
</picture>

<br>

**1324 个健身动作**，全部打进 App Bundle，**不联网也能用**。中英文步骤永远并排显示——打开就能看懂，两下点击看清动作要领。

---

## 是什么

一本装在口袋里的**双语健身动作字典**。按身体部位浏览，点开看 GIF 循环示范 + 中英对照步骤，收藏、组计划、分享给搭子。界面用 Apple 液态玻璃美学——深空背景悬浮玻璃卡，像把 visionOS 的冷静沉浸感带到了 iPhone 上。

| | |
|---|---|
| **平台** | iPhone 纵屏 · iOS 18+ |
| **动作量** | 1324 个，含 180×180 GIF 示范 |
| **语言** | 中英始终并排（不可关闭英语）|
| **离线** | 全部 Bundle 本地化，无后端 |
| **视觉** | Liquid Glass 双路径（iOS 26 原生 / iOS 18 回退）|

---

## 为什么不一样

大多数健身 App 设计成社区、课程、打卡——FitGuide 反其道而行：

**没有账号、没有社交、没有红点。** 它就是一本字典，翻开就用。

| 常见的做法 | FitGuide 的做法 |
|---|---|
| 中文名或英文名二选一 | 中英始终并排，同一行 zh 上 en 下 |
| 视频依赖网络加载 | 1324 GIF 打进 Bundle，健身房没信号也能播 |
| 首页信息爆炸、课程入口喧宾夺主 | 深空背景 + 玻璃卡片 + 按身体部位分组，两下点击看到动作 |
| 卖课、会员、弹窗 | 没有——仅个人作品集使用 |

---

## 怎么做到的

```
FitGuide/
├── FitGuideApp.swift            @main, 注入 ExerciseStore + LibraryStore
├── Models/
│   ├── Exercise.swift           1324 条 Codable 数据模型
│   └── ZH.swift                 中文翻译表 + 身体部位训练惯例排序
├── Stores/
│   ├── ExerciseStore.swift      JSON 加载 + 双语搜索 + 三维筛选
│   └── LibraryStore.swift       SwiftData 收藏/训练计划/历史
├── Theme/
│   └── Theme.swift              Spacing / Radii / 深空三档色
├── Views/
│   ├── Components/
│   │   ├── SpaceBackground.swift   深空渐变 + 漂浮光斑（减弱动效自动关闭）
│   │   ├── GlassCard.swift         iOS 26 .glassEffect() / iOS 18 .ultraThinMaterial
│   │   ├── GIFPlayerView.swift     ImageIO 自解压 GIF 循环
│   │   ├── BilingualStepView.swift 编号圆球 + zh↑/en↓ 始终并排
│   │   └── AttributionFooter.swift © Gym visual 版权硬约束
│   ├── Tabs/                    动作 / 训练 / 收藏 / 我的 四个 Tab
│   └── Detail/                  详情页 + 收藏选择 + 分享 + 计划加入
└── FitGuideTests/
    ├── AttributionTests.swift   版权硬约束（不可移除 Gym visual）
    └── PerformanceTests.swift   冷启动 / 解码 / 搜索 / GIF 解码基准
```

**视觉双路径**：运行时检测 iOS 版本——iOS 26 走原生 `.glassEffect()`，iOS 18 自动回退 `.ultraThinMaterial` + 高光描边，两个版本外观一致。

**版权硬约束**：每条动作数据归属 `© Gym visual — gymvisual.com`，详情页 + 设置页 + 关于页强制展示，`AttributionTests` 三个断言保证不可移除。

---

## 构建

数据集不在本仓库（含 © Gym visual 媒体，不能公开分发）。需将 `exercises-dataset/` 放到与本工程同级目录：

```
健身动作指导/
├── exercises-dataset/    # data/exercises.json + images/ + videos/
└── FitGuide/             # 本工程
```

```bash
# 一次性
brew install xcodegen

# 每次改工程结构后
cd FitGuide
rm -rf FitGuide.xcodeproj && xcodegen generate

# 构建
xcodebuild -project FitGuide.xcodeproj -scheme FitGuide \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

---

## 性能基准

在 iPhone 17 模拟器上测量（`PerformanceTests.swift`）：

| 指标 | 结果 |
|---|---|
| 冷启动到首页可交互 | **~168ms** |
| JSON 解码 1324 条 | **~151ms** |
| 双语搜索（3 词） | **~19ms** |
| GIF 首帧解码 | **<1ms** |
| 首屏 10 张缩略图 | **批量瞬时** |

---

## 测试

```bash
xcodebuild -project FitGuide.xcodeproj -scheme FitGuide \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test
```

两组：
- **AttributionTests** — 版权硬约束（移除任一处 Gym visual 致谢 → 构建失败）
- **PerformanceTests** — 上述性能基准

---

## 版本

| 分支 | 说明 |
|---|---|
| `main` | v1.0 稳定版（`git tag v1.0`）|
| `v2-development` | v2 开发分支 |

---

## 范围之外

明确不做的：
- iPad / visionOS / macOS 版
- 账户系统、云端同步
- HealthKit 集成、卡路里计算
- 动作识别 AI、摄像头姿态分析
- 社区、评论、订阅、付费
- 浅色主题（深色默认，浅色留待后续）

---

## 许可

代码 MIT。媒体（图片 / GIF / 数据集）© Gym visual — https://gymvisual.com/，按其条款仅用于个人学习与作品集展示。

---

## 作者

[@HanaAyane](https://github.com/HanaAyane)

---

*给维护此项目的 AI 见 [AGENTS.md](AGENTS.md)，设计 brief 见 [.design/fitness-app/DESIGN_BRIEF.md](.design/fitness-app/DESIGN_BRIEF.md)。*
