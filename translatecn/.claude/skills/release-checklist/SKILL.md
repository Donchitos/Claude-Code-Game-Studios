---
name: release-checklist
description: "Pre-release checklist — build verification, certification requirements, store metadata, launch readiness."
argument-hint: "[platform: pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/release-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: release-checklist
description: "发布前检查清单 — 构建验证、认证要求、商店元数据、发布就绪度。"
argument-hint: "[platform: pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/release-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,workflow,project.stage,cert_tier,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（collaborative 始终询问 · guided 仅主要项 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用。无配置块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Release Checklist
# 发布检查清单

**Scope this checklist to the project.** Emitting every item for every platform
trains the reader to skip the list, which defeats the gate:
**让本检查清单适用于本项目的范围。** 为每个平台输出所有条目会
训练读者跳过清单，从而使门禁失效：

- **`project.stage`** — items for phases this project has not reached are out of
  scope; say so rather than listing them unchecked.
- **`modes.rigor`** — at `minimal`, drop items whose only justification is process
  weight this project has opted out of.
- **`platform.cert_tier`** — emit certification items **only** for the tier the
  project targets. If it is **unset**, **ask which platforms are in scope**
  rather than emitting all of them — an unset value is a question, not a licence
  to emit every certification track. If it cannot be determined, mark the section
  **`NOT ASSESSED — cert tier unknown`**. **Unset is not `none`:** `none` is a
  decision, unset is a missing one, and they must not produce the same output.
  Branch on the **four values this key takes** — `none | itch | steam | console` —
  and not on platform names. The full requirement table is the `## platform.cert_tier`
  section of `.claude/docs/effects-map.md` — read **only that section** (Grep its
  heading, then a bounded Read); the file as a whole is not a runtime input.
  - `none` — **emit no certification section at all.** Internal release, alpha or
    jam game. Say the section was omitted and why; do not leave it blank.
  - `itch` — itch.io upload requirements only: build size, page setup, age tags.
    **No console and no Steamworks items.**
  - `steam` — Steamworks: store page, depot build, achievements, system
    requirements, common content rules. **No console certification items.**
  - `console` — full platform certification (TRC / XR / Lotcheck), save-data
    rules, controller-mapping rules, age-rating boards. The heaviest tier.
- **`project.stage`** — 本项目尚未到达的阶段所对应的条目不在
  范围内；应说明这一点，而不是把它们未勾选地列出。
- **`modes.rigor`** — 在 `minimal` 下，删除那些唯一理由是本项目已选择放弃的
  流程负担的条目。
- **`platform.cert_tier`** — **仅**针对项目目标层级输出认证条目。如果该值**未设置**，
  应**询问哪些平台在范围内**，而不是输出全部条目 — 未设置的值是一个问题，而不是
  输出所有认证轨道的许可。如果无法确定，将该节标记为
  **`NOT ASSESSED — cert tier unknown`**。**未设置不等于 `none`：** `none` 是一个
  决策，而未设置是缺失的决策，二者不得产生相同的输出。
  应按**该键取值的四个值**分支 — `none | itch | steam | console` —
  而不是按平台名称。完整的要求表是 `.claude/docs/effects-map.md` 的 `## platform.cert_tier`
  节 — **只读取该节**（Grep 其标题，然后进行有界读取）；整个文件不是运行时输入。
  - `none` — **完全不输出认证节。** 内部发布、alpha 或
    jam 游戏。说明该节已被省略及原因；不要让它留空。
  - `itch` — 仅 itch.io 上传要求：构建体积、页面设置、年龄标签。
    **无主机和无 Steamworks 条目。**
  - `steam` — Steamworks：商店页面、仓库构建、成就、系统
    要求、通用内容规则。**无主机认证条目。**
  - `console` — 完整平台认证（TRC / XR / Lotcheck）、存档数据
    规则、手柄映射规则、年龄分级机构。最重的层级。

  > **Branch on the `cert_tier` values above, not on platform names.** A test on
  > target platforms treats an `itch` project and a `steam` project identically,
  > conflates `none` with unset, and keys on `mobile`, which is not a `cert_tier`
  > value at all. Use the vocabulary the config defines.
  > **按上文的 `cert_tier` 值分支，而不是按平台名称。** 基于
  > 目标平台的测试会把 `itch` 项目和 `steam` 项目同等对待，
  > 把 `none` 与未设置混为一谈，并以 `mobile` 为键，而 `mobile` 根本不是 `cert_tier`
  > 值。请使用配置定义的词汇。

