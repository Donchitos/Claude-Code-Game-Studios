# skill-test — 技能文件结构与行为校验（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/skill-test/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/skill-test static [skill-name | all] | spec [skill-or-agent-name] | category [skill-or-agent-name | all] | audit`
- **一句话职责**：校验技能（`.claude/skills/*/SKILL.md`）与 agents（`.claude/agents/*.md`）的结构合规与行为正确——四模式：静态 linter、行为 spec 验证、类别 rubric、覆盖审计；无外部依赖，全在既有 skill/hook/template 架构内运行。
- **触发前置**：`resolve_config --keys automation` 已解析；`AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`。
- **四模式**：`static` — 结构 linter，每技能 7 项合规检查 + agent/delegation/compatibility 观察（~1k token/技能）；`spec` — 行为验证器，评估技能或 agent 测试 spec 中的断言（~5k/项）；`category` — 类别 rubric，对照类别专属指标（~2k/项）；`audit` — 覆盖报告：技能、agent spec、上次测试日期（~3k 总计）。
- **通过证明什么（诚实边界）**：每个模式都读文件，**没有一个运行技能**。`static`：文件有技能需要的结构，不证明它 behaves；`spec`：细读之下说明覆盖了每个 case，不证明 Claude 运行时遵循它们；`category`：技能满足其类别 rubric 如所写；`audit`：哪些技能和 agents 有 specs、每项上次何时检查。技能真正做什么只在运行时显现：在项目的一次性副本里发真实请求、在用的每个模型上、有和没有该技能各跑一遍（Anthropic Agent Skills 最佳实践 "Build evaluations first"）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 目标技能的 `SKILL.md` + 其 `references/` 下**每个文件**（全读，作为一个技能整体检查）；agent 文件 `.claude/agents/[name].md`；`studio-tests/catalog.yaml`（spec 路径 / category / last_* 记录）；`studio-tests/quality-rubric.md`；`studio-tests/skills|agents/` 下 spec 文件；项目 `CLAUDE.md` 及其 `@path` 行导入的每个文件（如 `coordination-rules.md`）；spec 引用的 `.claude/docs/director-gates/[gate-id].md`；`.claude/scripts/agent-check.sh` 与 `compat-inventory.sh` 输出；`.claude/rules/skill-authoring.md` §5（covered set 规则） | 被测对象 / spec 与 rubric / 运行时可见的共享上下文 / 观察脚本 |
| 产出 | 各模式报告（会话内）；spec 模式可选写 `studio-tests/results/skill-test-spec-[name]-[date].md` 并更新 catalog 的 `last_spec`/`last_spec_result`；category 模式可选更新 `last_category`/`last_category_result`；`static` 与 `audit` **不写文件** | — |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 解析参数
R1. 模式从首参数定：`static [name]` 单技能 7 检查（agent 名则只跑观察）；`static all` glob `.claude/skills/*/SKILL.md` 全查 + 每 agent 观察；`spec [name]` 读技能/agent + 其测试 spec 评估断言；`category [name]` 跑 `studio-tests/quality-rubric.md` 的类别 rubric；`category all` 每个有 `category:` 的技能与 agent；`audit`（或无参数）读 catalog 列覆盖。未识别参数 → 输出 usage 并停止。（Phase 1）
R2. **旧 spec 文件夹检测**：glob `CCGS Skill Testing Framework/catalog.yaml`——存在时**先说明**："1.2.0 时重命名为 `studio-tests/`，本技能只读 `studio-tests/`；把写在那边的 spec 移过来（UPGRADING.md v1.1.3→1.2.0 有方法）"，然后继续用 `studio-tests/`。（Phase 1）
R3. **名称解析（`spec`/`category` 前必做）**：查 `studio-tests/catalog.yaml`——`skills:` 下是技能（`.claude/skills/[name]/SKILL.md`），`agents:` 下是 agent（`.claude/agents/[name].md`）；无 catalog 条目 → 用两个文件中存在的那个；两者都不存在 → 报 "'[name]' is neither a skill in `.claude/skills/` nor an agent in `.claude/agents/`." 并停止。**是普通词的名字也是名字**：`/skill-test spec help` 测的是 `/help` 技能，绝不是对本技能 usage 的请求。7 项检查 lint 的是 SKILL.md 结构，所以**仅适用于技能**；给 agent 名，`static` 只跑观察（agent 文件没有可 lint 的 phase 或 verdict 关键词），**绝不把该 agent 报成缺失**。（Phase 1）

