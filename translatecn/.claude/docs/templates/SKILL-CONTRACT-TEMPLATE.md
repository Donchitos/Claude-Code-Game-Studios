# Skill Contract Template
# 技能契约模板

> **Status — read before using this template.**
>
> The **Identity & Scope**, **Input Contract**, **Output Contract**, **Hard/Soft
> Constraints** and **Handoff Configuration** sections are live and reflect how
> contracts are authored today.
>
> The **Testing Evidence Required** and **Drift Monitoring** sections are
> **aspirational** — the runners they name (`tests/smoke-tests/`,
> `tests/golden-datasets/`, `tests/behavioral-tests/`, `tests/integration/`) and
> `production/session-state/drift-monitor.md` do **not exist**, no skill has a
> `TESTS.md`, and none of the seven shipped `CONTRACT.md` files use the ASI or
> drift machinery. Treat them as a design sketch for a future skill-quality
> system, not as steps to follow.
>
> The seven shipped contracts use a simpler shape than this template:
> `Inputs Consumed` / `Files That Must Exist` / `Preconditions` /
> `Outputs Produced` / `Output Guarantees` / `Immutability Rules`. Match an
> existing contract (e.g. `.claude/skills/dev-story/CONTRACT.md`) rather than
> this template's schema-heavy form until the two are reconciled.
> **状态——使用此模板前请阅读。**
>
> **身份与范围**、**输入契约**、**输出契约**、**硬/软
> 约束**以及**交接配置**章节是现行的，反映了当前
> 契约的编写方式。
>
> **所需测试证据**与**漂移监控**章节是
> **理想化的**——它们提到的运行器（`tests/smoke-tests/`、
> `tests/golden-datasets/`、`tests/behavioral-tests/`、`tests/integration/`）以及
> `production/session-state/drift-monitor.md` **并不存在**，没有任何技能拥有
> `TESTS.md`，七个已发布的 `CONTRACT.md` 文件也都没有使用 ASI 或
> 漂移机制。把它们视为未来技能质量系统的设计草图，
> 而非要遵循的步骤。
>
> 七个已发布的契约使用比此模板更简单的形态：
> `Inputs Consumed` / `Files That Must Exist` / `Preconditions` /
> `Outputs Produced` / `Output Guarantees` / `Immutability Rules`。在两者
> 调和之前，请匹配现有契约（例如 `.claude/skills/dev-story/CONTRACT.md`），
> 而非此模板的 schema 繁重形式。

**Purpose:** Define formal handoff contract for a skill. Create as `.claude/skills/<skill-name>/CONTRACT.md`.
**目的**：为技能定义正式的交接契约。创建为 `.claude/skills/<skill-name>/CONTRACT.md`。

**How to Use:**
1. Copy this template
2. Replace `[SKILL_NAME]`, `[ROLE]`, `[DESCRIPTION]` with your skill's details
3. Define input/output schemas precisely
4. List hard constraints (must never violate) and soft constraints (recover if violated)
5. Include examples of valid input/output
6. Reference this contract in your SKILL.md file
**如何使用**：
1. 复制此模板
2. 用你的技能细节替换 `[SKILL_NAME]`、`[ROLE]`、`[DESCRIPTION]`
3. 精确界定输入/输出 schema
4. 列出硬约束（绝不能违反）与软约束（违反后恢复）
5. 包含有效输入/输出示例
6. 在你的 SKILL.md 文件中引用此契约

---

# [SKILL_NAME] Handoff Contract
# [SKILL_NAME] 交接契约

**Version:** 1.0
**Last Updated:** [DATE]
**Skill File:** `.claude/skills/[SKILL_NAME]/SKILL.md`
**Test File:** `.claude/skills/[SKILL_NAME]/TESTS.md`
**版本：**1.0
**最后更新：**[DATE]
**技能文件：**`.claude/skills/[SKILL_NAME]/SKILL.md`
**测试文件：**`.claude/skills/[SKILL_NAME]/TESTS.md`

---

## Identity & Scope
## 身份与范围

### Role
### 角色
[ROLE] — [ONE SENTENCE DESCRIBING WHAT THIS SKILL DOES]
[ROLE] — [一句话描述此技能做什么]

### Example
### 示例
Story Author — Decomposes game design epics into atomic, testable user stories with clear acceptance criteria.
故事作者——将游戏设计史诗分解为原子化、可测试的用户故事，并带有清晰的验收标准。

