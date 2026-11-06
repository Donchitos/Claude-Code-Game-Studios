---
name: story-done
description: "Closes a finished story: verifies each acceptance criterion, checks for design or ADR deviations and updates its status. Use when the user says a story is done, finished or ready to close."
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/story-status.sh*), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/session-state.sh *), Bash(git status --porcelain*)
model: sonnet
---
---
name: story-done
description: "关闭已完成的故事：验证每条验收标准、检查设计或 ADR 偏离并更新其状态。当用户说某个故事已完成、已做完或可以关闭时使用。"
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/story-status.sh*), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/session-state.sh *), Bash(git status --porcelain*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,automation_always_ask,workflow,qa.level,gate_level,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

用询问工具提问。若无该工具，将选项编号列出并结束回合等待。
被跳过或关闭的问题不算回答：请用纯文本再次询问。

# Story Done

# 故事完成

Closes a finished story. Every acceptance criterion is checked against evidence,
deviations from the GDD, the ADRs and the story's own scope are reported as facts,
and the story is marked Complete only on the user's yes.

关闭一个已完成的故事。每条验收标准都依据证据核对，
与 GDD、ADR 以及故事自身范围的偏离作为事实报告，
且仅在用户同意后才将故事标记为 Complete。

**Writes, after the user's yes:** the story file (`Status`, `Last Updated`, a
`## Completion Notes` section) and its `production/sprint-status.yaml` entry;
`docs/tech-debt-register.md` only when the user picks that option. The session
checkpoint is written at the end of every run, whatever the verdict.
**Next:** the next story (Phase 8).

**在用户同意后写入：** 故事文件（`Status`、`Last Updated`、一个
`## Completion Notes` 章节）及其 `production/sprint-status.yaml` 条目；
仅当用户选择该选项时才写 `docs/tech-debt-register.md`。会话
检查点在每次运行结束时写入，无论结论如何。
**下一步：** 下一个故事（阶段 8）。

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

询问遵循 `.claude/docs/automation-modes.md`（协作模式始终询问，引导模式就重大选择询问，
自主模式记录并继续；`automation_always_ask` 类别始终询问）。

Checklist (copy it and tick as you go):

清单（复制它并随做随勾）：

```
- [ ] Phase 1: story found, facts and settings read
- [ ] Phase 2: what the story is checked against, loaded for its tier
- [ ] Phase 3: each criterion verified, traceability table built
- [ ] Phase 4: test evidence and run result checked
- [ ] Phase 5: deviations and scope checked
- [ ] Phase 6: review gates run, or their skip noted
- [ ] Phase 7: report and verdict shown; close asked
- [ ] Phase 8: next story named, checkpoint written, closing block printed
```

## Phase 1: The story and its settings

## 阶段 1：故事及其设置

**Which story.** The text typed after the skill name, with any `--review <mode>`
pair removed, is the story path. With nothing typed:

1. The checkpoint in `production/session-state/active.md`: its **Current task**
   line, when it names a story.
2. Else the stories in progress: `bash .claude/scripts/story-facts.sh --all`, rows
   whose state is `IN_REVIEW` or `IN_PROGRESS`. Several: ask "Which story are we
   closing?" with one option per story.
3. None: ask for the path. When `production/epics/` holds no story file at all,
   stop:
   "No stories found in `production/epics/` — run `/create-stories [epic-slug]` to make them (at `standard` and `full`, run `/create-epics` first if there is no epic yet)."

**哪个故事。** 技能名之后输入的文本，去除任何 `--review <mode>`
对，即为故事路径。若什么都没输入：

1. `production/session-state/active.md` 中的检查点：当它点名某个故事时，
   取其 **Current task** 行。
2. 否则取进行中的故事：`bash .claude/scripts/story-facts.sh --all`，状态为
   `IN_REVIEW` 或 `IN_PROGRESS` 的行。若有多个：询问 "Which story are we
   closing?"，每个故事一个选项。
3. 若没有：请求路径。当 `production/epics/` 中完全没有故事文件时，
   停止：
   "No stories found in `production/epics/` — run `/create-stories [epic-slug]` to make them (at `standard` and `full`, run `/create-epics` first if there is no epic yet)."