If an item cannot be scoped because the config is absent, mark it
**`NOT ASSESSED — platform/stage unknown`**. Do not silently include it: a
`rigor: standard`, single-platform project would otherwise receive a ~150-item
checklist demanding PC **and** console **and** mobile certification plus age
ratings, of which ~140 are unassessable.
如果某条目因配置缺失而无法确定范围，将其标记为
**`NOT ASSESSED — platform/stage unknown`**。不要静默包含它：否则一个
`rigor: standard` 的单平台项目会收到约 150 条清单，要求 PC **以及** 主机
**以及** 移动端认证外加年龄分级，其中约 140 条无法评估。

---


## Phase 1: Parse Arguments
## 阶段 1：解析参数

Read the argument for the target platform (`pc`, `console`, `mobile`, or `all`). If no platform is specified, default to `all`.
读取目标平台参数（`pc`、`console`、`mobile` 或 `all`）。如果未指定平台，默认为 `all`。

**The argument selects DEVICE requirements. It never selects the certification
track.** Certification is decided by `platform.cert_tier`, resolved in the resolved-config block at the top of this skill —
see the `platform.cert_tier` rule above. The two axes are different lists that
happen to share one word: `pc`/`console`/`mobile` are hardware shapes, while
`none|itch|steam|console` are certification regimes. They agree on `console` and
nowhere else — `itch` and `none` have no device block at all, and `mobile` is not
a `cert_tier` value. So emitting a device block says nothing about which
certification block to emit, and `all` is **not** a licence to emit every
certification track.
**该参数选择的是设备要求。它从不选择认证
轨道。** 认证由 `platform.cert_tier` 决定，在本技能顶部的已解析配置块中解析 —
参见上文的 `platform.cert_tier` 规则。这两个轴是不同的清单，只是
恰好共享一个词：`pc`/`console`/`mobile` 是硬件形态，而
`none|itch|steam|console` 是认证体制。它们仅在 `console` 上一致，
其他任何地方都不一致 — `itch` 和 `none` 根本没有设备块，而 `mobile` 不是
`cert_tier` 值。因此输出设备块并不能说明应输出哪个
认证块，而 `all` **不是**输出所有
认证轨道的许可。

---

## Phase 2: Load Project Context
## 阶段 2：加载项目上下文

- Read `CLAUDE.md` for project context, version information, and platform targets.
- Read the current milestone from `production/milestones/` to understand what features and content should be included in this release.
- Read the open bugs from `production/qa/bugs/`: grep the `**Severity**` and `**Status**` lines of `production/qa/bugs/*.md`, as `/bug-triage` does. A bug is open unless its Status is `Closed` or `Verified Fixed`. The bug items use the thresholds `/gate-check release` applies for the resolved `workflow`: at `full` an open S1, S2 or S3 bug fails its item; at `standard` and `minimal` only an open S1 does, and an open S2 or S3 is listed in the Rationale as a risk. Each failing bug is named in the Rationale as a blocking item. **No bug files in `production/qa/bugs/`** → the bug items read `NOT ASSESSED — no bug records` — never zero and never ticked, since an absent record and a clean one must not produce the same checklist; bugs are filed with `/bug-report`.
- 读取 `CLAUDE.md`，以了解项目上下文、版本信息和平台目标。
- 从 `production/milestones/` 读取当前里程碑，以了解本次发布应包含哪些特性和内容。
- 从 `production/qa/bugs/` 读取未解决的缺陷：像 `/bug-triage` 那样，grep `production/qa/bugs/*.md` 中的 `**Severity**` 和 `**Status**` 行。除非其 Status 为 `Closed` 或 `Verified Fixed`，否则缺陷即为未解决。缺陷条目使用 `/gate-check release` 针对已解析 `workflow` 应用的阈值：在 `full` 下，未解决的 S1、S2 或 S3 缺陷会使其条目失败；在 `standard` 和 `minimal` 下，只有未解决的 S1 会使其失败，而未解决的 S2 或 S3 会在 Rationale 中列为风险。每个失败的缺陷都会在 Rationale 中命名为阻塞项。**`production/qa/bugs/` 中没有缺陷文件** → 缺陷条目读作 `NOT ASSESSED — no bug records` — 绝不为零，也绝不勾选，因为缺失记录与干净记录不得产生相同的清单；缺陷通过 `/bug-report` 提交。

---

## Phase 3: Scan Codebase
## 阶段 3：扫描代码库

