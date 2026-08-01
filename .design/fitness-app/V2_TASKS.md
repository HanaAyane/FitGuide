# FitGuide v2 Build Tasks

Generated from: `.design/fitness-app/V2_DESIGN_BRIEF.md`
Date: 2026-07-31
Target release: v2.0

## 使用方式

- 任务编号按依赖顺序排列，但同一阶段内无依赖的任务可以并行。
- 每项任务必须同时满足实现、测试和验收条件才可勾选。
- v2.0 只做训练闭环；搜索增强和指导内容分别进入 v2.1、v2.2。
- 任何任务都不得移除双语呈现、深空主题或 Gym visual 版权约束。

## Milestone 0：基线与工程准备

- [x] **V2-T0 同步 v2 开发基线**
  在 `v2.0` 分支完成开发基线准备，不改写 `v1.0` tag。

- [x] **V2-T1 修复 v1 阻塞性质量问题**
  先处理会妨碍 v2 开发的编译警告、明显状态错误和静默持久化失败路径。重点核对 `RootView` 未使用状态、`LibraryStore` 中的 `try?`、`TrainingPlanItem.completedAt` 在部分完成时被写入的问题。
  **Depends on**：V2-T0
  **Done**：项目无新增编译警告；保存失败有日志或可见错误；为修复项增加回归测试。

- [x] **V2-T2 建立 v2 测试夹具与测试辅助层**
  创建内存 SwiftData container、固定 Exercise fixture、固定 TrainingPlan fixture，以及 v1 schema 数据 fixture。测试不得依赖用户真实数据库。
  **Depends on**：V2-T0
  **Done**：单元测试可独立创建和销毁内存数据库；fixture 能构造空计划、完整计划、部分完成计划和大历史数据集。

## Milestone 1：数据模型与迁移

- [x] **V2-T3 定义并验证兼容 SwiftData Schema**
  使用显式 Schema 模型列表、可选新增列和启动回填完成轻量迁移；保留 v1 字段以兼容旧数据。
  **Depends on**：V2-T2
  **Done**：全新安装与 v1 数据库升级都能初始化；没有隐式破坏式迁移。

- [x] **V2-T4 新增 WorkoutSession 模型**
  增加 `id/sourcePlanId/planNameSnapshot/startedAt/endedAt/statusRaw/notes` 与到 `WorkoutExercise` 的 cascade 关系。状态只允许 `active/completed/abandoned`，通过类型安全枚举包装字符串。
  **Depends on**：V2-T3
  **Done**：模型关系、删除规则、状态编解码和非法状态回退均有测试。

- [x] **V2-T5 新增 WorkoutExercise 与 SetLog 模型**
  建立动作名称快照、顺序、计划组数、目标次数、休息秒数、跳过状态，以及逐组 `targetReps/actualReps/weightKg/completedAt/isWarmup`。
  **Depends on**：V2-T4
  **Done**：Session 删除能 cascade 清理子项；组顺序稳定；重量为空和 0 的规则明确且有测试。

- [x] **V2-T6 扩展计划模板字段**
  为 `TrainingPlan` 增加 `updatedAt`，为 `TrainingPlanItem` 增加默认休息时间；将 v1 `sets/reps` 继续解释为模板默认值。v2 不再使用 `setStatesRaw/completedAt` 作为训练状态。
  **Depends on**：V2-T3
  **Done**：旧计划升级后名称、动作、顺序、组数和次数完全保留；可编辑默认休息时间。

- [x] **V2-T7 实现并验证 v1 → v2 迁移**
  使用 v1 fixture 执行迁移；不将旧勾选状态伪造为历史，不删除旧字段内容。
  **Depends on**：V2-T4、V2-T5、V2-T6
  **Done**：迁移前后旧收藏表、计划数、计划项顺序和参数一致；收藏 UI 已移除，测试覆盖空库、常规库和部分完成计划。

## Milestone 2：训练领域层