**Its facts.** `bash .claude/scripts/story-facts.sh <story-path>` gives the status,
type, layer, TR-IDs, ADRs, criteria count, test-evidence status and dependencies.
Then read the story in full: the criteria text, the Test Evidence path, `## Files`,
Out of Scope.

**它的事实。** `bash .claude/scripts/story-facts.sh <story-path>` 给出状态、
类型、层、TR-ID、ADR、标准数、测试证据状态和依赖关系。
然后完整读取故事：标准文本、Test Evidence 路径、`## Files`、
Out of Scope。

**Tier.** `workflow` for the story's system, keyed on the GDD filename stem of its
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`; the `[system]` of its TR-ID only
when there is no GDD path): that system's `system_overrides` row if there is one,
else the project value.

**层级。** 故事所属系统的 `workflow`，以其 `GDD:` 路径的 GDD 文件名主干为键
（`design/gdd/<stem>.md` → `<stem>`；仅在没有 GDD 路径时才用其 TR-ID 中的 `[system]`）：
若有该系统的 `system_overrides` 行则用之，
否则用项目值。

**What `qa.level` requires** (the evidence rows of `.claude/docs/coding-standards.md`).
Take the value from the `qa.level` line above, never from `workflow` or `rigor`: the
two are set apart, so `workflow: minimal` with `qa.level: standard` still requires a
Logic story's unit test.

**`qa.level` 要求什么**（`.claude/docs/coding-standards.md` 的证据行）。
从上面的 `qa.level` 行取值，绝不从 `workflow` 或 `rigor` 取值：
两者是分开设置的，因此 `workflow: minimal` 配合 `qa.level: standard` 仍然要求
逻辑故事的单元测试。

| Check | `qa.level: minimal` | `qa.level: standard` | `qa.level: full` |
|---|---|---|---|
| Logic, Integration test | waived | required | required |
| Config/Data smoke report | waived | required, advisory by default | required, **blocking** by default |
| Visual/Feel, UI retained screenshot | required | required | required |
| Untested criteria (Phase 3) | never escalate | more than half block | **any** blocks |

| 检查 | `qa.level: minimal` | `qa.level: standard` | `qa.level: full` |
|---|---|---|---|
| Logic、Integration 测试 | 豁免 | 必需 | 必需 |
| Config/Data 冒烟报告 | 豁免 | 必需，默认建议性 | 必需，默认**阻断** |
| Visual/Feel、UI 留存截图 | 必需 | 必需 | 必需 |
| 未测试标准（阶段 3） | 从不升级 | 超过一半则阻断 | **任何**一条即阻断 |

The look is never waived: a Visual/Feel or UI story needs its screenshot at every
level. **Gate level** per type is the `gate_level` line above. At `full`, a
Config/Data default (`config=advisory(default…)`) becomes blocking; an explicit
`testing.strict.config: false` still makes it advisory.

外观从不豁免：Visual/Feel 或 UI 故事在每个层级都需要其截图。
按类型的**门禁级别**是上面的 `gate_level` 行。在 `full` 下，
Config/Data 的默认值（`config=advisory(default…)`）变为阻断；显式的
`testing.strict.config: false` 仍使其为建议性。

## Phase 2: What the story is checked against

## 阶段 2：故事依据什么进行核对

By the tier. Read every document by section, never whole.

按层级。按章节读取每份文档，绝不整份读取。

- **`full`:** the current requirement text of each TR-ID: in
  `docs/architecture/tr-registry.yaml`, the lines matching `id: <TR-ID>\s*$` and the
  entry's text below (the anchor keeps `TR-combat-001` from matching
  `TR-combat-0010`; `\s*` takes a Windows line ending). Never use text quoted in the
  story; the GDD's Acceptance Criteria and Detailed Design
  (`bash .claude/scripts/md-section.sh extract design/gdd/<file>.md "Acceptance Criteria"`,
  then the same for `"Detailed Design"`; exit 3: try `"Detailed Rules"`, the design
  standard's name for the same section);
  each ADR's status with `bash .claude/scripts/adr-status.sh <ADR ids>`, then its
  Decision and Consequences sections.
- **`standard`:** the same GDD sections; the ADR sections only for a critical ADR
  (`adr-status.sh`'s layer column reads Foundation, or has no layer).
- **`minimal`:** none. The story's criteria are the spec.

- **`full`：** 每个 TR-ID 的当前需求文本：在
  `docs/architecture/tr-registry.yaml` 中，匹配 `id: <TR-ID>\s*$` 的行及其下方
  条目的文本（锚定使 `TR-combat-001` 不会匹配
  `TR-combat-0010`；`\s*` 兼容 Windows 换行）。绝不使用故事中引用的文本；
  GDD 的 Acceptance Criteria 和 Detailed Design
  （`bash .claude/scripts/md-section.sh extract design/gdd/<file>.md "Acceptance Criteria"`，
  然后对 `"Detailed Design"` 做同样操作；退出码 3：尝试 `"Detailed Rules"`，即设计
  标准对同一章节的名称）；
  每份 ADR 的状态用 `bash .claude/scripts/adr-status.sh <ADR ids>`，然后取其
  Decision 和 Consequences 章节。
- **`standard`：** 同样的 GDD 章节；仅对关键 ADR 读取 ADR 章节
  （`adr-status.sh` 的 layer 列读作 Foundation，或没有 layer）。
- **`minimal`：** 无。故事的验收标准就是规格。

At every tier, when `docs/architecture/control-manifest.md` exists, note its
`Manifest Version` line.

在每个层级，当 `docs/architecture/control-manifest.md` 存在时，记下其
`Manifest Version` 行。

## Phase 3: Verify each criterion

## 阶段 3：验证每条标准

Take each acceptance criterion in turn:

逐条处理每个验收标准：

- **Checked by looking:** a file the criterion names exists; a test file it names
  exists (report "test file present", never "test passes": nothing here runs it);
  numeric literals in gameplay code that belong in data files; player-facing
  strings in the code root that belong in localization files (resolve the root
  per `.claude/docs/code-root-resolution.md`; unresolved, report `NOT ASSESSED —
  code root unresolved`, never zero hits).
- **Asked:** behaviour ("the player takes damage when…"), feel, and performance
  criteria. Never mark one passed from reading the code: the code says what should
  happen, not what the build does. Up to four per ask: "Does [criterion]?" Options:
  Yes — passes / No — fails / Not tested yet. `Not tested yet` is UNTESTED, and
  keeps the verdict at best NOT ASSESSED until someone checks it.
- **Seen on screen:** a criterion about something visible is covered by a retained
  image under `production/qa/evidence/[story-slug]/` (`[story-slug]`: the story
  file's name without `.md`) that you opened and saw it in.
  Never describe an image you have not opened; a checkpoint's `Run result:
  OBSERVED — <text>` is `/dev-story`'s description, to quote as such.
- **Needs a full playtest:** `DEFERRED — requires playtest session`. It does not
  block.

- **通过查看核对：** 标准点名的文件存在；它点名的测试文件
  存在（报告"测试文件存在"，绝不说"测试通过"：此处没有任何东西运行它）；
  玩法代码中本应属于数据文件的数字字面量；代码根目录中本应属于
  本地化文件的玩家可见字符串（按 `.claude/docs/code-root-resolution.md`
  解析根目录；无法解析时，报告 `NOT ASSESSED —
  code root unresolved`，绝不说零命中）。
- **询问：** 行为（"the player takes damage when…"）、手感和性能
  标准。绝不因阅读代码就将某条标为通过：代码说明应该
  发生什么，而不是构建实际做了什么。每次询问最多四条："Does [criterion]?" 选项：
  Yes — passes / No — fails / Not tested yet。`Not tested yet` 即 UNTESTED，并
  在有人检查之前将结论最多保持在 NOT ASSESSED。
- **在屏幕上看到：** 关于可见内容的标准由 `production/qa/evidence/[story-slug]/` 下的留存
  图像覆盖（`[story-slug]`：故事
  文件名去掉 `.md`），前提是你打开并在其中看到了它。
  绝不要描述你未打开过的图像；检查点的 `Run result:
  OBSERVED — <text>` 是 `/dev-story` 的描述，应按原样引用。
- **需要完整试玩：** `DEFERRED — requires playtest session`。它不
  阻断。

Then map each criterion to what covers it: a test under the test root, a
"Yes — passes", or a retained image.

然后将每条标准映射到覆盖它的东西：测试根目录下的一个测试、
一个 "Yes — passes"，或一张留存图像。

```
| Criterion | Covered by | Status |
|-----------|------------|--------|
| AC-1: [text] | tests/unit/[system]/[file]::[test] | COVERED |
| AC-2: [text] | production/qa/evidence/[slug]/01-[what].png | COVERED |
| AC-3: [text] | — | UNTESTED |
```

Untested criteria escalate by the Phase 1 table: blocking above the line; below it,
advisory, listed in the Completion Notes as "Untested criteria: [AC-N list]".

未测试标准按阶段 1 的表升级：在该线上方则阻断；在其下方
则为建议性，在 Completion Notes 中列为 "Untested criteria: [AC-N list]"。

## Phase 4: Test evidence and the run result

## 阶段 4：测试证据与运行结果

By the story's type, at the Phase 1 gate level. Skip a check `qa.level` waives, and
say so: `Test evidence: waived at qa.level minimal`.

按故事的类型，在阶段 1 的门禁级别下。跳过 `qa.level` 豁免的检查，并
说明：`Test evidence: waived at qa.level minimal`。

- **Logic:** the exact path in the story's Test Evidence section, else anywhere
  under `tests/unit/[system]/`.
- **Integration:** the same under `tests/integration/[system]/`, else a playtest
  record naming this story in `production/qa/playtests/` (`/playtest-report`
  writes them there).
- **UI:** a UI story is satisfied by the retained screenshot of each screen touched,
  under `production/qa/evidence/`. No evidence doc or sign-off needed.
- **Visual/Feel:** the screenshot, and a Visual/Feel story also needs the sign-off:
  `production/qa/evidence/[story-slug]-evidence.md` with every sign-off row
  `[x] Approved` (one person may sign every role).
- **Config/Data:** a `production/qa/smoke-*.md` report; none: "No smoke check
  report found. Run `/smoke-check`."
- **No Type:** advisory: "Story Type not declared. Add `Type:` to the story header."

- **Logic：** 故事 Test Evidence 章节中的确切路径，否则为
  `tests/unit/[system]/` 下的任意位置。
- **Integration：** 同样在 `tests/integration/[system]/` 下，否则为
  `production/qa/playtests/` 中点名本故事的试玩记录（`/playtest-report`
  就写在那里）。
- **UI：** UI 故事由每个涉及界面的留存截图满足，
  位于 `production/qa/evidence/` 下。无需证据文档或签署。
- **Visual/Feel：** 截图，且 Visual/Feel 故事还需要签署：
  `production/qa/evidence/[story-slug]-evidence.md`，其每一签署行
  为 `[x] Approved`（一人可为所有角色签署）。
- **Config/Data：** 一份 `production/qa/smoke-*.md` 报告；没有则："No smoke check
  report found. Run `/smoke-check`."
- **No Type：** 建议性："Story Type not declared. Add `Type:` to the story header."

A missing item is a gap at the gate level: BLOCKING stops COMPLETE, ADVISORY goes
in the notes. Name what is missing and where it goes. An evidence doc with no image
beside it is not evidence: a described check is an assertion.

缺失项是门禁级别的缺口：BLOCKING 阻止 COMPLETE，ADVISORY 进入
注释。指明缺了什么以及它应去哪里。没有图像相伴的证据文档
不是证据：描述出来的检查只是一种断言。

**Is the evidence older than its code?** For a retained image, run
`bash .claude/scripts/review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`.
Each `CHANGED:` or `GONE:` file: "[file] changed after the evidence was captured —
re-capture it." `RECEIPT: NONE`: "no stamp — whether the evidence is older than the
code cannot be told". Report these lines; they never change the verdict.

**证据比它的代码更旧吗？** 对于留存图像，运行
`bash .claude/scripts/review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`。
每个 `CHANGED:` 或 `GONE:` 文件："[file] changed after the evidence was captured —
re-capture it." `RECEIPT: NONE`："no stamp — whether the evidence is older than the
code cannot be told"。报告这些行；它们绝不改变结论。

**Run result, every other type.** Take the `Run result:` line from the `/dev-story`
checkpoint (only when its **Current task** names this story) or the story's Completion Notes.
`OBSERVED` with a path: note it. `N/A — <reason>`: accept only a reason that says
why nothing is observable ("it's a Logic story" is not one). `NOT VERIFIED` on a
story whose criteria name something on screen: a gap at the gate level. No line:
advisory, "confirm the build was launched and looked at". A user's "Yes — passes"
to an on-screen criterion with no retained image is an assertion, not an
observation: a gap at the gate level.

**运行结果，其他所有类型。** 从 `/dev-story` 检查点取 `Run result:` 行
（仅当其 **Current task** 点名本故事时）或故事的 Completion Notes。
`OBSERVED` 附带路径：注明它。`N/A — <reason>`：仅接受说明
为什么无可观察内容的理由（"it's a Logic story" 不算）。对于标准点名了
屏幕上某物的故事，`NOT VERIFIED`：门禁级别的缺口。无该行：
建议性，"confirm the build was launched and looked at"。用户对屏幕上标准的 "Yes — passes"
而没有留存图像，是断言而非
观察：门禁级别的缺口。

## Phase 5: Deviations and scope

## 阶段 5：偏离与范围

Run, by tier (`minimal` skips 1 and 3):

按层级运行（`minimal` 跳过 1 和 3）：

1. **GDD rules** (`full`; `standard` on its required sections): search the changed
   files for the names the current GDD text and TR requirement use.
2. **Manifest:** the story's `Manifest Version` older than the manifest's: ADVISORY,
   "written against manifest v[story]; current is v[current] — run
   `/story-readiness` to check". No manifest: skip. A `Manifest-Note:` line in the
   story is carried into the deviations as written.
3. **ADR constraints** (`full`; `standard` for a critical ADR): search for the
   patterns the ADR's Decision or the manifest forbids.
4. **Hardcoded values** in the changed files.
5. **Scope:** the files the story lists under `## Files` against the code and test
   files changed (`git status --porcelain`). A changed file the list does not name
   is OUT OF SCOPE. A story with no `## Files` section: use the checkpoint's
   **Files in progress** when its Current task names this story; else report
   `Scope: NOT ASSESSED — the story lists no files`. A clean working tree: report
   `Scope: not checked — no uncommitted changes to compare`.