### Phase 2A — static 模式（结构 linter）
R4. 逐技能读 `SKILL.md` 及 `references/` 全部文件，**作为一个技能跑全部 7 检查**（最长的技能把每个 phase 放在 `references/` 里）；frontmatter 检查（1、6、7）只读 `SKILL.md`。（Phase 2A）
R5. **7 项检查**（frontmatter 检查 1、6、7 只读 `SKILL.md`）：（Phase 2A）
   - **Check 1 必需 frontmatter 字段**：`name:`、`description:`、`argument-hint:`、`user-invocable:`、`allowed-tools:` 缺一即 FAIL；**frontmatter 解析失败也是 Check 1 FAIL**——malformed YAML 是该检查要抓的结构缺陷，不是不可评估的文件（结果为 NON-COMPLIANT 而非 NOT ASSESSED——缺陷在技能，不在 linter 的访问）；
   - **Check 2 多 Phase**：≥ 2 个 phase 型标题（`## Phase N`、`## N.` 或至少 2 个不同 `##` 标题），否则 FAIL；
   - **Check 3 verdict 关键词**：接受三类——门禁/审查类（`PASS`/`FAIL`/`CONCERNS`/`APPROVED`/`BLOCKED`/`COMPLETE`/`READY`/`COMPLIANT`/`NON-COMPLIANT`）、go/no-go（`PROCEED`/`PIVOT`/`KILL`/`GO`/`NO-GO`）、严重度（`CRITICAL`/`HIGH`/`MEDIUM`/`LOW`）。无且技能产出 assessment（描述或正文承诺 review/audit/check/gate/readiness 判断）→ **FAIL**；无且输出是 artifact 或值 → **WARN（绝不 FAIL）**（`/settings` 是参考案例——打印和写配置，无 verdict 可给；禁止为满足检查发明一个）。窄清单（只认门禁 verdict、其余硬 FAIL）会错误失败不该失败的技能——产生假失败的 linter 停止被信任；
   - **Check 4 协作协议语言**：找 ask-before-write（`"May I write"` 典范形式；文件写指令附近的 `"before writing"`/`"approval"`；同节内 `"ask"`+`"write"` 接近）。缺 → WARN；**`allowed-tools` 含 `Write` 或 `Edit` 而无 ask 语言 → FAIL**；
   - **Check 5 下一步交接**：以推荐后续动作收尾（末节提另一技能 / "Recommended next"、"next step" 措辞 / "Follow-Up"、"After this" 节）。缺 → WARN；
   - **Check 6 fork 上下文复杂度**：frontmatter 有 `context: fork` → 应 ≥ 5 个 phase 标题（fork 给复杂多阶段技能；简单技能不该用）。不足 → WARN；
   - **Check 7 argument-hint 合理性**：非空；正文提多模式（"Mode A | Mode B"）则 hint 应反映；与 Phase 1 "Parse Arguments" 交叉引用。空或与文档模式不符 → WARN。