### Domain Boundaries
### 领域边界
**Can Read:**
- `design/gdd/` (game design documents)
- `.claude/docs/` (architectural guidance)
- `production/session-state/` (context from previous skills)

**Can Write:**
- `production/epics/[epic-slug]/` (creates new story markdown files)
- `production/qa/evidence/` (creates test evidence stubs)

**Cannot Touch:**
- The code root — `src/`, `Assets/` or `Source/` by engine (no game code)
- `assets/` (no asset modifications)
- Source data files (read-only)
**可读取：**
- `design/gdd/`（游戏设计文档）
- `.claude/docs/`（架构指导）
- `production/session-state/`（来自先前技能的上下文）

**可写入：**
- `production/epics/[epic-slug]/`（创建新的故事 markdown 文件）
- `production/qa/evidence/`（创建测试证据存根）

**不可触碰：**
- 代码根目录——按引擎为 `src/`、`Assets/` 或 `Source/`（不写游戏代码）
- `assets/`（不修改资产）
- 源数据文件（只读）

---

## Input Contract
## 输入契约

### What This Skill Receives
### 此技能接收什么

**Source Skill:** [PREVIOUS_SKILL_NAME] (e.g., `/create-epics`)
**Format:** Markdown with structured frontmatter
**Transport:** Session context or file reference
**源技能：**[PREVIOUS_SKILL_NAME]（例如 `/create-epics`）
**格式：**带结构化 frontmatter 的 Markdown
**传输：**会话上下文或文件引用

### Required Fields
### 必需字段

```yaml
# Example input epic (YAML frontmatter in Markdown)
epic_id: "COMBAT-BASIC"
epic_goal: "Implement core melee attack system"
epic_acceptance_criteria:
  - "Player can attack with sword"
  - "Damage is configurable"
  - "Animation plays on hit"
  - "Enemy health updates"
target_complexity: "medium"  # low | medium | high
estimated_story_count: 3
```

### Schema Definition
### Schema 定义

```json
{
  "type": "object",
  "required": ["epic_id", "epic_goal", "epic_acceptance_criteria", "target_complexity"],
  "properties": {
    "epic_id": {
      "type": "string",
      "pattern": "^[A-Z]+(-[A-Z0-9]+)?$",
      "minLength": 2,
      "maxLength": 50
    },
    "epic_goal": {
      "type": "string",
      "minLength": 10,
      "maxLength": 500,
      "description": "High-level objective, not implementation"
    },
    "epic_acceptance_criteria": {
      "type": "array",
      "minItems": 1,
      "maxItems": 20,
      "items": {
        "type": "string",
        "minLength": 5,
        "maxLength": 200
      }
    },
    "target_complexity": {
      "type": "string",
      "enum": ["low", "medium", "high"]
    },
    "estimated_story_count": {
      "type": "integer",
      "minimum": 1,
      "maximum": 50
    }
  }
}
```

### Validation Rules
### 校验规则

- [ ] Epic ID matches pattern `^[A-Z]+-[A-Z0-9]+$` (e.g., `COMBAT-BASIC`)
- [ ] Epic goal is 10–500 characters (not too brief, not a novel)
- [ ] At least 1, at most 20 acceptance criteria
- [ ] Target complexity is one of: `low`, `medium`, `high`
- [ ] If estimated story count provided, >= 1 and <= 50
- [ ] 史诗 ID 匹配模式 `^[A-Z]+-[A-Z0-9]+$`（例如 `COMBAT-BASIC`）
- [ ] 史诗目标是 10-500 个字符（不过于简短，也不是小说）
- [ ] 至少 1 条、至多 20 条验收标准
- [ ] 目标复杂度为以下之一：`low`、`medium`、`high`
- [ ] 若提供预估故事数，>= 1 且 <= 50

### Examples of Valid Input
### 有效输入示例

```markdown
## Valid Example 1: Simple Epic

epic_id: COMBAT-BASIC
epic_goal: Implement core melee attack system
epic_acceptance_criteria:
  - Player can attack with sword
  - Damage is configurable from external data
  - Attack animation plays when action triggered
  - Target health decreases by damage amount
target_complexity: medium
estimated_story_count: 3
```

