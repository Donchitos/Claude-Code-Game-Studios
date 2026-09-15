# BattleUI（战斗界面）

> Steam任务/续局路由：mission-objectives.md与save-steam-pc.md定义六目标、暂停恢复点与RESULT_PENDING状态；UI只显示owner事实，COMPLETE匹配COMMITTED后才显示已到账/下一任务，STAGE_RESULT成功不作完成反馈。新目标HUD/保存退出旅程尚未实现。

> 2026-09-11 STEAM_PC R6：BattleUI只读InputSystem.neutral_required，在普通暂停/升级modal及恢复、active hotplug等待时显示回中说明，解除后移除；不额外poll输入、不改变门。Home/Active/Pause/Upgrade/Active-neutral/Settlement两尺寸均纳入R8表，Windows实测单列。

> **Status**: Designed / Full Review Pending — synced with 2026-09-10 InputSystem blocker remediation; BATTLE_ACTIVE pause gateway remains runtime/device unverified
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / qa-lead / ux-designer / art-director）
> **Created / Last Updated**: 2026-09-10 — InputSystem clean-context full review remediation（Option A pause gateway）
> **Implements Pillar**: 竖屏单手低打扰战斗；让生存、构筑、风险与终局信息一眼可读
> **Scope**: MVP battle HUD、暂停/选择交互、关键提示与 terminal handoff；不含 Settlement/Home/Prep 完整页面或最终资产

## 1. Overview

| 输入profile | 布局/交互权威 | 平台门 |
| --- | --- | --- |
| STEAM_PC | `input-steam-pc.md` PC07–10，1280×720响应横屏、键鼠/手柄focus、generation-bound 7001 | Windows完整菜单旅程与物理设备 |
| MOBILE_TOUCH / future-port | 本文3.4竖屏HUD、touch/ChoiceGestureSurface、ADR-0001原生ASN与移动AC | Android/iOS touch/safe-area/native a11y；BLOCKED-FUTURE-PORT |

PC modal P1补充（2026-09-11）：打开modal前背景pause按钮disabled/FOCUS_NONE，关闭后恢复。仅按PC显式binding表导航，规格外Up/Down/KpEnter不走Godot默认GUI旁路；拒绝设备、echo和release不得借默认Control转移焦点。

共享HP/XP/choice/Save owner边界保持不变。PC按钮序列不宣称实现移动ASN或方向几何golden。

BattleUI 是战斗态唯一玩家可见 UI composition owner，也是只读 presentation consumer。它把 GameRoot 原子捕获的同一逻辑时点、多 owner revision vector 组合为常驻 HUD、Boss/精英方向提示、暂停页、升级/宝匣/机缘选择页与 terminal/fault 暂存层。它不拥有 HP、XP、计时、技能冷却、选择结果、pause、terminal、Enemy、伤害或 Save truth。

界面遵守三条硬边界：只展示 matching、已发布、可 copy-out 的 typed view；所有交互先经过 Input blocked predicate 与 fresh-press 协议；成功反馈只来自 committed fact/receipt，不来自按钮按下、动画结束或 UI 本地计时。

BattleUI 不是 GameRoot phase participant，不运行 gameplay `_process/_physics_process`。唯一 GameRoot 在 sealed publish 后驱动 Active presenter，并在 ALWAYS control pump 中驱动 Paused/Resume、touch drain 与 cleanup。动画可用非权威 presentation time，但不得推进玩法状态。

## 2. Player Fantasy

玩家不需要盯仪表盘：余光能看出生命、替身符、等级进度和 Boss 阶段，方向提示回答“危险从哪里来”，但不自动导航。选择是短暂、明确的停顿：旧摇杆触点不会误选，返回键不会替玩家决定，连续选择不会同时铺满屏幕。

暂停页允许检查技能、属性和进化关系；恢复必须遵守 pause reason 与输入 drain。`VICTORY+lethal` 只呈现胜利，不闪死亡/复活；`UNSAFE_FALLBACK` 明示仍有危险，不伪装无敌。表现可以降级，玩法真相不能被装饰层改写。

## 3. Detailed Design

### 3.1 Owner、生命周期与 topology