1. **GDD 规则**（`full`；`standard` 在其必需章节上）：在变更文件中搜索
   当前 GDD 文本和 TR 需求所使用的名称。
2. **清单：** 故事的 `Manifest Version` 比清单的更旧：ADVISORY，
   "written against manifest v[story]; current is v[current] — run
   `/story-readiness` to check"。无清单：跳过。故事中的 `Manifest-Note:` 行
   按原样带入偏离列表。
3. **ADR 约束**（`full`；关键 ADR 用 `standard`）：搜索
   ADR 的 Decision 或清单所禁止的模式。
4. 变更文件中的**硬编码值**。
5. **范围：** 故事在 `## Files` 下列出的文件对照已变更的代码和测试
   文件（`git status --porcelain`）。列表中未点名的已变更文件是
   OUT OF SCOPE。没有 `## Files` 章节的故事：当其 Current task 点名本故事时，
   使用检查点的 **Files in progress**；否则报告
   `Scope: NOT ASSESSED — the story lists no files`。干净的工作树：报告
   `Scope: not checked — no uncommitted changes to compare`。

Each deviation is **BLOCKING** (contradicts the GDD or ADR), **ADVISORY** (drifts
but works the same; the user decides) or **OUT OF SCOPE** (for awareness). State
them as facts; the user judges them.