R6. **Agent 与 Delegation 观察（不计分）**：跑 `bash .claude/scripts/agent-check.sh`（`--skill [name]` / `--agent [name]` / `static all` 时一次）。它打印观察**绝不产出 verdict**，也不改变技能 verdict。在 `Observations:` 下逐项判断：`DELEGATION:`（技能交给 agent 工作的部分——读之并说明 brief 是否给了目标、输出格式、工具与来源、边界；交给 agent 的活是只有几次工具调用还是对技能自身工作的复查；其 `markers:` 是显示哪里值得看的字数，不是评分）；`AGENT:`（所设 model/effort/turn limit 与描述旁的工具——点名描述中的工作用不到的任何工具）；`NOTE:`（frontmatter 不解析；`asks-user`——agent 没有提问工具，其问题应放到报告末尾；被忽略或言过其实的设置——`agent-type-list`、`preload-off`、`disallowed-specifier`、`memory-grants`）；`OVERLAP:`（两个描述共享特征词——说明各自是否仍能 singled out 自己的 agent，或哪类请求会打到错的那个）。脚本跑不了 → 写 `Observations: not run (<reason>)`——**绝不省略该节：缺失的节读起来与干净的节一样**。（Phase 2A）
R7. **Compatibility 观察（不计分）**：跑 `bash .claude/scripts/compat-inventory.sh`。每条 `FOUND:` 行是文件依赖了仅 Claude Code 提供的东西的位置（questions、subagents、skill-loading、shell-lines、arguments、frontmatter、instructions、hooks、settings、tools）——Claude Code 全都支持，所以**无一是缺陷、无一改 verdict**。在 `Compatibility:` 下报告，每 feature 一行带构造与行号；`static all` 给 `COUNT:` 分 feature 总数。`NOT FOUND:` 行 = 名字没匹配到文件：说明之。脚本跑不了 → `Compatibility: not run (<reason>)`。（Phase 2A）
R8. **static 输出**：单技能——7 检查各一行 PASS/WARN/FAIL（带括号原因），加 Observations 与 Compatibility（不计分），Verdict 四值之一 + `Recommended:` 行（任何非 COMPLIANT 裁决都必须以命名修复的 Recommended 行收尾）；单 agent——**无 verdict，只有观察**（model/effort/turn limit、工具适配判断、observations、compatibility）。**Verdict 四值**：`COMPLIANT`（无警无败）/ `WARNINGS`（有警无败）/ `NON-COMPLIANT`（任一 FAIL）/ `NOT ASSESSED`（文件无法读取或解析、检查无法运行——点名原因）。`static all`：汇总表（Skill / Result / Issues）+ Summary + Aggregate Verdict + agents 观察汇总 + compatibility 计数。（Phase 2A）
R9. **NOT ASSESSED 是逐技能结果，不只是汇总行**：文件缺失或不可读（权限、不存在）以致任何检查都无法开始的技能，报 `NOT ASSESSED` 带原因——**绝不在表中省略、绝不计入 COMPLIANT**；排序在 COMPLIANT 之上、WARNINGS 与 NON-COMPLIANT 之下。**声明分母**：标题 "All 74 Skills" 必须是实际检查的数量而非存在的数量——不一致时报 `[N] of [M] skills checked`。计数静默少于自己标题的汇总，正是本技能要在别人身上抓住的失败。static 模式**不写任何文件**。（Phase 2A）