```markdown
## Valid Example 2: Large Epic

epic_id: PROGRESSION-FULL
epic_goal: Implement complete character progression system
epic_acceptance_criteria:
  - Player gains experience from defeated enemies
  - Experience unlocks new abilities
  - Player can level up manually
  - Leveling resets some cooldowns
  - New abilities appear in player menu
target_complexity: high
estimated_story_count: 12
```

---

## Output Contract
## 输出契约

### What This Skill Produces
### 此技能产出什么

**Destination Skill:** [NEXT_SKILL_NAME] (e.g., `/dev-story`)
**Format:** Markdown with structured headers
**Location:** Typically written to `production/epics/[epic-slug]/story-NNN-[slug].md`
**目标技能：**[NEXT_SKILL_NAME]（例如 `/dev-story`）
**格式：**带结构化标题的 Markdown
**位置：**通常写入 `production/epics/[epic-slug]/story-NNN-[slug].md`

### Output Structure
### 输出结构

```markdown
# Stories for [EPIC_ID]

## [STORY_ID]: [STORY_TITLE]

### Description
[1-3 paragraph description of the user story, written from player/user perspective]

### Acceptance Criteria
1. [Testable criterion 1 — imperative mood, specific observable behavior]
2. [Testable criterion 2]
3. [Testable criterion 3]
4. [Optional: criterion 4+, up to 5 per story]

### Complexity Estimate
[low | medium | high]

### Dependencies
[List other stories that should complete first, if any. Format: "EPIC_ID-N"]

---
## [STORY_ID+1]: [NEXT_STORY_TITLE]
...
```

### Schema Definition
### Schema 定义

```json
{
  "type": "object",
  "required": ["stories"],
  "properties": {
    "epic_id": { "type": "string" },
    "stories": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["story_id", "title", "description", "acceptance_criteria"],
        "properties": {
          "story_id": {
            "type": "string",
            "pattern": "^[A-Z]+-[A-Z0-9]+-[0-9]+$",
            "description": "Format: EPIC-ID-N"
          },
          "title": {
            "type": "string",
            "minLength": 5,
            "maxLength": 100,
            "description": "User-centric; action-oriented"
          },
          "description": {
            "type": "string",
            "minLength": 20,
            "maxLength": 1000,
            "description": "1-3 paragraphs, player perspective"
          },
          "acceptance_criteria": {
            "type": "array",
            "minItems": 3,
            "maxItems": 5,
            "items": {
              "type": "string",
              "minLength": 10,
              "maxLength": 200,
              "description": "Testable, imperative mood"
            }
          },
          "complexity_estimate": {
            "type": "string",
            "enum": ["low", "medium", "high"]
          },
          "dependencies": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Story IDs that should complete first"
          }
        }
      }
    }
  }
}
```

### Validation Rules
### 校验规则

- [ ] Each story has unique story ID matching pattern `^[A-Z]+-[A-Z0-9]+-[0-9]+$`
- [ ] Story IDs are sequential by epic (e.g., `COMBAT-BASIC-1`, `COMBAT-BASIC-2`, etc.)
- [ ] Story count matches epic estimate ± 1 (e.g., if epic estimated 3, produce 2–4)
- [ ] Each story has ≥3 and ≤5 acceptance criteria
- [ ] Acceptance criteria are in imperative mood ("Player can...", "System validates...")
- [ ] No code suggestions in story description (remain abstract)
- [ ] No modification to original epic acceptance criteria (can expand, not change)
- [ ] Dependencies reference valid story IDs (not forward references)
- [ ] 每个故事拥有唯一的故事 ID，匹配模式 `^[A-Z]+-[A-Z0-9]+-[0-9]+$`
- [ ] 故事 ID 按史诗顺序递增（例如 `COMBAT-BASIC-1`、`COMBAT-BASIC-2` 等）
- [ ] 故事数量与史诗预估相差 ± 1（例如史诗预估 3，则产出 2-4）
- [ ] 每个故事有 ≥3 且 ≤5 条验收标准
- [ ] 验收标准使用祈使语气（"玩家可以……"、"系统校验……"）
- [ ] 故事描述中不含代码建议（保持抽象）
- [ ] 不修改原始史诗验收标准（可扩展，不可更改）
- [ ] 依赖引用有效的故事 ID（非前向引用）

### Examples of Valid Output
### 有效输出示例