每处偏离是 **BLOCKING**（与 GDD 或 ADR 矛盾）、**ADVISORY**（偏离
但效果相同；由用户决定）或 **OUT OF SCOPE**（供知悉）。将它们
作为事实陈述；由用户判断。

## Phase 6: Review gates

## 阶段 6：评审门禁

Read the `review_gate` line above.

读取上面的 `review_gate` 行。

- **`skill-gates=skip`:** no agent. Note `QL-TEST-COVERAGE skipped — [Solo | Lean]
  mode` and `LP-CODE-REVIEW skipped — [Solo | Lean] mode`. In `lean` mode, ask: "Did
  you run `/code-review` on the implemented files?" Options: Yes — it passed or was
  approved with suggestions / No — skipping review for this story / No — I'll run
  it before the sprint close-out. The answer sets Reviewed by.
- **`skill-gates=run`:** read `references/review-gates.md` and
  `.claude/docs/director-gates.md`, and run both gates now. On a skip, do not load
  it.

- **`skill-gates=skip`：** 无智能体。注明 `QL-TEST-COVERAGE skipped — [Solo | Lean]
  mode` 和 `LP-CODE-REVIEW skipped — [Solo | Lean] mode`。在 `lean` 模式下，询问："Did
  you run `/code-review` on the implemented files?" 选项：Yes — it passed or was
  approved with suggestions / No — skipping review for this story / No — I'll run
  it before the sprint close-out。回答会设置 Reviewed by。