- 每局一个 `BattleUiRoot`，是 persistent root Window 下 battle-scoped child；cleanup 先撤销 callback writer、逻辑 detach，frame-end barrier 后才物理释放。
- 不加入 `RequiredPhaseManifest`，`LIFECYCLE_INTENT / FACT_COMMIT / PAUSE_CLOSURE / BLOCKING_CHOICE` contribution 均为 0；SkillDraft 14 与 RiskChoice 2 仍由各 owner 贡献。
- 不持有 gameplay Node、authority bank、Damage carrier、RNG、Pool lease 或 Grid handle。只持 caller-owned copy-out backing、stable identity、revision vector、focus/press state 与 reader cursor/ACK。
- 固定 scene-tree/Canvas 顺序：`world < VirtualJoystick < movement shield < passive HUD < interactive overlay < terminal/fault safe surface`。命中唯一性由 tree order、effective `mouse_filter`、`accept_event()`和真实 event trace 证明，不得只靠 `z_index`。
- Host、Shield、VJ、BattleUI 与 Stage camera 同属唯一 root Window；MVP 不建 battle SubViewport。

### 3.2 原子 read bundle

GameRoot 发布：

```text
BattleUiFrameBundleV1={
 schema_version=1,battle_instance_id,config_snapshot_id,topology_revision,
 capture_tick,bundle_generation,source_revision_vector,
 player_hud,player_frame,progress_hud,weapon_hud,boss_hud,
 elite_bank,risk_bank,combat_event_bank,foreground_choice,
 orchestration_view,valid
}
```

- 各 owner revision 不要求数值相等；GameRoot 必须在同一 sealed capture 中记录每个 source 的 expected identity/revision/generation，并逐项 copy-out。任一 state-applicable source mismatch/invalid 时不拼帧：保留上一完整只读帧或显示显式 unavailable，同时关闭相关交互。
- 不适用 source 用 typed `presence=false`，禁止 null、空 Dictionary 或零值冒充。
- 精确复用 `PlayerHudSnapshotV1` 与 `PlayerPresentationFrameV1`。BattleUI 只有取得 matching frame、联结 winner 且把表现真正提交到可见槽或冻结 P0 fallback 后，才以 BATTLE_UI bit `0b010` exact-once ACK；仅 enqueue 不算消费。
- 新 view 需求：`LevelingHudViewV1{level,xp_in_level,xp_required_for_next,at_cap,kill_count,completed_gameplay_ticks}`；`WeaponHudSnapshotV1` 最多4槽；`BossPresentationViewV1` 最多1行；`ElitePresentationBankV1` 最多4行；`RiskChallengeViewV1` 最多2行；`CombatPresentationEventBankV1`。全部含 battle/config/revision/generation/valid 且禁止 backing alias。
- 上述新 ABI 尚未由 owners 反向签发，为 `BLOCKED-HUD-VIEWS/PRESENTATION-ABI`；禁止临时扫 Node/fact bank或本地重算替代。
- Damage 提到的通用 `shield` 尚无唯一 owner/view，且不在封闭 `PlayerHudSnapshotV1` 中。本文不设计通用盾条；Risk ward 只作为独立“20%减伤护身”状态。

### 3.3 Surface 与 interaction 状态

Surface 投影：`HIDDEN / HUD_ONLY / PAUSE_OVERLAY / CHOICE_OVERLAY / TERMINAL_STAGED / FAULT_STAGED / TORN_DOWN`。

Interaction：`DISABLED → BLOCKED → READY → PRESSED → SUBMITTING → TOUCH_DRAIN → DISABLED/READY`。

- Loading 隐藏；Active 仅 HUD；PausePending 保持 HUD 并给一次锁定反馈；Paused 按 foreground 显示一个 overlay；ResumePreparing 保持原 overlay 且禁用；Ending/Fault 分别进入 staged safe surface。
- UI 只投影 GameRoot，不复制其 guard/priority。所有迁移带 battle/bundle generation；旧 callback 为 `OK_NOOP`。
- 同时最多一个 interactive foreground；只显示“后续选择 N”，不镜像或重排完整16行队列。
- terminal precedence：`FATAL > VICTORY > DEFEAT > ABANDONED > PAUSE > NONE`。terminal 时 choice/pause control 为0。

### 3.4 竖屏 HUD

