# localize — 字符串提取与本地化校验（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/localize/SKILL.md) ｜ 阶段：Phase 6-7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/localize [scan|extract|validate|status|brief|cultural-review|vo-pipeline|rtl-check|freeze|qa]`
- **一句话职责**：完整本地化管道——从扫出硬编码字符串、提取字符串表、冻结源文本、给外部译队生成语境简报，到校验译文、文化审查、VO 配音流水线、RTL 布局检查与发布前本地化 QA 签核；**本地化不只是翻译，而是让作品在每个语言与地区都像原生**
- **触发前置**：代码根（code root）可按 `.claude/docs/code-root-resolution.md` 解析；字符串表体系位于 `assets/data/strings/`。**无子命令 → 输出用法即停，裁决 FAIL — missing required subcommand**

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `automation`（仅此一个） | 每次提问遵守 automation-modes |
| 读取 | code root 源码（按 code-root-resolution 解析）、`assets/data/strings/` 字符串表、`assets/`（嵌入文本的资产）、`assets/audio/vo/` | scan/extract/validate/status/vo 的输入；**code root 未解析 → 报 `NOT ASSESSED — code root unresolved`，禁止报零命中** |
| 读取 | `design/gdd/`（类型/基调/设定/角色名，按节读：Grep `^#` + offset/limit）、`design/narrative/`（lore）、`project.yaml` 的 `engine.name`（缺失回退 `.claude/docs/technical-preferences.md`） | brief、vo-pipeline、rtl-check 的输入 |
| 读取 | `production/localization/freeze-status.md` | freeze 状态（ACTIVE / LIFTED） |
| 产出 | `assets/data/strings/strings-en.json`（仅增量 diff）、`production/localization/translator-brief-[locale]-[date].md`、`cultural-review-[date].md`、`vo-scripts-[locale]-[date].md`、`rtl-check-[date].md`、`freeze-status.md`、`loc-qa-[locale]-[date].md` | **每个写盘动作前必须先问**（"May I write…"）；绝不直接改译文文件——生成 diff 供审查 |
| 派生智能体 | `localization-lead`（cultural-review 与 qa 两模式） | 其余模式主会话直接执行 |

## 3. 核心规则（逐条编号 R1、R2……）

**模式总则**
R1. 十个子命令各自独立：`scan`（找硬编码串与反模式，只读）、`extract`（提取并生成待译表）、`validate`（查译文完整性/占位符/长度，只读）、`status`（覆盖矩阵，只读）、`brief`（译者语境简报）、`cultural-review`（文化敏感内容）、`vo-pipeline`（配音本地化）、`rtl-check`（RTL 布局校验）、`freeze`（字符串冻结）、`qa`（发布前 QA 签核）。

**Phase 2A scan（只读）**
R2. 在 code root 搜硬编码用户可见字符串：未包本地化函数（`tr()`、`Tr()`、`NSLocalizedString`、`GetText` 等）的 UI 字符串字面量；本应参数化的拼接串；用位置占位符（`%s`、`%d`）而非命名占位符（`{playerName}`）的串；混排 locale 敏感数据（数字/日期/货币）却无 locale-aware 格式化的格式串。
R3. 同时搜本地化反模式：日期/时间未用 locale-aware 函数；数字格式无 locale 感知（`1,000` vs `1.000`）；文本嵌入图片或纹理（标记 `assets/` 资产文件）；假设 LTR 文本方向的串（位置布局、拼装顺序）；性别/复数假设硬编码进字符串逻辑（必须用复数形式或性别 token）；硬编码标点（如 `"You won!"`——感叹风格随地区变化）。报告带文件路径与行号；**只读不写**。

**Phase 2B extract**
R4. 扫源文件字符串引用，与现有表比对，为未 keyed 的串生成新条目。键名约定 `[category].[subcategory].[description]`（例：`ui.hud.health_label`、`dialogue.npc.merchant.greeting`、`menu.main.play_button`）。**每条新条目必须含 `context` 字段**——译者注释：出现位置（哪个屏幕/场景）、最大字符长度、占位符含义（`{playerName}` = 玩家自选显示名）、适用的性别/复数语境。
R5. 呈现新串 diff，问 "May I write these new entries to `assets/data/strings/strings-en.json`?"——批准后**只写 diff（新条目），绝不整表替换**。完成裁决：**COMPLETE**。