```markdown
# Stories for COMBAT-BASIC

## COMBAT-BASIC-1: Player Can Attack with Sword

### Description
The player wields a sword and can trigger basic melee attacks against enemies. When the attack button is pressed, the player's character plays an attack animation and applies damage to the target if in range.

### Acceptance Criteria
1. Player equips sword from starting inventory
2. Attack action triggers when spacebar pressed
3. Attack animation plays (2-frame simple swing)
4. Damage applied to target if in melee range (2-unit radius)

### Complexity Estimate
low

### Dependencies
(none)

---

## COMBAT-BASIC-2: Damage Values Are Configurable

### Description
All damage values (sword damage, enemy health) come from external configuration files. This allows designers to tune balance without changing code.

### Acceptance Criteria
1. Sword damage loaded from `data/weapons.json`
2. Enemy health loaded from `data/enemies.json`
3. Changing JSON values changes in-game behavior immediately
4. Invalid values trigger error log and fall back to default

### Complexity Estimate
medium

### Dependencies
- COMBAT-BASIC-1
```

---

## Hard Constraints (Must Never Violate)
## 硬约束（绝不能违反）

Violations automatically trigger intervention/rejection.
违反会自动触发干预/拒绝。

- ❌ **Do not modify epic goals** — story must not contradict or rewrite the input epic's goal
- ❌ **Do not change acceptance criteria sources** — if epic says "damage is configurable", don't remove this criteria
- ❌ **Do not write game code** — stories remain abstract, no code suggestions like `player.attack()`
- ❌ **Do not modify input epic file** — treat as read-only immutable
- ❌ **Do not produce invalid story IDs** — must match pattern `EPIC-ID-N`
- ❌ **Do not produce stories without acceptance criteria** — minimum 3 required
- ❌ **Do not skip or merge stories** — if epic estimated 5 stories, deliver 4–6, not 2–3
- ❌ **Do not create circular dependencies** — story cannot depend on later stories
- ❌ **不得修改史诗目标**——故事不得与输入史诗的目标相矛盾或改写它
- ❌ **不得更改验收标准来源**——若史诗说"伤害可配置"，不要移除这条标准
- ❌ **不得编写游戏代码**——故事保持抽象，不出现类似 `player.attack()` 的代码建议
- ❌ **不得修改输入史诗文件**——视为只读不可变
- ❌ **不得产出无效故事 ID**——必须匹配模式 `EPIC-ID-N`
- ❌ **不得产出没有验收标准的故事**——至少需要 3 条
- ❌ **不得跳过或合并故事**——若史诗预估 5 个故事，交付 4-6 个，而非 2-3 个
- ❌ **不得创建循环依赖**——故事不能依赖后续故事

**Enforcement:** Schema validation + assertion checks in test runner. Failures block handoff.
**执行**：测试运行器中的 schema 校验 + 断言检查。失败会阻止交接。

---

## Soft Constraints (Recover if Violated)
## 软约束（违反后恢复）

Violations warn and attempt recovery; don't block.
违反会警告并尝试恢复；不会阻止。

- ⚠️ **Exceeded story count estimate** — if epic estimated 3, produced 6: log warning and continue (likely not a fatal error, but note for analysis)
- ⚠️ **Story description too brief** — < 20 characters: resample with examples and continue
- ⚠️ **Acceptance criteria phrasing unclear** — not imperative mood: ask for clarification or resample
- ⚠️ **Tone inconsistency** — some stories formal, others casual: resample to match baseline tone
- ⚠️ **Missing complexity estimates** — only partially provided: fill missing with median of provided values
- ⚠️ **Vague dependencies** — circular or invalid references: log and continue (downstream can validate)
- ⚠️ **超出故事数量预估**——若史诗预估 3 个，却产出 6 个：记录警告并继续（可能不是致命错误，但记录供分析）
- ⚠️ **故事描述过短**——< 20 个字符：带示例重新采样并继续
- ⚠️ **验收标准措辞不清**——非祈使语气：请求澄清或重新采样
- ⚠️ **语气不一致**——一些故事正式，另一些随意：重新采样以匹配基线语气
- ⚠️ **缺少复杂度估算**——仅部分提供：用所提供值的中位数填充缺失项
- ⚠️ **依赖含糊**——循环或无效引用：记录并继续（下游可校验）

**Enforcement:** Detected during behavioral tests; logged to drift monitor. Do not block handoff, but flag for review.
**执行**：在行为测试中检测；记录到漂移监控。不阻止交接，但标记供评审。