安全区顶部从上到下：

1. HP数值/条+替身符；completed gameplay timer；击杀数+暂停按钮。
2. `LV.N`+XP条；Level 40显示`MAX`，无伪阈值。
3. 4个稳定主动技能槽：family、等级/进化、owner发布的 cooldown。
4. Boss存在时单条全宽HP rail、名称和50%刻度。
5. 最多2个短状态签：Risk ward、夺宝精英计时/“持续追击”。

除暂停按钮外常驻 HUD 全部 `mouse_filter=IGNORE`。顶部不得侵入 Input lower 45% movement region；伤害数字、vignette、方向标也不截获触控。Boss rail 可保留稳定占位，Boss出现时不移动暂停热区。

### 3.5 Player、等级与技能

- HP ratio 仅在 finite、`max_hp>0`、`0<=current_hp<=max_hp` 后计算，不用 clamp 掩盖非法数据。
- 替身符固定位置、图形+文字双编码：完整符形“可用”；断裂符形“已用”。
- REVIVE 首个可见bundle原子显示 `35% HP + SPENT + generation+1`，中间 HP0/死亡页为0。SAFE/UNSAFE按同一事实表现；UNSAFE加危险三角/断环和“落点仍有危险”，无盾环、无无敌倒计时。
- `VICTORY+lethal` 只显示胜利，符仍AVAILABLE；HIT/DEATH/REVIVE/DEFEAT/pause cue全抑制。
- 同tick多级可显示“连续突破×N”，但每个SkillDraft choice分别完成。XP阈值来自Leveling view，UI不复制 `T(L)`。
- 4技能槽不重排、不本地倒计时；cooldown=0只表示owner发布due，成功commit后才由新view重置。
- 低血阈值暂定进入`<=30%`、恢复到`>35%`重置，为 `PROVISIONAL-UX` presentation hysteresis，不影响伤害/死亡。

### 3.6 Boss、Elite、Risk 与方向

- Boss bar 从 matching arrival/view 后出现，death/terminal后清除；P2显示断段鳞纹+“二阶段”，当前动作最多一条。世界 telegraph 始终是躲避主通道。
- 跟踪1 Boss+4 Elite共5身份后再聚合，不能先截断。Boss永不与Elite合并；Elite同22.5°扇区可成组，但显示总数、Risk数、behavior mask，reward-bearing身份不隐藏。
- 组内排序：`danger_priority DESC → reward_bearing DESC → distance_sq ASC → enemy_id ASC`。所有marker无输入/focus。
- Risk倒计时只读Active ticks；到2700 ticks exact-once改“持续追击”，不显示负数、失败或奖励失效。
- sealed VICTORY 后核心灵药/传送阵为不可交互表现，不显示“靠近拾取/点击传送”。

### 3.7 伤害数字与反馈容量

- 只显示 committed applied amount；仅相同target、damage class、merge window可聚合。crit/heal/shield-only/partial shield/毒域使用符号、轮廓或前缀，不只改色。
- 合并窗口建议12 Active ticks、普通生命周期36 presentation frames，均 `PROVISIONAL-PRESENTATION`，需Damage owner签发。
- 同时可见 label cap=64；Pool cap=96由`64 active +16 spawn-before-release +16 spare`构成。必须分别验证63/64/65可见及95/96/97 borrow，不能把96写成可见数。
- overflow 采用 PRESENTATION `OVERFLOW_DROPPED`：丢新低优先级数字、telemetry+1、0动态instantiate、0 gameplay变化。Player critical/Boss phase/terminal不借用该池。

### 3.8 统一 choice bottom sheet

- renderer支持Level 1..3行、Treasure 1..4行、Risk恰2行；foreground row cap=4、in-flight command cap=1、pending count range=0..16。
- Skill行显示类型、当前→目标等级、成长轴、槽位状态、剩余免费刷新；1/2项诚实显示，不复制。
- Treasure显示1..4项；无进化但有未满技能显示owner committed自动+1确认。全满且无候选仍 `BLOCKED-TREASURE-EXHAUSTION`，UI不造补偿。
- Risk两行必须保留：SAFE实际预计恢复`+X`、20%减伤10秒、不增敌；TREASURE新增1强化精英、生命/基础伤害+30%、45秒后持续追击、击杀240 XP+宝匣。
- panel≤safe height 50%，整行可点。2/3行主操作不得滚动；4行允许详情区滚动但身份、关键数值与选择动作始终可见。back/outside/slide/旧release不关闭、不选择、无默认项。

