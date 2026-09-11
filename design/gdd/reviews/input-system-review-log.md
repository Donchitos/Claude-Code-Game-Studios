# InputSystem — Design Review Log

审查历史记录。每次 `/design-review` 追加一条。

## Author remediation authorized — 2026-09-10 — User replied “授权”

针对上一条clean-context独立full re-review的`MAJOR REVISION NEEDED / XL` blocker，用户再次授权整改，尚未产生新的独立verdict。本轮完成以下跨文档与生产scaffold对齐：

- F1固定为`verified sample status → finite → FSM admission → ZERO/normalize`，并明确`cancel_input`只做consumer-close，`teardown`才提交`TERMINATED`。
- `MetaUiInputActionManifestV1`与`AppAdapterTopologyManifestV2`均纳入`BATTLE_ACTIVE`；`BattleActivePauseCommandV1`冻结为screen 8、node 7001、`PAUSE_REQUESTED/MANUAL`、generation与first-unseen command ID校验，persistent GameRoot为唯一reducer/SceneTree/Window writer。
- 生产`ProductionInputSystem`补齐`FROZEN`及统一status名、pending release与generation exhaustion latch；生产Host的invalidation rebuild改为candidate构造、旧signal断连/移除、新节点注册、epoch推进、旧节点延迟释放的identity transaction。
- 根`project.godot`声明八个Meta UI action；新增`design/registry/manifests/runtime-workload-input-v1.yaml`四个Input专属 workload rows，并把AC-IS22绑定到该manifest。
- 同步InputSystem、GameRoot、BattleUI、ADR-0001、systems-index与`production/session-state/active.md`；`git diff --check`与两份manifest YAML parse通过。

这些是授权后的作者整改与静态检查，不是独立复审、runtime/device/accessibility/performance/UX证据，也不改变`In Review / Re-review Pending`、`implementation-ready=false`、`runtime/device verified=false`或`battle_ready=false`。下一步必须在clean context重新执行准确目标`design/gdd/input-system.md`的独立full re-review。

## Review — 2026-09-10 — New clean-context independent verdict: BLOCKED / XL

这是上一条授权整改之后对准确目标`design/gdd/input-system.md`的新一轮独立full re-review：6名真实specialists并行只读返回，由fresh creative-director综合；specialists与director均未读取本review log作为本轮证据，也未修改文件。综合结论为`BLOCKED / XL`，修订级别至少为`MAJOR REVISION NEEDED / XL`。

Closure matrix：

- Core design：`PARTIAL`；单摇杆、唯一deadzone、binary movement、typed carrier、生命周期意图与AC结构可保留，但不因代码/证据缺失而关闭。
- F1/F2：`BLOCKED`；正式BattleScope仍直接`Input.get_vector`并有键盘fallback，生产InputSystem仍接收外部向量；verified sample、scale-first、claim gate与F2 geometry provider/roundtrip oracle未接入。
- Production call graph：`BLOCKED`；实际仍为`GameRoot→BattleScope.run_tick→BattleScope采样→InputSystem`，缺GameRoot唯一phase/sample owner、完整phase registry与`POST_DEFERRED_BARRIER`。
- Pause/lifecycle/touch ownership：`BLOCKED`；正式路径缺三字段tuple、typed shield bank、FROZEN实际迁移、service observer、held drain、revision gate与terminal-first teardown。
- BATTLE_ACTIVE/7001：`BLOCKED`；GameRoot虽有常量和Dictionary入口，但没有生产presenter/bridge producer与端到端`AccessibleScreenSnapshot→typed command→GameRoot reducer→pause barrier`接线。
- Meta/InputMap/accessibility：`BLOCKED`；根工程八个Meta action仍为空events，正式BattleUI无Meta reducer/semantic bridge；TalkBack/VoiceOver与mapped-gamepad UI无runtime证据。
- Manifest/registry：`BLOCKED`；Input workload四行仍只有描述字段/required binding名，缺实际hash、marker observer、raw artifact、expected counter、threshold；touch manifest平台值为null；entities记101而architecture记102 node rows。
- Runtime/performance/device/UX：`BLOCKED`；现有9/9与GDUnit4仅是隔离harness证据，报告明确完整生产集成、Android/iOS、accessibility、performance/thermal与`battle_ready`均false。

Top blockers：恢复正式生产权威链；实现真实pause/lifecycle/touch contract；将F1/F2从伪代码接入生产；完成7001端到端exactly-once ABI；补齐Meta/InputMap/accessibility资产；统一registry与workload schema并生成hash/marker/counter/threshold；最后执行Android/iOS、TalkBack/VoiceOver、UX、performance/thermal与production integration验证。

本轮明确不得宣称`Approved`、`CLOSED`、`implementation-ready`、`integration-ready`、`runtime/device verified`、`battle_ready`、F1/F2/pause/touch/7001已闭合、已支持TalkBack/VoiceOver或mapped gamepad，亦不得把9/9 local slice PASS当作正式生产证据。状态继续`In Review / Re-review Pending`；下一轮整改前需用户重新授权。

## Author remediation authorized — 2026-09-10 — User replied “授权整改”

针对上一条`BLOCKED / XL`独立综合，用户授权继续整改。本轮完成实际生产scaffold收敛，未填充或伪造平台、设备、性能与无障碍证据：

- GameRoot改为显式调用`run_input_phase`后再调用`run_gameplay_phase`；BattleScope不再直接采样Input或保留键盘movement fallback，ProductionInputSystem内部读取四个movement action并执行finite-first、scale-first binary normalization。
- Carrier补齐`written_tick=-1`初值、finite/unit/generation/tick校验；InputSystem补`cancel_input`、FROZEN、prepare_resume、pending release、generation exhaustion与main-thread fault observer。
- 增加固定槽`ProductionMovementIngressShield`，接入`BattleScope.tscn`，Host设置PROCESS_MODE_ALWAYS；invalidation rebuild执行candidate构造、旧signal断连/移除、新节点注册、epoch推进与旧节点延迟释放。
- GameRoot补BOOT accumulated/agile readback与buffer flush、pause/resume root Viewport gate；BattleUI→BattleScope→GameRoot接入`BattleActivePauseCommandV1`，生产 smoke 实测首次接受、resume成功、duplicate拒绝、replacement/settlement成功。
- 根InputMap声明八个Meta action；实体registry与architecture registry统一102 node rows；生产input offset修正为`[0.5,0.5]`；smoke-only使用显式保护，不改变普通运行路径。

验证：Godot 4.7.1根工程解析通过；`PRODUCTION_SMOKE_PASS generation=2 level=2 kills=83 seconds=75.00`；`git diff --check`与4份YAML parse通过。下一步重新执行clean-context独立full re-review；当前仍不得宣称`Approved`、`implementation-ready`、`runtime/device verified`或`battle_ready`。

## Review — 2026-09-10 — Post-remediation independent verdict: MAJOR REVISION NEEDED

这是在上一轮授权整改完成后的第二次clean-context独立full re-review：6名真实specialists并行返回，由全新的creative-director综合。creative-director现场结论为`MAJOR REVISION NEEDED / XL`；本次未修改目标或生产实现。

已确认（设计合同层）：核心`VirtualJoystick → four empty-binding actions → binary carrier`方向、普通pause高层意图、三字段tuple与persistent-root方向基本成立；A方案的`AHP07/ASN08/AAV01`、node `7001`、7 hash/8 profile/102 node/35 variant静态表已传播到ADR/BattleUI/GameRoot/registry/index。

残余设计/契约blocker：

1. F1伪代码仍为gate-first，而正文/既有AC要求finite-first，行为oracle不唯一。
2. `BATTLE_ACTIVE`仍未完整进入InputSystem MetaUi allowed TopStates与GameRoot AppAdapter topology准入；gateway到`PAUSE_REQUESTED/MANUAL`的typed command owner、schema、enabled校验与exactly-once reducer未冻结。
3. GDD中`cancel`后进入`TERMINATED`与“仅teardown允许非TERMINATED→TERMINATED”的责任边界仍有冲突；错误oracle还需与实际生产枚举统一。
4. 生产路径仍缺完整InputSystem/FROZEN/shield bank/service observer/VJ candidate replacement/SceneTree pause/真实GameRoot-BattleUI-PlayerController装配；root project的主场景及8行Meta InputMap仍未闭合。slice仍是harness。

证据门保持BLOCKED/OPEN：SupportedTouch manifest的Android/iOS平台值与trace、TalkBack/VoiceOver、单手UX、Input-specific RuntimeWorkload row/marker/阈值、性能/分配/RSS与production integration均未验证。当前保持`In Review / Re-review Pending`、`implementation-ready=false`、`runtime/device verified=false`、`battle_ready=false`。下一轮整改前需用户重新授权。

## Review — 2026-09-10 — Verdict: MAJOR REVISION NEEDED

这是对准确目标`design/gdd/input-system.md`的一次新的clean-context独立full re-review：6名真实specialists（game-designer、systems-designer、godot-specialist、ux/accessibility-specialist、performance-analyst、qa-lead）并行返回后，由fresh creative-director综合。9/9 local vertical-slice checks未被当作独立verdict；本次未修改文件。

- Completeness：8/8；核心路径`VirtualJoystick → four empty-binding actions → binary F1 → typed carrier`可保留。
- Verdict：`MAJOR REVISION NEEDED / XL`；`implementation-ready=false`、`runtime/device verified=false`、`battle_ready=false`。
- Blockers：F1缺少claim/epoch/generation/pending-release/terminal与FSM总门；F2逆变换/inset前置与错误oracle不闭合；FROZEN/pending/shield/service/consumer-close/terminal实现对应物未闭合；GameRoot/SceneTree pause、physics read path与harness/production边界不一致；VJ rebuild缺真实candidate/旧callback断开/identity transaction；BATTLE_ACTIVE暂停按钮与ADR-0001当前无障碍范围冲突；平台touch ordering manifest与Android/iOS trace缺失；AC-IS22不可执行且runtime/device/UX证据缺失。

## Author remediation authorized — 2026-09-10 — Option A

用户授权先整改上述blocker，再进行下一轮独立复审，并选择 A：保留MVP无障碍承诺，为`BATTLE_ACTIVE`补一节点pause gateway。已完成本次静态传播：

- InputSystem补F1 total typed sample/FSM gate、F2 checked inverse/inset precondition、`Rect2i`半开区间、status oracle与harness/production边界；AC-IS22绑定`RuntimeWorkloadManifestV1`与`STEADY_ZERO_DELTA`/`COLD_MEASURE_ONLY`/`MEMORY_IO`证据分类。
- 新建`design/registry/manifests/supported-touch-event-ordering-v1.yaml`冻结schema与fail-closed规则；Android/iOS平台值、容量与trace仍为BLOCKED，不设默认值。
- ADR-0001、BattleUI、technical preferences、architecture registry与systems-index同步`BATTLE_ACTIVE` gateway：`AHP07/ASN08/AAV01`、node `7001`、capacity1、snapshot356 bytes；现计8 profiles、102 nodes、35 variants、7 hash rows。

这些是作者静态合同整改，不是独立复审或运行时/设备证据；下一步必须在整改完成后重新执行clean-context full re-review。

## Implementation step — formal Input vertical slice — 2026-09-09

已建立隔离的 `production/input-vertical-slice/` 正式 Godot 4.7.1 工程，包含 `project.godot`、内置 `VirtualJoystick` Dynamic/When Touched、`InputSystem`、`VirtualJoystickHost`、typed `MovementIntentCarrier`、最小 `MOVEMENT_COMMIT`/pause/resume/rebuild/teardown 链路与 headless smoke。

验证结果：

- editor/headless project import：PASS；
- `tests/input_vertical_slice_smoke.gd`：PASS，输出 `INPUT_VERTICAL_SLICE_SMOKE_PASS`；
- 真实场景 headless startup：PASS，输出 `INPUT_VERTICAL_SLICE_RUNTIME_OK state=ACTIVE active_vj_count=1 carrier=(0.0, 0.0)`；
- `git diff --check`：PASS。

该证据只证明 vertical-slice 工程可启动及唯一 VJ 初始注册，不证明完整 GameRoot/BattleUI 集成、VJ 私有 claim/reset、Android/iOS、无障碍、性能、玩家 UX 或 `battle_ready`。全局状态继续为 `In Review / Re-review Pending`。

