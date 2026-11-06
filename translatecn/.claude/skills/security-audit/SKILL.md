---
name: security-audit
description: "Security audit — save tampering, cheat vectors, network exploits, data exposure, input validation. Before public or multiplayer release."
argument-hint: "[full | network | save | input | quick]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, Bash(bash "*/.claude/skills/security-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: security-audit
description: "安全审计 — 存档篡改、作弊途径、网络漏洞、数据暴露、输入校验。在公开发布或多人发布之前。"
argument-hint: "[full | network | save | input | quick]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, Bash(bash "*/.claude/skills/security-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每一次 `AskUserQuestion` 调用和
每一次文件写入都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅询问重大事项 · autonomous 记录并继续；
`automation_always_ask` 类目始终提示询问）。

**`workflow`** (resolved above) decides only what Phase 7 tells you about the
release gate: at `standard` and `full` it requires this report; at `minimal` it
does not. The audit itself runs the same at every tier.

**`workflow`**（上文已解析）仅决定阶段 7 向你说明的发布门禁内容：
在 `standard` 和 `full` 下它要求本报告；在 `minimal` 下不要求。
审计本身在每个层级都同样运行。

# Security Audit

# 安全审计

Security is not optional for any shipped game. Even single-player games have
save tampering vectors. Multiplayer games have cheat surfaces, data exposure
risks, and denial-of-service potential. This skill systematically audits the
codebase for the most common game security failures and produces a prioritised
remediation plan.

安全对任何已发布的游戏都不是可选项。即便是单人游戏也存在
存档篡改途径。多人游戏则有作弊面、数据暴露
风险以及拒绝服务潜力。此技能系统性地审计
代码库中最常见的游戏安全失效，并产出一份按优先级排序的
修复计划。

**Run this skill:**
- Before any public release (required for the Polish → Release gate at `workflow: standard` and `full`)
- Before enabling any online/multiplayer feature
- After implementing any system that reads from disk or network
- When a security-related bug is reported

**运行此技能：**
- 在任何公开发布之前（在 `workflow: standard` 和 `full` 下，Polish → Release 门禁所必需）
- 在启用任何在线/多人功能之前
- 在实现任何从磁盘或网络读取的系统之后
- 当报告了安全相关的缺陷时

**Output:** `production/security/security-audit-[date]-[scope].md` — the scope
in the name keeps a same-day `quick` or `save` run from overwriting the `full`
report the release gate reads.

**输出：** `production/security/security-audit-[date]-[scope].md` — 名称中的 scope
可避免同日的一次 `quick` 或 `save` 运行覆盖发布门禁所读取的 `full`
报告。

---

## Phase 1: Parse Arguments and Scope

## 阶段 1：解析参数与范围

**Modes:**
- `full` — all categories (recommended before release)
- `network` — network/multiplayer only
- `save` — save file and serialization only
- `input` — input validation and injection only
- `quick` — high-severity checks only (fastest, for iterative use)
- No argument — run `full`

**模式：**
- `full` — 所有类别（发布前推荐）
- `network` — 仅网络/多人
- `save` — 仅存档文件与序列化
- `input` — 仅输入校验与注入
- `quick` — 仅高严重度检查（最快，用于迭代使用）
- 无参数 — 运行 `full`

Read `project.yaml` to determine the following, falling back to `.claude/docs/technical-preferences.md` for engine/language/platforms when a key is absent or empty:
- `engine.name` and `engine.language` — **load-bearing: they select the Phase 3
  pattern set, and an engine with no sourced set for a category makes that
  category `NOT ASSESSED`.** If `engine.name` is absent or empty, say so in the
  report and treat every grep category as `NOT ASSESSED`; do not fall back to
  the Godot lists because they are the ones written out in full
- `platform.targets` (affects which attack surfaces apply)
- `platform.multiplayer` and `platform.online` — whether multiplayer/networking is
  in scope. `technical-preferences.md` has no equivalent fields, so the legacy
  fallback cannot supply them.

读取 `project.yaml` 以确定以下内容，当某个键缺失或为空时，对引擎/语言/平台回退到 `.claude/docs/technical-preferences.md`：
- `engine.name` 和 `engine.language` — **承重：它们决定阶段 3
  的模式集，而某类别若在某个引擎下没有来源化的集合，该
  类别即为 `NOT ASSESSED`。** 若 `engine.name` 缺失或为空，在
  报告中说明，并把每个 grep 类别都视为 `NOT ASSESSED`；不要回退到
  Godot 列表，只因它们是被完整写出的那一套