> **State the denominator with every count.** These scans look for something bad,
> so `0` means either "searched and found none" or "there was nothing to search",
> and on a release gate those are opposite findings. Report
> `scanned [N] source files: [M] TODO, [M] FIXME, [M] HACK` — or, when the code
> root (`src/`, `Assets/` or `Source/`; resolve per
> `.claude/docs/code-root-resolution.md`) is unresolved,
> **`NOT ASSESSED — code root unresolved`**, and when it is absent or holds no
> source files, **`NOT ASSESSED — no source files found to scan`**. A bare `0` is
> not a result.
> **每次计数都要说明分母。** 这些扫描是在寻找不好的东西，
> 因此 `0` 要么意味着 "已搜索且未找到"，要么意味着 "根本无可搜索"，
> 而在发布门禁上，这两者是相反的发现。报告
> `scanned [N] source files: [M] TODO, [M] FIXME, [M] HACK` — 或者，当代码
> 根目录（`src/`、`Assets/` 或 `Source/`；按
> `.claude/docs/code-root-resolution.md` 解析）未解析时，报告
> **`NOT ASSESSED — code root unresolved`**；当它不存在或不含
> 源文件时，报告 **`NOT ASSESSED — no source files found to scan`**。裸的 `0`
> 不是结果。

Scan for outstanding issues:
扫描未解决的问题：

- Count `TODO` comments
- Count `FIXME` comments
- Count `HACK` comments
- Note their locations and severity
- 统计 `TODO` 注释
- 统计 `FIXME` 注释
- 统计 `HACK` 注释
- 记录它们的位置和严重程度

Check for test results in any test output directories or CI logs if available.
**If none are found, say so** — `Test results: NOT ASSESSED — no test output or
CI logs found` — rather than omitting the line. An absent test result and a
passing one must not produce the same release checklist.
如有可用，检查任何测试输出目录或 CI 日志中的测试结果。
**如果找不到，就说明** — `Test results: NOT ASSESSED — no test output or
CI logs found` — 而不是省略该行。缺失的测试结果与通过的测试结果
不得产生相同的发布检查清单。

---

## Phase 4: Generate the Release Checklist
## 阶段 4：生成发布检查清单

```markdown
## Release Checklist: [Version] -- [Platform]
Generated: [Date]

### Codebase Health
- Scanned: [N] source files (or `NOT ASSESSED — [reason]`, per Phase 3)
- TODO count: [N] ([list top 5 if many])
- FIXME count: [N] ([list all -- these are potential blockers])
- HACK count: [N] ([list all -- these need review])

### Build Verification
- [ ] Clean build succeeds on all target platforms
- [ ] No compiler warnings (zero-warning policy)
- [ ] All assets included and loading correctly
- [ ] Build size within budget ([target size])
- [ ] Build version number correctly set ([version])
- [ ] Build is reproducible from tagged commit

### Quality Gates
- Open bugs (`production/qa/bugs/`): [N] S1, [N] S2, [N] S3 -- or `NOT ASSESSED — no bug records`
- [ ] Zero open S1 (Critical) bugs
- [ ] Zero open S2 (High) and S3 (Medium) bugs, no exceptions -- this row at `workflow: full` only; at `standard`/`minimal` open S2/S3 bugs go in the Rationale as risks
- [ ] All critical path features tested and signed off by QA
- [ ] Performance within budgets:
  - [ ] Target FPS met on minimum spec hardware
  - [ ] Memory usage within budget
  - [ ] Load times within budget
  - [ ] No memory leaks over extended play sessions
- [ ] No regression from previous build
- [ ] Soak test passed (4+ hours continuous play)

### Content Complete
- [ ] All placeholder assets replaced with final versions
- [ ] All TODO/FIXME in content files resolved or documented
- [ ] All player-facing text proofread
- [ ] All text localization-ready (no hardcoded strings)
- [ ] Audio mix finalized and approved
- [ ] Credits complete and accurate
```

Add **device** sections based on the argument. These carry no certification or
storefront-SDK items — those are gated on `platform.cert_tier` in the next
subsection, and repeating them here would hand an `itch` project Steamworks rows.
根据参数添加**设备**节。这些节不包含认证或
商店 SDK 条目 — 那些条目在下一小节中由 `platform.cert_tier` 门控，
在此重复它们会让 `itch` 项目获得 Steamworks 行。

