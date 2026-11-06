---
name: launch-checklist
description: "Launch readiness across every department: code, content, store, marketing, community, infrastructure, legal, go/no-go sign-offs."
argument-hint: "[launch-date or 'dry-run']"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/launch-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: launch-checklist
description: "跨各部门的发布就绪检查：代码、内容、商店、营销、社区、基础设施、法务，以及 go/no-go 签署。"
argument-hint: "[launch-date or 'dry-run']"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/launch-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,workflow,project.stage,cert_tier,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重要事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终询问）。

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用。无配置块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Launch Checklist

# 发布清单

**Scope this checklist to the project.** Emitting every item for every platform
trains the reader to skip the list, which defeats the gate:

**将本清单限定到项目范围。** 为每个平台输出每一项会让读者养成跳过清单的习惯，从而使门禁失效：

- **`project.stage`** — items for phases this project has not reached are out of
  scope; say so rather than listing them unchecked.
- **`modes.rigor`** — at `minimal`, drop items whose only justification is process
  weight this project has opted out of.
- **`platform.cert_tier`** — emit certification items **only** for the tier the
  project targets. If it is **unset**, **ask which platforms are in scope**
  rather than emitting all of them — an unset value is a question, not a licence
  to emit every certification track. The answer, mapped onto the four values
  below, is the tier for this run. If it cannot be determined, mark the section
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

- **`project.stage`** — 本项目尚未到达的阶段所对应的条目不在范围内；请说明，而不是把它们列为未勾选。
- **`modes.rigor`** — 在 `minimal` 下，舍弃那些唯一依据是本项目已选择不采用的流程负担的条目。
- **`platform.cert_tier`** — **只**为项目目标的层级输出认证条目。若该项**未设置**，**询问哪些平台在范围内**，
  而不是把它们全部输出 — 未设置的值是一个问题，而不是输出所有认证轨道的许可。答案映射到下面四个取值，
  即为本次运行的层级。若无法确定，将该小节标记为 **`NOT ASSESSED — cert tier unknown`**。
  **未设置不等于 `none`：** `none` 是一个决策，未设置是缺失的决策，二者绝不能产生相同输出。
  依据**该键的四个取值**分支 — `none | itch | steam | console` — 而不是依据平台名称。完整需求表是
  `.claude/docs/effects-map.md` 的 `## platform.cert_tier` 小节 — **只读该小节**（Grep 其标题，
  然后做有界 Read）；整份文件不是运行时输入。
  - `none` — **完全不输出认证小节。** 内部发布、alpha 或 jam 游戏。说明该小节已省略及原因；不要留空。
  - `itch` — 仅 itch.io 上传要求：构建体积、页面设置、年龄标签。**无主机与无 Steamworks 条目。**
  - `steam` — Steamworks：商店页面、depot 构建、成就、系统需求、通用内容规则。**无主机认证条目。**
  - `console` — 完整平台认证（TRC / XR / Lotcheck）、存档数据规则、手柄映射规则、年龄评级机构。
    最重的层级。

  > **Branch on the `cert_tier` values above, not on platform names.** A test on
  > target platforms treats an `itch` project and a `steam` project identically,
  > conflates `none` with unset, and keys on `mobile`, which is not a `cert_tier`
  > value at all. Use the vocabulary the config defines.

  > **依据上面的 `cert_tier` 取值分支，而非平台名称。** 以目标平台为条件的测试会把 `itch`
  > 项目与 `steam` 项目同等对待，把 `none` 与未设置混为一谈，并以 `mobile` 为键，而它根本
  > 不是 `cert_tier` 取值。请使用配置定义的词汇。

If an item cannot be scoped because the config is absent, mark it
**`NOT ASSESSED — platform/stage unknown`**. Do not silently include it: a
`rigor: standard`, single-platform project would otherwise receive a ~150-item
checklist demanding PC **and** console **and** mobile certification plus age
ratings, of which ~140 are unassessable.

若某条目因配置缺失而无法界定范围，将其标记为
**`NOT ASSESSED — platform/stage unknown`**。不要悄悄将其纳入：否则一个
`rigor: standard`、单一平台的项目会收到约 150 项的清单，要求 PC **和**主机**和**移动端认证外加年龄
评级，其中约 140 项无法评估。

---

## Phase 1: Parse Arguments

## 阶段 1：解析参数