- `platform.targets`（影响哪些攻击面适用）
- `platform.multiplayer` 和 `platform.online` — 多人/联网是否
  在范围内。`technical-preferences.md` 没有对应字段，因此旧版
  回退无法提供它们。

  > **ABSENT DOES NOT MEAN `false`.** These keys have a reader —
  > this skill — and **no writer in the setup flow**: neither
  > `/setup-engine` nor `/start` emits a `platform:` block, and only `/settings`
  > sets them, when someone runs it, so on most CCGS projects both keys are
  > absent. Defaulting them to `false` would skip **Category 2 (Network and
  > Multiplayer Security) on every project, genuinely multiplayer ones
  > included** — a security category failing open on a value nothing sets.
  >
  > When either key is absent or empty: **do not assume single-player, and do not
  > skip Category 2.** Ask the user whether the game has multiplayer or online
  > features. If you cannot ask, run Category 2 anyway and mark it
  > `NOT ASSESSED — multiplayer scope unconfirmed (platform.multiplayer unset —
  > set it with /settings)`, which makes `CLEAR TO SHIP` unreachable per Phase 5.
  > While the scope is unconfirmed, rate severity as for a multiplayer game — an
  > open HIGH is then DO NOT SHIP — and say in the report that the rating assumed
  > multiplayer, as `security-engineer` does.
  > Over-scanning a single-player game costs a few minutes; under-scanning a
  > multiplayer one ships the category unrun.
  >
  > Set them explicitly with `/settings platform.multiplayer=true` (they are
  > project-wide, so `--local` is refused). Recording it in `project.yaml` is the
  > fix; this rule is the guard for until someone does.

  > **ABSENT 并不意味着 `false`。** 这些键有一个读取者——
  > 本技能——而**在设置流程中没有任何写入者**：`/setup-engine`
  > 和 `/start` 都不输出 `platform:` 块，只有 `/settings`
  > 会在有人运行时设置它们，所以在大多数 CCGS 项目上这两个键都是
  > 缺失的。把它们默认为 `false` 会在**每个项目上跳过类别 2（网络与
  > 多人安全），包括真正的多人项目**——一个安全类别在一个无人设置的值上
  > 失败开放。
  >
  > 当任一键缺失或为空时：**不要假定为单人，也不要
  > 跳过类别 2。** 询问用户该游戏是否有多人或在线
  > 功能。若无法询问，仍然运行类别 2，并将其标记为
  > `NOT ASSESSED — multiplayer scope unconfirmed (platform.multiplayer unset —
  > set it with /settings)`，按阶段 5 这将使 `CLEAR TO SHIP` 不可达。
  > 在范围未确认期间，按多人游戏来评定严重度——此时一个
  > 未关闭的 HIGH 即为 DO NOT SHIP——并在报告中说明该评级假定了
  > 多人，正如 `security-engineer` 所做的那样。
  > 过度扫描一个单人游戏只多花几分钟；而欠扫描一个
  > 多人游戏，会让该类别未经运行就随版本发布。
  >
  > 用 `/settings platform.multiplayer=true` 显式设置它们（它们
  > 是全项目范围的，因此拒绝 `--local`）。在 `project.yaml` 中记录它才是
  > 修复；本规则是在有人这么做之前的防护。

---

## Phase 2: Spawn Security Engineer

## 阶段 2：生成安全工程师

Spawn `security-engineer` via `Agent` — the audit is its job, so do not run the
categories in this session instead. If it cannot be spawned, say why, run the
scan here, and let the report's **Audited by** line say so.

通过 `Agent` 生成 `security-engineer`——审计是它的职责，因此不要改为在本会话中
运行这些类别。若无法生成，说明原因，在此处运行
扫描，并让报告的 **Audited by** 行如实说明。

**Send this fixed brief template.** Fill only the `{…}` slots, from
`project.yaml` (else technical preferences), the code root resolved per
`.claude/docs/code-root-resolution.md`, and the Phase 3 text copied as written.
Add nothing else: no view on the game's type, no expected severity, no opinion
on any finding — a sentence of your own is where a pre-rating gets in.

**发送这份固定的简报模板。** 只填写 `{…}` 槽位，取值来自
`project.yaml`（否则取技术偏好）、按
`.claude/docs/code-root-resolution.md` 解析出的代码根，以及照抄的阶段 3 文本。
不要添加任何其他内容：不评论游戏类型、不预设严重度、不对任何发现
发表意见——你自己添的一句话正是预评级混入之处。