- [x] **V2-T8 创建 WorkoutMetrics 纯函数**
  集中计算训练时长、计划组数、完成组数、总次数、总训练量和完成动作数。使用 `Decimal` 或清晰的 Double 格式化策略避免展示漂移。
  **Depends on**：V2-T5
  **Done**：测试覆盖空训练、无重量、部分完成、跳过动作、热身组、小数重量和未结束训练。

- [x] **V2-T9 创建 ActiveWorkoutStore**
  负责 Session 生命周期、当前动作/组导航、SwiftData 保存和用户可见错误。禁止 View 直接实现跨模型写入。
  **Depends on**：V2-T7、V2-T8
  **Done**：Store 可在内存测试中创建、查询、恢复和持久化 Session；保存错误不会被静默吞掉。

- [x] **V2-T10 从计划创建训练快照**
  将计划及计划项复制成独立 Session、WorkoutExercise 和 SetLog；后续修改计划不得影响 Session。空计划不可开始。
  **Depends on**：V2-T9
  **Done**：快照顺序、名称、组数、次数和休息时间正确；修改或删除源计划后，进行中训练仍完整。

- [x] **V2-T11 创建自由训练**
  支持创建没有 sourcePlanId 的空 Session，搜索并添加动作，每个动作默认 3×12；支持删除未完成动作和调整顺序。
  **Depends on**：V2-T9
  **Done**：自由训练能完成并作为普通历史保存；同一动作的重复添加规则有明确产品行为和测试。

- [x] **V2-T12 实现组记录操作**
  支持完成、撤销、编辑重量与实际次数；默认继承上一组重量，实际次数默认目标次数；每次变更立即保存。
  **Depends on**：V2-T9、V2-T10
  **Done**：完成组只需一个主按钮；撤销后统计实时回退；杀掉并重启 App 后已完成数据不丢失。

- [x] **V2-T13 实现训练状态机**
  明确定义 active → completed / abandoned；completed 和 abandoned 不可继续写组记录。处理多个 active Session 的异常恢复。
  **Depends on**：V2-T9、V2-T12
  **Done**：所有合法与非法状态转换有测试；异常多 active 时保留最新记录并安全处理其余记录。

## Milestone 3：训练首页与计划体验

- [x] **V2-T14 重构 Training Tab 首页**
  组合“继续训练、快速开始、训练计划、最近训练、历史入口”。保留 v1 计划创建与编辑能力。
  **Depends on**：V2-T10、V2-T11、V2-T13
  **Done**：无数据、仅计划、有进行中训练和有历史四种状态均有完整 UI；进行中训练始终置顶。

- [x] **V2-T15 分离计划编辑与计划执行**
  `PlanEditorView` 只编辑模板，不再显示或写入永久完成圆点；增加明显的“开始训练”入口。
  **Depends on**：V2-T6、V2-T10、V2-T14
  **Done**：完成训练后回到计划，模板组数和次数不变；同一计划可连续开始多次训练。

- [x] **V2-T16 完善计划编辑器**
  支持调整动作顺序、组数、次数和默认休息时间；删除动作或计划时二次确认。
  **Depends on**：V2-T15
  **Done**：所有编辑均持久化且排序稳定；正在进行的 Session 不受计划编辑影响。

## Milestone 4：全屏训练模式

- [x] **V2-T17 搭建 WorkoutSessionView**
  创建全屏训练容器、顶部退出/结束入口、动作分页或顺序导航、当前训练进度和错误展示。训练时隐藏底部 Tab。
  **Depends on**：V2-T12、V2-T14
  **Done**：可从计划和自由训练进入；退出后 Session 保持 active；重新进入恢复到合理的当前组。

- [x] **V2-T18 创建 CurrentExerciseWorkoutCard**
  展示中英动作名、当前组、目标次数、重量、实际次数、大触控完成按钮，并提供 GIF/步骤入口。
  **Depends on**：V2-T17
  **Done**：完成一组 1 次点击；修改数据最多 2 次点击；数字使用等宽字体且支持 Dynamic Type。

- [x] **V2-T19 实现动作与组导航**
  支持上一/下一动作、跳过动作、定位首个未完成组以及查看已完成组。禁止导航造成数据丢失。
  **Depends on**：V2-T18
  **Done**：首尾边界、全部完成、部分跳过和撤销完成均有测试或 UI 流程覆盖。

