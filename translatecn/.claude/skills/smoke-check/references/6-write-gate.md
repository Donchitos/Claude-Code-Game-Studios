# /smoke-check — Phase 6: Write and Gate

# /smoke-check — 第 6 阶段：写入与闸门

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/smoke-check` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 6: Write and Gate

## 第 6 阶段：写入与闸门

**In this file:**

**本文件内容：**

- `qa.level` first
- Resolve the gate enforcement level
- Per verdict: FAIL (blocking or advisory), NOT ASSESSED, PASS WITH WARNINGS, PASS

- 优先处理 `qa.level`
- 解析闸门的执行级别
- 按结论分别处理：FAIL（阻塞或提示性）、NOT ASSESSED、PASS WITH WARNINGS、PASS

Present the full report in conversation, then ask:

在对话中呈现完整报告，然后询问：

"May I write this smoke check report to `production/qa/smoke-[date].md`?"

"May I write this smoke check report to `production/qa/smoke-[date].md`?"

Write only after approval.

仅在获得批准后写入。

**First apply `qa.level` (resolved earlier).** At `qa.level: minimal`, a FAIL is
**advisory** regardless of `testing.strict.config` — skip the resolution below and
deliver the advisory-FAIL outcome (smoke-check is optional at minimal and never
blocks hand-off). Otherwise:

**首先应用 `qa.level`（此前已解析）。** 在 `qa.level: minimal` 下，FAIL
无论 `testing.strict.config` 如何都是**提示性的** —— 跳过下方的解析，
直接给出提示性 FAIL 的结果（在 minimal 下冒烟检查是可选的，且从不
阻塞交接）。否则：

**Resolve the gate enforcement level.** A FAIL verdict either *blocks* QA
hand-off or is *flagged while hand-off proceeds*, governed by the
`testing.strict` block **resolved in the resolved-config block at the top of this skill** (which merges
`project.local.yaml` over `project.yaml` — read that block, not the file, or a
developer's local override is silently ignored):

**解析闸门的执行级别。** FAIL 结论要么*阻塞* QA
交接，要么在交接继续时*被标记*，这由
**本技能顶部的已解析配置块中解析出的** `testing.strict` 块控制（它将
`project.local.yaml` 合并到 `project.yaml` 之上 —— 要读那个块，而不是读文件，
否则开发者的本地覆盖会被静默忽略）：

1. Take `testing.strict.config` from that resolved block. If its value is `true`
   (case-insensitive) → blocking; if `false` → advisory; `unset` → fall through.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — if
   its value is `true` or `false`, it applies.
3. Else default to **blocking** — an unset `testing.strict.config` keeps
   smoke-check's FAIL gate blocking. Smoke check is a build-health gate, so its
   unset default is strict
   even though the `config` test type defaults to advisory elsewhere. The
   reciprocal carve-out is recorded in `.claude/skills/story-done/SKILL.md` and
   `.claude/docs/coding-standards.md`, which own the per-story evidence table.

1. 从该已解析块中取出 `testing.strict.config`。如果其值为 `true`
   （不区分大小写）→ 阻塞；如果为 `false` → 提示性；`unset` → 继续下一步。
2. 否则将 `testing.strict` 作为普通布尔值读取（旧式单值形式）—— 如果
   其值为 `true` 或 `false`，则生效。
3. 否则默认为**阻塞** —— 未设置的 `testing.strict.config` 会保持
   smoke-check 的 FAIL 闸门为阻塞。冒烟检查是一个构建健康闸门，因此其
   未设置的默认值是严格的，
   即便 `config` 测试类型在其他地方默认是提示性的。
   对应的例外记录在 `.claude/skills/story-done/SKILL.md` 和
   `.claude/docs/coding-standards.md` 中，它们负责按故事的证据表。

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user.

第 1–2 步只识别 `true` 和 `false`（不区分大小写）。若某个键存在但持有
任何其他值 —— `maybe`、`1`、`yes` 等 —— 则视为未设置：继续下一步，
并将无法识别的值告知用户。

After writing, deliver the gate verdict:

写入之后，给出闸门结论：

**If verdict is FAIL and the gate is blocking:**

**如果结论为 FAIL 且闸门为阻塞：**

"The smoke check failed. Do not hand off to QA until these failures are
resolved:

[List each failing automated test or smoke check with a one-line description]

Fix the failures and run `/smoke-check` again to re-gate before QA hand-off."

"The smoke check failed. Do not hand off to QA until these failures are
resolved:

[List each failing automated test or smoke check with a one-line description]

Fix the failures and run `/smoke-check` again to re-gate before QA hand-off."

**If verdict is FAIL and the gate is advisory** (`testing.strict.config: false`):

**如果结论为 FAIL 且闸门为提示性**（`testing.strict.config: false`）：

"The smoke check failed, but `testing.strict.config` is set to advisory — QA
hand-off is not blocked. Resolve these before release:

[List each failing automated test or smoke check with a one-line description]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification. Re-run `/smoke-check` once the failures
are fixed."

"The smoke check failed, but `testing.strict.config` is set to advisory — QA
hand-off is not blocked. Resolve these before release:

[List each failing automated test or smoke check with a one-line description]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification. Re-run `/smoke-check` once the failures
are fixed."

**If verdict is NOT ASSESSED:**

**如果结论为 NOT ASSESSED：**

"The smoke check could not establish build health — it did not fail, it did not
run. Do not hand off to QA on this result:

[Name each check that could not execute, and why: suite unconfirmed NOT RUN,
`PlayMode: NOT RUN`, zero tests executed, runner not installed, engine
executable not found, no build, build not launched this session, platform
unavailable]

[For each, the one thing that would make it runnable — e.g. 'confirm the suite
result from your IDE or CI', 'run `/setup-engine`', 'set `engine.path`',
'produce a build', 'launch the build and play the checks'.]

Re-run `/smoke-check` once any of those is resolved."

"The smoke check could not establish build health — it did not fail, it did not
run. Do not hand off to QA on this result:

[Name each check that could not execute, and why: suite unconfirmed NOT RUN,
`PlayMode: NOT RUN`, zero tests executed, runner not installed, engine
executable not found, no build, build not launched this session, platform
unavailable]

[For each, the one thing that would make it runnable — e.g. 'confirm the suite
result from your IDE or CI', 'run `/setup-engine`', 'set `engine.path`',
'produce a build', 'launch the build and play the checks'.]

Re-run `/smoke-check` once any of those is resolved."

This outcome is **not governed by `testing.strict.config`**. That setting decides
whether a *failure* blocks hand-off; it has nothing to say about a check that
never produced a result, and reading an unrun check as advisory-therefore-fine is
the exact substitution this verdict exists to prevent. Say what could not be
checked and let the user decide — do not resolve it to either pass or FAIL on
their behalf.

该结果**不受 `testing.strict.config` 控制**。该设置决定
*失败*是否阻塞交接；它与一个从未产生结果的检查毫无关系，
而把未运行的检查读成“提示性因此没问题”正是这一结论存在所要防止的
替代做法。说明哪些内容无法检查，并让用户来决定 —— 不要代表
用户把它解析为通过或 FAIL。

**If verdict is PASS WITH WARNINGS:**

**如果结论为 PASS WITH WARNINGS：**

"Smoke check passed with warnings. The build is ready for manual QA.

Advisory items to resolve before running `/story-done` on affected stories:
[list MISSING test evidence entries, and any runner warning — e.g. the orphan
count]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

"Smoke check passed with warnings. The build is ready for manual QA.

Advisory items to resolve before running `/story-done` on affected stories:
[list MISSING test evidence entries, and any runner warning — e.g. the orphan
count]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

**If verdict is PASS:**

**如果结论为 PASS：**

"Smoke check passed cleanly. The build is ready for manual QA.

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

"Smoke check passed cleanly. The build is ready for manual QA.

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

---