- **`skill-gates=run`：** 读取 `references/review-gates.md` 和
  `.claude/docs/director-gates.md`，并立即运行两个门禁。若为跳过，不要加载
  它。

**Reviewed by** is never blank: `lead-programmer` when LP-CODE-REVIEW ran;
`/code-review (you said you ran it; not verified here)` for the lean Yes; `self, no
independent review` in solo mode, for either No, and when no implementation file
exists yet.

**Reviewed by** 绝不为空：LP-CODE-REVIEW 运行时为 `lead-programmer`；
lean 下回答 Yes 时为 `/code-review (you said you ran it; not verified here)`；
solo 模式下、任一 No 时，以及尚不存在实现文件时，为 `self, no
independent review`。

## Phase 7: Report, verdict, and the close

## 阶段 7：报告、结论与关闭

```markdown
## Story Done: [title]
**Story**: [path] · **Type**: [type] · **Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [criterion] — [how verified]
- [ ] [criterion] — FAILS: [reason]
- [?] [criterion] — DEFERRED: requires playtest

### Traceability
[the Phase 3 table]

### Test Evidence
**Required**: [what the type needs at this qa.level, or "waived at qa.level minimal"]
**Found**: [YES — path | NO — BLOCKING | NO — ADVISORY]

### Deviations
[NONE, or each: BLOCKING / ADVISORY / OUT OF SCOPE — description — reference]

### Review
**Reviewed by**: [value]

### Verdict: [COMPLETE | COMPLETE WITH NOTES | NOT ASSESSED | BLOCKED]
```