- [x] **V2-T20 复用详情与 GIF 能力**
  在训练模式中提供轻量动作参考，不复制一套详情逻辑；保持双语步骤和 AttributionFooter 可访问。只加载当前动作 GIF。
  **Depends on**：V2-T18
  **Done**：训练中两次点击内看到动作步骤；GIF 离开后释放或复用；版权入口仍存在且测试通过。

## Milestone 5：休息计时与生命周期

- [x] **V2-T21 创建 RestTimerStore**
  使用目标结束时间而非每秒持久化；支持开始、暂停、跳过、`+15s` 和恢复。默认 90 秒，计划项可覆盖。
  **Depends on**：V2-T12
  **Done**：时钟推进、后台跨时、暂停与延长均使用可注入 Clock 测试，不依赖真实等待。

- [x] **V2-T22 实现 RestTimerOverlay**
  完成组后自动展示不阻塞导航的计时器；提供剩余时间、下一组信息和快捷操作。
  **Depends on**：V2-T18、V2-T21
  **Done**：计时器不遮挡退出和结束；VoiceOver 正确朗读；Reduce Motion 下无跳变动画。

- [x] **V2-T23 处理 App 生命周期与恢复**
  App 进入后台时保存 Session；回到前台时根据结束时间恢复计时；冷启动查询 active Session 并在训练首页显示继续卡片。
  **Depends on**：V2-T13、V2-T21、V2-T22
  **Done**：前后台切换、强制终止后重启和系统时间正常变化场景通过手工与自动测试。

- [x] **V2-T24 增加计时结束反馈**
  提供触觉与可选声音反馈，尊重系统设置；若需要通知权限，只在用户明确开启后台提醒时请求。
  **Depends on**：V2-T22、V2-T23
  **Done**：无权限时训练流程不受影响；设置项和实际行为一致。

## Milestone 6：完成、摘要与历史

- [x] **V2-T25 实现结束与放弃训练流程**
  结束前提示未完成组；允许继续训练或确认结束。放弃训练需二次确认并标记 abandoned，不伪装成 completed。
  **Depends on**：V2-T13、V2-T19
  **Done**：结束时间只写一次；结束后不可继续修改；放弃记录不进入默认完成历史。

- [x] **V2-T26 创建 WorkoutSummaryView**
  使用 WorkoutMetrics 展示时长、动作数、完成组、总次数、总训练量和动作明细。
  **Depends on**：V2-T8、V2-T25
  **Done**：所有数值与持久化 SetLog 一致；无重量训练不显示误导性的 0 kg 训练量。

- [x] **V2-T27 创建 WorkoutHistoryView**
  按日期倒序分页展示已完成训练，提供空状态和历史详情入口。
  **Depends on**：V2-T25、V2-T26
  **Done**：1000 次训练 fixture 下首屏查询满足性能目标；不会一次加载全部 SetLog。

- [x] **V2-T28 创建只读历史详情**
  展示 Session 名称快照、时间、统计、动作与逐组数据；Bundle 中动作仍存在时可跳转详情。
  **Depends on**：V2-T27
  **Done**：源计划或动作数据变化后历史仍可读；不存在当前动作资源时优雅显示名称快照。

- [x] **V2-T29 历史删除与数据说明**
  删除历史需二次确认并 cascade 清理子记录；设置页更新本地训练数据说明。
  **Depends on**：V2-T27、V2-T28
  **Done**：删除目标明确、不可误删计划；设置页说明数据仅保存在本机。

## Milestone 7：质量、无障碍与发布

- [x] **V2-T30 领域层完整测试**
  覆盖 Schema 迁移、Session 快照、状态机、组记录、统计和计时器。
  **Depends on**：V2-T7、V2-T13、V2-T21、V2-T26
  **Done**：核心领域逻辑不依赖 UI 测试即可验证；失败信息能定位具体规则。