---

## Handoff Configuration
## 交接配置

### Receives From
### 接收自
**Upstream Skill:** `/create-epics` (or equivalent epic-generation skill)
**上游技能：**`/create-epics`（或等效的史诗生成技能）

**How Data Arrives:**
- Option 1: Epic content passed as context string
- Option 2: Epic file path provided; skill reads it
- Option 3: Epic data in structured YAML/JSON
**数据如何到达：**
- 选项 1：史诗内容作为上下文字符串传递
- 选项 2：提供史诗文件路径；技能读取它
- 选项 3：史诗数据以结构化 YAML/JSON 提供

**Immutability at Boundary:**
- Epic goal — read-only, not modified
- Acceptance criteria sources — read-only, can expand but not contradict
- Epic ID — read-only, referenced in story IDs
**边界处的不可变性：**
- 史诗目标——只读，不修改
- 验收标准来源——只读，可扩展但不可矛盾
- 史诗 ID——只读，在故事 ID 中被引用

### Delivers To
### 交付给
**Downstream Skill:** `/dev-story` (or equivalent story-to-task skill)
**下游技能：**`/dev-story`（或等效的故事转任务技能）

**How Data Handed Off:**
- Option 1: Story markdown written to `production/epics/[epic-slug]/story-NNN-[slug].md`
- Option 2: Story content passed as context string to next skill
- Option 3: Story metadata indexed in central registry
**数据如何交接：**
- 选项 1：故事 markdown 写入 `production/epics/[epic-slug]/story-NNN-[slug].md`
- 选项 2：故事内容作为上下文字符串传递给下一个技能
- 选项 3：故事元数据索引到中央注册表

**What Downstream Must Receive:**
- All story IDs and content
- Acceptance criteria unchanged (downstream may add technical notes, not change criteria)
- Dependencies preserved
**下游必须接收什么：**
- 所有故事 ID 与内容
- 验收标准不变（下游可添加技术备注，不可更改标准）
- 依赖得以保留

**What Downstream Cannot Change:**
- Story IDs
- Story titles (can add context/notes, not rename)
- Acceptance criteria (can add implementation guidance, not modify criteria)
**下游不能更改什么：**
- 故事 ID
- 故事标题（可添加上下文/备注，不可重命名）
- 验收标准（可添加实现指导，不可修改标准）

### Rollback Procedure
### 回滚流程

If downstream skill (`/dev-story`) fails to consume stories:
如果下游技能（`/dev-story`）未能消费故事：

1. **Fail Signal:** Downstream returns error (e.g., "story validation failed")
2. **Rollback Action:** Discard any partial work in downstream; return to this skill's output
3. **Recovery:** This skill does NOT re-run; upstream skill decides whether to provide different epic
4. **No State Mutation:** Story file remains unchanged; epic remains unchanged; no side effects
1. **失败信号：**下游返回错误（例如"故事校验失败"）
2. **回滚动作：**丢弃下游的任何部分工作；返回此技能的输出
3. **恢复：**此技能**不**重跑；上游技能决定是否提供不同的史诗
4. **无状态变更：**故事文件保持不变；史诗保持不变；无副作用

---

## Testing Evidence Required
## 所需测试证据

Every story skill output must pass this test suite before handoff:
每个故事技能输出必须在交接前通过此测试套件：

### T1: Schema Validation (Deterministic)
### T1：Schema 校验（确定性）
- [ ] Output parses as valid Markdown
- [ ] Output validates against output schema (JSON schema above)
- [ ] Story IDs follow pattern `EPIC-ID-N`
- [ ] Each story has ≥3 acceptance criteria
- [ ] No hard constraint violations (assertion checks)
- [ ] 输出解析为有效 Markdown
- [ ] 输出通过输出 schema 校验（上方的 JSON schema）
- [ ] 故事 ID 遵循模式 `EPIC-ID-N`
- [ ] 每个故事有 ≥3 条验收标准
- [ ] 无硬约束违反（断言检查）

**Test File:** `tests/smoke-tests/schema-validate.sh`
**测试文件：**`tests/smoke-tests/schema-validate.sh`

