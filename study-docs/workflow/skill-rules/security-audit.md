# security-audit — 安全漏洞审计（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/security-audit/SKILL.md) ｜ 阶段：Phase 6-7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/security-audit [full | network | save | input | quick]`（无参 = `full`）
- **一句话职责**：系统审计代码库最常见的游戏安全失效——存档篡改、作弊向量、网络漏洞、数据暴露、输入校验——并产出按严重度分级的修复计划。
- **触发前置**：任何公开发布前（`workflow: standard`/`full` 下为 Polish → Release 门必需工件）、启用任何在线/多人功能前、实现任何读盘或读网络系统后、安全相关 bug 被报告时。`resolve_config --keys automation,workflow` 已解析；`workflow` 只决定 Phase 7 如何谈发布门（standard/full 要求本报告，minimal 不要求），**审计本身每个 tier 跑法相同**。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `project.yaml`（键缺失/空时回退 `.claude/docs/technical-preferences.md` 供 engine/language/platforms）：`engine.name` + `engine.language`——**承重：选择 Phase 3 模式集**；`platform.targets`（攻击面）；`platform.multiplayer` + `platform.online`（多人是否在范围内——legacy 回退**没有**等价字段）；代码根（按 code-root-resolution 解析）；`docs/engine-reference/<engine>/`（钉定的引擎参考——模式名与版本的权威源） | 引擎与多人范围决定扫描面 |
| 产出 | `production/security/security-audit-[date]-[scope].md`（**先征询后写**："May I write the full security audit report to …?"） | 文件名带 scope——同日 quick/save 跑不覆盖发布门要读的 full 报告 |
| 派生智能体 | `security-engineer`（经 `Agent` spawn——审计是它的职责，主会话**不得**代跑各类别；无法 spawn 时说明原因、在本会话跑扫描并让报告 Audited by 行如实记录） | 固定简报模板（见 R5） |

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 范围与多人判定
R1. 五模式：`full`（全类别，发布前推荐）、`network`（仅网络/多人）、`save`（仅存档与序列化）、`input`（仅输入校验与注入）、`quick`（仅高严重度检查，最快，迭代用）。（Phase 1）
R2. `engine.name` 缺失/为空 → 在报告中说明并**把每个 grep 类别按 NOT ASSESSED 处理**——**绝不**因为 Godot 清单是全文写出的就回退用 Godot 列表。（Phase 1）
R3. **ABSENT 不等于 `false`**——`platform.multiplayer`/`platform.online` 有读者（本技能）但**设置流程中没有写入者**（`/setup-engine`、`/start` 都不发 `platform:` 块，只有有人跑 `/settings` 才设），所以多数项目两键皆缺。默认成 `false` 会在**每个**项目上跳过 Category 2——包括真多人项目——安全类别在没有任何东西设置的值上 fail open。任一键缺失/为空时：**不假设单机、不跳过 Category 2**；问用户游戏是否有多人/在线功能；无法问 → **照跑 Category 2** 并标 `NOT ASSESSED — multiplayer scope unconfirmed (platform.multiplayer unset — set it with /settings)`（按 Phase 5 这使 CLEAR TO SHIP 不可达）；范围未确认期间按多人游戏评严重度——open HIGH 即 DO NOT SHIP——并在报告说明评级假设了多人（如 security-engineer 所做）。单机多扫几分钟的代价；少扫多人则带着未跑的类别上线。显式设置用 `/settings platform.multiplayer=true`（项目级，拒绝 `--local`）。（Phase 1）

### Phase 2 — 派发固定简报
R4. 代码根未解析时**不传猜测值**：扫代码的每个类别都 `NOT ASSESSED — code root unresolved` 并在报告中说明。代码根为空 = Phase 5 的实现不足情形，扫代码的每个类别读 `NOT ASSESSED — no source under <root>` 而非零发现。**两种情形都绝不报干净**。（Phase 2）
R5. 给 `security-engineer` 发**固定简报模板**，只填 `{…}` 槽（来自 `project.yaml`/技术偏好、解析的代码根、逐字照抄的 Phase 3 文本），**别的什么都不加**：不谈游戏类型、不预期严重度、不对任何发现持观点——你自己的一句就是评级先入的入口。简报内容：Scope / Engine / platform 两键值 + Phase 1 答案 / Code root / Also scan（`assets/data/` 与存在的配置文件）/ 逐类别照抄的检查与 grep 模式（含本引擎的表行）/ NOT SOURCEABLE on this engine（**每个都要报 NOT ASSESSED——绝不称 reviewed、verified safe 或 passed**）/ Skipped 及理由 / 报告路径——代理以文本返回报告，`/security-audit` 问过之后才写文件。（Phase 2）
R6. 严重度表随简报带给代理（**简报中没有任何东西设定或暗示严重度**；游戏类型永不降低评级——单机游戏按同一张表评；唯一调整是**向上**：多人或范围未确认时 HIGH 按 CRITICAL 计，并在适用处说明）：**CRITICAL** = 远程代码执行、数据泄露、或破坏多人完整性的可轻易利用作弊；**HIGH** = 绕过进度的存档篡改、凭据暴露、服务端权威绕过；**MEDIUM** = 客户端作弊使能、信息泄露、影响有限的输入校验缺口；**LOW** = 纵深防御改进——减少攻击面但无直接可利用的加固。每条发现记 SEC-NNN（category、file:line、description、attack scenario、remediation、effort），按严重度分组。（Phase 2）

