# AGENTS.md - 给维护此项目的 AI 的指南

## 项目概览
FitGuide 是一个 iOS SwiftUI 健身动作指导与训练记录 App。本地内置 1324 个动作（含 GIF），中英双语始终并排显示，使用 Apple Liquid Glass 视觉语言，深空背景 + 玻璃卡片悬浮美学。v2.0 已加入计划模板、自由训练、逐组记录、休息计时、训练摘要与历史。仅用于个人学习/作品集，不上 App Store 公开发行。

## 技术栈
- SwiftUI + SwiftData
- iOS 18+ Deployment Target（iOS 26+ 启用原生 `.glassEffect()`，否则回退 `.ultraThinMaterial` + 高光描边）
- 数据资源通过 xcodegen folder reference 整体打包进 Bundle（exercises.json + 1324 张 jpg + 1324 个 GIF，约 153MB）
- xcodegen 管理工程，改源文件后跑 `rm -rf FitGuide.xcodeproj && xcodegen generate`
- 无后端，全部离线

## 关键约束（硬约束，不可破坏）
- **版权硬约束**：每个 Exercise 的 attribution 必须 `© Gym visual — https://gymvisual.com/`。详情页 + 设置页 + 关于页强制显示 © Gym visual 页脚，AttributionTests 测试断言其不可移除（测试失败则构建失败）
- **双语原则**：步骤区永远中英并排（zh 上 + en small caps 下），不提供单语切换开关
- **深空主题**：默认深色 SpaceBackground，GlassCard 双路径（iOS 26 原生 glassEffect / iOS 18 Material 回退）
- **媒体版权**：仅个人/作品集用途，不上 App Store 公开分发

## 构建命令
- 重装依赖：`brew install xcodegen`（一次性）
- 重建工程：`rm -rf FitGuide.xcodeproj && xcodegen generate`
- 构建：`xcodebuild -project FitGuide.xcodeproj -scheme FitGuide -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 跑测试：`xcodebuild -project FitGuide.xcodeproj -scheme FitGuide -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test`

## 项目结构
```
FitGuide/
├── FitGuideApp.swift               # @main，共享 ModelContainer，注入三个 Store
├── Models/
│   ├── Exercise.swift              # Codable 数据模型
│   ├── ZH.swift                    # 中文翻译表 + bodyPart 训练惯例排序
│   ├── BodyPartTranslation.swift    # BodyPartOrder 索引
│   └── DataModels.swift            # 计划 + WorkoutSession/WorkoutExercise/SetLog（含旧收藏兼容模型）
├── Stores/
│   ├── ExerciseStore.swift         # JSON 加载 + 多维度搜索 + 筛选
│   ├── LibraryStore.swift          # 最近浏览、计划模板、v1 默认值迁移
│   └── ActiveWorkoutStore.swift    # Session 状态机、逐组记录、计时、恢复、历史
├── Theme/
│   ├── Theme.swift                 # Spacing/Radii/Color
│   └── Assets.xcassets             # 深空三档色 + AccentColor + 文本主次色
├── Views/
│   ├── RootView.swift              # 启动加载态 → MainTabView 切换
│   ├── Components/
│   │   ├── SpaceBackground.swift   # 深空渐变 + 漂浮光斑（减弱动效关闭）
│   │   ├── GlassCard.swift         # 双路径液态玻璃基础组件
│   │   ├── ExerciseCardView.swift  # 玻璃卡 + 缩略图 + 中文主名+英文副名+肌群/器械
│   │   ├── ThumbnailView.swift     # 本地图片加载
│   │   ├── GIFPlayerView.swift     # UIImage + ImageIO 自解压 GIF 循环播放
│   │   ├── BilingualStepView.swift # 编号圆球 + zh 上/en 下并排
│   │   ├── AttributionFooter.swift # © Gym visual 版权页脚（Link 跳转）
│   │   ├── FilterChipGroup.swift   # 玻璃 chip 多选 + FlowLayout 自适应换行
│   │   ├── AdaptiveGrid.swift      # 大屏 3 列 / 小屏 2 列
│   │   └── ExerciseListComponents.swift # BodyPartHeader + BodyPartSectionGrid + SearchResultsList
│   ├── Tabs/
│   │   ├── MainTabView.swift        # 3 Tab: 动作/训练/我的
│   │   ├── ExercisesTabView.swift   # 首页按 body_part 分组 + 搜索 + 筛选 sheet
│   │   └── ProfileTabView.swift     # 设置入口 + 关于入口
│   ├── Detail/
│   │   ├── ExerciseDetailView.swift # 详情页：双语标题 + GIF + 元数据 + 双语步骤 + 版权
│   │   ├── ShareSheet.swift          # 复制双语步骤 + 系统 ShareLink
│   │   └── PlanPickerSheet.swift     # 加入训练计划 picker（含查重）
│   ├── Plans/
│   │   ├── PlansView.swift          # 训练首页 + 计划模板编辑
│   │   ├── WorkoutSessionView.swift # 全屏训练、逐组编辑、休息 Overlay
│   │   └── WorkoutHistoryView.swift # 分页历史 + 摘要/只读详情
│   └── Settings/
│       ├── SettingsView.swift          # 语言说明 + 数据透明 + 致谢
│       └── AboutView.swift            # 关于作者：陈子超 + GitHub
├── Resources/                         # 空（数据由 folder ref 注入）
├── Info.plist
├── FitGuideTests/
    ├── AttributionTests.swift         # 版权硬约束 + 训练参考复用详情页
    ├── PerformanceTests.swift         # 资源性能 + 1000 条训练历史首屏
    └── WorkoutStoreTests.swift        # v2 训练领域层回归测试
└── FitGuideUITests/
    └── FitGuideUITests.swift          # v2 关键流程 + 无障碍 UI 回归测试
```

## 历史背景
- v1.0 是首个完整版本，从设计 brief → 任务拆分 → 20 个 build task + 版权硬约束测试 + 性能验证 全部完成。
- 设计 brief 见 `.design/fitness-app/DESIGN_BRIEF.md`
- 任务清单见 `.design/fitness-app/TASKS.md`
- v2 设计见 `.design/fitness-app/V2_DESIGN_BRIEF.md`，任务见 `.design/fitness-app/V2_TASKS.md`
- v2.0 开发与收尾在 `v2.0` 分支；不得改写 `v1.0` tag
- v1 升级采用兼容字段 + 启动回填。旧计划勾选状态保留，但不转换成训练历史
- 重装/换 AI 维护时，请先读 v2 design brief，并先运行完整测试

## 作者
- 陈子超 / HanaAyane
- GitHub: https://github.com/HanaAyane

## 当前版本
- v2.0（分支 `v2.0`，marketing version 2.0 / build 2）