```text
Run a security audit of this project for /security-audit.

Scope: {full | network | save | input | quick}
Engine: {engine.name} {engine.version}, language {engine.language}
platform.multiplayer: {true | false | unset}    platform.online: {true | false | unset}    Phase 1 answer: {multiplayer | single-player | not asked}
Code root: {the resolved code root, or "unresolved"}
Also scan: {assets/data/ and the config files that exist, or "none"}
Categories to run, with their checks and grep patterns for this engine:
{each Phase 3 category this scope runs, copied as written, with the table's row for this engine}
NOT SOURCEABLE on this engine: {categories, or "none"} — report each NOT ASSESSED; never call it reviewed, verified safe or passed
Skipped, with reason: {e.g. "Category 2 — platform.multiplayer and platform.online are false", or "none"}
Report: production/security/security-audit-{date}-{scope}.md — return the report as text; /security-audit writes the file after asking

Severity (rate every finding yourself, against this table only):
- CRITICAL: Remote code execution, data breach, or trivially-exploitable cheat that breaks multiplayer integrity
- HIGH: Save tampering that bypasses progression, credential exposure, or server-side authority bypass
- MEDIUM: Client-side cheat enablement, information disclosure, or input validation gap with limited impact
- LOW: Defence-in-depth improvement — hardening that reduces attack surface but no direct exploit exists
Nothing in this brief sets or suggests a severity. The game's type never lowers a rating: a single-player game is rated on the same table. The one adjustment is upward — when the game is multiplayer, or its scope is unconfirmed (unset and not answered), a HIGH counts as CRITICAL; say so where it applies.
Report each finding as SEC-NNN with category, file:line, description, attack scenario, remediation and effort, grouped by severity.
```

The template carries the rating rule, so there is nothing to restate: the
table already rates save tampering that bypasses progression HIGH, the agent
rates each finding against it, and Phase 5 applies the multiplayer rule to the
recommendation.

模板已包含评级规则，因此无需重述：
该表格已将绕过成长的存档篡改评为 HIGH，智能体
据此为每项发现评级，阶段 5 再把多人规则应用到
建议上。

If the code root is unresolved, do not pass a guessed one: every category that
scans code is `NOT ASSESSED — code root unresolved`, and the report says so. An
empty code root is the insufficient-implementation case in Phase 5, and each
category that scans code reads `NOT ASSESSED — no source under <root>`, not zero
findings. Neither is ever reported clean.

若代码根未解析，不要传入一个猜测的：每一个扫描代码的类别
都是 `NOT ASSESSED — code root unresolved`，报告也如此说明。空的
代码根属于阶段 5 的"实现不足"情形，每个扫描代码的
类别读作 `NOT ASSESSED — no source under <root>`，而不是零
发现。二者都绝不报告为干净。

The security-engineer runs the audit across 6 categories (see Phase 3). Collect their full findings before proceeding.

security-engineer 会在 6 个类别上运行审计（见阶段 3）。在继续之前收集其全部发现。

---

## Phase 3: Audit Categories

## 阶段 3：审计类别

The security-engineer evaluates each of the following. Skip categories not
applicable to the project scope, and name each skipped category and why in the
Executive Summary (`Category 2 — skipped: platform.multiplayer and
platform.online are false`).

security-engineer 会评估以下每一项。跳过不适用于项目范围的类别，
并在执行摘要中逐项列出被跳过的类别及原因（`Category 2 — skipped: platform.multiplayer and
platform.online are false`）。

### Engine pattern sets — read this before any Category below

### 引擎模式集 — 在阅读以下任何类别之前先读此节

**Every pattern list in Categories 1–3 is written for Godot.** On a Unity or
Unreal project they match nothing, and a zero-hit scan renders the report clean,
"the most dangerous possible failure for a security audit". Use the table for
`engine.name` resolved in Phase 1.

**类别 1–3 中的每一份模式列表都是为 Godot 编写的。** 在 Unity 或
Unreal 项目上它们匹配不到任何东西，而一次零命中的扫描会让报告显得干净，
"这是安全审计可能出现的、最危险的失效"。请使用针对
阶段 1 解析出的 `engine.name` 的表格。

| Category | Godot | Unity | Unreal |
|---|---|---|---|
| 1 — Save / serialization | the Godot list below | **NOT SOURCEABLE** | **NOT SOURCEABLE** |
| 2 — Network / multiplayer | the Godot list below | `ServerRpc`, `ClientRpc`, `NetworkVariable`, `NetworkObject`, `NetworkManager`, `NetworkBehaviour`, `IsServer`, `IsOwner` | `UFUNCTION`, `Server`, `Client`, `NetMulticast`, `Replicated`, `DOREPLIFETIME`, `GetLifetimeReplicatedProps`, `HasAuthority` |
| 3 — Input | the Godot list below | `InputSystem`, `PlayerInput`, `ReadValue`, `InputValue` | `EnhancedInput`, `UInputAction`, `InputMappingContext`, `BindAction`, `FInputActionValue` |
| 4 — Data exposure | engine-agnostic — the list below applies to all three | | |
| 5, 6 | judgement and manifests, not greps — no engine set needed | | |

