# Build Tasks: 健身动作指导 iOS App

Generated from: .design/fitness-app/DESIGN_BRIEF.md
Date: 2026-07-17

## Foundation

- [ ] **T0 工程骨架与资源打包**: 新建 Xcode SwiftUI 项目 `FitGuide`，iOS 18+ Deployment Target。把 `exercises-dataset/data/exercises.json`、`images/*.jpg`、`videos/*.gif` 作为文件夹引用（blue folder）加入 Bundle，确保 `.json` 与所有资源 `Bundle.main.url(forResource:)` 可解析。配置 `Info.plist` 显示名"健身动作指导"，AccentColor 设为预选 cyan-teal。_Done_: 跑一次模拟器能 `print(Bundle.main.urls(...))` 输出1324个文件。
- [ ] **T1 数据层 ExerciseStore + Exercise 模型**: 创建 Codable `Exercise` struct（id/name/category/body_part/equipment/instructions[String:String]/instruction_steps[String:[String]]/muscle_group/secondary_muscles/target/media_id/image/gif_url/attribution/created_at）。`ExerciseStore: ObservableObject` 单例：启动加载 JSON、提供过滤/搜索/按 body_part 分组的查询方法。搜索方法签名 `search(query: String) -> [Exercise]` 命中 name(中英)+target+muscle_group+equipment。_New component_.
- [ ] **T2 设计 Tokens 文件 + 深空背景**: 创建 `Theme/Colors.xcassets`（深空三档渐变色、cyan-teal Accent、玻璃高光描边色、文本主/次色）。新增 `Theme/Spacing.swift`（4-8-16-24-32 五档枚举）、`Theme/Radii.swift`（卡20pt、按钮 capsule）。落地 `SpaceBackground.swift` SwiftUI View：纵向渐变 + 缓慢漂移的多层径向柔光斑点（3-4s ease 循环），响应 `UIAccessibility.isReduceMotionEnabled` 时停止漂移。_New component_.
- [ ] **T3 GlassCard 玻璃卡基础组件（双路径）**: 创建 `GlassCard<Content>: View`，运行时检测 `if #available(iOS 26, *)` 走 `.glassEffect(.regular)`；否则走 `.ultraThinMaterial + 1pt 高光描边 + 微弱内阴影`。统一圆角 20pt、内容默认内边距 16。成为后续所有 Card/Sheet/Tab 的基础原语。_Depends on: T2_.

## Core UI

- [ ] **T4 首页窗格骨架 + 底部 Tab**: `MainTabView` 含3个 Tab："动作 / 收藏 / 我的"（图标+中文+英文 small caps 并排）。Tab 条本身用 GlassCard 浮在一行透明留白上。整个 App 外层背景由 T2 `SpaceBackground` 充填。_Depends on: T2, T3_.
- [ ] **T5 ExerciseListView 首页网格**: 按首字母分组（取 name 首字符）按 body_part 分区块，每个 body_part 一个 Section，Section Header 用玻璃卡浮一行中英双标题（如"胸部 Chest 163"）。网格 LazyVGrid 2列（Pro Max 检测横宽升 3 列，SE 恒 2列）。卡片显示缩略图(image)+中文主名+英文 small caps 副名+目标肌群胶囊。_Depends on: T3, T1_.
- [ ] **T6 ExerciseCardView 玻璃卡片组件**: 提取出可复用卡 view，含 180x180 `Image(uiLayer:)`、两行标题、胶囊小标签、点击手势回传 exercise。包含reduce motion下卡片状态色描边。_Depends on: T3, T5_.
- [ ] **T7 SearchBar + FilterChipGroup 浮层筛选**: 顶部固定（滑下时半隐藏）玻璃浮条。搜索框实时调用 `ExerciseStore.search`。下方一行横向滚动 FilterChips：部位/器械/目标肌群三组多选，选中态发光描边，未选半透明玻璃。受 chip 影响时 ExerciseListView 切到"按筛选分类"模式。_Depends on: T1, T5_.
- [ ] **T8 ExerciseDetailView 详情页骨架**: 全屏 `.sheet` 推入，背景被 GlassCard 模糊加重层。顶栏仅中文主标题 + 英文 small caps 副标题 + 收藏图标 + 分享菜单 + 关闭。下方 ScrollView：上块 GIF 区、中块元数据卡、下块双语步骤卡、底部 AttributionFooter © Gym visual 不可隐藏。_Depends on: T3, T1_.
- [ ] **T9 GIFPlayerView GIF 播放器**: 用 FLAnimatedImage / 自封装 `Image`：加载 Bundle GIF URL，循环自动播放。点击切换暂停，长按显示 0.5x 慢放标识（共享 currentTime）。降低动效时默认不自动播放。带 accessibilityLabel"动作名 + 主要目标肌群"。_Depends on: T8_.
- [ ] **T10 BilingualStepView 双语步骤组件**: 接受 `instruction_steps[zh]` 与 `instruction_steps[en]`，渲染编号清单中文为主体大号，英文小号浅灰同序号下方。无切换按钮、不可关闭英语。VoiceOver 逐行朗读，左右滑动切换中英文条目。_Depends on: T8_.
- [ ] **T11 MuscleTagView + EquipmentTag 元数据卡**: 元数据卡呈现 target（主）+ secondary_muscles（次）+ muscle_group + equipment，每个一行内嵌 SF Symbols 图标 + 中英对照标签。目标肌群胶囊发光，次肌肉只是描边。_Depends on: T8_.
- [ ] **T12 AttributionFooter 版权页脚**: 详情页底部 + 设置页强制呈现"© Gym visual — https://gymvisual.com/"，可点击以 `Link` 跳转 Safari。永不隐藏，永不缩进折叠。_New component_.

