独立专家报告，覆盖 `[persistence / Godot-engine / performance / QA]`。全文审阅 ADR-0006、Save Steam、Campaign、Mission，核对旧 Save/Settlement 的业务恢复约束及当前 `save_system.gd`。只读，未联网、未运行平台测试、未修改文件。

建议结论：**NEEDS REVISION**。JSON v2 架构方向可保留；以下合同问题应先修正。当前生产仍为 JSON v1，不能据本文称 v2 已实现或续局 ready。

### 必须本轮修正的合同问题

**1. [P1][persistence / QA] sealed result 的持久身份与恢复 epoch 相互矛盾。**

来源：

- `design/gdd/mission-objectives.md:19`：每次恢复重新签发 `instance_epoch`。
- 同文件 `:55`：`MissionResultV1` 把 `instance_epoch` 放入 sealed 结果。
- 同文件 `:59`、`:61`：snapshot 保存 sealed result，恢复绑定新 epoch。
- 同文件 `:69`、`:91`：恢复只能重试同一结果，sealed 字节一致。
- `design/gdd/campaign-flow.md:27`：验证结果 epoch，接受当前 run/实例结果。

重现：旧 epoch E1 的 sealed 胜利被捕获，进程退出，恢复签发 E2。保留结果字节则被“当前 epoch”检查拒绝；改成 E2 则破坏结果 hash 与不可变性。这不是待定义 owner payload 的细节，而是两条已写规则无法同时满足。

最小修正：持久结果使用 `profile/branch/run/mission/definition/terminal_tick` 等语义身份；当前实例 epoch 放在交付 envelope 中。或者定义独立的“持久 sealed 结果恢复验证”路径，验证旧结果证据，再用新 epoch 交付。补 AC：**E1 sealed → 保存 → E2 恢复 → 原 result bytes/hash 不变且完成恰一次**。

**2. [P1][persistence / Godot-engine] RUNNING、RESULT_PENDING 的重启恢复路径没有闭合。**

来源：

- `design/gdd/save-steam-pc.md:37`：持久状态包含 `PREPARED/RUNNING/SUSPENDED/RESULT_PENDING`。
- 同文件 `:57`：START 提交 RUNNING 后曝光。
- 同文件 `:59`：规定恢复 SUSPENDED，并承诺非保存退出崩溃回到最后 checkpoint。
- `docs/architecture/adr-0006-steam-save-and-mission-contracts.md:37`：继续流程。
- `design/gdd/mission-objectives.md:69`：sealed 后恢复只能继续原提交。

缺口：

- START 是否必须携带 tick 0 的完整恢复点，或何时首个合法 checkpoint 成立，没有定义。
- RUNNING head 在重启时走哪个恢复入口，未定义；现有 RESUME 说明围绕 SUSPENDED。
- RESULT_PENDING 没有进入它的事务，也没有恢复分派规则。
- `last_operation` 只记录**最近已写入**操作的身份/hash（Save `:31`）；如果 COMPLETE 尚未形成新 head，旧 head 不一定包含该次 terminal request 的 operation ID、不可变请求或 after-images。如何跨进程“重试同一次提交”没有定义。

最小修正：增加持久状态 × boot/recover action 表，明确 START 初始恢复点、RUNNING 恢复和 RESULT_PENDING 的创建/消费。对已持久 terminal intent 定义不可变请求恢复载体；无需本轮写出所有 owner schema。旧 Settlement 的思路可复用，其 `design/gdd/settlement-system.md:111` 明确先 durable stage 请求，重启复用相同请求字节。

补 AC：START readback 后首帧前强杀、普通 RUNNING 强杀、terminal 已 sealed 而 COMPLETE 未落盘、COMPLETE 已落盘但 callback 丢失，分别有唯一预期恢复动作。

**3. [P1][persistence] CANCEL_PREPARE 未保留已经曝光随机选择后的不可取消承诺点。**

来源：

- `design/gdd/save-steam-pc.md:57`：PREPARED 可 CANCEL_PREPARE，释放占用、退休 run。
- `docs/architecture/adr-0006-steam-save-and-mission-contracts.md:26`：旧 reservation 业务要求保留。
- `design/gdd/save-steam-pc.md:35`、`:77`：preparation 沿用业务 owner，依赖 Zhangtian。
- `design/gdd/zhangtian-bottle.md:196`：首个聚气 offer durable/visible 后，Back/关闭/重启只能恢复同一 reservation、seed、offer revision；不得生成 fresh 随机页。

v2 没定义 START 与 PRE_ACTIVE_CHOICE 的先后，也未定义 PREPARED 内的承诺点。实现者可以合法地先展示 offer、仍保持 PREPARED，随后按新取消规则释放并签发新 run，从而绕过旧业务约束。

最小修正：CANCEL_PREPARE 增加 owner 签发的 cancellation eligibility/commitment checkpoint 校验；或明确 START 的不可取消提交发生在 offer 曝光前。不要为此沿用旧 binary 字节数。补“offer 可见后 cancel 拒绝，重启恢复同页；可取消阶段取消不重复释放”的 AC。

**4. [P2][persistence / systems] `current_run` 的 wire shape 与 domain 注册规则不一致。**

来源：