| 类别 | Godot | Unity | Unreal |
|---|---|---|---|
| 1 — 存档 / 序列化 | 下方的 Godot 列表 | **NOT SOURCEABLE** | **NOT SOURCEABLE** |
| 2 — 网络 / 多人 | 下方的 Godot 列表 | `ServerRpc`, `ClientRpc`, `NetworkVariable`, `NetworkObject`, `NetworkManager`, `NetworkBehaviour`, `IsServer`, `IsOwner` | `UFUNCTION`, `Server`, `Client`, `NetMulticast`, `Replicated`, `DOREPLIFETIME`, `GetLifetimeReplicatedProps`, `HasAuthority` |
| 3 — 输入 | 下方的 Godot 列表 | `InputSystem`, `PlayerInput`, `ReadValue`, `InputValue` | `EnhancedInput`, `UInputAction`, `InputMappingContext`, `BindAction`, `FInputActionValue` |
| 4 — 数据暴露 | 与引擎无关 — 下方列表适用于三者 | | |
| 5、6 | 判断与清单，不是 grep — 无需引擎集合 | | |

The Unity and Unreal names above are **sourced from this repo's pinned
references** (`docs/engine-reference/unity/modules/{networking,input}.md`,
`docs/engine-reference/unreal/modules/{networking,input}.md`), not from recall.
Verify them against the pin before use and add what the reference documents that
this table omits — it is a floor, not a complete set.

上表中的 Unity 与 Unreal 名称**来源自本仓库钉定的
参考文档**（`docs/engine-reference/unity/modules/{networking,input}.md`、
`docs/engine-reference/unreal/modules/{networking,input}.md`），而非凭记忆。
使用前对照钉定版本核验它们，并补充参考文档记载而本表
遗漏的内容——它是一个下限，不是完整集合。

> **`NOT SOURCEABLE` is a verdict, not a gap to fill from memory.** Neither
> reference tree carries a serialization/save module, so the save-API names for
> Unity and Unreal cannot be confirmed here. **Do not write them from training
> data.** A confidently wrong pattern list is worse in this skill than in any
> other: it produces a scan that looks thorough, finds nothing, and reads as a
> pass. Where the table says NOT SOURCEABLE, that category is **`NOT ASSESSED`**
> for this engine — see Phase 5. To close it properly, add a save/serialization
> module, sourced like the others, to `docs/engine-reference/<engine>/modules/`;
> when one is there, take the category's pattern names from it, cite it in the
> report, and the category runs.

> **`NOT SOURCEABLE` 是一种裁决，而不是一处需要用记忆填补的空白。** 两棵
> 参考树都不带有序列化/存档模块，因此 Unity 和 Unreal 的存档 API 名称
> 在此无法确认。**不要凭训练数据写出它们。** 一份自信却错误的模式列表，在本技能里比在任何
> 其他技能里都更糟：它产生的扫描看起来彻底、什么也找不到，却被读作
> 通过。凡表格标注 NOT SOURCEABLE 之处，该类别在本引擎下即为 **`NOT ASSESSED`**
> ——见阶段 5。要正确关闭它，请像其他模块一样添加一个有来源的存档/序列化
> 模块到 `docs/engine-reference/<engine>/modules/`；
> 一旦有了，就从它取得该类别的模式名称，在报告中引用它，该类别便可运行。

### Category 1: Save File and Serialization Security

### 类别 1：存档文件与序列化安全

- Are save files validated before loading? (no blind deserialization)
- Are save file paths constructed from user input? (path traversal risk)
- Are save files checksummed or signed? (tamper detection)
- Does the game trust numeric values from save files without bounds checking?
- Are there any eval() or dynamic code execution calls near save loading?

- 存档文件在加载前是否经过校验？（不得盲目反序列化）
- 存档文件路径是否由用户输入构造？（路径遍历风险）
- 存档文件是否做了校验和或签名？（篡改检测）
- 游戏是否在不做边界检查的情况下信任存档文件中的数值？
- 存档加载路径附近是否存在任何 eval() 或动态代码执行调用？

Grep patterns — **check the pinned engine reference before trusting this list**
(see the API-name warning below): `FileAccess`, `File.open`, `open(`, `load`,
`deserialize`, `parse`, `parse_string`, `from_json`, `read_file`, `get_var`,
`bytes_to_var` — check each for validation.

Grep 模式 — **在信任此列表前先核对钉定的引擎参考文档**
（见下方的 API 名称警告）：`FileAccess`、`File.open`、`open(`、`load`、
`deserialize`、`parse`、`parse_string`、`from_json`、`read_file`、`get_var`、
`bytes_to_var` — 逐项检查是否做了校验。