Read the argument for the launch date or `dry-run` mode. Dry-run mode generates the checklist without creating sign-off entries or writing files. With no argument the run is a normal one with the target date unset (`Target Launch: not set`) — dry-run only when the argument says `dry-run`.

从参数读取发布日期或 `dry-run` 模式。Dry-run 模式生成清单，但不创建签署条目、不写文件。无参数时为正常运行，
目标日期未设置（`Target Launch: not set`）— 仅当参数写明 `dry-run` 时才为 dry-run。

---

## Phase 2: Gather Project Context

## 阶段 2：收集项目上下文

- Read `CLAUDE.md` for tech stack, target platforms, and team structure
- Read the latest milestone in `production/milestones/`
- Read any existing release checklist in `production/releases/`
- Read the content calendar in `design/live-ops/content-calendar.md` if it exists

- 阅读 `CLAUDE.md` 获取技术栈、目标平台与团队结构
- 阅读 `production/milestones/` 中最新里程碑
- 阅读 `production/releases/` 中任何既有的发布清单
- 若存在，阅读 `design/live-ops/content-calendar.md` 中的内容日历

---

## Phase 3: Scan Codebase Health

## 阶段 3：扫描代码库健康度

> **Every scan in this phase is a search for something bad, so a zero-hit result
> is ambiguous by construction: it means either "searched and found none" or
> "there was nothing to search". On a launch gate those are opposite findings,
> and a green checkbox renders them identically.**
>
> **Establish the denominator before every scan below, and report it.** Each line
> reads either `scanned [N] files, [M] hits` or
> `NOT ASSESSED — [code root unresolved | no source files | no asset folder | directory empty]`.
> Never a bare tick. The code root is `src/`, `Assets/` or `Source/` by engine
> (resolve per `.claude/docs/code-root-resolution.md`); assets live in
> `assets/`, `Assets/` or `Content/`.
>
> This applies to all four bullets below: each searches the same way, for
> placeholder assets, TODOs, debug output and hardcoded test values, and each
> returns zero hits on an empty or absent root. With no `assets/` directory, for
> example, the placeholder scan returns zero hits, and a bare tick would mark
> "All placeholder art replaced" green.

> **本阶段的每次扫描都是在找“坏东西”，所以零命中结果天生含糊：它要么表示“搜过且没找到”，
> 要么表示“根本没有可搜的东西”。在发布门禁上，这两种结论截然相反，而绿色勾选框会把它们
> 渲染得一模一样。**
>
> **在下面每次扫描前先确立分母，并报告它。** 每行要么读作 `scanned [N] files, [M] hits`，
> 要么读作
> `NOT ASSESSED — [code root unresolved | no source files | no asset folder | directory empty]`。
> 绝不只是裸勾选。代码根依引擎为 `src/`、`Assets/` 或 `Source/`
> （按 `.claude/docs/code-root-resolution.md` 解析）；资产位于
> `assets/`、`Assets/` 或 `Content/`。
>
> 这适用于下面全部四个条目：它们都以同样方式搜索占位资产、TODO、调试输出与硬编码测试值，
> 并且在根目录为空或不存在时都返回零命中。例如没有 `assets/` 目录时，占位资产扫描返回零命中，
> 裸勾选就会把“所有占位美术已替换”标成绿色。

- Count `TODO`, `FIXME`, `HACK` comments and their locations
- Check for any `console.log`, `print()`, or debug output left in production code
- Check for placeholder assets (search for `placeholder`, `temp_`, `WIP_`)
- Check for hardcoded test/dev values (localhost, test credentials, debug flags)

- 统计 `TODO`、`FIXME`、`HACK` 注释及其位置
- 检查生产代码中是否残留任何 `console.log`、`print()` 或调试输出
- 检查占位资产（搜索 `placeholder`、`temp_`、`WIP_`）
- 检查硬编码的测试/开发值（localhost、测试凭据、调试开关）

**Carry the distinction into the checklist itself.** An item whose scan returned
`NOT ASSESSED` is written `- [?]`, not `- [ ]`. An unticked box says *work
remains*; a `[?]` says *nobody could check*, and only one of those is closed by
doing the work. Include the legend wherever a `[?]` appears:
`[?] = not assessed — the input to this check was absent`.

