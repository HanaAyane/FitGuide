# Design Brief: 健身动作指导 iOS App

## Problem

健身房新手走进训练区，面对陌生器械和动作时没人在旁指导。他们看到别人练、或网上零散教程，但既看不懂动作要领（步骤、发力目标肌群），也分不清中文术语和英文动作名——只身照着练常做错、怕受伤，最后只能放弃重量训练。他们需要一本"随身、能看懂、中英对照"的动作字典，在现场随时翻开就知道怎么做。

## Solution

一个iPhone纵屏原生App，把1324个健身动作（含180×180示范GIF）整理成一个可搜索、可筛选、可对照、可组装计划的动作库。打开即按部位浏览，点开看GIF流式播放 + 中英双语步骤 + 目标肌群 + 器械，可收藏、可组合成训练计划、可一键分享给健身搭子。界面采用Apple Liquid Glass美学——动态模糊玻璃悬浮卡层叠在深空背景上，像从visionOS带到了iPhone。

## Experience Principles

1. **即时可懂 over 信息堆砌** -- 新手打开到看懂一个动作要领应在2次点击内完成。示范GIF要大、要循环、要可暂停慢放；步骤用编号清单一行一条；任何辅助元数据（肌群/器械）压到次要层级.
2. **中英共生 over 二选一** -- 双语始终并列展示，永不隐藏另一语言。中文为视觉主轴，英文小号辅助呈现，强化"一手看中文一手记英文动作名"的学习场景. 
3. **冷静沉浸 over 社区热闹** -- 像Apple Fitness+和visionOS而非Keep。无社交评论、无打卡积分、无红点徽章。背景永远是深空，玻璃永远克制，把注意力还给动作画面本身.

## Aesthetic Direction

- **Philosophy**: Liquid Glass Minimalism — 深空底色 + 半透明悬浮玻璃层 + 微发光强调色，仿visionOS带到iPhone纵屏的延伸.
- **Tone**: 冷静、未来、专注. 不煽动、不卖力、不为运动量造氛围.
- **Reference points**: 
  - Apple Fitness+（深色、克制、动作画面为核心）
  - visionOS 系统界面（.regular材质、悬浮玻璃、轻微景深）
  - iOS 26 原生 .glassEffect() 视觉语言
  - Linear 3.0 / Arc Browser（科技感冷色调排版）
- **Anti-references**:
  - Keep / 薄荷健康（色彩饱和、社交浮夸、红点泛滥）
  - Bodybuilding.com（信息过载、复古网页感）
  - 任何带课程购买/会员弹窗的健身App

## Design Tokens 方向

> 具体数值由 design-tokens 阶段产出的 `tokens.swift` / `Colors.xcassets` 决定，本节只定方向.

- **背景**: 三档深空渐变（near-black → ink → night-blue），全天候深色；浅色模式可选但低优先级.
- **玻璃材质**: 
  - iOS 26 → `.glassEffect(.regular)` 原生液态玻璃
  - iOS 18 → `.ultraThinMaterial` + 自定义高光描边 + 微弱内阴影回退
- **强调色**: 单一青绿主调（visionOS 风格的 cyan-teal），用于激活态、进度、`AccentColor`
- **字体**: SF Pro Display 标题 + SF Pro Text 正文；中文PingFang SC 自动回退；双语并列时英文用 SF Pro Text 小号浅灰.
- **间距**: 4-8-16-24-32 五档goin，无中间值.
- **圆角**: 玻璃卡 20pt，小块按钮胶囊(.capsule)，系统HIG相容.

## Use & Distribution Constraints

- **使用场景**：仅个人学习/作品集 demo，不上 App Store 公开发布、不产生任何商业分发.
- **媒体版权**：GIF 与缩略图 © Gym visual — https://gymvisual.com/，按其条款仅用于本项目借展与本地体验；**App 内版权致谢不可移除**（详情页页脚 + 设置页"致谢"页强制展示）.
- **分发范围**：本地 Xcode 调试安装、TestFlight 内部分享或个人 Developer 账号 Ad-Hoc；不进入 App Store 公共发行.

## Existing Patterns

代码库现为**纯数据集**，无任何iOS工程：

- **数据**：`exercises-dataset/data/exercises.json`（1324条，含 `instructions.zh/.en` 与 `instruction_steps.zh/.en`）
- **素材**：`exercises-dataset/images/*.jpg`（180×180缩略）、`exercises-dataset/videos/*.gif`（180×180动图）
- **版权**：每条记录有 `attribution: "© Gym visual — https://gymvisual.com/"`，**App 内必须可访问且不可移除**

无既有tokens、组件、字体加载。一切从零搭.

## Component Inventory

