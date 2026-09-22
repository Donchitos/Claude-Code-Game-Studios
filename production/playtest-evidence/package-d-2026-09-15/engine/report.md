# D包独立引擎 / GDScript / 恢复复审

日期：2026-09-15。独立审阅者：D engine specialist。**Verdict: CHANGES REQUIRED（P1 × 1，P2 × 1）**。

## 范围和方法

按 `.claude/skills/code-review/SKILL.md`、`src/CLAUDE.md`、引擎 VERSION.md、ADR-0008 和 `design/chapter-one-playable-redesign.md` 审阅冻结的 dirty worktree A–C 实现，而非仅 HEAD。`review-freeze.json` 的 57 个 SHA256 均与实测源码匹配，HEAD 为 e2ed080b8e35522863d7bc24e7c29de808855fc0。主要覆盖 ChapterOne、Encounter、Arena、Codec、Validation、Combat、GameRoot、Profile，并追读 Mission。

运行引擎实际输出：Godot 4.7.1.stable.official.a13da4feb。新增的三个探针和日志仅写本 engine 证据目录；真实磁盘双槽采用 OS 临时目录中新前缀 `independent_d_engine_*`。Root 探针 headless 使用内存 storage。未接触用户存档，未改生产代码、配置、设计或作者原测试证据。合成进度、实体容量和 HP 只用于边界复现，不作为合法旅程、真人试玩或平衡证据。

## P1：容量故障后“保存并返回”仍覆盖最后可靠任务快照

**主位置：`src/campaign/campaign_game_root.gd:157–165`（尤其162），并联 `campaign_profile.gd:207–214`、Root quit_game 的同类保存路径。**

触发：04 猎物必需生成在容量已满时重试60 tick并进入 `HUNT_CAPACITY_RETRY_EXHAUSTED`；关闭错误弹窗回暂停，再保存并返回首页，或走窗口退出保存。Root 只在 `_physics_process:247–249` 拦截故障，不在持久化出口拦截。`Profile.save_run` 注释要求 caller 完成语义验证，但 Root 未调用；Profile 的 `_valid_run` 也只要求 snapshot 是 Dictionary。于是 Arena 明确拒绝的故障状态仍能落盘。

独立实测：

- `probe.log`：`FAULT error=HUNT_CAPACITY_RETRY_EXHAUSTED retry=60 arena_valid=false`；紧接 `FAULT_SAVE accepted=true`。
- 同日志真实双槽销毁/重建 Storage 与 Profile：`FAULT_RELOAD profile=true`，但 `FAULT_RESTORE arena=false durable_error=HUNT_CAPACITY_RETRY_EXHAUSTED`。
- `root_probe.log` 通过实际 Root 方法链确认：`ROOT_FAULT modal=error paused=true` → `ROOT_HOME saved=true page=home durable_error=HUNT_CAPACITY_RETRY_EXHAUSTED` → `ROOT_CONTINUE result=false modal=error`。

影响：原先可靠 current_run 被不可恢复的最新 generation 取代；玩家正常“继续”失败。某旧槽可能仍留有历史 generation，不等于游戏会自动恢复到它。当前目录正常遭遇有保留名额，本探针明确是异常容量注入，未证明普通试玩自然达到180实体；但该受控故障路径本身是 C 包明确承诺的恢复安全要求。

**ADR compliance：VIOLATION。** ADR-0008 C扩展要求失败状态拒绝持久化、保留上次可靠档案；实际违背。作者 C 测试 `tests/integration/campaign_package_c_test.gd:106` 仅断言 `Arena.validate_snapshot` 返回 false，未执行保存，却把标签写成“error state cannot overwrite valid save”；237通过不能证明写入口安全。

需要整改后的验收：用合法可靠 checkpoint 起步，复现该故障后覆盖 save/home、quit、retry 出口，确认不发布新故障 afterimage，重建双槽后恢复原 checkpoint；不能只补 validator 负例。

## P2：玩家或护送物死亡 tick 的合法终态无法通过首章恢复校验

**主位置：`src/campaign/campaign_mission.gd:27–33` 与 `src/campaign/campaign_encounter.gd:159`；相关 Root 自动保存为 `campaign_game_root.gd:254–260`。**

Arena 在 step 起点推进 `state.elapsed`，Mission 遇玩家死亡或 escort_destroyed 却在推进 `objective.elapsed` 之前返回。首章 validator 无条件要求两者差小于0.00001，因此合法死亡终态固定相差1/60秒而遭拒。

独立实测 `probe.log`：用正常 Combat.zone 造成致命伤，任务01、03、08都产生 `finished=true elapsed=0.01666666666667 objective_elapsed=0.0 valid=false`。这不是直接伪造 finished；死亡来自实际 damage → Mission → Arena 的一个完整 step。

影响范围：首章死亡终态快照恢复。通常同回调内 `_sync_battle` 能成功结算并清除 run，因此不意味着每次死亡都会卡住。若死亡正好碰自动保存，Root 会先保存该终态，再提交 finish_run；在两次事务间退出/崩溃、或结算事务失败而需重载时，保存的 run 可能无法继续。已有 P1 验证表明 Profile 不拦截 Arena 无效快照。玩家因事件选择即时死亡的 delta=0 路径不必然有该1tick差异。

需要整改后的验收：玩家死亡、护送物死亡、死亡与自动保存同tick、保存成功而结算失败后重载，分别验证终态可恢复且仅结算一次。明确统一 active elapsed 的终态定义，保留死亡优先于胜利和timeout规则。

## 其它独立检查和正向结果

- `boss_restore_probe.log`：三种阶段的首次待落点（1/2/1个）在 tick38 经 JSON stringify/parse 后恢复；每支各推进真实200 tick，完整 snapshot（含 RNG 和 numeric_bits）均逐tick一致。阶段 HP 为显式 fixture 注入，不宣称自然三阶段曝光或玩家体验。
- `probe.log`：正常基础 Boss 走位350 tick逐tick验证，没有发现新增 snapshot 不合法（不包括上述致命伤专用探针）。
- Chapter/Encounter 保持 RefCounted 内部执行器，未新增独立 Node 时钟；Mission 仍处理胜负。根区关闭在 step 尾删除对应 zone；猎物 target_id/live/dead 联合校验、Boss预警容量预检和待落点记录方向合理。
- Codec 检查数值镜像后才 restore；技能 key 排序和 RNG 字符串保留使已测续跑可复现。
- Profile 旧进行中 content_hash 拒读位于设置迁移之前，静态追读未发现本轮绕过。C报告的旧 B PCK 实证属于作者证据；本领域没有独立重跑跨包磁盘兼容，不把它改称独立已验证。

## Standards / Architecture / Testability

引擎发现 ISSUES FOUND；测试性 GAPS：可从现有注入接口复现，但作者故障测试没有把 validator 结果连接真实写入口，死亡终态缺关键覆盖。架构主要问题是恢复验证和持久化边界脱节，而非需要新增系统。复杂度/40行标准尚不满足（如 Combat.advance_enemies、Profile.finish_run）；存在热路径字典/数组分配（如 `_enemy_grid`），没有本机分配/性能测量，不宣称零分配或60fps性能通过。未为非本轮结构性风格项另造 P1/P2。

## 结论与边界

**CHANGES REQUIRED**。先修复上述持久化安全和死亡恢复问题，再由独立评审复测。此报告仅给出引擎/GDScript领域 verdict；UI/QA由其它独立审阅者汇总。没有真人试玩、Windows实机、Steam、20小时体量或商业 Save v2 验证，不能从本报告得出 battle_ready。
