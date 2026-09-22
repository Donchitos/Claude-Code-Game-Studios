本组建议 **NEEDS REVISION**。三份新 GDD 都有完整八节；64 任务规划图静态合法。需修正的是以下合同矛盾，不能把这些问题与明确保留的实现门混为一谈。

1. **[P1][systems/QA] sealed 结果恢复后，没有同时满足 epoch 校验与字节不变的提交路径。**  
   `design/gdd/mission-objectives.md:55` 把 `instance_epoch` 写进不可变 `MissionResultV1`；`:61` 要求恢复重新绑定 runtime epoch；`:69` 要求已 sealed 结果恢复只能重试原提交；`:91` 要求重复请求字节一致。与此同时，`design/gdd/campaign-flow.md:27` 要验证当前实例与结果 epoch。  
   反例：旧实例 E1 sealed，提交前强杀；恢复成 E2。原结果携 E1 被当前实例验证拒绝；把结果改成 E2 又违反不可变/hash/原提交重试约束。  
   **最小修正：**区分持久 sealed-result 身份与新实例事件 epoch，规定恢复专用接纳凭据/路径：已封结果保持原字节及原事务身份，恢复校验其 checkpoint/run 绑定后只重试原提交；E2 只控制恢复后新事实，不能改写原结果。补 E1→E2、提交前后强杀的测试。

2. **[P1][systems/QA] 非法事实究竟封 technical 结果，还是不发布任何结果，规则与 AC 相反。**  
   `design/gdd/mission-objectives.md:38` 对错 epoch/tick/重复序号/非法值停止消费；`:46` 将 owner/identity/容量/快照异常仲裁为 `TECHNICAL_ABORT`；但 `:89` MO09 要求错 run/epoch、重复、溢出“不发布结果”。  
   同一 overflow/identity fixture 没有唯一结果 oracle；这还决定 run 能否被技术结算退休。  
   **最小修正：**明确外部 stale 输入被无效果拒绝与当前实例权威链损坏的区别；后者由 GameRoot 在 barrier 封唯一 technical 结果，普通成功结果为零。重写 MO09，并把对应分类加入 MO08。

3. **[P2][economy/systems] 失败也能按公式获得首次 unlock。**  
   `design/gdd/campaign-flow.md:29` 明确失败不增加 unlock，`:61` CF03 相同；但 `:43` 写了无条件 `after_unlocks=unlocks ∪ first_grants(m)`。  
   代入 `success=false` 且任务有非空首次奖励，公式与正文输出不同。  
   **最小修正：**`after_unlocks = first_completion ? unlocks ∪ first_grants(m) : unlocks`，同时把 `after_completed` 的否则分支显式写全；增加失败、重玩、首次成功三组边界。

4. **[P1][economy/game] 新 Mission 的快速胜利与直接引用的旧 Settlement 奖励校验不兼容，应明确 profile 适配边界。**  
   `design/gdd/mission-objectives.md:11,49` 要求主动目标完成即胜；`design/steam-1.0-campaign.md:28` 明确不强加统一计时。但是 `design/gdd/settlement-system.md:254`、`:380` AC-ST07 要求 `VICTORY` 仅接受 `43200..108000` ticks，早于 12 分钟一律拒绝。新 Mission `:73` 仅明确 entity/snapshot/阶段/容量传播门，Campaign `:35` 将普通奖励交旧 Drop/Settlement，尚未明确这些旧 Victory validator 何时适用。  
   另一关联边界：旧 Settlement `:107,236,380` 第一次正常胜/败便发三种 starter 并置解锁；产品 `design/steam-1.0-campaign.md:11,43` 和矩阵 `production/steam-1.0-content-matrix.csv:241` 起明确备战内容在 M01-03 后开放。前两任务失败/完成直接套旧 owner 会提前激活旧 unlock。新备战内容不完全等于旧种子，因此不能仅凭 ID 不同推断已解决。  
   **最小修正：**无需现在实现所有 owner，但必须声明新 Mission profile 不套旧 Boss 时长校验/首次结算解锁规则，列出 Settlement/Zhangtian/Prep 的新 profile 决策与传播 gate；明确首次开放的唯一 Campaign grant、任务结果→经济 outcome 映射，以及短局重复奖励的待冻结数值范围。旧 profile 保持原规则。至少增加“早于 43200 ticks 的合法 Mission victory 能完成结算”“M01-03 前普通失败/胜利不开放备战”合同 AC。