### 3.9 Fresh press 与全屏 `ChoiceTouchDrain`

- `ChoiceGestureSurface` 位于shield/VJ之上，`PROCESS_MODE_ALWAYS`、effective `MOUSE_FILTER_STOP`；它消费全屏所有ScreenTouch press/motion/release/cancel。原始Button只负责视觉/键盘焦点，不能用丢失touch index的`pressed()`作为触控identity。
- touch bank capacity 必须等于 `SupportedTouchEventOrderingManifest.max_concurrent_touches`，与Input shield同源；该manifest未建立，数值保持BLOCKED，不得猜4/10。
- 稀疏固定槽FSM：`FREE/HELD/COMMAND_ACCEPTED/TERMINATED`；identity=`{battle_instance_id,overlay_generation,touch_index,press_sequence}`。第一根合法fresh press可arm命令，其余触点只吞掉。
- 每次press、提交前、touch-drain完成前即时读`is_choice_input_blocked()`，不缓存bool。blocked episode首个拒绝操作只提示一次“请先松开移动触点”。
- matching release仍在同row才发typed command；cancel/滑出/第二触点/mismatch均0 command。command只含owner token、command_id、row_id、expected revision，无数值payload。
- receipt后卡片锁定，但surface直到所有matching touch terminal才撤。GameRoot reason完成条件必须为`owner_choice_committed && held_count==0 && !Input.is_choice_input_blocked()`；terminal胜出不resume。
- overflow/负index/非法FSM：先accept_event，first-error-wins latch，保持Paused且0 command。choice receipt、touch-drain complete、Player presentation ACK是三种不同协议，不共用ack。

### 3.10 Pause、terminal、fault

- 暂停按钮只请求MANUAL。标题精确为：MANUAL“试炼暂停”；LEVEL_UP“境界提升：选择一项”；TREASURE“法宝机缘：选择一项”；RISK“机缘抉择：选择一项”；APP_BACKGROUND“已安全暂停，准备好后继续”；GEOMETRY“界面已调整”。
- MANUAL页显示只读技能/属性/进化关系；“结束试炼”先二次确认。确认请求ABANDONED，取消仍Paused。警示文案：“本局奖励、纪录与教程进度均不结算，已消耗的开局准备资源不补偿。”
- MANUAL/APP_BACKGROUND要求fresh“继续”；纯geometry可自动；choice-only队列清空可请求resume，但其他reason仍保留时不得显示已恢复。
- Ending仅显示noninteractive staged surface，sealed outcome后交给Settlement。进入`CONTROLLED_FAULT`时BattleUI只关闭choice/pause并detach自身交互；安全故障页由persistent GameRoot的`FaultPresentationBundleV1`与root fault presenter显示，BattleUI不生产fault snapshot、不伪造战果。
- 缺非关键资产按`final → approved placeholder → text/shape P0 fallback`降级；缺authority source、touch terminal或topology matching不能视觉降级，必须关闭交互并fault。

## 4. Formulas

### F1 — HP / XP / cooldown ratio

The `battle_ui_progress_ratio` formula is defined as:

`ratio = current / maximum`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Current | `C` | float64/int64 | finite, `[0,M]` | owner published numerator |
| Maximum | `M` | same domain | finite, `>0` | owner published denominator |

**Output Range:** finite `[0,1]`；非法输入使source invalid，不clamp冒充合法。  
**Example:** `35/100=0.35`；`0/0`不显示空条。

### F2 — Gameplay clock

The `battle_ui_gameplay_clock` formula is defined as:

`whole_seconds=floor(completed_gameplay_ticks/60)`  
`minutes=floor(whole_seconds/60)`  
`seconds=whole_seconds mod 60`

**Variables:** `completed_gameplay_ticks`为int64、`>=0`、只计成功Active tick。  
**Output Range:** minutes `>=0`，seconds `[0,59]`，格式`MM:SS`且分钟不截断。  
**Example:** 43200 ticks=`12:00`；Paused 30秒仍不变。