### Phase 3 — 六类审计与引擎模式集
R7. **引擎模式集是前置**：Category 1–3 的每份模式清单都是为 Godot 写的——在 Unity/Unreal 项目上零命中，零命中扫描把报告渲染成干净——"安全审计最危险的失效"。按 `engine.name` 查表：

   | 类别 | Godot | Unity | Unreal |
   |---|---|---|---|
   | 1 存档/序列化 | 下述 Godot 清单 | **NOT SOURCEABLE** | **NOT SOURCEABLE** |
   | 2 网络/多人 | 下述 Godot 清单 | `ServerRpc` `ClientRpc` `NetworkVariable` `NetworkObject` `NetworkManager` `NetworkBehaviour` `IsServer` `IsOwner` | `UFUNCTION` `Server` `Client` `NetMulticast` `Replicated` `DOREPLIFETIME` `GetLifetimeReplicatedProps` `HasAuthority` |
   | 3 输入 | 下述 Godot 清单 | `InputSystem` `PlayerInput` `ReadValue` `InputValue` | `EnhancedInput` `UInputAction` `InputMappingContext` `BindAction` `FInputActionValue` |
   | 4 数据暴露 | 引擎无关——三个引擎同一份 | | |
   | 5、6 | 判断与清单，非 grep——无需引擎集 | | |（Phase 3）
R8. Unity/Unreal 名单**来自本仓库钉定参考**（`docs/engine-reference/{unity,unreal}/modules/{networking,input}.md`）而非回忆——使用前对照 pin 核验，并补充参考文档有而本表漏掉的（表是地板不是全集）。（Phase 3）
R9. **`NOT SOURCEABLE` 是裁决，不是靠记忆填的洞**：两棵参考树都没有序列化/存档模块，Unity/Unreal 的存档 API 名在此无法确认——**绝不从训练数据写**。一份自信但错误的模式清单产出的是看起来彻底、什么都没找到、读起来像通过的扫描；表标 NOT SOURCEABLE 的类别对该引擎记 **`NOT ASSESSED`**（见 Phase 5）。要正经关闭：向 `docs/engine-reference/<engine>/modules/` 加一个同样有源的 save/serialization 模块——届时从它取模式名、在报告中引用、类别即可运行。（Phase 3）
R10. 六类审计要点（跳过不适用的类别，并在 Executive Summary 点名每个跳过的及理由——"Category 2 — skipped: platform.multiplayer and platform.online are false"）：
    - **Category 1 存档与序列化**：载入前校验（无盲反序列化）？路径由用户输入构造（路径穿越）？有校验和/签名（篡改检测）？无界检查就信存档数值？存档加载附近有 eval()/动态代码执行？grep：`FileAccess` `File.open` `open(` `load` `deserialize` `parse` `parse_string` `from_json` `read_file` `get_var` `bytes_to_var`——逐个查校验。**API 名随版本变、此清单是起点非全集**：`File.open` 是 Godot 3.x，Godot 4 改名 `FileAccess`；依赖前先读 `docs/engine-reference/<engine>/` 钉定版本并补它记载的名字；grep 一个已不存在的类零命中，而零命中在本类把报告渲染成干净；无法确认名字就在报告里说明，绝不把零命中扫描当通过；
    - **Category 2 网络与多人**（仅单机才跳）：状态服务端权威还是客户端说了算？入站包校验尺寸/类型/值域？位置与状态变更服务端校验？网络调用有限流？auth token 处理正确（绝不明文）？release 构建暴露调试端点？grep：`recv` `receive` `PacketPeer` `socket` `MultiplayerPeer` `ENetMultiplayerPeer` `NetworkedMultiplayerPeer` `rpc` `rpc_id` `@rpc`（`NetworkedMultiplayerPeer` 是 3.x、4 用 `ENetMultiplayerPeer`——裸子串 `MultiplayerPeer` 两版都中，是更安全的探针）；
    - **Category 3 输入校验**：玩家字符串进文件路径（穿越）？未消毒进日志（注入）？数值输入先界检后使用？成就/统计值写后端前有核查？grep：`get_input` `Input.get_` `input_map`、用户输入的文本字段——查校验；
    - **Category 4 数据暴露**（引擎无关）：代码根或 `assets/` 硬编码 API key/凭据/秘密？release 构建带调试符号或冗长报错？敏感玩家数据落盘/落控制台？内部路径或系统信息暴露给玩家？在面向发布的代码里**大小写不敏感** grep：`api[_-]?key` `secret` `password` `token` `private[_-]?key` `sk_live` `BEGIN PRIVATE KEY` `DEBUG` + 引擎打印调用（Godot `print(`、Unity `Debug.Log`、Unreal `UE_LOG`）；
    - **Category 5 作弊与防篡改**：玩法关键值只在内存不在易编辑文件？关键进度旗标（如"已购 DLC"）服务端校验？多人有反内存编辑工具（Cheat Engine 等）防护？排行榜/分数提交先验证后接受？——客户端反作弊基本不可执行，竞争性或变现的任何东西**聚焦服务端校验**；
    - **Category 6 依赖与供应链**：列出全部第三方插件/库；所用版本有已知 CVE？来源可信（官方市场、经评审仓库）？Glob：`addons/` `plugins/` `third_party/` `vendor/`——列全部外部依赖。（Phase 3）