### Phase 2B — spec 模式（行为验证器）
R10. 定位文件：用 Phase 1 解析的文件 + catalog 的 `spec:` 路径。缺失分支：缺技能/agent → Phase 1 消息；catalog 无 spec 路径 → "No spec path set for '[name]' in catalog.yaml."；spec 文件不在路径 → "Spec file missing at [path]. Run `/skill-test audit` to see coverage gaps."。然后**完整读**技能（`SKILL.md` + `references/` 每个文件）或 agent 文件，以及 spec 文件。（Step 1-2）
R11. **对着运行它的模型能看到的东西评估**：技能在会话中跑、被 spawn 的 agent 在自己的上下文里跑，两者都载入项目 `CLAUDE.md` 及其 `@path` 行导入的每个文件（被 spawn 的 agent 会逐字引用 `coordination-rules.md` 而没读过它）——**这些文件也要读**。那里声明的规则对每个技能和 agent 都算数，**引用来源文件**；技能/agent 自己的文件与之矛盾时**自己文件赢**（它是更具体的指令）。（Step 3）
R12. **Agent spec 的评估**：spec 各节对 agent 文件**及其 frontmatter `skills:` 列出的每个技能**（Claude Code 启动时载入 agent）评估。Static Assertions——对 frontmatter 与 body 逐条核对；**命名字面值的断言（`model:` 别名、frontmatter 键、工具名）是与文件的精确比较**：`model: inherit` 不满足 "Model tier is `sonnet`"，**近似匹配是 FAIL，绝不是 PARTIAL**。Test Cases——每 case 的预期行为对 agent 的书面指令评估；**命名了门 ID（`LP-FEASIBILITY`、`CD-PILLARS`…）的 case 是对该门调用的评估**：spawn 它的技能会让 agent 先读 `.claude/docs/director-gates/[gate-id].md`，该文件的 Prompt 与 Verdicts 就是该 case 下 agent 的指令——也要读。Redirect/escalation case——agent 被要求其它角色拥有的工作、或遇到无法裁决的冲突：case 满足条件为 载入的 `coordination-rules.md` 覆盖该步（规则 2 域外不做约束性决定、规则 3 冲突升级共享父、规则 5 无委托不写自己目录外的文件）**且** agent 自己文件在其 collaborator/delegation/escalation/"must not" 列表中点名了拥有该工作的角色——**引用两者**；不要求 agent 用自己的话重述 redirect。agent 文件把该工作据为己有、或没有任何载入文件点名归属 → FAIL。Protocol Compliance——用 spec 自己的 `## Protocol Compliance` 清单**替代**技能版四检查。（Step 3）
R13. **技能 spec 的评估**：Static Assertions 对技能的 frontmatter 与 body（`SKILL.md` + `references/`）同样逐条核对，字面值精确比较。`/skill-test static` 只跑 7 项固定检查，所以 **spec 自己的静态行——某个 verdict 关键词、某个 phase、"May I write" 出现在命名文件之前——在这里评估，否则无处评估**。（Step 3）
R14. **逐 Test Case 评估**：读 Fixture（项目文件的假定状态）、Expected behavior 步骤、每条 Assertion checkbox。**无 Fixture 的 case 读其 Input 作 fixture；无 Assertions 列表的 case 把每条 Expected behavior 要点当断言**——多数 agent spec 这么写，case verdict 不会因为没有独立清单而悬空。每条断言评估"技能的书面指令在 fixture 状态下被正确遵循时是否满足它"——这是 Claude 评估的推理检查，不是代码执行。标记四值：**PASS**（指令清楚满足）/ **PARTIAL**（部分涉及但有歧义）/ **FAIL**（给定 fixture 下不会满足）/ **NOT ASSESSED**（断言完全无法评估：命名了 spec 从未定义的 fixture 状态、依赖静态读无法解决的运行时行为、引用不存在的文件或节——**仅对行为沉默的文件是 FAIL 或 PARTIAL，不是这个**）。NOT ASSESSED 排 **PASS 之上**（没人能评估的断言没有被满足）、**PARTIAL 与 FAIL 之下**（有人识别出的歧义比没人够得着的更可行动）；**禁止把无法评估的断言解析成 PASS** 因为技能"大概"处理了——那个判断正是 spec 存在要取代的。（Step 3）
R15. **技能的 Protocol Compliance 节（恒在）**：逐行按 case 断言同样评估（PASS/PARTIAL/FAIL/NOT ASSESSED）——spec 把规则放在那里而没有任何 case 复述（"covered by the protocol compliance assertions above"），**不评估的清单就是一套没人检查的规则**。四条底线，清单未覆盖时补上：要求 "May I write" 在文件写之前；展示发现后再请求批准；以推荐的下一步收尾；避免未经批准自动创建文件。（Step 3）
R16. **报告与裁决**：Static Assertions 块（每条 [PASS]/[NOT ASSESSED] + Reason）→ 各 Case（Fixture 摘要 + 断言逐条 + Reason + **Case Verdict = 其断言中最差**）→ Protocol Compliance → **Overall Verdict**（= static assertions、cases、Protocol Compliance 三者最差，顺序 **FAIL, PARTIAL, NOT ASSESSED, PASS**——没人能评估的断言使整体结果读不成 PASS）。agent 的报告头是 `=== Agent Spec Test: [name] ===`，`Spec:` 为 `studio-tests/agents/` 下路径，`Static Assertions:` 块在 Case 1 之前。写结果前先询问：写 `studio-tests/results/skill-test-spec-[name]-[date].md` 并更新 catalog 的 `last_spec: [date]` 与 `last_spec_result: PASS|PARTIAL|FAIL|NOT ASSESSED`（Overall Verdict）。（Step 4-5）