| Component | Status | Notes |
| --- | --- | --- |
| ExerciseListView（首页网格/列表） | New | 按body_part分组，玻璃卡片悬浮，缩略图+中文名作主、英文名作副 |
| SearchBar（搜索栏） | New | 玻璃浮在顶部，实时过滤动作名（中英）+肌群+器械 |
| FilterChipGroup（筛选条） | New | 部位/器械/目标肌群，胶囊型chips，多选 |
| ExerciseDetailView（详情页） | New | 顶部GIF + 中文主标题 + 英文副标题 + 中英双语步骤 + 元数据 + 收藏 |
| GIFPlayerView | New | 加载本地GIF循环播放，可暂停/0.5x慢放 |
| BilingualStepView（双语步骤） | New | 中文编号步骤为主体，英文小号辅助并排，始终展示 |
| MuscleTagView（肌群标签） | New | target + secondary_muscles的小标签 |
| TrainingPlanComposerView（计划编排） | New | 把选中动作组合成计划，记录组数×次数 |
| ShareSheet（分享面板） | New | 系统ShareLink + 中文动作文案复制按钮（中英步骤拼接） |
| FavoritesManager（收藏管理） | New | 多个自定义列表 + 默认收藏夹 + 最近看过历史区，SwiftData本地存储 |
| TrainingPlanComposerView（计划编排） | New | 把选中动作组合成计划，记录组数×次数，仅本地保存 |
| SettingsView（设置） | New | 语言策略=始终双语不可改；数据处理透明度；致谢Gym visual；版权页跳转 |
| GlassCardView（玻璃卡基础组件） | New | iOS26走原生.glassEffect()，iOS18走Material回退 |
| AttributionFooter（版权页脚） | New | 详情页与设置页强制显示© Gym visual，不可隐藏 |
| ExerciseStore（数据层） | New | Bundle JSON加载， SwiftUI `@Observable` |
| AssetBundle（图片GIF） | New | 1324张图+1324个GIF直接打进App Bundle（约几MB） |

## Key Interactions

- **首次打开**：深空背景 + 中央玻璃Logo淡入 + 一行Tagline（"中英对照的随身动作字典"），无Onboarding问卷，直接进首页网格.
- **浏览**：下拉刷新无需；上滑触发顶部玻璃Tab条"半隐藏"避免遮挡内容.
- **卡片点击**：卡片轻微下沉指定 + 全屏Sheet推入，背景被全局毛玻璃模糊加深，详情页GIF即开始循环.
- **GIF控制**：点击GIF切换暂停；长按0.5x慢放标识出现.
- **双语步骤**：始终中文上行+英文下行并排，无切换按钮；设置页也不能关闭英语（设计原则之一）.
- **标题层级**：详情页顶栏仅显示中文动作为主标题，英文动作名作 small caps 副标题弱化呈现（与其余并排双语原则不同，标题区以中文为主视觉锚点）.
- **搜索范围**：键入字符串同时匹配 动作名(中/英) + target 肌群名 + muscle_group + equipment，并列表展示命中项；中文与英文输入均支持.
- **筛选**：FilterChip选中态发光描边，未选半透明玻璃.
- **训练计划**：从详情页"加入计划"按钮 → 模态计划编辑器，可命名、调整顺序、保存到本地 SwiftData，仅本机存储不同步.
- **收藏**：详情页"收藏" →弹出选择"加入哪个列表"或新建列表；首页底部 Tab "收藏" 包含：默认收藏夹 + 用户自定义多列表 + 最近看过(自动收集最近20个). 列表可重命名/删除/排序.
- **分享**：右侧下拉菜单 "分享动作" → 系统ShareLink + "复制双语步骤"按钮（一键复制`中文步骤 + English steps`到剪贴板）.
- **背景动效**：首页背景为缓慢漂移的多层柔光斑点（3-4s ease），增添呼吸感但不分心.

## Responsive Behavior

仅iPhone纵屏：

- 大屏（iPhone Pro Max）网格默认2列密度提升到3列，字号不变
- 小屏（iPhone SE）网格恒2列，步骤区英文行夹紧到下方
- 不做iPad/iPadOS横屏布局（明确Out of Scope）

## Accessibility Requirements

- 动态字体Dynamic Type全支持，最大AX5
- GIF必须带`accessibilityLabel`（动作名+主要目标肌群），VoiceOver不读步骤序号只读内容
- 双语字母对比度 ≥ AA 4.5:1，玻璃卡上层文字必须保证可读（必要时增加玻璃材质下不透明文字layer）
- 所有色彩状态额外带图标（色觉障碍）
- 步骤区支持VoiceOver逐行朗读，左右滑动切换中英文
- 减弱动效（`UIAccessibility.isReduceMotionEnabled`）时关闭背景漂移与卡片下沉微动画

## Asset Bundle Strategy

- **全打包**：1324张 180×180 缩略图（jpg）+ 1324个 180×180 GIF 直接打入 App Bundle，接受本机体积（预估 100-300MB）换取离线零依赖体验.
- **加载优化**：
  - 缩略图用 `AsyncImage` / 自解压缓存，避免首屏卡顿
  - GIF 仅在进入动作详情页时同步加载并循环；列表卡片用缩略图不加载 GIF
  - 启用 `URLCache` 内存缓存与磁盘缓存复用
- **瘦身余地**：若体积超标可在后续迭代做有损压缩或换 AVFoundation 短视频，v1 不做.

## Storage Strategy

- 框架：SwiftData（iOS 17+）— 收藏列表、最近看过的元数据关系
- 实体：`FavoriteList`(name, order, items[]) / `RecentView`(exercise_id, viewed_at) / `TrainingPlan`(name, items_containing exercise_id+sets+reps)
- 仅本地持久化，不接 CloudKit，不跨设备同步
- 数据集本身（动作元数据、图片、GIF）走 Bundle 静态资源，不入 SwiftData

## Out of Scope

- iPad / visionOS / macOS Catalyst 版本
- 账户系统、云端同步、历史训练记录跨设备
- 读取HealthKit、运动数据集成、卡路里计算
- 视频流媒体、动作识别AI、摄像头姿态分析
- 社区、评论、点赞、订阅课程、会员付费
- 浅色主题在v1不做（默认深色，浅色留待后续迭代）
- 后端API / 服务器：全部从本地Bundle读取，1324动作离线可用
- 多语言扩展：v1只支持zh+en，数据集其余8种语言预留但不做UI