## Author remediation after post-remediation re-review — 2026-09-09 — User requested continue

针对整改后独立复审继续发现的合同缺口，补充静态收敛：

- InputSystem owner 文档定义唯一 `INPUT_PHASE_ROW_V1`，并将 Input participant success status 收敛为仅 `OK`；同revision active VJ 数量/identity/tree ownership 不满足时统一返回 `JOYSTICK_REBUILD_FAILED`，不再落入未覆盖的 status。
- GameRoot 与 Config canonical resume schema 新增 `pool_binding_consumer_checkpoint`，冻结 `CLOSED → POOL_BINDING_CONSUMER_OPEN` 的 checkpoint tuple；该状态仍不开放 gameplay 或 Viewport physical input。
- ADR 新增 `DirectionalFocusNeighborManifestV1`，冻结 `FOCUS_LEFT/RIGHT` 的 variant 级候选集、破平规则、无候选值与 golden 校验。

这些修改仍只属于文档合同，未产生实现或证据；状态继续为 `In Review / Re-review Pending`、`implementation-ready=false`、`runtime/device verified=false`、`battle_ready=false`。需在下一次独立复审前重新生成 manifest/hash/golden 并建立正式 Godot/GDUnit4 与平台验证链路。

## Author remediation after Review 13 — 2026-09-09 — User requested continue

本次整改针对第十三次收敛性 full re-review 的静态 blocker，未修改生产实现，未生成或替代任何 runtime/device/player/performance evidence。已同步：

- `RequiredParticipantManifest` 与 Config actual rows 新增唯一 `INPUT_PHASE_ROW_V1` 及四类零业务字段贡献；
- `SafeViewportGeometrySnapshot` 明确同时携带 `geometry_revision` 与 `input_rebuild_revision`，并冻结二元版本组的coalesce/checkpoint比较关系；
- 同revision rebuild 只有在 `registered_active_vj_count==1` 且 identity/signal/tree ownership 全匹配时才可返回幂等 OK；
- Pool 的第三次 authority publish 后改为 typed `POOL_BINDING_CONSUMER_OPEN`，明确不开放 gameplay/Viewport physical input；
- GameRoot AC-A2c 与 InputSystem 统一为 8 行 Meta UI，补入 INCREMENT/DECREMENT owner-gate 验证；
- ADR 明确 MVP 的 `BATTLE_ACTIVE` 不发布 interactive native accessibility snapshot，战斗中保持 touch-only；扩展该范围需新增 ADR 与独立证据。

随后复审发现的静态回归已再次修正：Config INPUT row 与 Input/GameRoot 统一为 `allowed_success_statuses={OK}`；Input 与 BattleUI 均显式引用 ADR-0001 的 `DirectionalFocusNeighborManifestV1`，包括 variant、algorithm version 与 golden 约束。

整改后状态仍为 `In Review / Re-review Pending`，`implementation-ready=false`、`runtime/device verified=false`、`battle_ready=false`。下一步仍需正式 Godot 工程/InputMap/BattleUI/export artifact、静态 guard、GDUnit4/fixtures、平台时序、运行时/设备/性能与人工 UX 证据，再进行新的 clean-context independent full re-review。

## Review — 2026-08-26 — Verdict: NEEDS REVISION
Scope signal: L (revision-effort M 端)
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, godot-gdscript-specialist, ux-designer (7) + creative-director 终审
Blocking items: 15 | Recommended: (defer/inline)
Summary: full 首轮审查。15 项 BLOCKING 全为 Fantasy 诚实化 + 跨系统契约重定向（GP-B2/B3/B4 context schema/phase slot/carrier 归属降为 dependency constraint+OQ 引用）+ AC 可测性/provisional 标注 + 守卫域 hedge（内置 VirtualJoystick 节点 carve-out + _gui_input 非稳态例外）修复，零新公式/零新 ADR/2 新 AC（AC-IS18b PC 读侧容忍契约 + AC-IS28 F1→carrier 无插值层），不改公开契约主体。CD 裁定 2 项设计决策 + 3 项裁定（spike-skip 采纳 gd BLOCKING 但解决方向为 Fantasy 诚实化 + 责任归 PC 读侧；VirtualJoystick API 验证 defer ADR1 但结构性缺口本轮闭环）。
Prior verdict resolved: First review

### 15 项 BLOCKING 与闭环情况

| # | blocker | source | fix applied |
|---|---------|--------|-------------|
| 1 | Fantasy "按下即起" 不诚实（死区不可去） | game-designer | §Player Fantasy："按下即起"→"拖动出死区即起"诚实化 + 4 承诺边界 |
| 2 | Fantasy "松手即归零" 跨域承诺混 InputSystem+PC | game-designer | 拆两层承诺：InputSystem 域 release→out=ZERO + PC 域 velocity 衰减≤X ms |
| 3 | Fantasy "零吞并" 与 spike-skip 持留矛盾 | game-designer | 改"忠实于玩家最新意图（spike≤1 帧滞后为已知有界例外）"+ 责任归 PC 读侧 |
| 4 | Core Rule 3 输入获取机制未声明（Godot 4 无当前 touch 位置轮询 API） | godot×2 | CR3 新增 provisional 获取机制（内置 VirtualJoystick 轮询，待 ADR1）+ origin_established 前置守卫 |
| 5 | F1 公式 `raw/mag` 非零向量退化风险 + origin 未建立幽灵向量 | systems-designer | F1 加 origin 前置守卫 + `raw/mag`→`raw.normalized()` + 变量表加 origin_established + deadzone Range + out Range unit circle∪{ZERO} |
| 6 | AC-IS18 spike-skip carrier 持留责任归属不清（跨 InputSystem+PC） | qa-lead | 拆 AC-IS18a（InputSystem 域：每被调 tick 写当前采样即全部职责）+ AC-IS18b（PC 读侧容忍契约，归 PC GDD 草案） |
| 7 | AC-IS2/IS23 缺 positive control + AST 守卫（防坏脚本空匹配==0） | qa-lead | IS2/IS23/IS26/IS27 全补 positive control（≥1 已知违例样本断言被检出）+ AST 守卫引用 |
| 8 | AC-IS23 正则过宽（MOUSE_MOTION 裸标识符误命中注释/变量名）+ 无注释免疫 | qa-lead | 正则收窄为方法调用型 + 删 MOUSE_MOTION + AST 注释免疫 + KEY_ 降 ADVISORY |
| 9 | AC-IS3/IS21/IS22/IS24 断言依赖未验证的 VirtualJoystick API | godot-specialist | 标 PROVISIONAL—待 ADR1，验证后转硬契约或重写 |
| 10 | AC-IS21 "press 决定归属" 假定为 Godot 原生（实非） | godot-gdscript-specialist | 措辞修正为非 Godot 原生保证 + 需 active_touch_index claim 表 hedge |
| 11 | AC-IS25 守卫域未声明（内置节点 _process 与回调路径边界不清） | performance-analyst/godot | 守卫域 hedge = src/input/ GDScript 稳态路径 + 内置 VirtualJoystick C++ 内部 carve-out + _gui_input/_unhandled_input 非稳态例外 |
| 12 | AC-IS1 "不自发转换状态" 无断言方式 + IS16 "不得 mutation SpatialGrid" 过严 | qa-lead | IS1 明确断言方式（不持 GameRoot 反向引用 + grep）+ IS16 改"不持 SpatialGrid 引用" + IS19 Then 改 carrier==ZERO |
| 13 | AC-IS3/IS1 隐式断言 context schema/phase slot/carrier 归属（跨系统） | systems-designer | 契约重定向 GP-B2/B3/B4：改为 dependency constraint + OQ 引用，不作 InputSystem 可独立测试 AC |
| 14 | F1 与 carrier 间可能引入插值/平滑层违 Fantasy | game-designer/qa-lead | 新增 AC-IS28 [V, ADVISORY] 禁止 InputSystem 域内插值层，平滑归 PC 读侧 |
| 15 | OQ1 VirtualJoystick ADR 无 allocation 源码核验 scope | performance-analyst | OQ1 scope 扩展：ADR1 须含 allocation 源码核验（回调内不触发稳态分配 + 轮询属性不装箱） |

### 设计决策（CD/用户裁定）
- **UX-B2**（用户裁定）：选择 UI = 底部弹起面板（非屏幕中央）
- **GP-B1**（用户裁定）：输入获取 = 内置 VirtualJoystick 轮询属性（provisional，待 ADR1）
- **GP-B2/B3/B4**（CD 裁定）：context schema / phase slot / carrier 归属降为 RECOMMENDED，以契约重定向闭环（不改 InputSystem 主体）
- **spike-skip**（CD 裁定）：采纳 game-designer BLOCKING，解决方向 = Fantasy 诚实化 + 责任归 PC 读侧速度模型
- **VirtualJoystick API 验证**（CD 裁定）：defer ADR1，但结构性缺口（获取路径声明 + 守卫 carve-out）本轮闭环

### 待 re-review
建议新会话 `/clear` 后 `/design-review design/gdd/input-system.md`（本轮 context 已高）。

## Review — 2026-08-26 — Third Full Re-review — Verdict: MAJOR REVISION NEEDED
Scope signal: L
Specialists: full multi-specialist review + creative-director synthesis
Blocking groups: 8
Summary: 确认核心数据路径`VirtualJoystick→4 empty-binding actions→get_vector(0)→binary carrier`可保留，问题集中在pause/background控制面、typed status/API、claim/epoch、safe viewport几何、灰盒可复现性和性能证据边界。用户裁定D1-A：普通pause保留内置claim至物理release，APP_BACKGROUND由Host重建唯一节点并推进gesture epoch；D2-A：几何按safe viewport比例计算，不依赖DPI。修订已写入InputSystem/GameRoot，当时状态保持In Review。
Prior verdict resolved: First full review blockers were superseded by D1-A/D2-A control-plane remediation; independent verification remained open.

## Review — 2026-08-26 — Fourth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Blocking groups: 7 remaining from the third-round control plane; performance evidence boundary closed
Summary: D1-A/D2-A与核心输入架构继续保留。用户批准D3-A..D7-A：GameRoot typed state publish、trusted void carrier/private commit helper/status precedence、active VJ几何不可变与离树candidate替换、APP_BACKGROUND/geometry invalidation全状态矩阵、scale-first finite归一化、display→window→Canvas几何、Host choice gate、AC-IS28/29 fixture。修订后仍要求新会话独立full re-review；当时按授权未更新本日志。
Prior verdict resolved: Third-round architecture decisions applied; closure not yet independently verified.

## Review — 2026-08-26 — Fifth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Blocking items: 7 implementation | Integration/acceptance gates: 4
Summary: 8/8必需章节完整；核心架构与二元满速契约保留。D3-A状态owner、D4-A carrier/status、D5-A节点生命周期、D6-A touch/F1/坐标均为部分关闭；D7-A实现契约关闭、UX验收未关。终审的7项implementation blocker为：（1）`RESUME_LOCKED→FROZEN`回滚边缺失；（2）cancel仅按tick幂等；（3）`release_pending: bool`可覆盖同tick fresh press；（4）pending async safe-close与publish failure零修改后置矛盾；（5）display/window physical到viewport stretch逆变换缺失；（6）AC-IS3要求VJ辨识已构造ScreenTouch的鼠标来源；（7）AC-IS17 writer allowlist禁止callback为同步关闭ingress所必需的hit-route属性写。

### Remediation applied after explicit four-file approval

- InputSystem增加专用resume-abort typed rollback边与确定后置条件。
- cancel幂等改为检查当前action/carrier/gate/pending-release脏状态；同tick再次非ZERO必须重新release。
- pending release改为`{gesture_epoch,press_generation}`，新generation可supersede旧release；AC-IS9/19补same-tick事件序列。
- Public API区分普通验证失败的零修改与pending latch的`ASYNC_SAFE_CLOSE`。
- F2冻结display safe/window client交集→window physical→viewport logical→Host local完整链、往返误差、immutable geometry snapshot与canonical fingerprint。
- AC-IS3改测原始mouse event；AC-IS17精确allowlist唯一hit-route disable，仍禁止callback写action/carrier/top-state。
- Host candidate冻结为不可命中入树、登记完成后仍等ACTIVE publish开放；补rebuild failure-stage、SETTLEMENT、touch-index、FTZ fixture。
- GameRoot冻结foreground preflight不调Grid request；紧接零-dt tick是首次request，首次PENDING后仍只允许一个额外drain。
- AC-IS25补自动blocking-choice旅程；AC-IS28冻结5人、warm-up、每人/每档/每手分母和失败计数。