> **API names are version-specific and this list is a starting point, not a
> complete set.** `File.open` is **Godot 3.x**; Godot 4 renamed the class to
> `FileAccess` (`docs/engine-reference/godot/breaking-changes.md`). Before relying
> on these patterns, read `docs/engine-reference/<engine>/` for the version this
> project pins and add the names it documents. A grep for a class that no longer
> exists returns zero hits, and **zero hits in this category renders the report
> clean** — which is the most dangerous possible failure for a security audit.
> Searching only `File.open` against a Godot 4 project finds nothing and reports
> CLEAR TO SHIP on a codebase nobody checked. If you cannot confirm the correct
> names for the pinned version, say so in the report rather than presenting a
> zero-hit scan as a pass.

> **API 名称是版本相关的，此列表只是起点，不是完整集合。**
> `File.open` 是 **Godot 3.x** 的；Godot 4 将该类重命名为
> `FileAccess`（`docs/engine-reference/godot/breaking-changes.md`）。在依赖
> 这些模式之前，请读取 `docs/engine-reference/<engine>/` 中本项目钉定的版本，
> 并补充它记载的名称。对一个已不存在的类做 grep 会返回零命中，而**在此类别中零命
> 会让报告显得干净**——这是安全审计可能出现的最危险的失效。
> 仅以 `File.open` 搜索一个 Godot 4 项目会什么都找不到，并在一个无人检查过的
> 代码库上报告 CLEAR TO SHIP。若你无法确认钉定版本的正确
> 名称，请在报告中说明，而不要把一次零命中扫描当作通过。

### Category 2: Network and Multiplayer Security (skip if single-player only)

### 类别 2：网络与多人安全（仅在纯单人时跳过）

- Is game state authoritative on the server, or does the client dictate outcomes?
- Are incoming network packets validated for size, type, and value range?
- Are player positions and state changes validated server-side?
- Is there rate limiting on any network calls?
- Are authentication tokens handled correctly (never sent in plaintext)?
- Does the game expose any debug endpoints in release builds?

- 游戏状态是否由服务器权威决定，还是由客户端主导结果？
- 传入的网络数据包是否对大小、类型和值域做了校验？
- 玩家位置和状态变更是否在服务端校验？
- 任何网络调用是否有速率限制？
- 认证令牌是否被正确处理（绝不以明文发送）？
- 游戏在发布构建中是否暴露了任何调试端点？

Grep for: `recv`, `receive`, `PacketPeer`, `socket`, `MultiplayerPeer`,
`ENetMultiplayerPeer`, `NetworkedMultiplayerPeer`, `rpc`, `rpc_id`,
`@rpc` — check each call site for validation.

Grep：`recv`、`receive`、`PacketPeer`、`socket`、`MultiplayerPeer`、
`ENetMultiplayerPeer`、`NetworkedMultiplayerPeer`、`rpc`、`rpc_id`、
`@rpc` — 逐个调用点检查是否做了校验。

> Same version caveat as Category 1. `NetworkedMultiplayerPeer` is **Godot 3.x**;
> Godot 4 uses `ENetMultiplayerPeer`
> (`docs/engine-reference/godot/modules/networking.md`). The bare substring
> `MultiplayerPeer` matches both and is the safer probe.

> 与类别 1 相同的版本注意事项。`NetworkedMultiplayerPeer` 是 **Godot 3.x**；
> Godot 4 使用 `ENetMultiplayerPeer`
> （`docs/engine-reference/godot/modules/networking.md`）。裸子串
> `MultiplayerPeer` 可同时匹配两者，是更安全的探测。

### Category 3: Input Validation

### 类别 3：输入校验

- Are any player-supplied strings used in file paths? (path traversal)
- Are any player-supplied strings logged without sanitization? (log injection)
- Are numeric inputs (e.g., item quantities, character stats) bounds-checked before use?
- Are achievement/stat values checked before being written to any backend?

- 是否有任何玩家提供的字符串被用于文件路径？（路径遍历）
- 是否有任何玩家提供的字符串未经净化即被记录日志？（日志注入）
- 数值输入（例如物品数量、角色属性）在使用前是否做了边界检查？
- 成就/统计数据在写入任何后端之前是否经过检查？

Grep for: `get_input`, `Input.get_`, `input_map`, user-facing text fields — check validation.

Grep：`get_input`、`Input.get_`、`input_map`、面向用户的文本字段 — 检查校验。

### Category 4: Data Exposure

### 类别 4：数据暴露

- Are any API keys, credentials, or secrets hardcoded in the code root or `assets/`?
- Are debug symbols or verbose error messages included in release builds?
- Does the game log sensitive player data to disk or console?
- Are any internal file paths or system information exposed to players?