**将这一区别带入清单本身。** 扫描返回 `NOT ASSESSED` 的条目写成 `- [?]`，而不是 `- [ ]`。
未勾选的框表示*仍有工作*；`[?]` 表示*没人能检查*，而只有前者能通过完成工作来关闭。在出现 `[?]`
的地方附上图例：
`[?] = not assessed — the input to this check was absent`。

---

## Phase 4: Generate the Launch Checklist

## 阶段 4：生成发布清单

```markdown
# Launch Checklist: [Game Title]
Target Launch: [Date or DRY RUN]
Generated: [Date]

---

## 1. Code Readiness

### Build Health
- [ ] Clean build on all target platforms
- [ ] Zero compiler warnings
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Performance benchmarks within targets
- [ ] No memory leaks (verified via extended soak test)
- [ ] Build size within platform limits
- [ ] Build version correctly set and tagged in source control

### Code Quality
- [ ] TODO count: [N] (zero required for launch, or documented exceptions)
- [ ] FIXME count: [N] (zero required)
- [ ] HACK count: [N] (each must have documented justification)
- [ ] No debug output in production code
- [ ] No hardcoded dev/test values
- [ ] All feature flags set to production values
- [ ] Error handling covers all critical paths
- [ ] Crash reporting integrated and verified

### Security
- [ ] No exposed API keys or credentials in source
- [ ] Save data encrypted
- [ ] Network communication secured (TLS/DTLS)
- [ ] Anti-cheat measures active (if multiplayer)
- [ ] Input validation on all server endpoints (if multiplayer)
- [ ] Privacy policy compliance verified

---

## 2. Content Readiness

### Assets
- [ ] All placeholder art replaced with final assets
- [ ] All placeholder audio replaced with final audio
- [ ] Audio mix finalized and approved by audio director
- [ ] All VFX polished and performance-verified
- [ ] No missing or broken asset references
- [ ] Asset naming conventions enforced

### Text and Localization
- [ ] All player-facing text proofread
- [ ] No hardcoded strings (all externalized for localization)
- [ ] All supported languages translated and verified
- [ ] Text fits UI in all languages (text fitting pass complete)
- [ ] Font coverage verified for all supported languages
- [ ] Credits complete, accurate, and up to date

### Game Content
- [ ] All levels/maps playable from start to finish
- [ ] Tutorial flow complete and tested with new players
- [ ] All achievements/trophies implemented and tested
- [ ] Save/load works correctly for all game states
- [ ] Difficulty settings balanced and tested
- [ ] End-game/credits sequence complete

---

## 3. Quality Assurance

### Testing
- [ ] Full regression test suite passed
- [ ] Zero S1 (Critical) bugs open
- [ ] Zero S2 (High) bugs open (or documented exceptions) — at `workflow: full` instead: zero S2 (High) and S3 (Medium) bugs open, no exceptions
- [ ] Soak test passed (the longest soak `/soak-test` runs, or longer by hand if a play session lasts longer)
- [ ] Multiplayer stress test passed (if applicable)
- [ ] All critical user paths tested on every platform
- [ ] Edge cases tested (full storage, no network, suspend/resume)

### Platform Certification

**Emit ONLY the block matching `platform.cert_tier`** (resolved in the resolved-config block at the top of this skill — see
the `platform.cert_tier` rule above). Do not emit this section's other blocks, and
do not fall back to emitting all of them.

**At `none`** — omit the section and say so in one line:
`Platform Certification: omitted — cert_tier is 'none' (internal/jam release).`

**At `itch`:**
- [ ] Build size within itch.io upload limits
- [ ] itch.io page complete (cover art, screenshots, description, tags)
- [ ] Age/content tags set honestly
- [ ] Downloadable vs browser build decided and tested

**At `steam`:**
- [ ] Steamworks SDK integrated and tested
- [ ] Store page complete (capsule art, trailer, description, system requirements)
- [ ] Depot build uploaded and installs cleanly from a fresh account
- [ ] Achievements functional
- [ ] Steam common content rules reviewed

**At `console`:**
- [ ] TRC/TCR/Lotcheck submission prepared
- [ ] Save-data rules compliant (corruption, full storage, user switching)
- [ ] Controller-mapping rules met, platform-correct button prompts
- [ ] Suspend/resume verified
- [ ] Age ratings obtained (ESRB, PEGI, regional)

**Every tier**, because these are not certification-gated:
- [ ] Accessibility: minimum standards met (remapping, text scaling, colorblind)

> **Emit this section gated by tier, never as one ungated list.** PC *and*
> Console *and* Mobile rows emitted at every tier contradict the `cert_tier` rule
> at the top of this skill, which says an `itch` project gets no console and no
> Steamworks items.

### Performance
- [ ] Target FPS met on minimum spec hardware
- [ ] Load times within budget on all platforms
- [ ] Memory usage within budget on all platforms
- [ ] Network bandwidth within targets (if multiplayer)
- [ ] No frame hitches in critical gameplay moments

---

## 4. Store and Distribution

### Store Pages
- [ ] Store page copy finalized and proofread
- [ ] Screenshots current and per-platform resolution
- [ ] Trailers current and approved
- [ ] Key art and capsule images finalized
- [ ] System requirements accurate (PC)
- [ ] Pricing configured for all regions
- [ ] Pre-purchase/wishlist campaigns active (if applicable)

### Legal
- [ ] EULA finalized and approved by legal
- [ ] Privacy policy published and linked
- [ ] Third-party license attributions complete
- [ ] Music/audio licensing verified
- [ ] Trademark/IP clearance confirmed
- [ ] GDPR/CCPA compliance verified (data collection, consent, deletion)

---

## 5. Infrastructure

### Servers (if multiplayer/online)
- [ ] Production servers provisioned and load-tested
- [ ] Auto-scaling configured and tested
- [ ] Database backups configured
- [ ] CDN configured for content delivery
- [ ] DDoS protection active
- [ ] Monitoring and alerting configured

### Analytics and Monitoring
- [ ] Analytics pipeline verified and receiving data
- [ ] Crash reporting active and dashboard accessible
- [ ] Server monitoring dashboards live
- [ ] Key metrics tracked: DAU, session length, retention, crashes
- [ ] Alerts configured for critical thresholds

---

## 6. Community and Marketing

### Community Readiness
- [ ] Community guidelines published
- [ ] Moderation team briefed and tools ready
- [ ] Discord/forum/social channels set up
- [ ] FAQ and known issues page prepared
- [ ] Support email/ticketing system active

### Marketing
- [ ] Launch trailer published
- [ ] Press/influencer review keys distributed
- [ ] Social media launch posts scheduled
- [ ] Launch day blog post/dev update drafted
- [ ] Patch notes for launch version published

---

## 7. Operations

### Team Readiness
- [ ] On-call schedule set for first 72 hours post-launch
- [ ] Incident response playbook reviewed by team
- [ ] Rollback plan documented and tested
- [ ] Hotfix pipeline tested (can ship emergency fix within 4 hours)
- [ ] Communication plan for launch issues (who posts, where, how fast)

### Day-One Plan
- [ ] Day-one patch prepared (if needed)
- [ ] Server unlock/go-live procedure documented
- [ ] Launch monitoring dashboard bookmarked by all leads
- [ ] War room/channel established for launch day

---

## Go / No-Go Decision

**Overall Status**: [READY / CONDITIONAL / NOT ASSESSED / NOT READY]

First match wins: **NOT READY** if Blocking Items is not empty; else **NOT
ASSESSED** if any item is `- [?]`, any section came out `NOT ASSESSED`, or any
item is still unconfirmed — neither ticked on evidence or on a Phase 4b answer,
nor marked N/A, nor listed below (name each; group by section when there are
many); else **CONDITIONAL** if Conditional
Items is not empty; else **READY**. NOT ASSESSED outranks CONDITIONAL and READY —
an item nobody could check is not a passed one — and ranks below NOT READY, so a
known blocker is never buried behind it.

### Blocking Items
[Every FAIL or unresolved finding: a check that found a problem — FIXMEs, debug
output, placeholder assets, hardcoded dev values, an open S1 bug, a failing
build or test — with no documented workaround and no explicitly accepted risk]

### Conditional Items
[Every shortfall with a documented workaround or an explicitly accepted risk —
e.g. a HACK with its documented justification, an S2 with a documented
exception (below `workflow: full`, which allows none). Name the workaround, or
who accepted the risk]

### Sign-Offs Required
- [ ] Creative Director — Content and experience quality
- [ ] Technical Director — Technical health and stability
- [ ] QA Lead — Quality and test coverage
- [ ] Producer — Schedule and overall readiness
- [ ] Release Manager — Build and deployment readiness
```