### Remaining gates

- PlayerController GDD、BattleUI GDD、`project.godot`/InputMap/stretch资产与静态守卫工具仍未建立，只能标记integration BLOCKED。
- 本轮修订未经新的独立full review，状态为`Re-review Pending`，不得记为Approved/PASS。

## Review — 2026-08-27 — Sixth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Fifth-review closure: 3/7 CLOSED | 4/7 PARTIAL/reopened
Blocking items: 6 implementation | Integration/acceptance gates: 5
Summary: 8/8必需章节继续完整，`VirtualJoystick→4 empty-binding actions→F1→typed carrier`核心架构保留。按“是否形成无新blocking caveat的安全实现契约”口径，第五轮7项中epoch/generation release、原始mouse AC、callback writer allowlist为CLOSED；resume rollback、cancel dirty predicate、async safe-close、F2转换为PARTIAL。终审新增普通pause GUI route、resume不可逆点、async cleanup活性、pressed-zero、cancel矩阵与precision-aware容差等实现边界，并重开AC-IS25/27/28验收口径。

### Required Before Implementation（终审原始裁定）

1. 普通pause不能把claimed VJ设`MOUSE_FILTER_IGNORE`，否则Godot touch-focus release在GUI filter处被跳过；需要完整movement-rect new-press shield。
2. InputSystem的“ACTIVE前都可rollback”与GameRoot首次Grid/Pool matching publish后的不可逆语义冲突，须冻结统一边界。
3. `pending_input_status`缺consume/ack，可能反复遮挡teardown，须给fault cleanup唯一活性路径。
4. action cancel只看raw strength会遗漏`pressed=true/raw=0`，须以pressed或raw任一dirty触发release并验证二者均clean。
5. `cancel_input`缺state×reason×caller可枚举oracle；无从确定重复调用的OK/WRONG_STATE/WRONG_PHASE。
6. F2固定`1e-4 physical px`在float32合法1.1 scale下可能误拒，须按real_t/ULP与坐标量级冻结容差。

### Required Before Integration（终审原始裁定）

- AC-IS25的manual与automatic choice旅程必须使用各自实际存在的press target，自动显示/恢复不是press。
- AC-IS25“至少5人”与AC-IS28“同一5人”及fixture分母不一致，须预登记participant并冻结完整cell。
- BattleUI须补manual pause/continue target、UI→shield→VJ scene route及左右手可达性。
- AC-IS27须补participant分母、artifact/frame manifest、曝光/回答窗口、动态VFX与真实手指遮挡证据。
- PlayerController、BattleUI、`project.godot`/InputMap/stretch、静态守卫工具与真机性能证据继续保持BLOCKED/OPEN。

### Remediation applied after explicit four-file approval

- 普通pause增加预创建、覆盖完整movement rect的new-press shield；固定交互UI→shield→VJ顺序，claimed VJ保持非IGNORE接收matching release。APP_BACKGROUND/geometry invalidation仍可disable/rebuild旧节点。
- 首次Grid/Pool matching publish调用冻结为resume不可逆点：点前可abort/rollback FROZEN；点后须完成matching publish/lease cleanup并fault teardown，禁止恢复旧bundle或重试resume。
- async latch改为首个同步API一次capture+ack并safe-close；first failure转只读telemetry，迟到callback只作suppressed diagnostic，后续teardown可进入TERMINATED。
- action dirty改为`Input.is_action_pressed(action) || raw_strength != 0.0`，后验同时验证pressed=false/raw=0；新增`ACTION_CLEAR_FAILED`与pressed-zero fixture。
- Public API补完整`cancel_input` state×reason矩阵，并明确`WRONG_PHASE`只归`run_phase`。
- F2增加`roundtrip_tolerance_physical=max(1e-4,4×ulp_real_t(max(1,max_abs_coordinate)))`、precision字段及1080p/4K/1.1 scale正负fixture。
- AC-IS25冻结恰好5名预登记participant、A/B各自target与`participant×fixture×hand×journey×target`的20次/19通过分母；AC-IS28复用同一预登记5人。
- AC-IS27冻结每人36个trial、个人阈值、immutable artifact manifest、曝光/回答窗口及动态/真实手指证据。
- GameRoot AC-D4b/E1/E2/F2同步不可逆点、shield、pressed-zero与async teardown活性；systems-index同步依赖与追踪。

### Remaining gates

- PlayerController GDD、BattleUI GDD、`project.godot`/InputMap/stretch资产、静态守卫工具与min-spec真机性能证据仍未建立。
- 本轮只是用户授权后的文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved/PASS。

## Review — 2026-08-27 — Seventh Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Sixth-review closure: 5/6 CLOSED | 1/6 PARTIAL
Blocking items: 6 implementation | Integration/acceptance gates: 5
Summary: 8/8必需章节完整，核心路径`VirtualJoystick→4 empty-binding actions→F1→typed carrier`继续保留，不需要重选架构。第六轮普通pause shield、resume不可逆边界、pressed-zero、cancel矩阵与F2主体已关闭；async cleanup仅因teardown可成为首观察者而PARTIAL。本轮新增缺口集中于shield owner/held-touch生命周期、failure安全后置条件、rebuild clean precondition、同index事件可辨识边界与不可逆点前二次dirty cancel。

### Required Before Implementation（终审原始裁定）

1. 冻结shield唯一owner、process mode、初始化校验及pause期间按住到resume后的held-touch生命周期；旧motion/release不得自动晋升，只有fresh press可建立generation。
2. `teardown()`若是async latch首观察者，必须同调用完成capture/ack、安全关闭与TERMINATED，或由GameRoot冻结确定性重试协议。
3. `ACTION_CLEAR_FAILED`仍须清carrier与pending release并关闭consumer，PlayerController不得消费旧intent。
4. `ensure_rebuilt_after_invalidation()`必须要求shield/gate closed、carrier当前tick精确clear、pending release空、actions pressed/raw clean；非法前置不得构建candidate。
5. AC-IS19要求“旧epoch release晚于同index新press仍可辨识”超出Godot内置VJ/index模型能力；须先证明支持平台不会产生该顺序，否则重开raw-touch/custom joystick架构。
6. 不可逆点前的resume invalidation必须按`disable ingress→dirty-aware cancel→clean verify→abort/close→rollback`执行，避免旧focused drag在初次cancel后重新写dirty action。

### Required Before Integration（终审原始裁定）

- AC-IS25覆盖三选一upper/middle/lower与二选一upper/lower全部真实row。
- AC-IS25冻结device model、物理屏幕尺寸、OS/scale、safe area、orientation/grip等physical-device manifest。
- AC-IS27为动态VFX与真实手指遮挡定义任务、样本和个人通过阈值。
- AC-IS28冻结`timeout_ticks`值或推导公式、owner与变更后的完整复测规则。
- PlayerController、BattleUI、`project.godot`/InputMap/stretch、静态守卫与min-spec性能证据继续作为诚实integration/evidence gate。

### Remediation applied after explicit four-file approval

- `VirtualJoystickHost`成为typed `MovementIngressShield`唯一owner；Host/shield均`PROCESS_MODE_ALWAYS`，初始化验证full-rect/order/filter/accept-event与定容held-touch bank。普通pause按`{shield_epoch,touch_index}`持有到matching release；lifecycle rebuild checked推进shield epoch并淘汰旧bank。
- `is_choice_input_blocked()`同时反映旧VJ claim与shield-held bank；BattleUI choice入口及GameRoot进入RESUME_PREPARING前都必须读取，held时保持Paused并给低打扰反馈。
- async latch首观察者为`teardown`时，同一调用capture/ack、safe-close、释放节点并进入TERMINATED；返回captured root status且GameRoot不得二次teardown。
- `ACTION_CLEAR_FAILED`前也强制carrier=`{ZERO,false,-1,tick_revision}`、pending release清空、gate closed/shield enabled；PlayerController读数为0。
- Host ensure新增严格clean precondition和确定性`WRONG_STATE/ACTION_CLEAR_FAILED`；未满足时candidate build count=0。
- AC-IS19改为`SupportedTouchEventOrderingManifest`+Android/iOS真机trace；反序synthetic fixture标UNSUPPORTED，目标设备若观测违反则阻塞实现并重开架构。
- `RESUME_LOCKED`新增APP_BACKGROUND/INPUT_GEOMETRY_CHANGED合法cancel行；InputSystem/GameRoot/AC-D4b/E1/E2同步不可逆点前二次dirty cancel与清理顺序。
- AC-IS25以20次B旅程均衡覆盖五个choice row并冻结physical-device manifest；AC-IS27冻结静态36+动态18+真机手指12 trial及个人阈值；AC-IS28冻结`ideal_ticks=ceil(path_length/4.5×60)`、`timeout_ticks=ceil(ideal_ticks×1.50)`及变更全量复测。

### Remaining gates

- PlayerController GDD、BattleUI GDD、`project.godot`/InputMap/stretch资产、`SupportedTouchEventOrderingManifest`真机trace、静态守卫工具与min-spec性能证据仍未建立。
- 本轮仅完成四文件设计契约remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved/PASS。

## Review — 2026-08-27 — Eighth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Seventh-review closure: 6/6 CLOSED by original target | New blocking items: 5 implementation | Integration/acceptance gates: 7
Summary: 8/8必需章节完整，核心路径`VirtualJoystick→4 empty-binding actions→F1→typed carrier`与binary/no-hysteresis手感继续保留，不需重选架构。第七轮6项按原修订目标全部文档层闭环；本轮新缺口集中于resume期间正常shield press的非故障活性、系统手势cancel、bank容量/paused async fault观察、effective GUI route可执行性，以及cancel failure后的资源收敛。

### Required Before Implementation（终审原始裁定）

1. resume开始后、ACTIVE前的合法movement press会进入shield bank，使尾段publish返回WRONG_STATE并把正常操作升级为technical fault；须按不可逆点前回Paused、点后无lease held-drain闭环。
2. 系统返回/Home或OS touch cancellation若无普通release/background，旧VJ/shield held state可能永久不空；须冻结canceled terminal、fallback与navigation gesture inset owner。
3. shield bank capacity无确定来源，overflow callback的safe-close与callback writer禁令冲突，Paused又无必达同步observer；须冻结manifest上界与`service_pending_input_fault`。
4. AC-IS2漏掉shield的`PROCESS_MODE_ALWAYS`，initialize又无法运行时内省未来`accept_event()`；须改精确allowlist、effective filter/ancestor验证与静态+行为AC。
5. resume invalidation第二次dirty cancel失败后，“abort=0”与teardown前无open lease/candidate冲突；须区分正常rollback与emergency fault-abort/matching-close cleanup。

### Required Before Integration（终审原始裁定）

- BattleUI GDD/scene须关闭blocked feedback出现/消失/限频、动态字体、五个choice row与UI→shield→VJ route。
- PlayerController GDD须冻结速度、碰撞直径、release→stop与AC-IS28消费契约。
- `project.godot`/InputMap/stretch/portrait/CanvasLayer资产尚未建立。
- `SupportedTouchEventOrderingManifest`及目标Android/iOS真机原始trace尚未建立；违反顺序或cancel终止边界时须重开架构。
- AC-IS25三段latency目前只有记录值、无pass threshold；须冻结上限或明确为EVIDENCE ONLY。
- 物理touch target口径仍OPEN，BattleUI须冻结physical/dp/pt判定与转换证据。
- 静态守卫、min-spec性能与AC-IS27真机证据仍OPEN。

### Specialist disagreements resolved by Creative Director

- teardown返回captured非OK但同调用已TERMINATED：Public API/GameRoot/AC已一致冻结，不列implementation blocker；建议后续仅把表头改为completion/terminal postcondition。
- 第二次dirty cancel failure cleanup：采纳Systems/QA，旧“不得abort”不能阻止emergency resource cleanup。
- edge gesture/cancel：从UX风险提升为implementation blocker，因为它决定held bank是否有限步收敛。
- binary/no hysteresis与下游GDD/asset缺失：前者当前AC充分，后者是诚实integration gate，不重开Input核心架构。