- 是否有任何 API 密钥、凭据或机密被硬编码在代码根或 `assets/` 中？
- 发布构建中是否包含调试符号或详尽的错误消息？
- 游戏是否将敏感玩家数据记录到磁盘或控制台？
- 是否有任何内部文件路径或系统信息暴露给玩家？

Grep case-insensitively in release-facing code for: `api[_-]?key`, `secret`,
`password`, `token`, `private[_-]?key`, `sk_live`, `BEGIN PRIVATE KEY`, `DEBUG`,
and the engine's print call (`print(` on Godot, `Debug.Log` on Unity, `UE_LOG`
on Unreal).

在面向发布的代码中不区分大小写地 Grep：`api[_-]?key`、`secret`、
`password`、`token`、`private[_-]?key`、`sk_live`、`BEGIN PRIVATE KEY`、`DEBUG`，
以及该引擎的打印调用（Godot 上是 `print(`，Unity 上是 `Debug.Log`，Unreal 上是 `UE_LOG`）。

### Category 5: Cheat and Anti-Tamper Vectors

### 类别 5：作弊与防篡改途径

- Are gameplay-critical values stored only in memory, not in easily-editable files?
- Are any critical game progression flags (e.g., "has paid for DLC") validated server-side?
- Is there any protection against memory editing tools (Cheat Engine, etc.) for multiplayer?
- Are leaderboard/score submissions validated before acceptance?

- 玩法关键数值是否仅存于内存，而非易于编辑的文件中？
- 是否有任何关键游戏进度标志（例如"已为 DLC 付费"）在服务端校验？
- 多人游戏是否有任何针对内存编辑工具（Cheat Engine 等）的防护？
- 排行榜/分数提交在接受前是否经过校验？

Note: Client-side anti-cheat is largely unenforceable. Focus on server-side validation for anything competitive or monetised.

注意：客户端反作弊在很大程度上无法强制执行。对任何竞争性或涉及付费的内容，应聚焦于服务端校验。

### Category 6: Dependency and Supply Chain

### 类别 6：依赖与供应链

- Are any third-party plugins or libraries used? List them.
- Do any plugins have known CVEs in the version being used?
- Are plugin sources verified (official marketplace, reviewed repository)?

- 是否使用了任何第三方插件或库？列出它们。
- 是否有任何插件在所使用版本中存在已知 CVE？
- 插件来源是否经过验证（官方市场、已审阅的仓库）？

Glob for: `addons/`, `plugins/`, `third_party/`, `vendor/` — list all external dependencies.

Glob：`addons/`、`plugins/`、`third_party/`、`vendor/` — 列出所有外部依赖。

---

## Phase 4: Classify Findings

## 阶段 4：归类发现

For each finding, assign:

为每项发现指定：

**Severity:**
| Level | Definition |
|-------|-----------|
| **CRITICAL** | Remote code execution, data breach, or trivially-exploitable cheat that breaks multiplayer integrity |
| **HIGH** | Save tampering that bypasses progression, credential exposure, or server-side authority bypass |
| **MEDIUM** | Client-side cheat enablement, information disclosure, or input validation gap with limited impact |
| **LOW** | Defence-in-depth improvement — hardening that reduces attack surface but no direct exploit exists |

**严重度：**
| 级别 | 定义 |
|-------|-----------|
| **CRITICAL** | 远程代码执行、数据泄露，或破坏多人完整性的、可轻易利用的作弊 |
| **HIGH** | 绕过成长的存档篡改、凭据暴露，或服务端权威绕过 |
| **MEDIUM** | 客户端作弊使能、信息泄露，或影响有限的输入校验缺口 |
| **LOW** | 纵深防御改进 — 减少攻击面的加固，但不存在直接利用 |

**Status:** Open / Accepted Risk / Out of Scope

**状态：** Open / Accepted Risk / Out of Scope

---

## Phase 5: Generate Report

## 阶段 5：生成报告