**Phase 2C validate（只读）**
R6. 读全部字符串表文件，每 locale 七查：**Completeness**（源 en 有 key 无译文）；**Placeholder mismatches**（源有 `{name}` 而译文漏掉或加多余的）；**String length violations**（译文超源 `context` 记录的字符上限）；**Plural form count**（该 locale 需要 N 个复数形式而译文只给了更少）；**Orphaned keys**（译文存在但 code root 无引用）；**Stale translations**（译文写完后源串改过——标记需重译）；**Encoding**（非 ASCII 字符且字体图集支持——不确定即标记）。按 locale 与严重度分组报告；只读不写。

**Phase 2D status（只读）**
R7. 计源表可本地化串总数、每 locale 计 translated/untranslated/stale，生成覆盖矩阵（含 String freeze 状态行：Active / Not yet called / Lifted）与 Issues 节（硬编码串数、超限数、占位符错配数、孤儿 key 数、freeze 违规数）。
R8. **矩阵每一格都必须从字符串表实取计数——源语言行也不例外**：禁止预填源 locale 为 `100%`（那是计数前断言结果；在无 `assets/data/strings/` 的项目上会为一个不存在的表产出覆盖报告）。**字符串表缺失 → 整个 status 输出 `NOT ASSESSED — no string table found`，不是带自信源行的全零矩阵**。

**Phase 2E brief**
R9. 读 `design/gdd/`（按节读）、`strings-en.json`、`design/narrative/`，生成 `production/localization/translator-brief-[locale]-[date].md`：**Game Overview**（2-3 段：类型/基调/受众）；**Tone and Voice**（Overall tone 如 "Darkly comic, not slapstick — think Terry Pratchett, not Looney Tunes" / Player address 如法语恒用 "tu" 不用 "vous" / Profanity policy 强度对齐源文不软化不升级 / Humour 如双关不可译时造等效本地笑点、禁止直译）；**Character Glossary**（Name/Role/Personality/Notes 含"不译/按 X 转写"）；**World Glossary**；**Do Not Translate List**（游戏名、与引擎内标签一致的 UI 术语、品牌/商标名——全 locale 逐字保留）；**Placeholder Reference**；**Character Limits**（硬限制在表 `context` 标注，未标注处以英语长度 **±30%** 为指引）；**Contact**（交付格式 JSON、同 strings-en.json schema）。问 "May I write this translator brief…?" 后写盘。

**Phase 2F cultural-review**
R10. spawn `localization-lead` 从字符串表与资产审六域：**符号手势**（thumbs up/OK 手势/剪刀手含义随地区变化；宗教符号；国旗/地图/争议领土）；**颜色**（白色在部分亚洲文化=丧、绿色部分地区=政治、红色=好运 vs 危险；警示色与文化联想冲突）；**数字**（4=日中谐音死、13、666——UI 房号/物品数/价格中的使用都要标）；**幽默习语**（习语译过去变冒犯；厕所/身体幽默在日、德、中东不妥；特定地区敏感话题的黑色幽默）；**暴力与内容分级**（DE/AU/CN/AE 会触发分级变化；血色/血腥度/毒品引用——需区域资产变体时全标）；**名称与表现**（角色名在目标 locale 冒犯/负面；国籍/宗教/族群刻板表现）。
R11. 发现以表格呈现：Finding / Locale(s) Affected / Severity / Recommended Action。严重度：**BLOCKING**（该 locale 发货前必修）/ **ADVISORY**（建议改）/ **NOTE**（仅供参考）。问 "May I write this cultural review report to `production/localization/cultural-review-[date].md`?" 后写盘。

**Phase 2G vo-pipeline**
R12. 四个子任务：`scan`——读字符串表与 `design/narrative/`，识别全部 `dialogue.*` 行及录制状态（`assets/audio/vo/` 有无音频），输出 Recording Manifest（Key/Character/Source Line/Status：Recorded / Needs recording）；`script`——每角色按场景分组生成录制脚本：角色名+性格简介、完整台词+生僻专名发音指南、**每行情绪/导演注**（`[Warm, welcoming]`、`[Annoyed, clipped]`）、对话应答行给上下文（"Player just said X"）；问 "May I write the VO recording scripts to `production/localization/vo-scripts-[locale]-[date].md`?"；`validate`——Glob `assets/audio/vo/[locale]/` 全部 `.wav`/`.ogg` 对照 manifest 报缺失/多余/命名违规；`integrate`——grep code root 的 VO 音频引用、验证每个引用路径存在，报断链。
R13. **VO 脚本必须带导演注**——光秃台词录出来是平的。