### Remediation applied after explicit four-file approval

- resume事务增加四时点held检测：不可逆点前恢复old owner、fault-free abort/close、publish FROZEN回Paused；点后完成正确双publish、end lease与quarantine cleanup，在`open lease/candidate=0`的`RESUME_HELD_DRAIN`等待release/cancel，只执行ACTIVE尾段且不重跑Grid/Pool。
- shield与VJ把`InputEventScreenTouch.is_canceled()`/公开released作为matching terminal；`SupportedTouchEventOrderingManifest`新增navigation mode、residual gesture insets、max concurrent touches及edge/Home/cancel trace，F2改由interactive safe viewport派生movement rect。
- `shield_bank_capacity=max(all supported artifact max_concurrent_touches)`，固定槽按entry保存任意稀疏非负index；overflow callback只latch+accept event，GameRoot paused control pump最迟下一iteration调用typed `service_pending_input_fault`完成capture/ack/safe-close/fault。
- AC-IS2使用participant pausable + Host/shield/registered VJ ALWAYS精确allowlist；initialize验证`get_mouse_filter_with_override()`与ancestor递归配置，`accept_event()`迁到静态call-site和behavior spy，并补ancestor-disabled negative fixture。
- resume第二次dirty cancel failure明确禁止的是正常FROZEN rollback；emergency path必须恢复old owner、fault-abort未publish candidate、matching close lease、清staging/quarantine，再按Input→Grid→Pool teardown，cleanup failure仅suppressed。

### Remaining gates

- 本轮只完成5组implementation blocker的四文件remediation；尚未经新的独立full review，不能登记CLOSED/Approved/PASS。
- PlayerController、BattleUI、project asset、platform manifest/trace、latency/物理热区、静态守卫与min-spec性能证据仍按Integration Gates保持BLOCKED/OPEN。
- 下一轮full re-review应重点注入resume四窗口new press、capacity+1 paused overflow、edge/Home cancel、ancestor effective-filter失效，以及second-cancel failure后的candidate/lease终态。

## Review — 2026-08-27 — Ninth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Eighth-review closure: 3/5 CLOSED | 2/5 PARTIAL
Blocking items: 5 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，核心路径`VirtualJoystick→4 empty-binding actions→F1→typed carrier`与binary/no-hysteresis继续保留。第八轮resume误fault、edge/Home terminal设计与emergency cleanup按原目标关闭；bank/paused observer及process/effective route因新实现矛盾为PARTIAL。本轮5项集中于可信safe-close tick、shield bank FSM、Godot callback返回边界、GameRoot paused pump exact mode，以及held rollback后的自动resume活性。

### Required Before Implementation（终审原始裁定）

1. pending async latch优先于invalid/stale tick且必须safe-clear，但唯一helper需要可信tick；须冻结内部`safe_close_tick_revision`并覆盖pending+negative/invalid/stale组合。
2. shield bank缺duplicate press、matching/unknown/stale terminal、terminal后index复用的完整FSM；callback fatal只能覆盖本地可判定事件，跨epoch反序留给platform trace gate。
3. AC-IS24误把Godot `_gui_input`/notification/signal callback纳入typed `->int`，形成不可实现oracle；须精确列出status-returning API allowlist。
4. Input要求GameRoot ALWAYS paused pump，但GameRoot正文与AC-IS2精确allowlist未冻结唯一`PROCESS_MODE_ALWAYS` GameRoot。
5. pre-irreversible合法held rollback回Paused后未冻结resume intent是否保留及terminal后的继续方式；自动choice无第二Continue target，须保证幂等latch与自动单次重试。

### Specialist disagreements resolved by Creative Director

- resume期间正常press误升technical fault按第八轮原目标已关闭；rollback后自动重试是本轮新活性blocker。
- 缺少真实edge/cancel manifest不列当前设计blocker，但在证据到位前不得声称implementation-ready；真机违反时重开架构。
- shield FSM、AC-IS24与GameRoot exact process mode均阻塞实现；binary/no-hysteresis与下游GDD/资产缺失不重开核心架构。

### Remediation applied after explicit four-file approval

- InputSystem增加内部`safe_close_tick_revision`：initialize在连接callback前以合法权威tick seed；无pending时仅在同步验证通过后单调更新；pending首观察者忽略本次未验证tick，以内部值capture/ack+safe-close并返回root status。AC-IS8补negative/invalid/stale组合与carrier written_tick oracle。
- 新增Shield Bank FSM：固定slot `FREE/HELD`、unique press占槽、duplicate press/motion幂等诊断、matching terminal恰释放一次、unknown/stale terminal只诊断、terminal后同index可复用。运行时fatal限负index/capacity overflow/本地非法边，跨epoch反序只由AC-IS19平台gate裁决。
- AC-IS24改为项目自定义同步mutation API、participant与可返回status Host helper的精确`->int` allowlist；Godot override/notification/signal callback按引擎void签名并由AC-IS17 writer spy验证。
- GameRoot精确冻结为`PROCESS_MODE_ALWAYS`集中编排例外；AC-IS2/AC-B1加入唯一GameRoot、participant pausable及错误process-mode negative fixtures，Paused不得运行七phase。
- `resume_requested_latched`在blocking choice提交或manual Continue接受时幂等置true，仅ACTIVE/ending/fault清除；pre-irreversible held rollback保留latch，terminal且service OK后pump自动启动恰一个attempt。连续press不累计intent、不并行attempt、不重复choice effect；AC-IS11与GameRoot AC-E1/E2补端到端矩阵。
- held/blocked反馈冻结为entry-once、terminal-clear-once，paused iteration不得逐帧重复动画、音效、震动或辅助功能播报。

### Remaining gates

- 本轮只是四文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved/PASS。
- `SupportedTouchEventOrderingManifest`及Android/iOS edge/Home/cancel真机trace、PlayerController/BattleUI、`project.godot`/InputMap/scene route、UX latency/物理touch target、静态守卫与min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮full re-review应重点注入`pending latch + negative/invalid/stale tick`、shield duplicate/terminal/index复用长序列、GameRoot四种process mode、自动choice early-held连续rollback后的single retry/choice-effect计数，以及Godot callback signature静态fixture。

## Review — 2026-08-27 — Tenth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Ninth-review closure: 3/5 CLOSED | 2/5 PARTIAL
Blocking items: 4 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，31个AC编号唯一；核心路径`VirtualJoystick→4 empty-binding actions→F1→typed carrier`与binary/no-hysteresis继续保留。第九轮Shield Bank FSM、Godot callback返回边界及held rollback原目标关闭；trusted tick/no-latch service与GameRoot process仍存在实现矛盾。本轮另发现pause reason到resume intent的来源/优先级缺口及geometry fingerprint幂等歧义。

### Required Before Implementation（终审原始裁定）

1. `safe_close_tick_revision`规则允许所有validated sync API推进，但`service_pending_input_fault`无latch又声明完全无副作用；须只保留一种语义并补`service no-latch→callback latch→invalid caller tick`精确oracle。
2. blocking choice完成自动置resume latch会绕过仍存在的MANUAL pause；纯APP_BACKGROUND/INPUT_GEOMETRY_CHANGED又没有latch生产者或真实Continue入口。须冻结choice/manual/lifecycle及其组合的resume intent矩阵。
3. Input/GameRoot要求唯一GameRoot=`PROCESS_MODE_ALWAYS`主动编排与paused pump，但项目technical preferences仍全局禁止`_process/_physics_process`；须登记唯一例外并冻结两个callback职责。
4. 同revision rebuild仅凭未冻结的`geometry_fingerprint`相等判幂等，hash碰撞可跳过必要rebuild；须以完整canonical geometry field bits作为最终相等判据。

### Specialist disagreements resolved by Creative Director

- Systems/QA把F1极小finite/FTZ“方向同向”oracle列BLOCKING；终审降为RECOMMENDED，因为公式实现唯一，缺口集中在测试容差。
- Godot组把第九轮held-retry列PARTIAL；终审按原修订目标记CLOSED，manual/lifecycle pause-source问题作为本轮新回归记录。
- geometry fingerprint保留为implementation blocker，因为它直接控制是否跳过安全rebuild。
- choice touch terminal ownership归BattleUI/scene integration gate；缺失真机manifest与下游资产继续作为evidence/integration gate，不冒充Input核心设计缺陷。

### Remediation applied after explicit five-file approval

- InputSystem将无pending的`service_pending_input_fault`排除出trusted tick推进：只验证参数/state，连内部tick都零修改。AC-IS8加入`N→service(N+1) no-op→callback latch→invalid/stale observer`，safe-close carrier仍必须写N；safe-close自身action-clear失败只作suppressed diagnostic。
- InputSystem与GameRoot冻结pause reason→resume latch矩阵：choice-only在全部choice完成后自动resume；lifecycle-only在preflight、Grid pause/quarantine和FROZEN publish成功后自动resume；lifecycle+choice等待两者完成；任意MANUAL残留必须等待合法Continue。duplicate/coalesced reason不累计intent、不重复choice effect，terminal只能解除block，不能凭空创建resume intent。
- `.claude/docs/technical-preferences.md`登记唯一GameRoot例外：`_physics_process`只在未暂停时驱动七phase，`_process`只在BATTLE_PAUSED/RESUME_PREPARING驱动control pump；AC-IS2/AC-B1覆盖缺callback、职责互换、双跑和错误mode。
- geometry fingerprint降为快速不等预筛/diagnostic；同revision no-op必须fingerprint与完整canonical field bits双重相等。collision fixture要求返回STALE_TICK且candidate build count=0；跨进程fingerprint需另冻schema/算法/位宽/字节序。

### Remaining gates

- 本轮只是五文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready或PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、UX latency/物理touch target、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮full re-review应重点注入无latch service与trusted tick序列、choice/manual/lifecycle全组合、GameRoot两个process callback职责/调用计数，以及fingerprint collision/canonical-field mismatch。

