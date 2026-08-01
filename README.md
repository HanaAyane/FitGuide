# FitGuide · 健身动作指导

一个 iOS SwiftUI 健身动作字典：1324 个动作内置离线可用，中英双语始终并排显示，深空 + Apple 液态玻璃美学。仅个人/作品集使用。

## 截图

进入模拟器后：深空漂光背景 + 玻璃卡片悬浮；首页按身体部位分组；详情页 GIF 循环 + 双语编号步骤 + 元数据卡 + 版权页脚。

## 作者

- HanaAyane
- GitHub: https://github.com/HanaAyane

## v2.0 功能

- 1324 动作本地 Bundle（无后端，离线可用）
- 双语始终并排：中文为主，英文 small caps 副标，步骤区 zh 上 en 下
- Liquid Glass 双路径：iOS 26 走原生 `.glassEffect()`，iOS 18 走 `.ultraThinMaterial` + 高光描边回退
- 3 个 Tab：动作 / 训练 / 我的
- 首页按身体部位分组（中文训练惯例排序：胸→背→肩→上臂→大腿→小腿→腰腹→前臂→有氧→颈）
- 双语搜索：同时匹配动作名（中英）+ target + muscleGroup + equipment + bodyPart（中英两版）
- 筛选：FlowLayout 自适应换行 chip，三维度多选（部位/器械/目标肌群）
- 最近看过：自动保留最近 20 个动作
- 训练计划：作为可重复使用的模板，支持动作排序、组数、次数和休息时间
- 训练模式：从计划或自由训练开始，逐组记录重量/次数，支持撤销、跳过和动作导航
- 休息计时：自动开始、暂停、继续、跳过、`+15s`，前后台切换后按目标结束时间恢复
- 训练历史：保存动作与参数快照、训练摘要、逐组明细，按 30 条分页加载并可删除
- 数据迁移：保留 v1 旧收藏表以安全升级，但不再展示或写入；最近浏览和计划继续可用，旧版勾选状态不会伪造成训练历史
- 分享：系统 ShareLink + 一键复制双语步骤
- 设置 + 关于页（作者信息）
- 版权硬约束：© Gym visual 致谢在详情/设置/关于强制展示，训练中的动作参考复用详情页

## 构建前准备

数据集不在本仓库内（含 © Gym visual 媒体，不能公开分发）。需将 `exercises-dataset/` 放到与本工程同级目录：

```
健身动作指导/
├── exercises-dataset/       # 数据集（含 data/exercises.json, images/, videos/）
└── FitGuide/                # 本工程
```

## 构建

```bash
brew install xcodegen                    # 一次性
cd FitGuide
rm -rf FitGuide.xcodeproj && xcodegen generate
xcodebuild -project FitGuide.xcodeproj -scheme FitGuide -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 跑测试

```bash
xcodebuild -project FitGuide.xcodeproj -scheme FitGuide -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

含四组测试：

- `AttributionTests` — 版权硬约束（不可移除 © Gym visual）
- `PerformanceTests` — 资源性能与 1000 条训练历史首屏查询
- `WorkoutStoreTests` — 快照、状态机、逐组记录、计时、迁移默认值、历史分页与删除
- `FitGuideUITests` — 计划/自由训练、恢复、结束、放弃、历史与无障碍关键流程

## v1 → v2 数据策略

v2 在同一个本地 SwiftData store 中增加训练历史模型。新增计划字段使用可选持久化列，启动后补齐默认值，因此已有 v1 数据可以轻量迁移；旧 `FavoriteList/FavoriteItem` 表保留在 schema 中，仅为兼容既有数据库，应用不再展示或写入收藏。旧 `setStatesRaw/completedAt` 字段同样仅为兼容保留，v2 训练执行只写入 `WorkoutSession / WorkoutExercise / SetLog`。

所有训练数据仍只保存在本机。删除 App 或系统清除数据后无法恢复，当前版本不提供云同步、导出、后台通知或跨设备同步。

## 给维护此项目的 AI

见 [AGENTS.md](AGENTS.md)。v2 设计 brief 见 `.design/fitness-app/V2_DESIGN_BRIEF.md`，任务清单见 `.design/fitness-app/V2_TASKS.md`。

## 版本

- v1.0（git tag `v1.0`）— 首个完整版本
- v2.0 — 完整训练闭环，开发分支为 `v2.0`

发布说明见 [RELEASE_NOTES_V2.0.md](RELEASE_NOTES_V2.0.md)。

## 许可

代码 MIT。媒体（图片/GIF/数据集）© Gym visual — https://gymvisual.com/，按其条款使用。
