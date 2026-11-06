> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.

> 门禁定义，由 `/gate-check` **仅为目标阶段**加载。绝不加载其余五个——每次调用只适用一个门禁。


# Gate: Polish → Release

# 门禁：Polish → Release


**Required Artifacts:**

**必需产物：**

- [ ] All features from milestone plan are implemented
- [ ] Content is complete (all levels, assets, dialogue referenced in design docs exist)
- [ ] Localization strings are externalized (no hardcoded player-facing text in the code root)
- [ ] QA test plan exists (`/qa-plan` output in `production/qa/`)
- [ ] QA sign-off report exists (`/team-qa` output — APPROVED or APPROVED WITH CONDITIONS)
- [ ] All Must Have story test evidence is present (Logic/Integration: test files pass; UI: retained screenshots of each screen touched; Visual/Feel: retained screenshots plus lead sign-off — both in `production/qa/evidence/`, and no `qa.level` waives either)
- [ ] Smoke check passes cleanly (PASS verdict) on the release candidate build — a full run, not a `quick` one labelled `(quick — …)`
- [ ] No test regressions from previous sprint (test suite passes fully)
- [ ] Balance data has been reviewed (`/balance-check` run)
- [ ] Release checklist completed (`/release-checklist` run)
- [ ] Store metadata prepared (if applicable)
- [ ] Changelog / patch notes drafted

- [ ] 里程碑计划中的所有特性都已实现
- [ ] 内容已完整（设计文档中引用的所有关卡、资产、对话都存在）
- [ ] 本地化字符串已外部化（代码根目录中无硬编码的面向玩家的文本）
- [ ] QA 测试计划存在（`production/qa/` 中的 `/qa-plan` 输出）
- [ ] QA 签核报告存在（`/team-qa` 输出——APPROVED 或 APPROVED WITH CONDITIONS）
- [ ] 所有 Must Have 故事的测试证据都已具备（Logic/Integration：测试文件通过；UI：每个涉及界面的保留截图；Visual/Feel：保留截图加主管签核——二者都在 `production/qa/evidence/` 中，且任何 `qa.level` 都不会豁免其中任一）
- [ ] 冒烟检查在候选发布构建上干净通过（PASS 裁定）——完整的运行，而不是标记为 `(quick — …)` 的 `quick` 运行
- [ ] 相对于上一个冲刺没有测试回退（测试套件完全通过）
- [ ] 平衡数据已评审（已运行 `/balance-check`）
- [ ] 发布检查清单已完成（已运行 `/release-checklist`）
- [ ] 商店元数据已准备（如适用）
- [ ] 变更日志 / 补丁说明已草拟

**Quality Checks:**

**质量检查：**

- [ ] Full QA pass signed off by `qa-lead`
- [ ] All tests passing
- [ ] Performance targets met across all target platforms
- [ ] No known open S1 Critical, S2 High or S3 Medium bugs
- [ ] No open CRITICAL or HIGH findings in the newest `production/security/security-audit-*.md` whose **Scope** is `full`, as updated by any later `quick` report (the re-run `/security-audit` prescribes after remediation). A later `network`, `save` or `input` report adds its open findings but never clears a category it did not scan — any open CRITICAL or HIGH finding means not ready (a blocker). No `full`-scope audit report means the check could not run: this item is NOT ASSESSED, never passed. A report whose release recommendation is itself NOT ASSESSED makes this item NOT ASSESSED too
- [ ] Accessibility basics covered (remapping, text scaling if applicable)
- [ ] Localization verified for all target languages — every translated locale being shipped has a `/localize qa` verdict of PASS or PASS WITH CONDITIONS (`production/localization/loc-qa-[locale]-[date].md`). A FAIL blocks that locale; the others may still ship. A locale with no QA report, or whose QA reported NOT ASSESSED (nobody has played it), has not been verified: this item is NOT ASSESSED, never passed. The source locale (`en`, per `/localize`) is not a target language and needs no `/localize qa` report; a game that ships only its source locale marks this item N/A and says so
- [ ] Legal requirements met (EULA, privacy policy, age ratings if applicable)
- [ ] Build compiles and packages cleanly

- [ ] 完整 QA 通过已由 `qa-lead` 签核
- [ ] 所有测试通过
- [ ] 所有目标平台均达到性能目标
- [ ] 没有已知的未关闭 S1 Critical、S2 High 或 S3 Medium 缺陷
- [ ] 最新一份 **Scope** 为 `full` 的 `production/security/security-audit-*.md` 中没有未关闭的 CRITICAL 或 HIGH 发现（并以任何更晚的 `quick` 报告为更新——即补救后所规定的重跑 `/security-audit`）。更晚的 `network`、`save` 或 `input` 报告会追加其未关闭发现，但绝不会清除它未扫描过的类别——任何未关闭的 CRITICAL 或 HIGH 发现都意味着尚未就绪（阻塞项）。没有 `full` 范围的审计报告意味着该检查无法运行：此项为 NOT ASSESSED，绝不算通过。若某报告的发布建议本身为 NOT ASSESSED，则此项也为 NOT ASSESSED
- [ ] 无障碍基础已覆盖（改键、文本缩放（如适用））
- [ ] 所有目标语言的本地化已验证——每一个要发布的已翻译语种都有 `/localize qa` 裁定为 PASS 或 PASS WITH CONDITIONS（`production/localization/loc-qa-[locale]-[date].md`）。FAIL 会阻塞该语种；其他语种仍可发布。没有 QA 报告的语种，或其 QA 报告为 NOT ASSESSED（没人玩过）的语种，都尚未验证：此项为 NOT ASSESSED，绝不算通过。源语种（按 `/localize` 为 `en`）不是目标语言，无需 `/localize qa` 报告；仅发布源语种的游戏将此项标记为 N/A 并说明即可
- [ ] 法律要求已满足（EULA、隐私政策、年龄分级（如适用））
- [ ] 构建可干净地编译与打包

## Workflow tier reductions

## 工作流层级削减

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

上述检查清单是 **`full` 基线**。在较低层级，应用对应已解析层级的削减；未被点名的项目保持上述状态。削减只会 *放松* 要求——`workflow_overrides` 是唯一会新增要求的东西。

- **`full`** — all features + content complete + localization + QA sign-off + smoke (PASS) + no open S1–S3 bugs all required
- **`standard`** — content-complete audit + QA sign-off + localization → recommended; **all features + smoke + no open S1 Critical bugs** required; open S2 High and S3 Medium bugs → recommended
- **`minimal`** — only **smoke + no open S1 Critical bugs** required; everything else **drops**

- **`full`**——所有特性 + 内容完整 + 本地化 + QA 签核 + 冒烟（PASS）+ 无未关闭的 S1–S3 缺陷，全部为必需
- **`standard`**——内容完整性审计 + QA 签核 + 本地化 → 转为建议；**所有特性 + 冒烟 + 无未关闭的 S1 Critical 缺陷**为必需；未关闭的 S2 High 与 S3 Medium 缺陷 → 转为建议
- **`minimal`**——仅要求**冒烟 + 无未关闭的 S1 Critical 缺陷**；其余全部**丢弃**