- [ ] **V2-T31 关键 UI 流程测试（最终回归待重跑）**
  覆盖从计划开始、自由训练、后台恢复、结束、放弃和历史回看。
  **Depends on**：V2-T23、V2-T28
  **Done**：六条流程在目标模拟器稳定通过；测试使用固定 fixture。

- [ ] **V2-T32 无障碍走查（自动审计与字号矩阵已通过，手动 VoiceOver 待完成）**
  使用 VoiceOver、AX1–AX5、Reduce Motion 和不同对比度设置遍历训练首页、训练模式、计时器、摘要和历史。
  **Depends on**：V2-T22、V2-T26、V2-T28
  **Done**：无裁切、无只依赖颜色的状态、所有操作具有明确 label/hint。

- [ ] **V2-T33 性能与稳定性验证（自动基准已通过，真机内存走查待完成）**
  测量进入训练、完成组、恢复训练、历史首屏和当前动作 GIF 内存。执行长历史数据压力测试。
  **Depends on**：V2-T27、V2-T30
  **Done**：满足设计 brief 性能目标；无明显内存持续增长；保存失败路径可恢复。

- [ ] **V2-T34 版权与双语最终复核（最终回归待完成）**
  扩展 AttributionTests，确认训练模式的动作参考仍能访问 Gym visual 署名；检查所有新增用户界面保持中英并列。
  **Depends on**：V2-T20、V2-T32
  **Done**：移除版权入口会导致测试失败；新增页面无单语核心信息。

- [ ] **V2-T35 真机试用与缺陷收敛**
  在真实设备完成至少 3 次完整训练，记录现场操作摩擦、误触、计时和数据问题，并修复 P0/P1 缺陷。
  **Depends on**：V2-T31、V2-T32、V2-T33、V2-T34
  **Done**：3 次训练均可从开始走到历史；无数据丢失；未解决问题有明确降级或延期说明。

- [ ] **V2-T36 发布文档与版本更新（待 T35 后定稿）**
  更新 README、AGENTS.md、版本号、数据模型说明、构建命令和已知限制；生成 v2.0 release notes。
  **Depends on**：V2-T35
  **Done**：文档与实际功能一致；新维护者可按文档构建、测试并理解迁移策略。

## v2.1 Backlog：现场效率

- [ ] **V2.1-T1 SearchNormalizer**：统一空白、大小写、重音和中文拼音标准化。
- [ ] **V2.1-T2 本地别名表**：为常见动作名维护经审核的中英别名。
- [ ] **V2.1-T3 搜索与筛选组合**：同一结果管线同时应用 query 和多维筛选。
- [ ] **V2.1-T4 替代动作**：按 target/bodyPart/muscleGroup/equipment 确定性排序。
- [ ] **V2.1-T5 计划复制**：复制计划并安全生成独立项目。
- [ ] **V2.1-T6 自由训练另存为计划**：从 Session 生成模板，不携带完成状态和实际重量。
- [ ] **V2.1-T7 CSV 导出**：导出训练与逐组数据，包含字段说明与单位。

## v2.2 Backlog：指导增强

- [ ] **V2.2-T1 指导覆盖层 Schema**：定义 cues、commonMistakes、difficulty、aliases 和审核元数据。
- [ ] **V2.2-T2 内容校验脚本**：检查 exerciseId、双语配对、空内容、审核日期和来源说明。
- [ ] **V2.2-T3 详情页指导卡**：仅在存在经审核内容时显示。
- [ ] **V2.2-T4 指导内容可访问性与免责声明**：确保 VoiceOver、Dynamic Type 和来源说明完整。
- [ ] **V2.2-T5 Widget / App Intents**：快速继续训练或开始计划，不暴露敏感训练明细。

## 建议并行分组

在依赖满足后，可按以下工作流并行：

- **数据与领域层**：V2-T3～V2-T13
- **训练首页与计划**：V2-T14～V2-T16
- **训练模式**：V2-T17～V2-T20
- **计时与生命周期**：V2-T21～V2-T24
- **历史与摘要**：V2-T25～V2-T29
- **质量与发布**：V2-T30～V2-T36