### F3 — Choice geometry

The `battle_ui_choice_geometry` formula is defined as:

`row_height=max(56,safe_height*0.044)`  
`row_gap=max(8,safe_height*0.00625)`  
`rows_height=n*row_height+max(0,n-1)*row_gap`  
`panel_height=min(rows_height+chrome_height,safe_height*0.50)`

**Variables:** safe height finite `>0`；`n∈[1,4]`；chrome finite `>=0`。  
**Output Range:** row≥56、gap≥8、panel≤50%。若内容超限只允许批准的详情scroll，不缩热区/字号。  
**Example:** safe height 640、n=4时rows=248；若chrome=72，panel恰320。

### F4 — Edge marker

The `battle_ui_edge_marker` formula is defined as:

`d=target_canvas-player_canvas`  
`k=min(valid signed ray-to-warning_safe_rect edge intersections)`  
`marker=center+k*d; angle=atan2(d.y,d.x)`

**Variables:** target/player/safe rect finite；按dx/dy符号选择边界，零分量跳过。  
**Output Range:** marker在warning safe rect边界；zero/nonfinite隐藏该row并telemetry，不产生NaN。  
**Example:** 正右目标落在`safe_right-margin`且箭头朝右。

### F5 — Risk / ward countdown

The `battle_ui_remaining_seconds` formula is defined as:

`remaining_ticks=max(0,deadline_tick-current_active_tick)`  
`seconds=ceil(remaining_ticks/60)`

**Variables:** risk范围0..2700，ward范围0..600，均为owner发布Active tick。  
**Output Range:** 非负整数秒；Risk到0切“持续追击”，ward到0移除，不用wall clock。  
**Example:** remaining=1 tick显示1秒；0 tick不显示负数。

### F6 — Capacities

The `battle_ui_capacity` formula is defined as:

`tracked_direction_identities=Boss(1)+Elite(4)=5`  
`foreground_rows=max(Skill(3),Treasure(4),Risk(2))=4`  
`pending_count_max=SkillDraft(14)+RiskChoice(2)=16`  
`damage_number_pool=visible(64)+spawn_before_release(16)+spare(16)=96`

**Output Range:** exact `5/4/16/96`；required−1/required/+1分别失败/成功/上游拒绝或presentation overflow。touch bank不在本公式，须由平台manifest定容。

## 5. Edge Cases

1. 任一source stale：不混出新HP+旧XP/旧Boss phase，交互关闭。
2. Loading/新局收到旧callback：OK_NOOP。
3. pause与terminal同barrier：只显示terminal。
4. revive+pause：首帧即35%HP+SPENT；无HP0中间帧。
5. VICTORY+lethal：胜利唯一，符仍AVAILABLE。
6. Level40继续XP：MAX，无fake threshold。
7. 1项offer：只显示1项，不复制/自动选。
8. 4项+大字体：仅详情scroll，关键数值不裁切。
9. treasure exhausted无owner result：保持blocked/fault-safe，不自造奖励。
10. 旧VJ touch held：0 command，terminal后还需fresh press。
11. press滑出后release：0 command且不建立movement。
12. receipt早于release：保持TOUCH_DRAIN，Active不可publish。
13. terminal事件丢失：保持safe paused/fault，不超时猜完成。
14. queue空但MANUAL存在：保留Pause与Continue。
15. Continue后再次后台：无Active闪帧。
16. Boss+4 Elite同方向：跟踪5身份，reward-bearing不隐藏。
17. 第65个可见数字：按冻结策略不超过64；第97个pool borrow不动态扩容。
18. rebuild：已ACK不重播，未ACK重绑后恰表现一次。
19. geometry change：GEOMETRY pause后原子换layout generation。
20. 合法cleanup detach：切CleanupViewportHandoffManifest，不误报drift。

## 6. Dependencies