### T2: Golden Dataset Consistency (Stochastic)
### T2：黄金数据集一致性（随机性）
- [ ] Input: Known good epic (golden dataset)
- [ ] Output: Compare to baseline stories (golden dataset)
- [ ] Metric: Semantic similarity >= 0.85 (embedding cosine distance)
- [ ] Pass: If similarity OK, stories are consistent
- [ ] 输入：已知良好的史诗（黄金数据集）
- [ ] 输出：与基线故事（黄金数据集）比较
- [ ] 指标：语义相似度 >= 0.85（嵌入余弦距离）
- [ ] 通过：若相似度达标，故事一致

**Test File:** `tests/golden-datasets/` (stores expected outputs)
**测试文件：**`tests/golden-datasets/`（存储预期输出）

### T3: Format Stability (Stochastic)
### T3：格式稳定性（随机性）
- [ ] Run skill on same input 5 times
- [ ] Measure format consistency across runs
- [ ] Metric: All 5 outputs match structure (no sections added/removed)
- [ ] Pass: If all 5 runs have same format
- [ ] 对同一输入运行技能 5 次
- [ ] 测量各次运行的格式一致性
- [ ] 指标：全部 5 次输出结构匹配（未添加/移除章节）
- [ ] 通过：若全部 5 次运行格式相同

**Test File:** `tests/behavioral-tests/format-stability.sh`
**测试文件：**`tests/behavioral-tests/format-stability.sh`

### T4: Handoff Integration (Integration)
### T4：交接集成（集成）
- [ ] Downstream skill (`/dev-story`) accepts this output
- [ ] No schema validation errors from downstream
- [ ] Downstream produces valid task output
- [ ] Pass: If downstream accepts >95% of stories
- [ ] 下游技能（`/dev-story`）接受此输出
- [ ] 下游无 schema 校验错误
- [ ] 下游产出有效任务输出
- [ ] 通过：若下游接受 >95% 的故事

**Test File:** `tests/integration/story-to-devstory.sh`
**测试文件：**`tests/integration/story-to-devstory.sh`

### Acceptance Criteria for Handoff
### 交接的验收标准

**This skill is READY TO HAND OFF when:**
- ✅ All hard constraints pass (schema validation, assertion checks)
- ✅ Semantic similarity to golden dataset >= 0.85
- ✅ Format stability across 5 runs (all match structure)
- ✅ Downstream skill accepts output (integration test passes)
- ✅ Drift monitor ASI >= 0.75 (no degradation)
**此技能在以下情况下已准备好交接：**
- ✅ 所有硬约束通过（schema 校验、断言检查）
- ✅ 与黄金数据集的语义相似度 >= 0.85
- ✅ 5 次运行的格式稳定性（全部匹配结构）
- ✅ 下游技能接受输出（集成测试通过）
- ✅ 漂移监控 ASI >= 0.75（无退化）

**Blocking Issues:**
- ❌ Hard constraint violation → must fix before handoff
- ❌ Similarity < 0.85 → investigate drift, resample or adjust
- ❌ Downstream rejection → fix schema or content
**阻塞问题：**
- ❌ 硬约束违反 → 必须在交接前修复
- ❌ 相似度 < 0.85 → 调查漂移，重新采样或调整
- ❌ 下游拒绝 → 修复 schema 或内容

---

## Drift Monitoring
## 漂移监控

### Agent Stability Index (ASI) Components
### 智能体稳定性指数（ASI）组成

**For `/create-stories`, we measure:**
**对于 `/create-stories`，我们测量：**

1. **Response Consistency (30%)** — Are story formats stable across runs?
   - Measure: Embedding similarity of 5 runs on same input (cosine distance)
   - Baseline: >= 0.88 (established on 10 historical stories)
   - Alarm: < 0.85 for 3 consecutive runs

2. **Tool Usage Patterns (25%)** — Does the skill use consistent patterns?
   - Measure: Tool calls, templates, references consistent
   - Baseline: Same design docs referenced, same patterns followed
   - Alarm: New patterns emerge without explanation

3. **Acceptance Criteria Quality (25%)** — Acceptance criteria stable and testable?
   - Measure: Phrasing in imperative mood, specific, testable
   - Baseline: 0 vague criteria per story (e.g., no "should work")
   - Alarm: >1 vague criterion per story

4. **Behavioral Boundaries (20%)** — Skill stays in lane?
   - Measure: No code suggestions, no modified epic goals, no assets touched
   - Baseline: 0 violations per output
   - Alarm: Any violation