## Interactions & States

- [ ] **T13 收藏管理（SwiftData）**: 定义 SwiftData 模型 `FavoriteList(name, order)` 与 `FavoriteItem(exercise_id, list)`、`RecentView(exercise_id, viewed_at, limit=20)`。详情页"收藏"点击 → 选择列表 sheet / 新建列表。`FavoritesView` 显示：默认收藏夹 + 用户自定义列表 + 最近看过三段，列表项支持重命名/删除/排序。_Depends on: T4, T8_.
- [ ] **T14 训练计划本地保存**: SwiftData 模型 `TrainingPlan(name, items[TrainingItem{exercise_id, sets, reps, order}])`。详情页"加入计划"菜单 → 选择已有计划或新建 → 进入 `TrainingPlanEditorView` 排序/记录组数次数/命名保存。计划列表放在"我的"Tab 内子页。_Depends on: T4, T13_.
- [ ] **T15 分享动作**: 详情页下拉菜单"分享动作" → 系统 ShareLink（含图片 + 中文名 + 中文步骤文本）+ "复制双语步骤"按钮（一键写剪贴板 `中文步骤\n\nEnglish steps`）。_Depends on: T8, T10_.
- [ ] **T16 设置页 + 致谢**: "我的"Tab 内"设置"入口：始终双语不可改的告知项、数据处理透明度说明、AccentColor说明了多少数据被本地保存、链接到 Gym visual 致谢页（含 T12 AttributionFooter + 媒体来源完整说明 + Link 跳转）。_Depends on: T12_.

## Responsive & Polish

- [ ] **T17 网格密度自适应**: 大屏（width >= 430）3 列、中屏 2 列、SE 强制 2 列；卡片字号不放大只增密度。验证 `Environment.horizontalSizeClass` 切换。_Depends on: T5, T6_.
- [ ] **T18 Dynamic Type + 减弱动效长期验证**: 全屏遍历 AX1-AX5 Dynamic Type，确认双语步骤换行礼不崩卡片高度、Tab 不被切挤。`UIAccessibility.isReduceMotionEnabled = true` 时关闭背景漂移与卡片下沉、GIF 不自动播放。_Depends on: T5, T9, T10_.
- [ ] **T19 VoiceOver 通读**: 用 VoiceOver 走通首页 → 筛选 → 详情 → 双语步骤 → 收藏 → 分享，每个交互可听 label，GIF 区有 accessibilityLabel。_Depends on: T9, T10, T13_.
- [ ] **T20 双路径液态玻璃验证**: iOS 18 模拟器 + iOS 26 模拟器分别跑详情页与 Tab，确认 iOS 26 启用原生 `.glassEffect()` 而外观一致。条件色核描边在两个版本下肉眼对比无显著差异。_Depends on: T3, T8, T4_.

## Review

- [ ] **R1 设计评审**: 运行 design-review 对比 brief 检验页面、视觉层级、双语呈现、液态玻璃强度，回填到 `FEEDBACK.md` 后修复。
- [ ] **R2 性能验证**: 真机或模拟器跑首页滚动 60fps 不掉帧；冷启动到首页可交互 < 1s；首次进入详情 GIF 出现 < 200ms。
- [ ] **R3 版权最终复核**: 全 App 内搜索"gymvisual.com"确认至少出现在详情页和设置页；移除任一处不能编译通过（用单元测试或静态 assert 保护）。