### Phase 2D — category 模式（rubric 评估）
R17. 定位：catalog 的 `category:` 字段。无文件 → Phase 1 消息；无 `category:` → "No category assigned for '[name]' in catalog.yaml. Add `category: [name]` to its entry first."。`category all`：收集每个有 `category:` 的技能与 agent 分别处理报告；`category: utility` 的技能只评估 U1（static 检查通过）与 U2（如适用 gate 模式正确）——跳到 static 模式做 U1。**对 `.claude/skills/*/SKILL.md` 与 `.claude/agents/*.md` 交叉核对**（Audit 模式 Step 2 的 glob）：把任何 catalog 缺失或无 `category:` 的技能/agent 按名列为 **NOT ASSESSED——绝不静默排除出运行**。（Step 1）
R18. 读 `studio-tests/quality-rubric.md` 提取匹配类别的节（技能 `### gate`、`### team` 等；agent 类别在 `## Agent Categories` 下如 `### director`）。**rubric 没有该类别的节 → 结果 NOT ASSESSED：点名缺失节，绝不借用另一类别的指标**。完整读技能（含 references/）或 agent 文件 + Phase 2B Step 3 所述项目上下文——**`CLAUDE.md` 或其导入文件中的规则满足的 metric 即算满足，引用该文件**；其 redirect/escalation 规则同时决定 domain、deferral、escalation 类指标（D2、D3、L2、S1–S3、O2）。（Step 2-3）
R19. 逐 rubric metric：检查书面指令是否清楚满足标准；标 PASS / FAIL / WARN / **NOT ASSESSED**（无法评估——点名为何）；FAIL/WARN/NOT ASSESSED → 在文本中指出确切 gap（引用相关节、注明缺失、或点名无法评估什么）。输出每 metric 一行 + Verdict + `Fix:`。**类别 verdict 首匹配**：任一 metric FAIL → **FAIL**；否则任一 WARN → **WARNINGS**；否则任一 metric 无法评估（rubric 节缺失、文件不可读）→ **NOT ASSESSED**；否则全过 → **PASS**——与 static 和 spec 模式同一排序。写入前询问更新 catalog 的 `last_category` / `last_category_result`。（Step 4-6）

### Phase 2C — audit 模式（覆盖报告）
R20. 读 `studio-tests/catalog.yaml`（缺失 → 注明还不存在，首次运行状态）。枚举：glob `.claude/skills/*/SKILL.md` 得完整技能列表（目录名即名）；glob `.claude/agents/*.md` 得完整 agent 列表——**repo 本身而非 catalog 是 covered set**（`skill-authoring.md` §5：门禁派生其覆盖集，不枚举它）。两个 glob 对 catalog 的 `skills:`/`agents:` 条目比对，**按名报告任何 catalog 缺失的技能或 agent**——未入册的不能静默掉队。（Step 1-2）
R21. 技能覆盖表：spec 文件存在性（catalog `spec:` 路径或 glob `studio-tests/skills/*/[name].md`）；`last_static`/`last_static_result`/`last_spec`/`last_spec_result`/`last_category`/`last_category_result`/`category`（不在 catalog → "never"/"—"）；priority（critical/high/medium/low）。agent 覆盖表同理（agents 节每项）。输出：SKILLS（总数 / Specs written % / Never static tested / Never category tested）+ 明细表；AGENTS + 表；Top 5 Priority Gaps（无 spec 的 critical/high 技能，全齐则 "(none)"）；Skill coverage / Agent coverage 结算。**audit 模式不写文件**。收尾提供后续：`/skill-test static all` / `category all` / `spec [name]`。（Step 3-4）