**For `pc`:**
**对于 `pc`：**
```markdown
### Platform Requirements: PC
- [ ] Minimum and recommended specs verified and documented
- [ ] Keyboard+mouse controls fully functional
- [ ] Controller support tested (Xbox, PlayStation, generic)
- [ ] Resolution scaling tested (1080p, 1440p, 4K, ultrawide)
- [ ] Windowed, borderless, and fullscreen modes working
- [ ] Graphics settings save and load correctly
```

**For `console`:**
**对于 `console`：**
```markdown
### Platform Requirements: Console
- [ ] Platform-specific controller prompts display correctly
- [ ] Suspend/resume works correctly
- [ ] User switching handled properly
- [ ] Network connectivity loss handled gracefully
- [ ] Storage full scenario handled
```

**For `mobile`:**
**对于 `mobile`：**
```markdown
### Platform Requirements: Mobile
- [ ] App store guidelines compliance verified
- [ ] All required device permissions justified and documented
- [ ] Privacy policy linked and accurate
- [ ] Data safety/nutrition labels completed
- [ ] Touch controls tested on multiple screen sizes
- [ ] Battery usage within acceptable range
- [ ] Background behavior correct (pause, resume, terminate)
- [ ] Push notification permissions handled correctly
- [ ] In-app purchase flow tested (if applicable)
- [ ] App size within store limits
```

> **Mobile storefront rows stay here on purpose.** `platform.cert_tier` models
> `none|itch|steam|console` and has no mobile regime, so App Store / Play Store
> compliance cannot be gated on it. Leaving these in the device block is a
> deliberate choice, not an oversight — do not "fix" it by inventing a `mobile`
> tier, which is the exact wrong vocabulary the `cert_tier` rule warns against.
> **移动端商店行有意保留在此处。** `platform.cert_tier` 建模的是
> `none|itch|steam|console`，没有移动端体制，因此 App Store / Play Store
> 合规无法以它为门控。将这些保留在设备块中是有意的
> 选择，而非疏忽 — 不要通过发明一个 `mobile`
> 层级来"修复"它，那正是 `cert_tier` 规则所警告的错误词汇。

**Certification — emit ONLY the block matching `platform.cert_tier`** (resolved in
the resolved-config block at the top of this skill). Do not emit this subsection's other blocks, and do not fall back to
emitting all of them because the platform argument was `all`.
**认证 — 仅输出与 `platform.cert_tier` 匹配的块**（在本技能顶部的
已解析配置块中解析）。不要输出本小节的其他块，也不要因为平台参数是 `all`
就退而输出全部块。

**At `none`** — emit no certification block at all. Emit exactly this one line in
its place, so the omission is visible rather than looking like a missing section:
**在 `none` 下** — 完全不输出认证块。在相应位置只输出这一行，
使省略可见，而不是看起来像缺失的节：
```markdown
Certification: omitted — cert_tier is 'none' (internal build, alpha or jam release).
```

**At `itch`:**
**在 `itch` 下：**
```markdown
### Certification: itch.io
- [ ] Build size within itch.io upload limits
- [ ] itch.io page complete (cover art, screenshots, description)
- [ ] Age/content tags set honestly
- [ ] Downloadable vs browser build decided and tested
- [ ] Butler channel names correct for each platform uploaded
```

**At `steam`:**
**在 `steam` 下：**
```markdown
### Certification: Steamworks
- [ ] Steamworks SDK integrated and tested
- [ ] Depot build uploaded and installs cleanly from a fresh account
- [ ] Achievements functional
- [ ] Cloud saves functional
- [ ] Steam Deck compatibility verified (if targeting)
- [ ] Steam common content rules reviewed
```

**At `console`:**
**在 `console` 下：**
```markdown
### Certification: Console
- [ ] TRC/TCR/Lotcheck requirements checklist complete
- [ ] First-party certification submission prepared
- [ ] Platform-specific achievement/trophy integration tested
- [ ] Parental controls respected
- [ ] Save-data rules compliant (corruption, full storage, user switching)
- [ ] Age ratings obtained (ESRB, PEGI, regional)
```

If `cert_tier` is **unset**, ask which platforms are in scope rather than
emitting every track; if it cannot be determined, emit
`### Certification: NOT ASSESSED — cert tier unknown` and say why. **Unset is not
`none`** — `none` is a decision and unset is a missing one.
如果 `cert_tier` **未设置**，询问哪些平台在范围内，而不是
输出所有轨道；如果无法确定，输出
`### Certification: NOT ASSESSED — cert tier unknown` 并说明原因。**未设置不等于
`none`** — `none` 是一个决策，而未设置是缺失的决策。