| System | Contract | Status |
|---|---|---|
| GameRoot | atomic bundle、TopState/pause/terminal、touch-drain gate、cleanup | In Review；actual binding待传播 |
| InputSystem | geometry、blocked predicate、touch manifest、event route、BATTLE_ACTIVE pause gateway | Re-review Pending；2026-09-10 MAJOR REVISION NEEDED / XL整改中，真机trace BLOCKED |
| PlayerController | HUD/frame、consumer bit与critical ACK | Full Re-review Pending |
| Drop + Leveling | live level/xp/kill/tick view | Designed；正式view缺失 |
| SkillDraft / RiskChoice | offer、typed command/receipt、14+2 pending | Designed；full review pending |
| Weapon | 4槽与cooldown view | Designed；正式view缺失 |
| Damage | combat event bank、64/96、merge/drop/ACK | Designed；ABI/策略缺失 |
| Boss / Elite | HP/phase/action/risk/direction views | Designed；正式view缺失 |
| Config | scene/layout/capacity/allowlist/hash | In Review；本文facts待登记 |
| Settlement / Save / BattleRules | sealed terminal handoff | 三者作者GDD均已冻结；capture/copy/save/runtime integration仍BLOCKED |
| Art / VFX / Audio | P0 fallback、最终资产与mix | Audio Designed / Full Review Pending；Art/VFX/Sound Bible/assets仍BLOCKED |

## 7. Tuning Knobs

| Knob | Initial / constraint | Status |
|---|---|---|
| canvas | 720×1280, canvas_items, expand | locked contract；asset missing |
| movement region | lower 45% safe viewport | locked |
| choice row/gap/panel | F3 | locked formula |
| HUD safe margin | `max(12,0.02*min(w,h))` | provisional UX |
| font scale | 100% / 115% / 130% | provisional UX |
| minimum touch target | 56 logical px contract lower bound；目标≥48dp | runtime verify |
| low HP | enter≤30%, reset>35% | provisional UX |
| damage merge/lifetime | 12 ticks / 36 frames | provisional presentation |
| direction grouping | 22.5° | provisional UX |
| marker/row/pending/visible-number/pool | 5/4/16/64/96 | locked |

## 8. Visual & Audio Requirements

- 优先级：terminal/fault与Player致命危险 > blocking choice > Boss > Elite/Risk > 构筑进度 > 普通反馈。
- P0：Player轮廓、即将生效危险、fog硬边、UNSAFE、blocking control/focus、winner、输入故障；永不丢，必须预加载无粒子fallback。
- P1：HP/符、Boss条/phase、低血、受击方向、Boss/Risk/Elite marker、ward结束；可去shader，不可去语义。
- P2/P3依次为构筑/重要命中与普通数字/装饰；降级顺序`P3→P2高级效果→P1高级效果`，P0不降。
- 所有危险、符、crit/heal/ward/risk/phase至少两条非颜色通道；重复闪烁≤2Hz，支持reduce motion。
- Audio只收exact-once语义handoff；同tick稳定聚合，低优先级不抢terminal/revive/Boss危险。静音时信息阈值不降低。
- Art Bible、字体、图标、VFX/SFX、bus/mix与振动未签发，placeholder不构成生产验收。

## 9. UI Requirements

- 触屏、键盘、控制器焦点独立；复杂页面显式focus neighbor，不依赖自动猜测。
- 方向焦点唯一采用 ADR-0001 的 `DirectionalFocusNeighborManifestV1`；BattleUI 对每个 screen/variant 只消费其 `left_node_id/right_node_id` 与 `algorithm_version`，动态可见性变化时重建并匹配对应 golden，不自行推导邻接，也不退化为 previous/next。
- accessible name/state/value与reading order完整；live region只播choice打开/commit、低血首次、revive、Boss phase、terminal，禁止逐damage/cooldown播报。`BATTLE_ACTIVE`按ADR-0001新增仅含暂停入口的`ASN08/AHP07` gateway：固定capacity1、exact bytes356、node `7001` 为唯一可激活按钮，不发布战斗HUD交互节点；激活只进入现有typed pause command路径。`BATTLE_PAUSED`是ADR-0001的action-bearing TopState，必须按ASN05发布固定capacity24、exact bytes6060、非choice最多21行、choice用七行替换四个reason后最多24行的`AccessibleScreenSnapshotV2`，unused tail全零。`CONTROLLED_FAULT`固定capacity12 snapshot由persistent GameRoot root fault presenter按ASN07发布，BattleUI生产数0。BattleUI仍只消费snapshot/typed command，GameRoot每render frame drain adapter mailbox。
- `BATTLE_ACTIVE` gateway的唯一业务输入为`BattleActivePauseCommandV1`：BattleUI只校验`screen_generation/layout_generation/node_id=7001/enabled/accepted_command_id`并发给GameRoot；GameRoot以`command_id`首见原则exactly-once接纳，转换为`PAUSE_REQUESTED(reason=MANUAL)`。任何stale、duplicate、disabled、非7001或非BATTLE_ACTIVE command为0 effect；BattleUI不得直接调用GameRoot pause、SceneTree或Window setter。
- 248-byte row必须携带当前layout generation、safe-area logical bounds、visible/clipped及typed localization args；reflow后旧layout native action为0 command。Godot 4.7.1 Control transform、RichTextLabel、AccessibilityLiveMode等路径须目标build spike；TalkBack/VoiceOver未验证前保持`BLOCKED-ACCESSIBILITY-MOBILE-RUNTIME`。
- 100/115/130%字体、简中、英文扩展30%、伪本地化；关键代价不可截断，不能靠缩字体过线。
- resize/rotation期间通过GEOMETRY pause原子切layout；Active中不临时setter修补hit target。
- Loading预实例化固定Control/card/marker/64 active label与96 pool backing；steady state不instantiate/free/add_child/resize容器/新Tween/Dictionary/closure。文本缓存或glyph atlas策略须Config冻结，未验证前不宣称零分配。