### Phase 4-5 — 分级与报告
R11. 每条发现赋严重度（R6 表）与状态：**Open / Accepted Risk / Out of Scope**。（Phase 4）
R12. 报告结构：题头（Date、Scope、Engine、**Audited by**——`security-engineer via /security-audit` 或 `this session — security-engineer not spawned: reason`、Files scanned〔N 源文件、N 配置文件〕）→ Executive Summary（严重度计数表：CRITICAL/HIGH 均为 "Yes — all" 必须修；MEDIUM Recommended；LOW Optional；**Release recommendation**）→ CRITICAL/HIGH/MEDIUM/LOW 各节（每条 SEC-NNN：Category、File line N、Description、Attack scenario、Remediation、Effort〔Low/Medium/High〕）→ Accepted Risk → Dependency Inventory（Plugin/Library | Version | Source | Known CVEs）→ Remediation Priority Order → Re-Audit Trigger（修复任何 CRITICAL/HIGH 后重跑；standard/full 的 Polish → Release 门要求本报告无未结 CRITICAL/HIGH）。（Phase 5）
R13. **发布建议按未结发现首匹配**：
   - **DO NOT SHIP** — 任何未结 CRITICAL（多人游戏中任何未结 HIGH 按 CRITICAL 计）；
   - **FIX BEFORE SHIPPING** — 有未结 HIGH 且无 CRITICAL（standard/full 的 Polish → Release 门需要零未结 HIGH）；
   - **NOT ASSESSED** — 扫描没能覆盖攻击面时（规则见 R14）；排在两个失败值**之下**（已知发现比未扫类别更可行动、仍须修）、CLEAR TO SHIP **之上**；
   - **CLEAR TO SHIP** — 无未结 CRITICAL 或 HIGH（MEDIUM/LOW 可留）。（Phase 5）
R14. **NOT ASSESSED 在实现面不足、或钉定引擎版本的 API 名无法确认时必给——顶替的是 CLEAR TO SHIP，绝不是失败值**。未结 CRITICAL/HIGH 仍按首匹配决定建议：带未扫类别 + 未结 HIGH 的运行是 FIX BEFORE SHIPPING，并把未扫类别列在旁边。两文件源码上的零发现扫描不是健康证明——**CLEAR TO SHIP 绝不能靠"没东西可看"达到**；点名缺了什么、哪个技能产出它。**引擎轴是同一规则的一部分**：Phase 3 表为本引擎标 NOT SOURCEABLE 的类别记 NOT ASSESSED——在 Executive Summary 按名陈述，且**本次运行的 CLEAR TO SHIP 不可达**；该类别读 `NOT ASSESSED — <category> has no sourced pattern set for <engine>`；发布建议仍走首匹配，故仅当运行本可 CLEAR TO SHIP 时才是 NOT ASSESSED。**绝不**以其它方式把该类别报成已评审：它覆盖的文件可以因别的类别被读到、读出的发现照样报告，但类别保持 NOT ASSESSED——绝非 "reviewed"、"verified safe" 或通过。没能看的扫描不是没找到东西的扫描，只有报告能告诉读者是哪一种。（Phase 5）