**不是本轮新增 blocker 的事项**

- CSV 读取得到 **64 个唯一 mission、八章各八个、严格线性前置、START 可达**；第八章 M07→M08、M08→终局与 Campaign 一致。
- Campaign “已完成集合必须为合法前缀”、首次奖励只在 durable 完成后曝光、重玩不重发、旧 v1 victories 不映射章节，规则方向一致。
- 新 Mission 玩家死亡优先，旧 GameRoot 胜利优先：`mission-objectives.md:53` 已明确只用于新 profile，不将这处有意隔离的差异本身计为缺陷；生产仍需 profile 接线与独立 oracle。
- 世界/HP/路径、required-owner snapshot、MISSION phase/capacity 的缺口已由 `mission-objectives.md:32,36,59,73,92` 明确关闭生产入口。它们是未完成实施门，不能因为暂缺实现就推翻架构方向。
- 20 小时不是已验证事实。产品 `steam-1.0-campaign.md:180-182` 已明确时长不足风险和整章试玩门；没有伪造验证。
- 不将旧二进制大小限制套在 JSON v2：ADR-0006 明确隔离。

**八节及 AC 可测性**

- Campaign：8/8。CF01–07、09–10 可构造确定 fixture；CF08 是完整产品路线试玩/平衡 AC，仍需冻结普通难度配置、测试者能力/辅助条件及通关证据，当前只能算待验证产品门，不能用图连通代替。
- Mission：8/8。MO01–08、10–11 基本具确定输入与预期；MO09 与 fault 规则冲突见上；MO12 是 admission gate，测试应验证缺 owner/manifest/workload 时拒绝生产 profile，而不是以“文件存在”当运行通过。
- Save：8/8。SP01–10 属可定义的功能/故障注入测试；SP11 依赖尚未冻结预算，明确 gate；SP12 属设备证据要求。SP03 `COMPLETION` 与规范 enum `COMPLETE` 不同，建议统一名词（轻微编辑项）。

**依赖核实**

- Campaign 所列八个 GDD 均存在；商业来源实际位于 `design/steam-1.0-campaign.md`，不是 GDD 目录。
- Mission 所列十二个 GDD 均存在。
- Save 所列八个 GDD 及 ADR-0006 均存在。
- Character/Codex/Narrative 独立 GDD 缺失已由 Campaign `:51` 明示追踪，未伪装已就绪依赖。
- `design/gdd/game-concept.md` 与 `design/narrative/` 不存在；因此没有据此臆测额外 lore 限制。
- 三份新文档尚无对应 review-log，本次按首次评审处理。

**阅读范围与证据边界**

全文阅读 `.claude/skills/design-review/SKILL.md`、`CLAUDE.md`、`design/CLAUDE.md`、三份新 GDD、ADR-0006、`design/steam-1.0-campaign.md`；读取并静态解析整个商业 CSV。定点读取/检索 `.claude/docs/technical-preferences.md`、GameRoot 终态/manifest、Settlement 奖励/首次解锁/AC、Save 旧业务语义、相关 Stage/Enemy/Spawn/Damage/Boss/UI/Config 的新 profile 传播情况；完成依赖和 review-log 文件存在性核实。未全文审阅所有旧 owner GDD，未改文件，未运行图形或 runtime。

这是一名独立工作组审查者覆盖 game/systems/economy/UX/QA 的报告，不声称本组内部又启动了五名专家；最终综合 verdict 请由 fresh creative-director 作出。粗略范围信号：**XL**。

<oai-mem-citation>
<citation_entries>
MEMORY.md:119-121|note=[read only independent review and evidence boundaries]
</citation_entries>
<rollout_ids>
</rollout_ids>
</oai-mem-citation>