---

## Phase 4b: Confirm What Only a Person Can

## 阶段 4b：确认只有人才能确认的事

Most items above cannot be settled from the repository — the on-call schedule,
the EULA, press keys, pricing, a soak test someone ran. Left unasked, every one
of them stays unconfirmed and the Overall Status can only be NOT ASSESSED, so ask.

上面大多数条目无法从仓库中确定 — 值班表、EULA、媒体密钥、定价、某人跑过的浸泡测试。
若不询问，它们每一个都保持未确认，整体状态便只能是 NOT ASSESSED，所以要问。

For each of the seven sections, collect the items no scan or file settled (the
Phase 3 counts and anything read in Phase 2 are not asked again) and ask **one
`AskUserQuestion` per section**, listing those items numbered. Each item's
answer is **yes / no / not yet / N/A**. Options: `Yes — all of them` /
`Not yet — none of them` / `N/A — this section does not apply` /
`Some differ — I'll answer per item` (the user then gives each numbered item its
answer). Skip a section with nothing left to ask.

对七个小节中的每一个，收集没有任何扫描或文件能确定的条目（阶段 3 的计数与阶段 2 读过的内容
不再询问），并对**每个小节做一次 `AskUserQuestion`**，把这些条目编号列出。每个条目的答案是
**yes / no / not yet / N/A**。选项：`Yes — all of them` / `Not yet — none of them` /
`N/A — this section does not apply` / `Some differ — I'll answer per item`
（随后用户为每个编号条目给出答案）。没有剩余可问内容的小节跳过。