## Review — 2026-08-27 — Eleventh Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Tenth-review closure: 4/4 CLOSED
Blocking items: 4 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整；第十轮no-latch trusted tick、pause reason矩阵、唯一GameRoot process例外与geometry collision修订均按原目标关闭。核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`继续保留。本轮终审确认初始化虚回调隔离、callback ABI/Callable identity、rebuild status/config identity及APP_BACKGROUND readiness四组新实现阻塞。

### Required Before Implementation（终审原始裁定）

1. Host/shield/VJ已在树时，signal连接数0不能隔离`_gui_input/_notification`；须冻结UNARMED/BOOTSTRAPPING、seed前虚回调零运行时mutation及seed后exact connect→arm顺序。
2. 冻结Godot 4.7.1 callback ABI：`pressed()`、`released(Vector2)`、无独立VJ canceled signal、shield `_gui_input(InputEvent)`、Host `_notification(int)`及GameRoot两个delta callback；epoch用direct bound Callable且保存同一身份精确disconnect。
3. `ensure_rebuilt_after_invalidation`须返回唯一精确status；canonical identity须覆盖immutable candidate-config，包括initial offset、mode/visibility/actions/deadzone/size/clamp/theme等candidate-affecting输入。
4. 纯foreground geometry可在安全preflight后自动恢复；reason含APP_BACKGROUND时必须保持Paused等待一个真实readiness/Continue，和MANUAL重叠不叠加按钮，确认press不得兼作movement。

### Specialist disagreements resolved by Creative Director

- Systems/QA与Godot组认为第十轮resume矩阵已闭环；Gameplay/UX指出后台返回自动开战会让玩家在fresh movement尚不可用时暴露。终审采纳并列为新implementation blocker，不倒记第十轮PARTIAL。
- Choice touch terminal ownership有真实风险，但实现owner是BattleUI；终审列Required Before Integration，不要求扩大Input核心FSM。
- Callback准确签名只有Godot组列BLOCKING；终审确认错误arity/Callable身份会导致连接与断连分叉，维持BLOCKING。
- binary/no-hysteresis不重开；只有AC-IS28失败trace明确归因阈值映射时才另立设计变更。

### Remediation applied under user's pre-authorization

- Input与GameRoot加入UNARMED初始化协议：arm前VJ不可命中，shield/notification虚回调零运行时mutation；initialize最终重读geometry、seed trusted tick、保存并连接exact epoch-bound Callable后原子arm，failure恢复UNARMED/bank空/连接数0。
- 冻结pressed()/released(Vector2)、shield/Host/GameRoot callback原型、direct bind参数顺序、exact disconnect及无独立VJ canceled signal；technical preferences同步。
- rebuild Public API与阶段矩阵冻结`INVALID_ARGUMENT/STALE_TICK/WRONG_STATE/INVALID_CONFIG/ACTION_CLEAR_FAILED/GENERATION_EXHAUSTED/JOYSTICK_REBUILD_FAILED`，并新增instance-frozen candidate-config canonical identity及collision AC。
- pause reason矩阵拆分geometry与background：纯geometry可自动，APP_BACKGROUND及其组合必须等待单一readiness/Continue，确认press不建立movement generation；BattleUI choice terminal gate继续明确为integration blocker。

### Remaining gates

- 本轮只是五文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready或PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮full re-review重点注入seed前touch/resize/background、callback arity/bind/disconnect、rebuild逐status与candidate-config collision，以及geometry/background/manual/choice全组合readiness。

## Review — 2026-08-27 — Twelfth Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Eleventh-review closure: 2/4 CLOSED | 2/4 PARTIAL
Blocking items: 2 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时33个AC编号唯一；核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、single-writer、fresh-press、shield bank与resume不可逆点继续保留。callback ABI/exact Callable与rebuild behavior identity按第十一轮目标CLOSED；UNARMED bootstrap及APP_BACKGROUND readiness因加载期与连续revision的新边界为PARTIAL。本轮不允许Approved。

### Required Before Implementation（终审原始裁定）

1. `initialize`末尾callbacks arm并进入IDLE后，GameRoot仍执行Grid/Pool/owner warmup才publish ACTIVE；armed consumer-closed shield可把加载期早按登记为held，而ACTIVE publish要求bank/claim为空，BATTLE_LOADING又无held drain/pump。seed前Host notification零runtime写还可能吞掉本应中止load的background。须把callbacks arm与runtime ingress开放分离，冻结PREACTIVE_DISCARD及必达的bootstrap lifecycle latch。
2. 合法序列`background A→Continue A→resume未越过不可逆点→background B→rollback`中，generic resume latch按既有规则保留，却可能绕过B的新readiness。须以per-background required/acked revision配对，使每个新revision重新关闭gate，未确认事件可coalesce到最新revision，duplicate同revision不重复确认。

### Specialist disagreements resolved by Creative Director

- 第十一轮closure数量：Systems/QA与Godot组倾向更多PARTIAL，Gameplay/UX倾向3 CLOSED + 1 PARTIAL；终审裁定2 CLOSED + 2 PARTIAL，rebuild字段级行为identity已闭环，但runtime readiness连续revision仍有冲突。
- seed前background与armed-IDLE早按合并为一个blocker，因为两者同属bootstrap→ACTIVE缺少完整input/lifecycle模式。
- candidate-config ID被原文排除canonical sequence；终审将其降为RECOMMENDED telemetry/provenance澄清，不阻塞字段级candidate行为等价。
- choice terminal ownership风险真实，但owner为尚未建立的BattleUI，继续列Required Before Integration，不扩大Input核心FSM。

### Remediation applied after explicit five-file approval

- InputSystem与GameRoot分离`callbacks_armed`和`runtime_ingress_armed`：UNARMED及armed-IDLE时VJ不可命中，shield touch只`accept_event()`并走PREACTIVE_DISCARD，项目owned gesture/bank/action/carrier/pending-status零写；只有`IDLE→ACTIVE`同步尾段原子开放new-press route，加载期早按不能导致WRONG_STATE/fault或跨ACTIVE晋升。
- 增加预分配、无需trusted tick的preactive invalidation latch。seed前或armed-IDLE期间的APP_BACKGROUND/geometry事件必达；initialize或ACTIVE publish以typed WRONG_STATE安全中止BATTLE_LOADING、逆序cleanup回PREP，technical fault=0。
- GameRoot增加`background_readiness_required_revision/background_readiness_acked_revision`：每个新background revision推进required并使旧Continue失效；Continue只ack当时最新revision，duplicate不推进，多个未确认事件coalesce到最新。pump必须同时满足generic latch、revision gate与held predicate。
- Input新增AC-IS11b，并扩展AC-IS7/8/17/17a；GameRoot扩展AC-A2/A2b/E1/E2并新增AC-D3b，覆盖preactive press跨publish、seed前background、A确认后B到达、A/B/C合并及MANUAL/choice/geometry组合。
- `.claude/docs/technical-preferences.md`与`systems-index.md`同步三段初始化和per-background revision规则。

### Remaining gates

- 本轮只是五文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready或PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮full re-review应重点注入UNARMED/armed-IDLE每个加载边界的press/motion/terminal与background、`IDLE→ACTIVE`原子开放，以及`background A→Continue A→background B`和多revision coalesce/duplicate矩阵。

## Review — 2026-08-27 — Thirteenth Convergence Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: S
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Twelfth-review closure: 1/2 CLOSED | 1/2 PARTIAL
Blocking items: 1 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC编号唯一；核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、single-writer、fresh-press、shield bank与resume事务架构继续保留。preactive callbacks/runtime ingress/lifecycle abort按第十二轮目标CLOSED；per-background required/acked模型及`Continue A→首次matching publish前background B`路径已闭环，但完整R7时序仍有不可逆点后的observer缺口，本轮不允许Approved。

### Required Before Implementation（终审原始裁定）

1. R7 step 8在首次matching publish前检查held/revision；step 9两次publish之间与step 10 cleanup/held-drain/ACTIVE尾段只检查pending Input fault与held。`APP_BACKGROUND`推进input/background revision而不属于`pending_input_status`，因此不可逆点后的新revision可能未被观察，最终尾段又清`foreground_input_blocked`并错误发布ACTIVE。必须让每个resume attempt固定捕获input rebuild/background revision与geometry snapshot，在两次publish之间、双publish后、lease/quarantine cleanup后、每个held-drain iteration及最终ACTIVE尾段前统一复核；点后发现变化必须完成保存tx的matching publish/cleanup后fault，不得清block或发布ACTIVE。

### Specialist disagreements resolved by Creative Director

- Systems/QA与Gameplay/UX均裁定第十二轮2/2 CLOSED，因为required/acked数据模型、Continue A后且不可逆点前到达B的原始fixture已经闭环。
- Godot/GDScript/performance沿R7完整执行步骤发现点后observer集合没有revision gate；Creative Director采纳该结论，因为这是同一“每个background revision不得被旧确认绕过”的安全不变量覆盖缺口，不是新增体验优化。
- Godot 4.7.1源码核验确认preactive shield touch focus跨ACTIVE时旧motion/terminal不会重新命中VJ sibling，terminal最终释放引擎focus；因此第一个blocker保持CLOSED。

### Remediation applied after explicit four-file approval

- GameRoot将`can_start_resume`收紧为required/acked精确相等；每个attempt原子捕获`attempt_input_rebuild_revision/attempt_background_revision/attempt_geometry_snapshot`，并定义任一当前revision或invalidation latch与快照不一致为`attempt_invalidation_changed`。
- R7 prepare/arm/swap、两次matching publish之间、双publish后、lease/quarantine cleanup后、每个RESUME_HELD_DRAIN iteration与最终ACTIVE尾段统一复核attempt快照。首次publish前仍按既有规则rollback；首次publish后必须完成保存tx的matching publish与cleanup后进入ControlledFault，保持`foreground_input_blocked=true`且Input ACTIVE publish=0。
- ACTIVE尾段只有在`required==acked==attempt_background_revision`、`input_rebuild_revision==attempt_input_rebuild_revision`、无新invalidation、无pending fault且held为空时才可开放；held重新出现继续drain，其余失败进入fault。
- GameRoot AC-D4b/E1/E2与Input AC-IS11b/12b扩充逐边界注入和oracle；systems index同步依赖摘要。核心binary移动、shield、rollback与三系统publish架构均未改变。

### Remaining gates

- 本轮只是四文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮只做B1 closure复核：按两次publish之间、双publish后/cleanup前、cleanup后、held-drain iteration与最终ACTIVE尾段矩阵注入background/geometry revision，确认全部点后路径ACTIVE publish=0、consumer始终关闭且资源收敛后fault；同时回归preactive与首次publish前readiness路径。

## Review — 2026-08-27 — Fourteenth Convergence Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Thirteenth-review closure: 1/1 CLOSED
Blocking items: 1 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC编号唯一；第十三轮attempt snapshot observer已覆盖两次publish、cleanup、held-drain与final activation入口，原B1按目标关闭。核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、shield、fresh-press与三系统resume transaction继续保留。但Godot 4.7.1引擎API在“最终不可重入尾段”内部仍可同步调用项目代码，最后一次revision检查之后仍可能产生新invalidation，因此本轮不允许Approved。

### Required Before Implementation（终审原始裁定）

1. R7最终尾段把`SceneTree.set_pause(false)`、Input ACTIVE publish中的`Control.set_mouse_filter()`以及GameRoot ACTIVE提交视为无callback的连续步骤；实际Godot 4.7.1中，解除pause会同步传播`NOTIFICATION_UNPAUSED`，mouse filter setter会同步更新mouse-over并可能派发mouse enter/exit notification/signal。任一项目handler都可推进background/geometry invalidation，而当前流程已越过最后一次revision check，可能错误开放VJ/runtime ingress并进入ACTIVE。必须把resume激活拆为unpause后的显式复核与Input hit-route activation guard；同步callback只能latch，所有setter返回后再次检查，且`foreground_input_blocked`只能在ACTIVE publish确认OK后清除。

### Specialist disagreements resolved by Creative Director

- Systems/QA与Gameplay/UX裁定第十三轮B1 CLOSED：attempt snapshot、点后资源收敛和逐边界AC已按上一轮原始范围闭环。
- Godot/GDScript/performance沿Godot 4.7.1实现调用链指出“无await/无项目主动callback”不等于不可重入；引擎在`set_pause(false)`与`set_mouse_filter()`内部同步派发通知/信号。Creative Director采纳，因为这直接破坏“任何新invalidation均不得越过ACTIVE gate”的冻结安全不变量，不是新增优化。
- 源码取证点固定为Godot 4.7.1 `scene/main/scene_tree.cpp:1126-1144`、`scene/main/node.cpp:727-740`、`scene/gui/control.cpp:2554-2568`与`scene/main/viewport.cpp:2594-2697`；它们分别覆盖pause传播、unpaused notification与mouse-over更新/通知路径。该证据只证明同步可重入性，不冒充项目运行时AC已执行。
- 因此本轮不回退第十三轮closure，而登记一个同一激活尾段的新实现阻塞项；binary手感、VirtualJoystick选择、shield bank与Grid/Pool matching publish均不重设计。

### Remediation applied after explicit four-file approval

- GameRoot将最终激活拆成两阶段。第一阶段保持GameRoot=`RESUME_PREPARING`、Input=`RESUME_LOCKED`、consumer/ingress关闭及`foreground_input_blocked=true`，先执行`SceneTree.set_pause(false)`并等待同步`NOTIFICATION_UNPAUSED`返回；随后重新执行pending service、attempt revision/invalidation、pending fault与held复核。失败则重新pause，保持Input ACTIVE publish=0并在资源已收敛后进入fault；held-only仍回既有drain。
- 第二阶段调用guarded Input ACTIVE publish。Host使用预分配`activation_guard_armed/activation_invalidated_latched`，切换shield/VJ mouse filter期间的mouse enter/exit与同步layout/lifecycle callback只能latch；setter全部返回后复核。guard污染时在guard仍armed下恢复shield STOP/VJ不可达，保持RESUME_LOCKED与runtime ingress关闭并返回`WRONG_STATE`，GameRoot重新pause后fault。
- 只有guard clean才以不再调用引擎API的局部提交写Input ACTIVE/runtime ingress并开放fresh-press route；GameRoot收到OK后才清`foreground_input_blocked`并提交GameRoot ACTIVE。同一guard覆盖`IDLE→ACTIVE`，其污染复用preactive typed latch安全中止BATTLE_LOADING。
- GameRoot AC-D4b/E1/E2与Input AC-IS11b/12b/17增加`NOTIFICATION_UNPAUSED`及mouse enter/exit同步注入和成功对照；systems index同步依赖摘要。

### Remaining gates

- 本轮只是四文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮仅做activation closure：逐一注入`NOTIFICATION_UNPAUSED`、shield/VJ `set_mouse_filter()`引发的mouse enter/exit notification/signal及恢复setter再入，确认失败路径始终重新pause、VJ route峰值=0、consumer/foreground block不开、ACTIVE成功数=0；再用无invalidation对照确认只有guard clean时按`unpause→复核→Input ACTIVE OK→clear block→GameRoot ACTIVE`开放一次。

## Review — 2026-08-27 — Fifteenth Convergence Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX+UI+gameplay + creative-director synthesis
Fourteenth-review closure: Phase 1 CLOSED | Phase 2 PARTIAL
Blocking items: 1 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC编号唯一；第十四轮unpause后等待同步`NOTIFICATION_UNPAUSED`返回并复核的Phase 1按目标关闭。Phase 2的activation guard可以观察filter setter回调污染，却不能保证回调期间内置VJ物理不可达，因此原blocker只部分关闭。核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、shield、fresh-press与Grid/Pool resume transaction继续保留，本轮不允许Approved。

### Required Before Implementation（终审原始裁定）

1. Godot 4.7.1 `Control.set_mouse_filter()`先写入新filter，再同步更新mouse-over并可能派发项目notification/signal；若先把shield切为IGNORE，内置VirtualJoystick在activation guard完成复核和局部ACTIVE提交前已成为Control picking的实际target。Host的`runtime_ingress_armed=false`只能保护项目adapter，不能阻止内置VJ原生`_gui_input`、私有claim或Input action writer。因此第十四轮要求的“guard期间VJ route峰值=0”无法由现有filter顺序实现，且Core Rules/状态发布中残留“先发布state/gate再切filter”的描述与新顺序矛盾。必须增加一个覆盖整个filter变更与提交窗口的真实物理输入屏障，并冻结唯一owner、同步callback observer、failure cleanup与loading/resume对称路径。

### Specialist disagreements resolved by Creative Director

- 三路专项均同意严重度为BLOCKING、且第十四轮只可判PARTIAL；无severity分歧。
- Systems/QA与Gameplay/UX要求“实际输入送达数为0”的可测试外部oracle；Godot/GDScript/performance给出Viewport gate与额外Control overlay两种方向。Creative Director选择目标battle Viewport `gui_disable_input`，因为`Viewport::push_input()`在Control picking前返回，能覆盖内置VJ自身而不依赖Host bool或filter顺序。
- 终审拒绝只扩大Host activation bool、只调整shield/VJ filter先后或把同步窗口标为“理论上不会有OS事件”的弱化方案；它们均不能形成物理不可达证明。
- 源码取证固定为Godot 4.7.1 `scene/main/scene_tree.cpp:1126-1144`、`scene/main/node.cpp:727-740`、`scene/gui/control.cpp:2554-2568`、`scene/main/viewport.cpp:2594-2697`，以及同文件`Viewport::push_input`入口gate与`Viewport::set_disable_input`实现。静态源码只证明调用/短路语义，不冒充项目runtime fixture已执行。

### Remediation applied after explicit five-file approval

- GameRoot成为目标battle Viewport `gui_disable_input`及预分配`viewport_input_gate_owned` sentinel的唯一项目writer。每次`IDLE/RESUME_LOCKED→ACTIVE`前先验证精确Viewport identity、gate当前false且owner空闲，再checked取得owner并调用true setter；其他节点、UI与InputSystem均不得写gate。
- true setter同步drop focus/leave/tooltip期间，项目callback只可写既有typed invalidation latch与diagnostic；返回后执行第一次service/revision/invalidation/held复核。resume仅在clean时unpause，等待`NOTIFICATION_UNPAUSED`返回后执行第二次同序复核。
- Input activation guard、filter变更及Input局部ACTIVE/runtime-ingress提交均在Viewport disabled时完成；`Viewport::push_input()`在Control picking前返回，故false setter前VJ event delivery、claim、四action写入与generation变化必须全部为0。Input返回OK后GameRoot只作BATTLE_ACTIVE/consumer/block/latch/feedback局部提交，最后以false setter作为唯一物理开放点并清owner。
- resume activation failure重新pause或保持pause，Viewport继续disabled至Input与battle input节点teardown完成；只有ControlledFault/Home UI成为唯一target后才恢复Viewport input并清owner。BATTLE_LOADING safe abort则在同样teardown后仅为PREP UI恢复Viewport。held-only在gate acquisition或unpause observer后重新出现时，先重新pause（如需要）并恢复Viewport gate/owner，再回`RESUME_HELD_DRAIN`以允许matching terminal。
- 同一协议覆盖BATTLE_LOADING `IDLE→ACTIVE`；activation callback静态禁止调用`Input.parse_input_event`、`Viewport.push_input/push_unhandled_input`或等价注入。InputSystem、GameRoot、technical preferences、systems index与本review log已同步；AC-D4b/E1/E2及AC-IS11b/12b/17冻结success/failure/held-only oracle。

### Remaining gates

- 本轮只是五文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene Viewport route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮只做Viewport activation closure：分别在true setter focus/leave、unpause通知与filter mouse enter/exit回调中注入background/geometry/direct push/OS event，确认false setter前VJ delivery/claim/action/generation全部为0；覆盖gate acquisition/identity失败、held-only回drain、resume fault teardown恢复、BATTLE_LOADING safe abort及无invalidation成功对照。通过前不再扩大核心设计范围。

## Review — 2026-08-27 — Sixteenth Viewport Activation Closure Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: M
Specialists: systems+QA, Godot+GDScript+performance, game+UX/UI/gameplay + creative-director synthesis
Fifteenth-review closure: PARTIAL
Blocking items: 2 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC标题唯一。第十五轮true setter返回后的Viewport gate已关闭filter切换期间内置VJ物理可达，但Godot默认accumulated input可使gate-held期间入队事件在false后派发；同时true setter内部callback发生在bool置true前，旧AC、ACTIVE publish route开放点与pre-acquire failure后置条件相互冲突。核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、shield、fresh-press与Grid/Pool resume transaction继续保留，本轮不允许Approved。

### Required Before Implementation（终审原始裁定）

1. Godot 4.7.1默认`use_accumulated_input=true`。`Input.parse_input_event()`可只把事件加入全局buffer，后续`flush_buffered_events()`才实际dispatch；Viewport gate只在最终`push_input()`检查。因此gate=true时enqueue、gate=false后flush可形成幽灵fresh press。必须在所有battle input节点前冻结accumulated/agile buffering均为false并验证本局无漂移，或设计可证明完成的buffer fence；单次flush不能证明并发追加已清空。
2. `Viewport.set_disable_input(true)`先同步执行drop focus/leave/tooltip及可能的focused-Control `_gui_input`，最后才写bool。旧AC却要求setter callback内Viewport delivery=0，并残留ACTIVE publish返回即route=1、pre-acquire failure保持gate true等矛盾。必须冻结`PRE_ACQUIRE/SET_TRUE_IN_FLIGHT/GATE_HELD/SUCCESS_RELEASE/FAILURE_RELEASE`矩阵：setter-in-flight只保证VJ/gameplay effect=0；true返回后的held区间才保证Viewport零投递；false返回才是route 0→1；未取得gate的failure不得写或恢复Viewport。

### Specialist disagreements resolved by Creative Director

- 累积Input buffer越过Viewport gate采纳为BLOCKING，因为gate约束最终投递而不清除更早进入全局队列的事件。
- held-only repause后没有同调用observer降为Recommended：现有paused drain每次iteration固定`service→attempt invalidation→held`，在再次ACTIVE前必达观察；增加repause notification invalidation fixture即可。
- true-setter callback oracle、旧ACTIVE publish开放点及pre-acquire failure后置合并为一个lifecycle blocker，不重复计数。
- 源码取证固定为Godot 4.7.1 `core/input/input.h:164-165`、`core/input/input.cpp:1519-1580`、`scene/main/viewport.cpp:3489-3496,3716-3726`、`scene/main/scene_tree.cpp:1126-1144`与`scene/main/node.cpp:727-740`。静态源码只证明调用/缓冲/短路语义，不冒充项目runtime fixture已执行。

### Remediation applied after explicit five-file approval

- 选择无buffer生产契约：唯一GameRoot bootstrap在BOOT恰调用一次脚本可用的`Input.set_use_accumulated_input(false)`并readback；未绑定脚本setter的agile buffering由`project.godot`冻结`input_devices/buffering/agile_event_flushing=false`，GameRoot通过ProjectSettings只读验证。随后在Home/Battle input target均未激活时恰flush一次历史buffer，项目effect=0；本局后续Input setter、flush与ProjectSettings runtime mutation均为0，initialize和每个ACTIVE `PRE_ACQUIRE`任一readback漂移都返回`INVALID_CONFIG`且Viewport setter/release=0。
- loading与resume统一为`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT→GATE_HELD→reasoned release`。setter-in-flight明确允许Viewport dispatch，但项目callback/Control只可latch/diagnostic，VJ/action/carrier/consumer/top-state effect为0；true返回/readback后至false调用前才要求Viewport/Control/VJ delivery=0。
- Input ACTIVE publish只准备Control topology/runtime ingress，GameRoot局部ACTIVE提交后以`ACTIVATION_SUCCESS` release使物理route 0→1。唯一私有release helper另允许`HELD_ONLY_RETURN_TO_DRAIN`与`LOAD_ABORT_OR_FAULT_CLEANUP`；每个owner周期false/clear各一次，pre-acquire failure release=0。
- held-only repause同步notification的invalidation由下一paused drain iteration在任何ACTIVE retry前必达观察；focused-Control、buffering漂移、enqueue→false→flush、setter-in-flight/held区间、loading safe abort与fault/Home活性均加入AC矩阵。
- InputSystem、GameRoot、technical preferences、systems index与本review log已同步；未改变binary移动、shield FSM、GameRoot phase或Grid/Pool resume transaction。

### Remaining gates

- 本轮只是五文件设计契约remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/scene Viewport route、choice touch terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮只做第十六轮两项closure：验证buffering bootstrap唯一writer/生命周期无漂移及幽灵enqueue负例；验证五阶段gate矩阵、focused-Control setter-in-flight effect=0、held区间delivery=0、三种release reason、pre-acquire零setter、held-only repause必达observer、loading/fault成功恢复。通过前不扩大核心设计范围。

## Review — 2026-08-27 — Seventeenth Viewport Activation Closure Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: S
Specialists: systems+QA, Godot+GDScript+performance, game+UX/UI/accessibility + creative-director synthesis
Sixteenth-review closure: 1 CLOSED + 1 PARTIAL
Blocking items: 1 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC标题唯一。第十六轮Input accumulated/agile buffering关闭、BOOT历史buffer处理与生命周期漂移检查已按设计契约CLOSED；Viewport主阶段、true返回后的物理gate、false开放点及三种release reason成立。但`SET_TRUE_IN_FLIGHT`时bool仍false，hostile合法ScreenTouch可以到达STOP shield；resume既有Shield Bank FSM要求`accept_event()`并写held entry，旧AC却要求consumer accept与shield bank均为0，形成唯一不可同时实现的oracle。核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、shield、fresh-press、Grid/Pool resume transaction与Viewport gate均保留。

### Required Before Implementation（终审原始裁定）

1. Godot 4.7.1 `set_disable_input(true)`在写`disable_input=true`前同步drop focus/leave/tooltip；该窗口direct ScreenTouch可通过Viewport入口并命中STOP shield。loading必须由shield PREACTIVE_DISCARD，resume必须按现有current-epoch FSM accept/写held bank，因此不能同时满足旧AC的accept/bank零写。必须冻结containment + held drain：loading bank保持0；resume first observer发现held后以`HELD_ONLY_RETURN_TO_DRAIN`恢复terminal路由，VJ/action/carrier/generation/choice/gameplay consumer/top-state仍零写。press与matching terminal均在setter返回前完成时允许bank `0→1→0`后继续clean路径；capacity/FSM异常沿既有typed latch进入fault observer。

### Specialist disagreements resolved by Creative Director

- Systems/QA与Godot/GDScript/performance均把setter-in-flight direct ScreenTouch oracle裁定为唯一BLOCKING；Creative Director选择运行时containment + held drain，而非只把direct injection改成静态guard positive control，因为前者复用现有shield FSM并为所有引擎入口提供安全后置。
- UX/UI提出BOOT target-free flush仍会更新Godot InputMap/cache并可能影响未来keyboard/gamepad/switch access。终审确认当前生产范围为Touch-only、Gamepad None、四movement action empty-binding，故不升级为Input design blocker；但将“项目effect=0”收窄为项目Control callback、scene transition、choice/movement/gameplay effect为0，不冒充Godot global input state零修改。未来增加非touch action polling前必须补neutral-input fence。
- 源码取证固定为Godot 4.7.1 `core/input/input.cpp:1005-1048,1519-1597`、`main/main.cpp:3653-3656`、`scene/main/viewport.cpp:2213-2227,3489-3496,3716-3726`。静态源码只证明配置映射、buffer/dispatch与Viewport setter/hit-route语义，不冒充项目runtime fixture已执行。

### Remediation applied after explicit five-file approval

- `SET_TRUE_IN_FLIGHT`统一采用ScreenTouch containment：loading由armed-IDLE shield `accept_event()`后PREACTIVE_DISCARD且项目bank为0；resume由STOP shield按current-epoch FSM accept并写held bank，true返回后的first observer以`HELD_ONLY_RETURN_TO_DRAIN`回drain，不继续unpause/ACTIVE、不升级technical fault。
- AC覆盖press-held、press→release、press→cancel、duplicate press与capacity/FSM异常。press与terminal均在setter返回前完成时允许bank `0→1→0`并继续clean成功对照；所有格VJ/action/claim/generation/carrier/choice/gameplay consumer/top-state零写。
- 生产activation callback仍静态禁止`Input.parse_input_event`、`Input.flush_buffered_events`、`Viewport.push_input/push_unhandled_input`或等价注入；hostile runtime harness是绕过静态guard的containment正向测试。
- BOOT flush项目effect口径收窄，并冻结该窗口无项目Input polling/`window_input` consumer、flush后四movement action clean；Input accumulated使用实时readback，agile使用ProjectSettings冻结值验证。
- InputSystem、GameRoot、technical preferences、systems index与本review log已同步；未创建新ADR，未改变binary移动、shield FSM、Grid/Pool resume transaction或Viewport gate主架构。

### Remaining gates

- 本轮只是五文件文档remediation，尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/battle Viewport/CanvasLayer route、choice/Continue/readiness terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮只做setter-in-flight closure：验证loading PREACTIVE_DISCARD、resume held containment、press→terminal clean、duplicate/capacity/FSM异常、first observer reasoned release，以及无ScreenTouch成功对照；同时确认BOOT flush口径、GATE_HELD零投递和三种release reason未回归。通过前不扩大核心设计范围。

## Review — 2026-08-28 — Eighteenth Focused Viewport Activation Closure Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: S
Specialists: systems+QA, Godot+GDScript+performance, game+UX/UI/accessibility + creative-director synthesis
Seventeenth-review closure: 1 CLOSED
Blocking items: 1 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC标题唯一。第十七轮setter-in-flight ScreenTouch containment已按原目标CLOSED：loading PREACTIVE_DISCARD、resume current-epoch held bank、first-observer reasoned release及press→terminal clean对照内部一致。本轮发现一个独立的新谓词冲突：旧契约同时用`runtime_ingress_armed`门控ACTIVE gameplay ingress和LOCK_PENDING/FROZEN/RESUME_LOCKED shield bank service；consumer closed要求runtime=false，却又要求resume shield FSM写bank，二者不可同时实现。核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、Viewport gate阶段、shield FSM与Grid/Pool resume transaction均保留。

### Required Before Implementation（终审原始裁定）

1. 拆分adapter、gameplay ingress与consumer-closed shield service的启用谓词。`callbacks_armed`只表示initialize成功至teardown的callback生命周期；`runtime_ingress_armed`只允许ACTIVE的新VJ press、generation、action/carrier movement路径；新增`shield_bank_service_enabled`只允许LOCK_PENDING/FROZEN/RESUME_LOCKED的current-epoch bank/FSM、choice predicate与first-error latch。IDLE必须为`true/false/false`，ACTIVE为`true/true/false`，三种locked state为`true/false/true`，TERMINATED为`false/false/false`；ACTIVE guard必须原子翻转runtime/service，callback不得写两个enable字段。

### Specialist disagreements resolved by Creative Director

- Systems/QA把双用途predicate判为BLOCKING，因为它使同一resume fixture同时要求runtime=false与bank可写；Godot/GDScript/performance同意最小修复为新字段而非放宽runtime ingress含义。Creative Director采纳三字段拆分，以保持“暂停期绝不开放gameplay ingress”和“shield terminal必须可服务”两条安全边界。
- Game/UX/UI确认该修订不改变玩家可见流程、binary手感、Continue/held-drain反馈或choice交互，只澄清内部所有权；因此scope保持L但revision effort为S，不重开架构或数值决策。
- 推荐项（setter true返回后的额外readback failure分类、BOOT预装press的精确事件类型、fault/Home UI press可达性）继续作为后续实现/集成证据，不升级为本轮新设计blocker。

### Remediation applied after explicit five-file approval

- `input-system.md`冻结三字段职责、状态真值表、Public API后置、cancel顺序、Shield Bank FSM predicate、setter-in-flight writer allowlist、ACTIVE guard原子翻转及对应AC；loading始终service=false，resume locked始终runtime=false/service=true。
- `game-root-scene-flow.md`反向同步BATTLE_LOADING、pause cancel、RESUME_LOCKED、held-drain、Viewport activation与fault teardown的三字段状态；callback只能在已启用service内写bank，不得临时开关service。
- `technical-preferences.md`登记项目级实现约束；`systems-index.md`登记第十八轮结论与依赖边；本review log记录原始blocker、裁定与修订边界。
- 未改变binary移动、InputMap四action、shield bank数据结构、Viewport release reason、GameRoot七phase或Grid/Pool resume事务；未创建新ADR或实现资产。

### Remaining gates

- 本轮仅完成五文件设计契约remediation，修订后尚未经新的独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/battle Viewport/CanvasLayer route、choice/Continue/readiness terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 下一轮只做三字段closure：逐状态核对callbacks/runtime/service真值、setter-in-flight callback writer计数、shield FSM enable predicate、ACTIVE guard原子翻转、failure/held-only/teardown后置及第十七轮containment无回归。通过前不扩大核心设计范围。

## Review — 2026-08-28 — Nineteenth Focused Three-Field Closure Full Re-review — Verdict: NEEDS REVISION
Scope signal: L | Revision effort: S
Specialists: systems+QA, Godot+GDScript+performance, game+UX/UI/accessibility + creative-director synthesis
Eighteenth-review closure: PARTIAL
Blocking items: 1 implementation | Integration/evidence gates remain OPEN
Summary: 8/8必需章节完整，复审时34个AC标题唯一。第十八轮把`callbacks_armed`、`runtime_ingress_armed`与`shield_bank_service_enabled`拆为独立职责，稳定状态真值、loading/resume containment与ACTIVE guard主体成立；但普通cancel、pending-first safe-close、IDLE ending/fault cleanup与teardown前置仍能产生状态表外tuple。三路专项与Creative Director把这些表象去重为一个callback-observable consumer-close/terminal transaction blocker；核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、Viewport gate、shield bank、fresh-press与Grid/Pool resume transaction继续保留。

### Required Before Implementation（终审原始裁定）

1. 冻结唯一、callback-observable的consumer-close/terminal transaction。ACTIVE normal pause、fatal cancel或async safe-close必须在任何`set_mouse_filter(STOP)`同步callback及fallible action clear前，以无函数/property setter/signal/Callable/`await`的主线程局部提交原子发布`state=LOCK_PENDING、callbacks/runtime/service=true/false/true`；随后才STOP/clear，`ACTION_CLEAR_FAILED`保持该tuple进入fault。IDLE load-abort/cleanup/async必须保持`true/false/false`与PREACTIVE_DISCARD，禁止临时开启bank service；既有LOCK_PENDING/FROZEN/RESUME_LOCKED保持`true/false/true`。teardown须在任何filter/tree cleanup前先提交`TERMINATED + false/false/false`并撤销bank/choice/pending latch写权，迟到callback不得重填。

### Specialist disagreements resolved by Creative Director

- 无实质分歧。Systems/QA、Godot/GDScript/performance与game/UX/UI均同意唯一根因是state与三字段没有形成完整、可重入安全的关闭提交；终审采纳“先完整LOCK_PENDING tuple，再STOP setter与clear”的最小方向。
- Godot专项确认`Control.set_mouse_filter()`会同步刷新mouse-over并可能派发notification/signal，因此STOP-first会暴露ACTIVE=`true/true/false`，fields-first但state-last会暴露ACTIVE=`true/false/true`；两者都不满足Shield Bank FSM全谓词。终审将该窗口升级为本轮BLOCKING，而非只靠生产callback静态禁注入回避。
- Gameplay/UX确认缺口会让正常pause press未登记、choice gate误开或cleanup触点语义不唯一，但修订不改变binary手感、Continue/held-drain反馈或玩家旅程。

### Remediation applied after explicit five-file approval

- `input-system.md`新增唯一`commit_consumer_closed()`设计契约、callback-observable atomicity定义、state-aware `ASYNC_SAFE_CLOSE`、按state拆分的cancel矩阵，以及terminal-first teardown；Public API、first-error测试、AC-IS8/10/13与第十九轮冻结说明同步更新。
- `game-root-scene-flow.md`同步R1/R5/R6/R8、loading cleanup、invalidation矩阵、teardown AC与跨文档一致性清单；ACTIVE close先完整发布LOCK_PENDING tuple，IDLE不启service，terminal commit先于setter/tree cleanup。
- `.claude/docs/technical-preferences.md`登记项目级纯标量commit限制及失败后置；`systems-index.md`登记第十九轮结论、批准范围与Re-review Pending边界；本review log保存原始blocker、裁定和修订。
- 未修改binary移动、InputMap四action、shield bank数据结构、Viewport release reason、GameRoot七phase、Grid/Pool resume transaction或任何实现/project asset；未创建新ADR。

### Remaining gates

- 本轮只是五文件文档remediation，尚未经修订后的新独立full review；InputSystem继续为`Re-review Pending`，不得登记Approved、implementation-ready、integration-ready或任何运行AC PASS。
- PlayerController、BattleUI、`project.godot`/InputMap/battle Viewport/CanvasLayer route、choice/Continue/readiness terminal ownership、`SupportedTouchEventOrderingManifest`与Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 若后续再复审，只需验证本轮唯一transaction closure：ACTIVE close完整tuple先于STOP/clear、`ACTION_CLEAR_FAILED`不回滚、IDLE/locked state-aware safe-close、terminal-first teardown及迟到callback零写；不扩大核心设计范围。

## Review — 2026-08-28 — Twentieth Focused Consumer-Close Closure Confirmation — Verdict: APPROVED
Scope signal: L | Confirmation effort: XS
Specialists: prior full-review systems+QA, Godot+GDScript+performance, game+UX/UI/accessibility + creative-director synthesis；本轮由主审执行聚焦文本确认
Blocking items: 0 | Recommended: 0 | Integration/evidence gates remain OPEN
Summary: 第十九轮唯一callback-observable consumer-close/terminal transaction blocker已CLOSED。Edge Cases C与AC-IS10的两处STOP-first旧简写已改为唯一顺序`前置验证→commit_consumer_closed()原子发布LOCK_PENDING + true/false/true→shield STOP→release_movement_actions_and_clear(tick_revision)`，并与Core Rule 15、Public API、AC-IS8/10/13、GameRoot R1/D4b/F2及technical preferences一致；8/8章节与34个唯一AC保持不变。
Prior verdict resolved: Yes — Nineteenth Focused Three-Field Closure Full Re-review

### Approval boundary

- `Approved`仅表示InputSystem GDD设计契约通过；不表示实现、集成、运行AC、真机或性能证据已经通过。
- PlayerController、BattleUI、`project.godot`/InputMap/battle Viewport/CanvasLayer route、choice/Continue/readiness terminal ownership、`SupportedTouchEventOrderingManifest`、Android/iOS真机trace、AC-IS25/27/28人体协议、静态守卫和min-spec性能证据继续保持BLOCKED/OPEN。
- 核心`VirtualJoystick→4 empty-binding actions→binary F1→typed carrier`、Viewport gate、shield bank、fresh-press、held-drain与Grid/Pool resume transaction未改变；本轮未创建实现、project asset或新ADR。

## Implementation checkpoint — 2026-09-09 — Formal Input Vertical Slice Contract Gate

Scope: 执行第十三次收敛性复审后授权的下一步实现验证；不构成新的独立 full re-review 或 Approval。

### Executed

- 创建正式 Godot 4.7.1 工程 `production/input-vertical-slice`，包含 `project.godot`、`main.tscn`、`InputSystem`、`VirtualJoystickHost`、`MovementIntentCarrier` 与运行入口。
- 固化四个 empty-binding movement actions、`deadzone=0.0`、`Input.set_use_accumulated_input(false)` readback，以及 `emulate_touch_from_mouse=false`、`agile_event_flushing=false` 配置。
- 增加 18 项 headless contract test：InputMap、唯一内置 VirtualJoystick、三字段状态链、MOVEMENT_COMMIT 归一化、cancel/resume、revision rebuild、teardown 后置。
- 增加 machine-readable static guard，检查正式工程入口、InputMap 行、输入 writer 禁止项、内置 VJ 实例化和唯一 active VJ 后置。

### Evidence

- Godot editor headless import: PASS。
- `input_vertical_slice_contract.gd`: `INPUT_VERTICAL_SLICE_CONTRACT_PASS tests=18`。
- `input_vertical_slice_smoke.gd`: `INPUT_VERTICAL_SLICE_SMOKE_PASS`。
- Runtime startup: `INPUT_VERTICAL_SLICE_RUNTIME_OK state=ACTIVE active_vj_count=1 carrier=(0.0, 0.0)`。
- Static guard: JSON `status=PASS`。
- `git diff --check`: PASS。

### Boundary remains open

- 该证据只证明正式切片的静态合同、headless 状态链和启动时唯一 VJ 注册；尚未证明完整 GameRoot/BattleUI/Viewport route、VJ 私有 claim/reset/reentrancy、Android/iOS 真机 touch ordering、语义可访问性、GDUnit4、min-spec 性能/thermal 或玩家 UX。
- Meta UI 八行目前已声明并受静态守卫覆盖，但尚未接入实际键盘/gamepad bindings 或 `DirectionalFocusNeighborManifestV1` 的运行时 presenter/golden。
- InputSystem 状态仍为 `In Review / Re-review Pending`；`implementation-ready=false`、`runtime/device verified=false`、`battle_ready=false` 保持不变。

## Implementation checkpoint — 2026-09-09 — Unified CI Evidence Report

在已有 vertical-slice contract/smoke/static checks之上，新增真实 Godot `ScreenTouch→ScreenDrag→release` fixture，并将其与统一入口 `production/input-vertical-slice/tools/ci/run_checks.py` 一起执行；入口一次汇总 editor import、contract、smoke、touch-order fixture 与 static guard，并生成 `evidence/input_vertical_slice_check_report.json`。

本次执行结果：suite `PASS`；六个子检查均 `PASS`，其中 Godot 版本为 `4.7.1.stable.official.a13da4feb`，contract 为 `18` 项，touch-order fixture 为 `10` 项，GDUnit4 为 `v6.2.1 / 2 test cases / 0 errors / 0 failures / 0 orphans`。报告显式记录 `complete_game_root_battle_ui_integration=false`、`gdunit4_framework_and_slice_contract=true`、`gdunit4_full_review_gate=false`、`android_ios_device=false`、`accessibility_runtime=false`、`performance_thermal=false`、`battle_ready=false`，避免将切片证据扩大解释为生产验收。

InputSystem 仍保持 `In Review / Re-review Pending`，本 checkpoint 不构成独立 full re-review、Approved、implementation-ready 或 runtime/device verified。

## Implementation checkpoint — 2026-09-09 — Steps 1–3: GDUnit4 Touch, VJ Reentrancy, Minimal BattleUI

按授权执行下一步三项实现：

1. 将 `ScreenTouch → ScreenDrag → release` 纳入真实非 headless GDUnit4 `scene_runner("res://main.tscn")` 测试，验证动态 VJ claim、右向 movement action 与 release 后四 action 清理。
2. 补 VJ claim/reset/rebuild/reentrancy 合同：重复 `pressed` 不重复生成 claim；active claim 时 rebuild 返回 `STATUS_WRONG_STATE` 且不推进 epoch；release/reset 后新 revision rebuild 恰一次；同 revision 调用幂等；重复 initialize 不产生第二个 VJ。
3. 接入最小 BattleUI slice：8 行 Meta UI、8 个 focusable button，以及按 `DirectionalFocusNeighborManifestV1.algorithm.v1` 生成并应用 left/right 邻接的 manifest。该 slice 只用于 harness，不替代完整 GameRoot/BattleUI 生产集成。

### Evidence

- GDUnit4 已安装并固定为 `v6.2.1`；三个 suite 分别通过：Input 状态合同 `3 test cases`、真实触摸场景 `1 test case`、BattleUI/manifest `2 test cases`，合计 `6 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`。
- 统一入口 `python3 production/input-vertical-slice/tools/ci/run_checks.py --write-report`：`PASS`；editor import、18 项 headless contract、smoke、10 项 touch fixture、三组 GDUnit4 suite、static guard 均 `PASS`。
- 机器报告：`production/input-vertical-slice/evidence/input_vertical_slice_check_report.json`；新增边界标记 `real_touch_scene_runner=true`、`minimal_battle_ui_slice_integration=true`，同时保持 `complete_game_root_battle_ui_integration=false`、`gdunit4_full_review_gate=false`、`android_ios_device=false`、`accessibility_runtime=false`、`performance_thermal=false`、`battle_ready=false`。

InputSystem 仍保持 `In Review / Re-review Pending`；本 checkpoint 不构成独立 full re-review、Approved、implementation-ready、runtime/device verified 或 `battle_ready`。

## Implementation checkpoint — 2026-09-09 — Minimal GameRoot/BattleUI/Viewport Route

在步骤 1–3 的切片基础上，将 harness 路由收敛为 `GameRootSlice → root Viewport.gui_disable_input → BattleUICanvasLayer(layer=10) → BattleUI`，VJ/InputSystem 仍由同一 root Viewport 接收。GameRoot 在 `_ready` 先取得并验证 root Viewport、持有 gate、完成 Input/BattleUI 装配，只有 `ACTIVATION_SUCCESS` readback 后才释放 `gui_disable_input=false`；错误 reason 不得释放。新增 GDUnit4 场景测试覆盖 CanvasLayer owner、root Viewport identity、gate-held 阻断 touch，以及成功 release 后重新开放 touch。

### Evidence boundary

- GameRoot/Viewport route GDUnit4：`2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`。
- Godot editor import 与该场景测试均通过；当前环境未发现 `adb`，`xcrun simctl` 也不可用，故 Android/iOS 真机或模拟器证据未执行。
- `accessibility_runtime=false`、`performance_thermal=false`、`gdunit4_full_review_gate=false`、`battle_ready=false` 保持不变。该实现是最小 route harness，不构成完整 GameRoot/BattleUI 生产集成或批准。

## Review — 2026-09-11 — Clean-context Full Re-review — Verdict: BLOCKED / XL

Scope signal: XL | Minimum revision effort: XL (`MAJOR REVISION NEEDED`)
Specialists: game+systems、Godot+GDScript+performance、UX/UI/accessibility+QA + fresh creative-director synthesis
Structure: 8/8 required sections | 35 unique AC IDs | AC independence audit: Y=13 / D=20 / N=2

本轮对准确目标`design/gdd/input-system.md`执行只读clean-context full re-review；三份真实specialist报告由fresh creative-director综合，review期间未修改文件。Stage/render/batched-renderer不在本次Input verdict范围内。

### Prior blocker closure

- 正式主场景、Steam横屏/WASD scaffold、GameRoot先调Input再调gameplay、FROZEN/Shield/VJ rebuild、7001入口、102-node registry与四行workload manifest已出现，但都只形成`PARTIAL`或`REOPENED`；没有任何顶层blocker可记为完整`CLOSED`。
- F2 geometry、正式phase/context/lease ABI、完整pause/resume transaction、Meta/focus/native accessibility、Input workload阈值与runtime/device/UX证据继续`OPEN/BLOCKED`。
- 既有static、synthetic、isolated vertical-slice与本地headless smoke只在其声明边界内有效，不构成production runtime/device证据。

### BLOCKING findings

1. `[game+systems][UX/QA][Godot/performance]` Steam `move_*` active profile与canonical touch-only F1、portrait/VJ正文及生产双采样互相冲突；尚无真正互斥、逐公式/逐AC可审计的InputProfile。
2. `[game+systems][Godot/performance]` PC action deadzone=0且binary normalize会把手柄漂移放大为满速；键盘/手柄路径以`maxi(generation,1)`伪造generation，一次Input sample还可能被accumulator的多个fixed gameplay tick复用。
3. `[systems][creative-director]` 正式实现缺`run_phase(phase,context,lease_id)`、七phase/`POST_DEFERRED_BARRIER`、typed identity/revision与carrier消费ABI，无法证明pause ordering、stale input和exactly-once。
4. `[UX/UI/QA][Godot]` layer10全屏BattleUI的`MOUSE_FILTER_PASS`不能证明事件穿透layer5 VJ；Host内VJ晚于Shield加入且两者STOP时VJ先命中；resize/reset还可能遗留Host claim，正式GUI bank route不成立。
5. `[game+systems][UX/QA][Godot]` pause/background/resume缺三字段原子close、action clean readback、epoch-bound callback、typed pending release、revision snapshot、fresh-press rollback、held drain/readiness、不可逆点检查与terminal-first teardown；合法held-only不得升级为fault。
6. `[game+systems][UX/UI/accessibility/QA][Godot]` 八个Meta action events为空且P/R旁路；BattleUI发送Dictionary、screen/layout generation固定1，command ID每实例重置而GameRoot last ID跨局持久，第二局首个7001存在ABA拒绝。
7. `[accessibility/QA][performance][creative-director]` ASN05汇总21/capacity24与actual B01-B28共28行冲突；AC-IS3/22未按Steam profile重写，touch capacity manifest仍null而生产config硬编码4；缺唯一oracle与重新生成的capacity/hash/golden。
8. `[QA][performance]` 缺Windows release artifact上的物理键盘/控制器、deadzone/noise、remap/hotplug/focus/held、第二局7001、正式BattleScope routing/F2，以及CPU/frame/RSS/allocation证据。Android/iOS、TalkBack/VoiceOver与portrait UX在profile隔离后应作为future-port独立门，不阻塞Steam，但当前尚未隔离。

### Specialist disagreements resolved by Creative Director

- Android/iOS touch-order、TalkBack/VoiceOver与portrait UX本身不应阻塞Steam；当前阻断是profile未隔离。隔离后移动端保持`BLOCKED-FUTURE-PORT`，不得用Steam证据外推。
- Shield/VJ节点存在不等于lifecycle blocker关闭；实际CanvasLayer、`mouse_filter`和child顺序反例优先，正式routing仍`OPEN`。
- 7001 smoke只证明同一command重复拒绝，没有覆盖BattleUI replacement后的合法首击；不得据此宣称exactly-once关闭。

### Final boundary

最终verdict：`BLOCKED / XL`，最低修订级别`MAJOR REVISION NEEDED / XL`。InputSystem继续`In Review / Re-review Pending`；`implementation-ready=false`、`integration-ready=false`、`runtime/device verified=false`、`battle_ready=false`。

建议依赖顺序：先冻结Steam/mobile profile、PC source/deadzone/fresh-resume/arbitration与AC适用矩阵；再实现typed carrier/context/phase、真实GUI route、三字段close及完整pause/resume；最后在同一Windows release artifact上补物理输入、焦点/生命周期和Input workload证据。移动端证据保持独立future-port gate。