1. **响应一致性（30%）**——故事格式在各次运行间是否稳定？
   - 测量：同一输入 5 次运行的嵌入相似度（余弦距离）
   - 基线：>= 0.88（基于 10 个历史故事建立）
   - 警报：连续 3 次运行 < 0.85

2. **工具使用模式（25%）**——技能是否使用一致的模式？
   - 测量：工具调用、模板、引用保持一致
   - 基线：引用相同的设计文档，遵循相同的模式
   - 警报：无解释地出现新模式

3. **验收标准质量（25%）**——验收标准是否稳定且可测试？
   - 测量：措辞为祈使语气、具体、可测试
   - 基线：每个故事 0 条含糊标准（例如不出现"应该能行"）
   - 警报：每个故事 >1 条含糊标准

4. **行为边界（20%）**——技能是否守在本分内？
   - 测量：无代码建议、无修改史诗目标、未触碰资产
   - 基线：每次输出 0 违反
   - 警报：任何违反

**ASI Calculation:**
```
consistency_score = avg_embedding_similarity across 5 runs
tool_score = 1.0 if patterns consistent, 0.8 if slight drift, 0.6 if major change
criteria_score = 1.0 if all testable, 0.8 if 1 vague, 0.6 if >1 vague
boundary_score = 1.0 if no violations, 0.0 if any violation

ASI = (0.30 * consistency) + (0.25 * tool) + (0.25 * criteria) + (0.20 * boundary)
```
**ASI 计算：**
```
consistency_score = avg_embedding_similarity across 5 runs
tool_score = 1.0 if patterns consistent, 0.8 if slight drift, 0.6 if major change
criteria_score = 1.0 if all testable, 0.8 if 1 vague, 0.6 if >1 vague
boundary_score = 1.0 if no violations, 0.0 if any violation

ASI = (0.30 * consistency) + (0.25 * tool) + (0.25 * criteria) + (0.20 * boundary)
```

**Monitoring:**
- Measure after every 5 story skill invocations
- Log to `production/session-state/drift-monitor.md`
- Alert if ASI < 0.75 for 3 consecutive windows
**监控：**
- 每 5 次故事技能调用后测量
- 记录到 `production/session-state/drift-monitor.md`
- 若连续 3 个窗口 ASI < 0.75 则告警

---

## Glossary & References
## 术语表与参考

**Immutable:** Data that cannot be changed after being read. At skill boundaries, input is immutable (protect source epic).
**不可变：**读取后不能更改的数据。在技能边界处，输入是不可变的（保护源史诗）。

**Handoff:** Moment when one skill's output becomes another skill's input. Must be machine-validated.
**交接：**一个技能的输出成为另一个技能输入的时刻。必须经过机器校验。

**Hard Constraint:** Rule that must never be violated. Violation blocks handoff.
**硬约束：**绝不能违反的规则。违反会阻止交接。

**Soft Constraint:** Rule that should be followed. Violation warns but doesn't block; recovery attempted.
**软约束：**应遵循的规则。违反会警告但不阻止；尝试恢复。

**ASI (Agent Stability Index):** Four-dimensional metric measuring skill consistency across 4 dimensions. Threshold 0.75.
**ASI（智能体稳定性指数）：**跨 4 个维度衡量技能一致性的四维指标。阈值 0.75。

**Drift:** Progressive degradation of skill behavior over time or repeated invocations.
**漂移：**技能行为随时间或重复调用的渐进退化。

**Semantic Similarity:** Embedding-based comparison of two texts (0.0 = completely different, 1.0 = identical meaning). Used instead of exact string matching for LLM outputs.
**语义相似度：**基于嵌入的两段文本比较（0.0 = 完全不同，1.0 = 含义相同）。用于 LLM 输出，替代精确字符串匹配。

**Golden Dataset:** Curated set of real inputs and expected outputs used as regression test baseline.
**黄金数据集：**精心挑选的真实输入与预期输出集合，用作回归测试基线。

**Schema Validation:** Checking output against JSON/Markdown schema. Deterministic, machine-verifiable.
**Schema 校验：**对照 JSON/Markdown schema 检查输出。确定性、机器可验证。

---

**Template Version:** 1.0
**Last Updated:** 2026-03-26
**Audience:** Skill authors creating new skills or upgrading existing ones to include contracts
**模板版本：**1.0
**最后更新：**2026-03-26
**受众：**创建新技能或将现有技能升级以包含契约的技能作者