```markdown
# Security Audit Report

**Date**: [date]
**Scope**: [full | network | save | input | quick]
**Engine**: [engine + version]
**Audited by**: [security-engineer via /security-audit | this session — security-engineer not spawned: reason]
**Files scanned**: [N source files, N config files]

---

## Executive Summary

| Severity | Count | Must Fix Before Release |
|----------|-------|------------------------|
| CRITICAL | [N] | Yes — all |
| HIGH | [N] | Yes — all |
| MEDIUM | [N] | Recommended |
| LOW | [N] | Optional |

**Release recommendation**: [NOT ASSESSED — INSUFFICIENT IMPLEMENTATION / CLEAR TO SHIP / FIX BEFORE SHIPPING / DO NOT SHIP]

Choose it by the open findings, first match wins:
- **DO NOT SHIP** — any open CRITICAL finding (in a multiplayer game, any open HIGH
  counts as CRITICAL)
- **FIX BEFORE SHIPPING** — open HIGH findings and no CRITICAL; the Polish → Release
  gate needs zero open HIGH (at `standard` and `full`)
- **NOT ASSESSED** — per the rule below, when the scan could not cover the surface.
  It ranks below both failure values — a known finding is more actionable than an
  unscanned category, and still has to be fixed — and above CLEAR TO SHIP
- **CLEAR TO SHIP** — no open CRITICAL or HIGH (MEDIUM and LOW may remain)

> **`NOT ASSESSED` is required when there was not enough implemented surface to
> audit**, or when the API names for the pinned engine version could not be
> confirmed — **in place of CLEAR TO SHIP, never of a failure value.** An open
> CRITICAL or HIGH still decides the recommendation (first match above): a run
> with an unscanned category and an open HIGH is FIX BEFORE SHIPPING, and names
> the unscanned category beside it. A zero-finding scan over two files of source is not a clean bill of
> health, and `CLEAR TO SHIP` must never be reachable by having nothing to look
> at. Name what was missing and which skill produces it.
>
> **The engine axis is part of that rule, not a separate one.** If
> the Phase 3 table marks a category `NOT SOURCEABLE` for this project's
> `engine.name`, that category is `NOT ASSESSED` — state it by name in the
> Executive Summary, and **`CLEAR TO SHIP` is unreachable for the run**. The
> category reads `NOT ASSESSED — <category> has no sourced pattern set for
> <engine>`; the release recommendation is still the first match above, so it is
> NOT ASSESSED only where the run would otherwise have been CLEAR TO SHIP. Never
> report the category as reviewed by other means: files it covers may still be
> read for another category, and a finding that read turns up is reported, but
> the category stays NOT ASSESSED — never "reviewed", "verified safe" or passed.
> A scan that could not look is not a scan that found nothing, and only the
> report can tell the reader which of the two happened.

---

## CRITICAL Findings

### SEC-001: [Title]
**Category**: [Save / Network / Input / Data / Cheat / Dependency]
**File**: `[path]` line [N]
**Description**: [What the vulnerability is]
**Attack scenario**: [How a malicious user would exploit it]
**Remediation**: [Specific code change or pattern to apply]
**Effort**: [Low / Medium / High]

[repeat per finding]

---

## HIGH Findings

[same format]

---

## MEDIUM Findings

[same format]

---

## LOW Findings

[same format]

---

## Accepted Risk

[Any findings explicitly accepted by the team with rationale]

---

## Dependency Inventory

| Plugin / Library | Version | Source | Known CVEs |
|-----------------|---------|--------|------------|
| [name] | [version] | [source] | [none / CVE-XXXX-NNNN] |

---

## Remediation Priority Order

1. [SEC-NNN] — [1-line description] — Est. effort: [Low/Medium/High]
2. ...

---

## Re-Audit Trigger

Run `/security-audit` again after remediating any CRITICAL or HIGH findings.
At `workflow: standard` and `full`, the Polish → Release gate requires this report with no open CRITICAL or HIGH items.
```

---

## Phase 6: Write Report

## 阶段 6：写入报告

Present the report summary (executive summary + CRITICAL/HIGH findings only) in conversation.

在对话中呈现报告摘要（仅执行摘要 + CRITICAL/HIGH 发现）。

Ask: "May I write the full security audit report to `production/security/security-audit-[date]-[scope].md`?"

询问："我可以把完整的安全审计报告写入 `production/security/security-audit-[date]-[scope].md` 吗？"

Write only after approval.

仅在获批后写入。

---

## Phase 7: Gate Integration

## 阶段 7：门禁集成

This report is a required artifact for the **Polish → Release gate** at `workflow: standard` and `full`; the `minimal` gate drops it with everything but smoke and S1 bugs. Say which applies to this project, from the `workflow` resolved above.

本报告是在 `workflow: standard` 和 `full` 下 **Polish → Release 门禁**的必需产物；`minimal` 门禁会将其连同除冒烟与 S1 缺陷之外的一切一并舍弃。根据上文解析的 `workflow`，说明本项目适用哪一种。

After remediating findings, re-run: `/security-audit quick` to confirm CRITICAL/HIGH items are resolved before running `/gate-check release`.

修复发现后，重新运行：`/security-audit quick`，在运行 `/gate-check release` 之前确认 CRITICAL/HIGH 项已解决。

Branch on the release recommendation, not on the finding counts alone:

根据发布建议分支，而不只依据发现数量：