**Verdicts, the first that matches wins:**

1. **BLOCKED:** a criterion fails, or a BLOCKING gap or deviation stands.
2. **NOT ASSESSED:** a criterion could not be evaluated: it names no observable
   outcome, the user answered "Not tested yet", a review gate returned NOT ASSESSED
   and its input was not supplied, evidence exists but cannot be read, or the GDD
   or ADR a deviation would be judged against is missing. Name each one and what
   would settle it. It outranks the two passes and never hides a failure.
3. **COMPLETE WITH NOTES:** every criterion passes or is DEFERRED, with advisory
   items listed. Information lines are not advisory items: the evidence-stamp
   lines, an absent sprint file and the run result never turn COMPLETE into COMPLETE
   WITH NOTES.
4. **COMPLETE:** every criterion passes, nothing advisory.

**结论，最先匹配者胜出：**

1. **BLOCKED：** 某条标准失败，或存在 BLOCKING 缺口或偏离。
2. **NOT ASSESSED：** 某条标准无法评估：它未指明可观察的
   结果、用户回答 "Not tested yet"、某评审门禁返回 NOT ASSESSED
   且其输入未提供、证据存在但无法读取，或判断偏离所需的 GDD
   或 ADR 缺失。逐项指明，以及什么能解决它。它排在两种通过之上，绝不掩盖失败。