- `design/gdd/save-steam-pc.md:32`：所有 domain 为 `{schema:string,payload:object}`。
- 同文件 `:35`：current_run 是必需 domain。
- 同文件 `:37`：`current_run=null` 或 run object。
- 同文件 `:43`、`:57`：新档与完成后 current_run=null。
- 同文件 `:19`：严格 schema、缺/未知字段拒绝。

目前无法判断 null 是 domain 整体、domain.payload，还是 payload 内字段；前两者违反已写的固定 wrapper/object 规则。这个问题会直接阻止新档、完成档的唯一规范编码。

最小修正：例如统一为 `domains.current_run={schema:"1",payload:{run:null|RunStateV1}}`，全文语义引用说明指 `payload.run`。补空档、PREPARED、SUSPENDED、退休后的 canonical 示例即可；不要求此轮完成所有快照 serializer。

### 推荐修正

- **[P2][QA] 修正封闭错误/操作名。** Save `:69` 规定缺预算返回 `INVALID_CONFIG`，但 `:45` SaveResult status 集合不含它；SP03 `:87` 使用 `COMPLETION`，kind `:43` 则只有 `COMPLETE`。应统一，避免 reducer 与测试生成器各自猜别名。
- **[P2][persistence] 云冲突分支身份与选择结果进一步明确。** Save `:26` branch_id 创建后稳定，`:65` 让用户选择一个 branch 继续，但没有说明离线复制时同 branch_id 的 sibling 如何表示、选择后是否 fork 新 branch、后续保留哪一个 parent。现有“保留两份、不合并”的保守规则可以成立；建议补一个同 branch、同 revision、异 hash 的案例，避免实现按 branch_id 把两份误当同一份。
- **[P2][QA] 两槽读取的异常组合补矩阵。** Save `:53` 主要写双方合法时的选择，`:63`、`:73` 已要求未来 schema/损坏不得覆盖。建议明确“合法旧槽 + 未来 schema 槽”“合法槽 + 读取权限失败”“两槽相同 hash”“初建仅一槽”的判定。不能把“解析不支持”混成“文件不存在”。
- **[P3][codec] float64 hex 明确位模式书写方向。** Save `:17` 已限制 16 位小写 IEEE754 hex、NaN/Inf 和负零，建议补 `1.0 → 3ff0000000000000`，明确不是宿主内存字节顺序。跨编码器 golden 留给实施期。

### 完整性、AC 与依赖检查

| 文档 | 8 节完整性 | AC 检查 |
|---|---|---|
| Save Steam | **8/8** | SP01–SP12 均有可观察断言；SP03 命名需修；缺上述状态恢复/epoch/cancel 用例 |
| Campaign | **8/8** | CF01–CF10 可测试；CF04/CF05 需纳入跨进程 sealed 恢复 |
| Mission | **8/8** | MO01–MO12 可测试；MO10/11 目前遇到 epoch 矛盾 |
| ADR-0006 | ADR 模板，8 节 GDD 检查不适用 | Validation Criteria 有事务、迁移、同 tick、设备与预算边界 |

SP11 没有现成阈值，**不等于含糊 AC 或假通过**：正文明确“缺预算即门未过”。MO12 同理。它们是实施启用门，当前不能报告 PASS。

依赖文件实际存在：

- Save：save-system、game-root-scene-flow、settlement-system、campaign-flow、mission-objectives、progression-tree、zhangtian-bottle、config-data-system。
- Campaign：mission-objectives、save-steam-pc、game-root-scene-flow、settlement-system、config-data-system、home-ui、prep-ui、progression-tree；商业来源实际位于 `design/steam-1.0-campaign.md`。
- Mission：campaign-flow、save-steam-pc、game-root-scene-flow、settlement-system、config-data-system、stage-map、enemy-system、spawn-director、damage-system、boss-state-machine、battle-ui、rng-system。

Character/Codex/Narrative 独立 GDD 缺失已由 Campaign `:51` 明确披露；required snapshot owner、MISSION phase/capacity 传播也由 Mission `:73` 明确保持 gate OPEN。**文件存在不代表双向 owner 集成已经完成。**

没有找到三份新 GDD 对应的 review-log；本轮按首次独立 review 对待。`design/gdd/game-concept.md` 与 `design/narrative/*.md` 当前不存在，未据此推测 lore 冲突。

### 不应混入本轮合同阻断的实施证据

以下工作确实未完成，但文档已诚实标记，应维持实施门，不能要求作者用伪造数值填成 ready：

- 各 owner snapshot 的真实 schema、validator、migration、最大合法 fixture。
- 完整内容预算 manifest、编码/读回/恢复的时间和峰值内存测量。
- 跨编码器 golden、generated fault matrix 与实际事务实现。
- Windows OS 锁、替换、权限/满盘、强杀与设备证据。
- Steam Cloud adapter 与真实冲突测试。
- 全局 required owner、MISSION phase 和容量配置传播。

当前代码佐证：`src/persistence/save_system.gd:15` 固定 schema 1；`:59`、`:76` 仍为旧提交入口；`:96` 使用普通 `JSON.stringify`；`:104` 直接写目标槽；`:150` 走现有 v1 reader。它没有 v2 操作身份、平台锁、严格 v2 codec、checkpoint 或云恢复实现。ADR `:9`、Save `:3` 对此表述准确。

范围信号：**XL**，涉及持久化、备战、Mission、Campaign、Settlement、全体快照 owner 与 Windows/Cloud adapter。最终 verdict 请由 fresh creative-director 综合所有真实专家报告后签发。