**Phase 2H rtl-check**
R14. RTL 语言（Arabic、Hebrew、Persian、Urdu）需要超出文本翻译的**布局镜像**；本模式验证实现。引擎取 `project.yaml` 的 `engine.name`（缺失/为空回退 technical-preferences）。检查四组：**Layout mirroring**——引擎 RTL 是否启用（Godot `Control.layout_direction`、Unity `RTL Support` 包、Unreal text direction flags）；容器是自动镜像还是硬编码坐标；进度条/血条/方向指示是否正确镜像。**Text rendering**——字体是否支持 Arabic/Hebrew 字符集；阿拉伯文连写（ligature）是否正确；需要处是否显示 Eastern Arabic numerals。**String assembly**——是否存在假设 LTR 阅读顺序的拼接；句子结构反转后 `{placeholder}` 位置是否仍正确。**Asset review**——带方向箭头/不对称的 UI 图标是否需要镜像变体；text-in-image 资产是否需要 RTL 版。
R15. Grep 检查模式：场景/prefab 中的引擎 RTL flag；任何 `HBoxContainer`/`LinearLayout`/`HorizontalBox` 节点查 layout_direction 设置；对话/UI 代码附近用 `+` 的字符串拼接。发现分 **BLOCKING**（不修内容不可读）与 **ADVISORY**（外观改进）。问 "May I write this RTL check report to `production/localization/rtl-check-[date].md`?" 后写盘。

**Phase 2I freeze**
R16. `freeze call`：先查 `production/localization/freeze-status.md`。已冻结 → 报 "String freeze is currently ACTIVE (called [date]). [N] strings have been added or modified since freeze. These are freeze violations — they require re-translation or an approved freeze lift."。未冻结 → 呈现 Pre-Freeze Checklist（全部计划 UI 屏已实现 / 全部对话行已定稿 / 系统串（错误信息、教程文本）齐备 / `/localize scan` 零硬编码 / `/localize validate` 源 (en) 无占位符错配 / 营销串（商店描述、成就）定稿），AskUserQuestion：`[A] Yes — call string freeze now` / `[B] No — I still have strings to add`。选 [A] 写 freeze-status.md：`Status: ACTIVE`、`Called: [date]`、`Called by: [user]`、`Total strings at freeze: [N]`、`## Post-Freeze Changes`（由 extract 自动续写）。
R17. `freeze lift`（参数含 `lift`）：问 "May I update `freeze-status.md` to LIFTED?" 后置 `Status: LIFTED` 并记录原因与日期；必须警告："Lifting the freeze requires re-translation of all modified strings. Notify the translation team."
R18. **freeze check（自动集成进 extract）**：extract 发现新/改字符串且 freeze Status 为 ACTIVE 时——必须在 extract 自己的 "May I write" 提问里点名 `freeze-status.md`、获批后把新 key 追加进 `## Post-Freeze Changes`，并警告 "⚠️ String freeze is active. [N] new/modified strings have been added. These are freeze violations. Notify your localization vendor before proceeding."

**Phase 2J qa**
R19. 本地化 QA 是译文交付后、任何 locale 发货前的专门 pass——**不等于 `/localize validate`**（validate 只查完整性），这是基于 playthrough 的结构化质检。spawn `localization-lead`，传入：目标 locale、游戏全部屏幕/流程清单（来自 `design/gdd/` 或 `/content-audit` 输出）、当前 validate 报告、cultural review 报告（若有）。
R20. QA 计划覆盖六项：① **Functional string check**——每串在游戏内显示无截断/占位符错误/编码损坏；② **UI overflow check**——译文超 UI 边界（即使字符限制内某些语言也会膨胀）；③ **Contextual accuracy**——10% 抽样在游戏内复查翻译准确与措辞自然；④ **Cultural review items**——cultural review 全部 BLOCKING 已解决；⑤ **VO sync check**——如有 VO，口型/字幕时间在译后可接受；⑥ **Platform cert requirements**——平台本地化要求（年龄分级文本、法律声明、ESRB/PEGI/CERO 文本）。
R21. 每 locale 输出 QA 裁决（Findings 表：LOC-ID/Area/Description/Severity/Status；Conditions 节；Sign-Off 节：全部 BLOCKING 已解决 + Producer 批准发货）。**首中即停（first match wins）**：任何 BLOCKING open → **FAIL**；否则有检查未能运行 → **NOT ASSESSED**（检查基于 playthrough——没人实际玩过的 locale、或译文未交付的 locale，不能凭字符串表通过；**必须逐个点名未运行的检查**）；否则仍有未解决 conditions → **PASS WITH CONDITIONS**；否则 **PASS**。**NOT ASSESSED 位次高于两个 pass 值**（没玩过的 locale 等于没通过）、**低于 FAIL**（open BLOCKING 绝不被埋没）。问 "May I write this localization QA report to `production/localization/loc-qa-[locale]-[date].md`?" 后写盘。