> **Certification rows belong here, in one `cert_tier`-gated subsection.** Do not
> put them in the PC, Console and Mobile device blocks: those are selected by the
> command argument and default to `all`, so an `itch` project running
> `/release-checklist` with no argument would be handed the Steamworks SDK rows
> *and* the Lotcheck rows, which the `cert_tier` rule at the top of this skill
> forbids.
>
> **`console` means two different things in this file.** It is a device-block
> argument value *and* a `cert_tier` value, colliding on one word out of four. A
> `**For \`console\`:**` heading is argument-gating, not tier-gating — do not read
> it as evidence that certification is already scoped by tier.
> **认证行属于此处，即一个由 `cert_tier` 门控的小节。** 不要
> 把它们放进 PC、Console 和 Mobile 设备块：那些块由
> 命令参数选择并默认为 `all`，因此一个 `itch` 项目在无参数情况下运行
> `/release-checklist` 时，会被同时给予 Steamworks SDK 行
> *和* Lotcheck 行，而本技能顶部的 `cert_tier` 规则
> 禁止这样做。
>
> **在本文件中 `console` 意味着两件不同的事。** 它既是设备块
> 参数值 *也是* `cert_tier` 值，在四个值中有一个词发生冲突。
> `**For \`console\`:**` 标题是参数门控，而非层级门控 — 不要把它
> 当作认证已按层级限定范围的证据。

**Store and launch sections (all platforms):**
**商店与发布节（所有平台）：**
```markdown
### Store / Distribution
- [ ] Store page metadata complete and proofread
  - [ ] Short description
  - [ ] Long description
  - [ ] Feature list
  - [ ] System requirements (PC)
- [ ] Screenshots up to date and per-platform resolution requirements met
- [ ] Trailers up to date
- [ ] Key art and capsule images current
- [ ] Age rating obtained and configured:
  - [ ] ESRB
  - [ ] PEGI
  - [ ] Other regional ratings as required
- [ ] Legal notices, EULA, and privacy policy in place
- [ ] Third-party license attributions complete
- [ ] Pricing configured for all regions

### Launch Readiness
- [ ] Analytics / telemetry verified and receiving data
- [ ] Crash reporting configured and dashboard accessible
- [ ] Day-one patch prepared and tested (if needed)
- [ ] On-call team schedule set for first 72 hours
- [ ] Community launch announcements drafted
- [ ] Press/influencer keys prepared for distribution
- [ ] Support team briefed on known issues and FAQ
- [ ] Rollback plan documented (if critical issues found post-launch)

### Go / No-Go: [READY / NOT ASSESSED / NOT READY]

First match wins: **NOT READY** if any blocking item fails; else **NOT ASSESSED**
if any section or item came out `NOT ASSESSED` (name each one); else **READY**. NOT
ASSESSED outranks READY — an unassessed section is not a passed one — and ranks
below NOT READY, so a known blocker is never buried behind it.

**Rationale:**
[Summary of readiness assessment. List any blocking items that must be
resolved before launch. If NOT READY, list the specific items that need
resolution and estimated time to address them.]

**Sign-offs Required:**
- [ ] QA Lead
- [ ] Technical Director
- [ ] Producer
- [ ] Creative Director
```

---

## Phase 5: Save Checklist
## 阶段 5：保存检查清单

Present the checklist to the user with: total checklist items, number of known blockers (FIXME/HACK counts, known bugs).
向用户呈现检查清单，并附上：检查清单条目总数、已知阻塞项数量（FIXME/HACK 计数、已知缺陷）。

Ask: "May I write this to `production/releases/release-checklist-[version].md`?"
询问："我可以把它写入 `production/releases/release-checklist-[version].md` 吗？"

If yes, write the file, creating the directory if needed.
如果是，写入文件，必要时创建目录。

---

## Phase 6: Next Steps
## 阶段 6：后续步骤

- Draft the changelog or patch notes (`/changelog`, `/patch-notes`) if not done — the release gate checks them.
- Run `/gate-check release` — the Polish → Release gate reads this checklist.
- After a PASS: `/launch-checklist`, then coordinate the release via `/team-release`.
- 如尚未完成，起草变更日志或补丁说明（`/changelog`、`/patch-notes`）— 发布门禁会检查它们。
- 运行 `/gate-check release` — Polish → Release 门禁会读取本检查清单。
- 在 PASS 之后：`/launch-checklist`，然后通过 `/team-release` 协调发布。
