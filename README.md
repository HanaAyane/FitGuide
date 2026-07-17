# FitGuide · 健身动作指导

一个 iOS SwiftUI 健身动作字典：1324 个动作内置离线可用，中英双语始终并排显示，深空 + Apple 液态玻璃美学。仅个人/作品集使用。

## 截图

进入模拟器后：深空漂光背景 + 玻璃卡片悬浮；首页按身体部位分组；详情页 GIF 循环 + 双语编号步骤 + 元数据卡 + 版权页脚。

## 作者

- HanaAyane
- GitHub: https://github.com/HanaAyane

## v1.0 功能

- 1324 动作本地 Bundle（无后端，离线可用）
- 双语始终并排：中文为主，英文 small caps 副标，步骤区 zh 上 en 下
- Liquid Glass 双路径：iOS 26 走原生 `.glassEffect()`，iOS 18 走 `.ultraThinMaterial` + 高光描边回退
- 4 个 Tab：动作 / 训练 / 收藏 / 我的
- 首页按身体部位分组（中文训练惯例排序：胸→背→肩→上臂→大腿→小腿→腰腹→前臂→有氧→颈）
- 双语搜索：同时匹配动作名（中英）+ target + muscleGroup + equipment + bodyPart（中英两版）
- 筛选：FlowLayout 自适应换行 chip，三维度多选（部位/器械/目标肌群）
- 收藏：多自定义列表 + 默认收藏 + 最近看过（自动 20 条）
- 训练计划 TodoList：每组圆点切换完成，全部完成自动归入已完成段；支持重置
- 分享：系统 ShareLink + 一键复制双语步骤
- 设置 + 关于页（作者信息）
- 版权硬约束：© Gym visual 致谢在详情/设置/关于强制展示，AttributionTests 3 个测试断言不可移除

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

含两组测试：
- `AttributionTests` — 版权硬约束（不可移除 © Gym visual）
- `PerformanceTests` — 性能基准（冷启动 168ms / JSON 解码 151ms / 搜索 19ms / GIF 首帧 <1ms）

## 给维护此项目的 AI

见 [AGENTS.md](AGENTS.md)。设计 brief 见 `.design/fitness-app/DESIGN_BRIEF.md`，任务清单见 `.design/fitness-app/TASKS.md`。

## 版本

- v1.0（git tag `v1.0`）— 首个完整版本
- v2 在 `v2-development` 分支开发

## 许可

代码 MIT。媒体（图片/GIF/数据集）© Gym visual — https://gymvisual.com/，按其条款使用。