### Phase 3 — 推荐后续
R22. 任何模式完成后按上下文给跟进：（Phase 3）
   - `static [name]` 后 → "Run `/skill-test spec [name]` to validate behavioral correctness if a test spec exists."；
   - `static all` 有失败 → "Address NON-COMPLIANT skills first. Run `/skill-test static [name]` individually for detailed remediation guidance."；
   - `spec [name]` PASS → 更新 catalog 记录日期 + 考虑 `/skill-test audit` 找下一个 spec 缺口；
   - `spec [name]` FAIL → "Review the failing assertions and update the skill or agent, or the test spec, to resolve the mismatch."；
   - `audit` 后 → 从 critical 优先缺口开始，用 `studio-tests/templates/skill-test-spec.md`（agent 用 `agent-test-spec.md`）模板创建新 spec。

## 4. 门禁与裁决
- **static Verdict**：`COMPLIANT` / `WARNINGS` / `NON-COMPLIANT`（任一 Check FAIL）/ `NOT ASSESSED`（文件不可读或检查无法运行）；排序 NON-COMPLIANT ≈ WARNINGS > NOT ASSESSED > COMPLIANT。
- **spec 裁决**（逐断言、逐 case、整体三级同序）：`FAIL` > `PARTIAL` > `NOT ASSESSED` > `PASS`；字面值断言近似即 FAIL；Case Verdict = 最差断言；Overall = 最差部分。
- **category 裁决（首匹配）**：FAIL > WARNINGS > NOT ASSESSED > PASS；rubric 无该类节 → NOT ASSESSED，禁止借别类指标。
- **观察与兼容项恒不计分**；static 与 audit 模式零文件写入。

## 5. 移植建议
- **可直接移植**：R5 全部 7 检查的思路（frontmatter 完整性、多阶段、verdict 词汇三级分类、ask-before-write 与 Write/Edit 权限联动、下一步交接、fork 复杂度、参数提示合理性）；R6-R7 的"观察绝不计分 + 缺失的节读起来与干净的一样"；R8 的"任何非合规裁决必须以命名修复的 Recommended 行收尾"；R9（NOT ASSESSED 是逐项结果 + 声明分母）；R11（评估要看运行时实际载入的全部上下文）；R12（字面值精确比较，近似即 FAIL）；R14（NOT ASSESSED 的排序论证 + 禁止"大概"→PASS）；R17（绝不静默排除未入册项）；R20（covered set 取自 repo 而非登记表）。
- **需替换概念**：`.claude/skills/` 与 `.claude/agents/` → 你的 prompt/命令/工作流定义目录（如 `.cursor/rules`、`.github/instructions`、agent 配置）；SKILL.md frontmatter → 你的定义文件 schema；`studio-tests/` → 定义文件的测试目录（spec + catalog + rubric）；director-gates → 角色权限文档；Anthropic Agent Skills 最佳实践 → 对应平台的评测指引。
- **改写示例**：
  - R14 → "静态行为核验中断言标记四级：PASS / PARTIAL / FAIL / NOT ASSESSED。NOT ASSESSED 用于断言引用了未定义状态、依赖运行时行为或指向不存在的文件；它排序在 PASS 之上、PARTIAL 与 FAIL 之下——没人能评估的断言没有被满足，但已识别的歧义更可行动。禁止因目标'大概'满足而记 PASS：那正是测试规格要取代的判断。"
  - R9 → "汇总报告的分母必须与标题一致：标题写 All N，则 N 是实际检查的数量而非存在的数量；两者不符时逐字报告 checked N of M。计数静默小于自身标题的汇总，就是这类检查要在被检对象上抓的缺陷。"

## 6. 关联文档
- 上游：`.claude/rules/skill-authoring.md`（covered set 与编写规范）、`skill-creator`（技能的创建方）。
- 下游：`studio-tests/catalog.yaml`（last_* 记录的更新目标）、`/skill-improve`（修复建议的消费方之一）。
- 引用：`studio-tests/quality-rubric.md`、`studio-tests/templates/skill-test-spec.md`、`studio-tests/templates/agent-test-spec.md`、`.claude/docs/automation-modes.md`、`.claude/scripts/agent-check.sh`、`.claude/scripts/compat-inventory.sh`、`.claude/docs/director-gates/`、Anthropic Agent Skills best practices（"Build evaluations first"）。