## 10. Acceptance Criteria

> 标签：`[U]` unit、`[I]` integration、`[R]` Godot/runtime、`[M]` min-spec、`[UX]` user、`[A]` accessibility、`[P]` presentation。这里只冻结验收设计，未附artifact均未通过。

- **AC-BUI01 `[U][I]` owner boundary**：Given全状态writer spies，When ingest/choice/teardown，Then仅写presentation、typed command、touch/fault latch与自身cursor；gameplay/SceneTree/Window writer=0，phase/contribution=0。
- **AC-BUI02 `[U][I]` atomic bundle**：逐source制造stale/bank flip/generation change；只有GameRoot sealed revision vector全匹配才publish，mixed frame=0。
- **AC-BUI03 `[I]` revive/winner**：SAFE/UNSAFE/pause/VICTORY组合逐帧；普通revive首帧原子35%+SPENT，VICTORY+lethal只有胜利。
- **AC-BUI04 `[I]` Player ACK**：matching frame+winner+可见槽/P0 fallback后只ACK `0b010`；跨revision/仅enqueue ACK=0；rebuild前后已ACK不播、未ACK恰一次。
- **AC-BUI05 `[U][I]` HUD math**：F1测0/边界/max/非法；F2测0/59/60/3599/3600/43200与pause；Level40 MAX、4槽不重排/不本地计时。
- **AC-BUI06 `[I]` Boss/Elite/Risk**：1 Boss+4 Elite同方向/离屏/phase/2700tick，5身份不丢、Risk奖励不隐藏、持续追击exact-once、0负倒计时。
- **AC-BUI07 `[U][I]` capacities**：分别验证direction 4/5/6、rows 3/4/5、pending15/16/17、visible63/64/65、pool95/96/97；非法上游fail closed，presentation overflow不改gameplay。
- **AC-BUI08 `[I][R]` choice geometry/content**：1/2/3/4行与最长copy在四档viewport、safe inset、三档font下满足F3；Risk六个关键事实完整，2/3行不scroll。
- **AC-BUI09 `[I][R]` fresh press**：旧VJ/shield、outside/back/slide/second touch各20次，command=0；全terminal后fresh press+inside release恰1。
- **AC-BUI10 `[I]` blocked episode**：每input route同episode连续10次拒绝只提示1次；新episode可再1次。
- **AC-BUI11 `[I][R]` drain**：receipt早/同/晚于release/cancel，只有owner committed、held=0、blocked=false才完成reason；丢terminal安全暂停/fault。
- **AC-BUI12 `[I]` exact-once command**：100次duplicate、conflict、stale、cross-battle，合法effect恰1；其他在selector/ACK/effect/RNG前拒绝。
- **AC-BUI13 `[I]` pause journeys**：manual/background/geometry及组合逐条验证title、reason retention、Continue/auto resume，无Active闪帧。
- **AC-BUI14 `[I]` manual abandon**：Active不能直退；Paused confirm恰一ABANDONED，cancel保持manual pause。
- **AC-BUI15 `[R]` event uniqueness**：目标build记录Control tree/effective filter/accept trace，每个touch terminal唯一owner；z-index截图不能作为通过证据。
- **AC-BUI16 `[R][UX]` safe/readability**：720×1280、360×640、390×844、430×932+cutout/gesture；HUD不侵入lower45%。5人×设备×手×核心控件20次，命中≥19/20、误选0。
- **AC-BUI17 `[UX][A]` glance/non-color**：HP/符/ward/UNSAFE/Boss phase/choice代价每人20次正确≥19、中位≤1s；灰阶/三类色觉/静音分别过线，缺raw记录为INCONCLUSIVE。
- **AC-BUI18 `[A][R]` focus/a11y**：触屏/键盘/控制器完整旅程，name/state/value/flow准确；BATTLE_ACTIVE必须可到达并激活唯一`7001/BATTLE_ACTIVE_PAUSE` gateway，且不得出现其他战斗HUD rows；BATTLE_PAUSED V2 rows的bounds/layout generation/typed args逐值matching，reflow后stale callback命令0；adapter在所有TopState恰每render frame drain一次；damage number不形成live洪水；移动screen-reader未验证不得PASS。
- **AC-BUI19 `[P]` semantic cues**：revive/unsafe/level/Boss/choice/terminal cue只在matching committed edge一次；VICTORY+lethal death cue=0；P0耗尽测试丢失/遮挡/输入变化=0。
- **AC-BUI20 `[M]` allocation/performance**：full-load Active与Paused choice各10000 iteration×3，预热后动态Node/Tween/容器增长=0并有positive control；报告CPU/GPU p50/p95/p99/max、draw/overdraw/RSS。min-spec与阈值未冻结前保持OPEN。
- **AC-BUI21 `[I]` evidence truth**：每项记录fixture、build SHA、config hash、device与raw artifact；静态grep、headless smoke、单张截图不得替代runtime/UX/a11y/perf。