- **yes** → ticked `- [x]`, marked `(confirmed by the user)`
- **no** or **not yet** → a failed item: under Blocking Items, or under
  Conditional Items when the user names a workaround or accepts the risk
- **N/A** → written `- N/A — [item]` and left out of the Overall Status
- an item left unanswered stays unconfirmed, and the status names it

- **yes** → 勾选 `- [x]`，标记 `(confirmed by the user)`
- **no** 或 **not yet** → 失败条目：列入 Blocking Items，或在用户给出变通方案或接受风险时
  列入 Conditional Items
- **N/A** → 写成 `- N/A — [item]`，并从整体状态中排除
- 未获回答的条目保持未确认，且状态中点名它

These are questions of fact only the user can answer, so they are asked in
`collaborative` and `guided` alike and never answered on the user's behalf. In
`autonomous` mode and in `dry-run`, skip this phase and say so: the items it
would have asked stay unconfirmed, and the Overall Status is NOT ASSESSED.

这些是只有用户才能回答的事实问题，因此在 `collaborative` 与 `guided` 下都会询问，且绝不可
代替用户作答。在 `autonomous` 模式与 `dry-run` 下，跳过本阶段并说明：本应询问的条目保持未确认，
整体状态为 NOT ASSESSED。

Then fill in the Go / No-Go section from the answers.

然后根据答案填写 Go / No-Go 小节。

---

## Phase 5: Save Checklist

## 阶段 5：保存清单

Present the completed checklist and summary to the user (Overall Status, total items, blocking items count, conditional items count, not-assessed items count, departments with incomplete sections).

向用户呈现已完成的清单与摘要（整体状态、条目总数、阻塞条目数、条件条目数、未评估条目数、
存在未完成小节的部门）。

If not in dry-run mode, ask: "May I write this to `production/releases/launch-checklist-[date].md`?"

若非 dry-run 模式，询问：“我可以将其写入 `production/releases/launch-checklist-[date].md` 吗？”

Create nothing before the answer — not even the `production/releases/` directory.
If yes, write the file; the write creates the directory with it.

在得到答复前不创建任何东西 — 连 `production/releases/` 目录也不创建。
若同意，写入文件；写入会连带创建该目录。

---

## Phase 6: Next Steps

## 阶段 6：后续步骤

- If `project.stage` is not `Release` (`Polish`, an earlier stage, or unset), run `/gate-check release` first — it is the readiness gate before launch.
- Coordinate sign-offs and the deployment via `/team-release`.

- 若 `project.stage` 不是 `Release`（`Polish`、更早阶段，或未设置），先运行 `/gate-check release` — 它是发布前的就绪门禁。
- 通过 `/team-release` 协调签署与部署。