**Phase 3 规则与推荐工作流**
R22. **八条铁律**：英语 (en) 恒为源 locale；每条字符串表目必须含 `context` 字段（译者注、字符上限、占位符含义）；**绝不直接改译文文件——生成 diff 供审查**；字符上限按 UI 元素逐一定义并在 validate 强制；**发字符串给译者前必须冻结——绝不翻译移动目标**；RTL 支持必须从头设计——回头补 RTL 布局非常昂贵；凡商业销售的 locale 必须做文化审查；VO 脚本必须含导演注。
R23. 推荐顺序：`scan` → `extract` → `freeze` → `brief` → [发给译者] → `validate` → `cultural-review` → `rtl-check`（发 Arabic/Hebrew/Persian 时）→ `vo-pipeline`（发行配音时）→ `qa`。`qa` 对每个发货 locale 返回 PASS 或 PASS WITH CONDITIONS 后，跑 `/gate-check release` 时**附上 QA 报告路径**。

## 4. 门禁与裁决
- **子命令缺失门禁**：无子命令 → 输出用法即停，裁决 **FAIL — missing required subcommand**。
- **QA 裁决词**（每 locale）：PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL，取最严（首中即停）顺序 **FAIL > NOT ASSESSED > PASS WITH CONDITIONS > PASS**。
- **发布门禁（Gate integration）**：`workflow: full` 档 Polish → Release 门禁要求**每个发货的已翻译 locale** 有 PASS 或 PASS WITH CONDITIONS（`standard` 推荐、`minimal` 舍弃）。**FAIL 只阻塞该 locale**——其它 locale QA 通过仍可继续；**NOT ASSESSED 的 locale 没有通过**：它的 QA 没跑。
- 文化审查严重度：BLOCKING / ADVISORY / NOTE；RTL 检查：BLOCKING / ADVISORY。
- 其它 NOT ASSESSED 出口：code root 未解析（scan）、字符串表缺失（status）——见 R2/R8。

## 5. 移植建议
- **可直接移植**：R4-R5（键名约定 + context 字段 + 只写 diff）、R6（七项译文校验）、R8（未解析根/缺表报 NOT ASSESSED 而非零值矩阵）、R9（译者语境简报模板——语气/称呼/双关策略/不译清单/±30% 长度指引）、R16-R18（字符串冻结协议与 freeze 违规告警）、R21（QA 首中即停与位次）、R22（八条铁律几乎全部与游戏无关）。
- **需替换概念**：游戏字符串表 (strings-en.json) → UI 文案/消息文案的 i18n 资源文件（ICU、JSON、gettext .po）；`tr()`/`NSLocalizedString` → 项目实际 i18n API；VO 配音 → 语音助手播报/视频字幕轨；RTL 布局检查 → 双向排版（Bidi）与镜像布局检查；`/gate-check release` → 产品发布检查清单；localization-lead → 本地化负责人角色。
- **改写示例**：
  - "提取用户可见文案入表时，每条必须带 `context` 字段（出现位置、字符上限、占位符含义），键名遵循 `[域].[子域].[描述]`；写入只允许增量 diff，禁止整表替换或直接改译文文件。"
  - "外部翻译启动前必须冻结源文案（写 freeze-status.md，Status: ACTIVE）；冻结后的任何新增/修改都是 freeze violation——必须在写入提问中点名状态文件、追加变更记录并向用户告警，直到获得批准的 freeze lift。任何覆盖率/质检输出在输入缺失（代码根未解析、文案表不存在、无人实跑流程）时一律记 NOT ASSESSED，禁止以零值或通过口径呈报。"

## 6. 关联文档
- 上游：`/content-audit`（屏幕/流程清单来源）、GDD 与 `design/narrative/`（语境来源）
- 下游：`/gate-check release`（附 QA 报告路径；`workflow: full` 档 PASS/PASS WITH CONDITIONS 为硬要求）
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/code-root-resolution.md`、`.claude/docs/technical-preferences.md`