## 11. Open Questions / Blockers

| ID | Status | Required closure |
|---|---|---|
| OQ-BUI01 | BLOCKED-INTEGRATION | GameRoot签发bundle actual capture/copy matrix；各owner revision无需相等但必须同sealed时点。 |
| OQ-BUI02 | BLOCKED-HUD-VIEWS | Leveling/Weapon/Boss/Elite/Risk/Combat正式typed views；通用shield不自造。 |
| OQ-BUI03 | BLOCKED-INPUT | touch manifest、全屏touch bank数值、GameRoot drain完成门与fault service。 |
| OQ-BUI04 | BLOCKED-PRESENTATION | Damage bank、64可见/96 pool、merge/drop/ACK和producer worst-case。 |
| OQ-BUI05 | BLOCKED-CHOICE | choice kind priority actual table/hash、Treasure exhaustion result。 |
| OQ-BUI06 | BLOCKED-ASSET | project.godot、BattleUI scene、Art/VFX/Audio/P0 fallback、字体与copy table。 |
| OQ-BUI07 | BLOCKED-ACCESSIBILITY-MOBILE-RUNTIME | ADR-0001已冻结semantic bridge路径；TalkBack/VoiceOver插件能力、战斗overlay映射与真机尚未验证。 |
| OQ-BUI08 | BLOCKED-TERMINAL-INTEGRATION | Save与Settlement/BATTLE_RULES已冻结typed handoff；actual capture/copy/runtime仍BLOCKED。 |
| OQ-BUI09 | BLOCKED-PERF/EVIDENCE | min-spec预算、真机、动态字体、色弱/静音/遮挡与raw profiling。 |
| OQ-BUI10 | FULL-REVIEW-PENDING | clean-context独立full review未执行；作者咨询不等于批准。 |
| OQ-BUI11 | RUNTIME-BLOCKED | Godot/GDUnit4/设备验证未执行，`battle_ready=false`。 |

Audio、Save、Settlement、Home与Prep作者GDD均已完成。本文足以作为UI接口协商基线；OQ-BUI01–09、跨页面runtime接线及独立full review未闭合前，不得称implementation-ready或runtime verified。