3. **COMPLETE WITH NOTES：** 每条标准通过或为 DEFERRED，并列出了建议性
   条目。信息行不是建议性条目：证据戳记
   行、缺失的冲刺文件和运行结果绝不会把 COMPLETE 变成 COMPLETE
   WITH NOTES。
4. **COMPLETE：** 每条标准通过，没有建议性条目。

**Then ask, before writing anything:** "How do you want to proceed?" Options:
Close the story — mark it Complete and log notes (Recommended) / Close and log the
advisory deviations as tech debt / Don't close yet — I'll fix things first / Close
anyway, accepting the deviations. On BLOCKED or NOT ASSESSED, recommend "Don't close
yet" and list what must change. Closing such a story is a `scope_changes` decision:
when the `automation_always_ask` line lists it, ask in every automation mode, even
when the user's own request is what got here. Write only on an explicit choice to
close.

**然后，在写入任何内容之前询问：** "How do you want to proceed?" 选项：
Close the story — mark it Complete and log notes (Recommended) / Close and log the
advisory deviations as tech debt / Don't close yet — I'll fix things first / Close
anyway, accepting the deviations。在 BLOCKED 或 NOT ASSESSED 下，推荐 "Don't close
yet" 并列出必须改变什么。关闭这样的故事是 `scope_changes` 决策：
当 `automation_always_ask` 行列有它时，在每种自动化模式下都询问，即使
把流程带到这里的正是用户自己的请求。仅在明确选择关闭时才写入。

**On close:**

**关闭时：**

1. `bash .claude/scripts/md-section.sh set-field <story> Status Complete`, then
   `set-field <story> "Last Updated" <YYYY-MM-DD> --after Status`.