### Phase 6-7 — 写盘与门禁联动
R15. 会话内只呈现摘要（Executive Summary + 仅 CRITICAL/HIGH 发现）；征询 "May I write the full security audit report to `production/security/security-audit-[date]-[scope].md`？"——**批准后才写**。（Phase 6）
R16. 本报告是 **Polish → Release 门**在 `workflow: standard`/`full` 下的必需工件；`minimal` 门随"除 smoke 与 S1 bug 外一切"一并丢弃它——按解析的 `workflow` 说明本项目适用哪种。修复后重跑 `/security-audit quick` 确认 CRITICAL/HIGH 已解决，再跑 `/gate-check release`。收尾按**发布建议**分支（不是单看发现计数）：
    - **DO NOT SHIP**（未结 CRITICAL，或多人游戏未结 HIGH）："⛔ CRITICAL security findings must be resolved before any public release. Do not proceed to `/launch-checklist` until these are addressed.";
    - **FIX BEFORE SHIPPING**（未结 HIGH、无 CRITICAL、单机）：standard/full 下提醒 Polish → Release 门的安全项要求零未结 HIGH——修完重跑 `/security-audit quick` 再 `/gate-check release`；minimal 下提醒 minimal 发布门不读本报告，但未结 HIGH 仍使建议为 FIX BEFORE SHIPPING；
    - **NOT ASSESSED**：逐类别点名未评估原因与缺失输入——`engine.name`、代码根、多人范围（`/settings platform.multiplayer=…`）、或（Unity/Unreal 上 NOT SOURCEABLE 的常见原因）`docs/engine-reference/<engine>/modules/` 里缺 save/serialization 模块；standard/full 下 `/gate-check release` 的安全项将 NOT ASSESSED 直到补输入并重跑；
    - **CLEAR TO SHIP**："✅ No blocking security findings. Report written to `production/security/`. Include this path when running `/gate-check release`."（Phase 7）
R17. 协作协议：**绝不假设模式安全**——标出让用户决定；**接受风险是合法结局**——某些 LOW 对 solo 团队是可接受的取舍，把决定写进文档；**多人游戏门槛更高**——多人语境下任何 HIGH 按 CRITICAL 对待；**这不是渗透测试**——只覆盖常见模式，任何竞争性或变现的多人上线前仍建议真人安全专家做真正的 pentest。（Collaborative Protocol）

## 4. 门禁与裁决
- **裁决词（发布建议）**：`DO NOT SHIP` / `FIX BEFORE SHIPPING` / `NOT ASSESSED`（含 `NOT ASSESSED — INSUFFICIENT IMPLEMENTATION`）/ `CLEAR TO SHIP`；类别级：`NOT ASSESSED`（含 NOT SOURCEABLE、多人范围未确认、代码根未解析/无源码）。
- **排序（首匹配）**：DO NOT SHIP > FIX BEFORE SHIPPING > NOT ASSESSED > CLEAR TO SHIP（NOT ASSESSED 只顶替 CLEAR TO SHIP，绝不顶替失败值）。
- **最严原则**：多人（或范围未确认）时 HIGH 升计 CRITICAL；任何 NOT SOURCEABLE 类别使本次运行的 CLEAR TO SHIP 不可达。
- **消费方**：`/gate-check release`（读最新 full 范围报告 + 后续 quick 更新）、`/launch-checklist`。

## 5. 移植建议
- **可直接移植**：R3（可选键缺失不默认 false——有读者无写入者的键不得 fail open；未确认按更严评）、R4（代码根未解析/为空绝不报干净）、R5（固定简报零私货——主会话不代跑、代理评审不带预期）、R7-R9（按技术栈可溯源的模式集；NOT SOURCEABLE 是裁决不是靠记忆填的洞）、R13-R14（首匹配发布建议、NOT ASSESSED 只顶替绿灯）、R17（接受风险要落文档、多人更严）。
- **需替换概念**：游戏六类 → Web/后端等价面（注入、鉴权、越权、密钥泄漏、依赖 CVE）；引擎参考树（`docs/engine-reference/`）→ 技术栈的钉定 API 参考；`platform.multiplayer` → 是否有公网攻击面的配置键；Polish → Release 门 → 生产/发布门禁；`addons/plugins/vendor` → 依赖清单目录。
- **改写示例**：
  - R9 → "扫描模式集必须可溯源到本仓库钉定的参考文档；技术栈没有来源的类别记 NOT SOURCEABLE 并整体 NOT ASSESSED——绝不从模型记忆补写 API 名：自信而错误的清单产出的是看似彻底、零命中、读起来像通过的扫描。"
  - R3 → "决定攻击面的配置键缺失时不得默认为 false：缺键按更严假设运行并标 NOT ASSESSED——多扫单机几分钟，少扫多人则带着未运行的类别上线。"

## 6. 关联文档
- 上游：`/setup-engine`、`/settings`（engine.*、platform.* 键）。
- 下游：`/gate-check release`（Polish → Release 门的安全项消费本报告）、`/launch-checklist`（DO NOT SHIP 时阻断）、`/security-audit quick`（修复后确认）。
- 引用：`docs/engine-reference/<engine>/modules/{networking,input}.md`、`docs/engine-reference/godot/breaking-changes.md`、`.claude/docs/code-root-resolution.md`、`.claude/docs/automation-modes.md`。