If it is **DO NOT SHIP** (an open CRITICAL, or an open HIGH in a multiplayer game):
> "⛔ CRITICAL security findings must be resolved before any public release. Do not proceed to `/launch-checklist` until these are addressed."

若为 **DO NOT SHIP**（存在未关闭的 CRITICAL，或在多人游戏中存在未关闭的 HIGH）：
> "⛔ 在任何公开发布之前必须解决 CRITICAL 安全发现。在这些被处理之前，不要进入 `/launch-checklist`。"

If it is **FIX BEFORE SHIPPING** (open HIGH findings, no CRITICAL, single-player):
> At `workflow: standard`/`full`: "⚠️ [N] HIGH finding(s) are open. The Polish → Release gate's security audit item requires none — fix them and re-run `/security-audit quick` before `/gate-check release`."
>
> At `minimal`: "⚠️ [N] HIGH finding(s) are open — fix them and re-run `/security-audit quick` before you ship. The `minimal` release gate does not read this report; the open HIGH still makes the recommendation FIX BEFORE SHIPPING."

若为 **FIX BEFORE SHIPPING**（存在未关闭的 HIGH 发现、无 CRITICAL、单人游戏）：
> 在 `workflow: standard`/`full` 下："⚠️ 有 [N] 项 HIGH 发现未关闭。Polish → Release 门禁的安全审计项要求为零——修复它们，并在 `/gate-check release` 之前重新运行 `/security-audit quick`。"
>
> 在 `minimal` 下："⚠️ 有 [N] 项 HIGH 发现未关闭——修复它们，并在发布前重新运行 `/security-audit quick`。`minimal` 发布门禁不读取本报告；未关闭的 HIGH 仍使建议为 FIX BEFORE SHIPPING。"

If it is **NOT ASSESSED**:
> "Security audit NOT ASSESSED — [each category not assessed, and why]. The report is
> written. [At `workflow: standard`/`full`:] `/gate-check release` will report its
> security item NOT ASSESSED until [the missing input] is supplied and the audit
> re-run. [At `minimal`:] The `minimal` release gate does not read this report,
> but those categories stay unscanned until [the missing input] is supplied."
>
> Name the missing input for each category: `engine.name`, the code root, the
> multiplayer scope (`/settings platform.multiplayer=…`), or — for a category the
> Phase 3 table marks NOT SOURCEABLE on this engine, the usual cause on Unity and
> Unreal — a save/serialization module in `docs/engine-reference/<engine>/modules/`
> (Phase 3), naming that category.

若为 **NOT ASSESSED**：
> "安全审计 NOT ASSESSED — [逐项列出未评估的类别及原因]。报告已
> 写入。[在 `workflow: standard`/`full` 下：] 在提供 [缺失的输入] 并重新运行审计之前，
> `/gate-check release` 会将其安全项报告为
> NOT ASSESSED。[在 `minimal` 下：] `minimal` 发布门禁不读取本报告，
> 但在提供 [缺失的输入] 之前，那些类别仍未被扫描。"
>
> 为每个类别指明缺失的输入：`engine.name`、代码根、
> 多人范围（`/settings platform.multiplayer=…`），或者——对于
> 阶段 3 表格在本引擎上标记为 NOT SOURCEABLE 的类别，这在 Unity 和
> Unreal 上是常见原因——`docs/engine-reference/<engine>/modules/` 中的存档/序列化模块
> （阶段 3），并指明该类别。

If it is **CLEAR TO SHIP**:
> "✅ No blocking security findings. Report written to `production/security/`. Include this path when running `/gate-check release`."

若为 **CLEAR TO SHIP**：
> "✅ 无阻断性安全发现。报告已写入 `production/security/`。运行 `/gate-check release` 时请包含此路径。"

---

## Collaborative Protocol

## 协作协议

- **Never assume a pattern is safe** — flag it and let the user decide
- **Accepted risk is a valid outcome** — some LOW findings are acceptable trade-offs for a solo team; document the decision
- **Multiplayer games have a higher bar** — any HIGH finding in a multiplayer context should be treated as CRITICAL
- **This is not a penetration test** — this audit covers common patterns; a real pentest by a human security professional is recommended before any competitive or monetised multiplayer launch

- **绝不假定某个模式是安全的** — 标记它，让用户决定
- **接受风险是一种有效结果** — 对单人团队而言，某些 LOW 发现是可接受的取舍；将决定记录在案
- **多人游戏的标准更高** — 多人情境下的任何 HIGH 发现都应按 CRITICAL 处理
- **这不是渗透测试** — 本审计覆盖常见模式；在任何竞争性或涉及付费的多人发布之前，建议由人类安全专家执行一次真正的渗透测试