2. Add at the end of the story, with a file edit, never a shell command (a shell
   write skips the project's write checks):
   ```markdown
   ## Completion Notes
   **Completed**: [date]
   **Criteria**: [X/Y passing] ([deferred items])
   **Deviations**: [None, or the advisory ones]
   **Test Evidence**: [path, or "waived at qa.level minimal", or "none required"]
   **Reviewed by**: [value]
   ```
3. "Close and log as tech debt": read `references/tech-debt-row.md` and add one
   row per advisory deviation.
4. `production/sprint-status.yaml`, when it exists: this story's entry gets
   `status: done` and `completed: [date]`, and the top-level `updated` gets today.
   The close answer covers it.
5. Print a suggested commit: `git add [the changed code and test files] [story path]`
   and `git commit -m "feat: [story title] ([TR-ID])"`.

1. `bash .claude/scripts/md-section.sh set-field <story> Status Complete`，然后
   `set-field <story> "Last Updated" <YYYY-MM-DD> --after Status`。
2. 在故事末尾添加，用文件编辑，绝不用 shell 命令（shell
   写入会跳过项目的写入检查）：
   ```markdown
   ## Completion Notes
   **Completed**: [date]
   **Criteria**: [X/Y passing] ([deferred items])
   **Deviations**: [None, or the advisory ones]
   **Test Evidence**: [path, or "waived at qa.level minimal", or "none required"]
   **Reviewed by**: [value]
   ```
3. "Close and log as tech debt"：读取 `references/tech-debt-row.md` 并为每处建议性偏离
   添加一行。
4. `production/sprint-status.yaml`（若存在）：本故事的条目得到
   `status: done` 和 `completed: [date]`，顶层 `updated` 得到今天的日期。
   关闭回答已涵盖它。
5. 打印一个建议的提交：`git add [the changed code and test files] [story path]`
   和 `git commit -m "feat: [story title] ([TR-ID])"`。

**On "Don't close yet":** change no story file. List what the user flagged. Never
fix a failing criterion yourself: report it and ask what to do.

**在 "Don't close yet" 时：** 不更改任何故事文件。列出用户指出的问题。绝不
自行修复失败的验收标准：报告它并询问该怎么做。

## Phase 8: Next story, checkpoint, close

## 阶段 8：下一个故事、检查点、收尾

**The next story.** With no sprint plan in `production/sprints/` (always at
`workflow: minimal`): Run `bash .claude/scripts/story-status.sh` after the close, so
this story's new status is in it. It prints the unfinished stories in route order;
do not re-rank them. The first `In Review` story is next (the first `IN_REVIEW`
line), else the first `In Progress` one, else the first `Ready` or `Not Started`
one (`TODO`):

**下一个故事。** 当 `production/sprints/` 中没有冲刺计划时（在
`workflow: minimal` 下总是如此）：在关闭后运行 `bash .claude/scripts/story-status.sh`，
使本故事的新状态包含其中。它按路由顺序打印未完成的故事；
不要重新排序。下一个是第一个 `In Review` 故事（第一条 `IN_REVIEW`
行），否则是第一个 `In Progress` 的，否则是第一个 `Ready` 或 `Not Started`
的（`TODO`）：

```
### Next Up
**[Story NNN: title]** — [one line]
Run `/story-done [path]` to close it (In Review) — else `/dev-story [path]` to implement it.
```

When the `workflow` line above reads `minimal`, print no `/story-readiness` line at
all, not even as an option: it is not on that path. With no sprint plan at
`workflow: standard` or `full`, add "Run `/story-readiness [path]` first."

当上面的 `workflow` 行读作 `minimal` 时，完全不打印 `/story-readiness` 行，
甚至不作为选项：它不在该路径上。在 `workflow: standard` 或 `full` 下
没有冲刺计划时，添加 "Run `/story-readiness [path]` first."

- Only `COMPLETE N of N`: every story is built. Offer: play the build and note what
  feels wrong; add stories from the brief with `/create-stories`; or `/settings` to
  raise `modes.rigor` if the game has outgrown its brief.
- Only `BLOCKED`, `OTHER` or `NO_STATUS` lines left: there is no Next Up, and the
  build order is **not** done. Name each story with its blocker, `Draft` or `no
  status`.
- Never print the Sprint Close-Out Sequence on this branch: there is no sprint.

- 仅有 `COMPLETE N of N`：每个故事都已构建。提议：试玩构建并记下感觉不对的地方；
  用 `/create-stories` 从简报添加故事；或用 `/settings`
  在游戏已超出其简报时提高 `modes.rigor`。
- 仅剩 `BLOCKED`、`OTHER` 或 `NO_STATUS` 行：没有 Next Up，且
  构建顺序**没有**完成。逐个指明故事及其阻断项、`Draft` 或 `no
  status`。
- 在此分支上绝不打印 Sprint Close-Out Sequence：这里没有冲刺。

With a sprint plan: read `references/sprint-next.md`.

有冲刺计划时：读取 `references/sprint-next.md`。

**The checkpoint**, on every verdict, closed or not. Pipe the block to
`bash .claude/scripts/session-state.sh checkpoint`, which replaces the old block:

**检查点**，无论结论如何、无论是否关闭。将该块通过管道传给
`bash .claude/scripts/session-state.sh checkpoint`，它会替换旧块：

```
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /story-done — [story path]: [verdict], [closed | left open]
**Next step:** [the Next Up command, or the fix the verdict named]
**Blocked on:** [nothing, or what blocked the verdict]
**Files in progress:** none
**Open questions:** [tech debt logged: N items, or none]
```

**The run's last reply ends with this block** (repeat it if you showed it earlier):

**本次运行的最后一条回复以此块结尾**（若你之前已展示过，请重复它）：

```
Verdict: [COMPLETE | COMPLETE WITH NOTES | NOT ASSESSED | BLOCKED] — [story path]
Story: [closed — Status: Complete | left open — Status: [status]]
Review: [Reviewed by value; the gates' skip notes]
Next step: [/dev-story [path] | /story-done [path] | the fix | play the build]
```
