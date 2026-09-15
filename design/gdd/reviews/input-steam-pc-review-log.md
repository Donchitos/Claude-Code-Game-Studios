# Steam PC Input — author review log

## Review — 2026-09-11 — solo — Verdict: NEEDS REVISION (evidence gates pending)

Scope: `input-steam-pc.md`及本次profile传播；design-review技能solo模式，仅作者自查。Specialists consulted: none。Senior Verdict: not requested/not issued。不能用本条代替clean-context full re-review。

- Completeness: 8/8 required sections，PC01–PC10共10个AC；PC01–09本地证据与PC10设备证据分开。
- Dependency graph: InputSystem、GameRoot、PlayerController、BattleUI GDD、ADR-0004/0005、生产config均存在；Home/Settlement由GameRoot UI dispatcher接入。无`design/gdd/game-concept.md`或`design/narrative/`可额外读取。本次不改战斗数值、自动攻击或剧情规则。
- Consistency: 键盘held优先包含抵消ZERO；径向闭死区只判断一次，d按Vector2 real_t精度比较；补帧重新采样。profile声明已向Input/Player/BattleUI/GameRoot/technical preferences/index传播。
- Required before release: [author] PC06真实设备选择、hotplug、Steam remap和PC10物理输入未执行；PC09只有macOS截图而非Windows显示验收；PC workload只有无设备idle和密集战斗本地测量，min-spec/分配/长时性能未通过。
- Remaining full-contract work: [author] PC context只绑定Input→Player，不是完整七phase、Save durable identity、native typed UI command；7001仍为受验证Dictionary adapter。独立评审需裁定该profile边界，不能据本实现宣布原full blocker全部关闭。
- Recommended: 将真实多控制器/设备映射、输入异常与reentrant边界加入回归；没有这些证据时保留PARTIAL。Mobile ASN上界修正为21−4+7=24，但generated/native依然未验证。
- Specialist disagreements: 不适用，无specialist参与。Rough scope signal: L，producer应再确认。

作者整改继续执行用户已授权的证据记录与导出；不新增批准门，不自批准系统。


## Review — 2026-09-11 — Post-remediation Clean-context Full — Verdict: MAJOR REVISION NEEDED

Specialists: 三个真实独立分组（game+systems、Godot/GDScript+performance、UX/UI/accessibility+QA），全部返回后由fresh creative-director综合。两主目标均8/8节；35个IS AC、10个PC AC。PC修订范围信号L、完整合同XL（协调者估计）。

PC05 FAIL：resume尾段hide_modal同步回调失焦后被ACTIVE提交覆盖，回焦无需Continue即可推进tick。PC07 FAIL：升级modal按默认Up，焦点外泄到PauseButton。均有Godot 4.7.1 headless探针和原始日志，不是Windows物理设备证据。未知joy South绕过假设未复现，已撤回。

B1 profile裁定/运行隔离关闭，传播PARTIAL；B2常规输入整改成立，real_t边界与抵消generation待修；B3局部lease成立/完整ABI OPEN；B4移动future-port；B5 REOPENED；B6跨局identity局部关闭/modal FAIL；B7 ASN 21−4+7=24算术关闭，generated/native未关闭；B8 Windows/发行workload OPEN。

P2还包括neutral反馈遗漏、具体binding/default GUI测试覆盖与多界面显示证据不足。完整报告和覆盖声明：production/playtest-evidence/2026-09-11-pc-input-independent-review.md。复审未修改生产代码；历史作者测试不冒充本次重跑。系统保持In Review / Re-review Pending，battle_ready=false。继续用户授权的性能A/B与Windows证据检查，未将review转换为代码整改或批准。


## Authorized P1 remediation — 2026-09-11 — Re-review Pending

用户授权修复R1/R2。GameRoot恢复事务锁及逐可重入边界identity/state/focus复核，Input在hide_modal/focus期间FROZEN，失效退回暂停且回焦不自动继续；modal背景pause禁用focus，默认GUI旁路移除，拒绝设备/release/echo同样消费。

六边界恢复回归71 checks在headless/图形均PASS；Meta36/40、输入81 checks通过。25项integration脚本正常退出（24PASS、1图形专属SKIP），旧两个探针复跑不再出现原反例。两尺寸暂停PNG已查看。新版Windows验证包为build/windows-pc-input-p1-fixed，PCK SHA256 2e106d23c3a22db1e41fa0c513968aa30c3980f538d307a9a8632cdc9985573e；导出与macOS PCK启动、ZIP完整性通过，Windows实机仍NOT_RUN。

本条是作者整改，不覆盖前一独立MAJOR REVISION NEEDED；R3–R8及完整ABI/Windows/性能门保持OPEN，battle_ready=false。详见production/playtest-evidence/2026-09-11-pc-input-p1-fix.md。


## Review — 2026-09-11 — R3–R8 Clean-context Full — Senior: APPROVED WITH ADVISORIES (local STEAM_PC scope)

三真实独立工作组（game/systems、Godot/GDScript/performance、UX/UI/accessibility/QA）全部返回后由fresh creative-director综合。R3转换后配置域、R4抵消generation、R5指定profile传播、R6neutral提示、R7exact binding oracle与R8六面双尺寸覆盖CLOSED；R1/R2本地回归CLOSED。没有新确认P1/P2。整体InputSystem保持In Review，battle_ready=false；本条不批准全部PC AC或Windows发行。

本地profile99/Meta134/reentry71/surfaces127通过，实际macOS图形surfaces139通过；全量26脚本25PASS/1图形SKIP。独立组另有21/24/11/11 checks的数值/生命周期/替换探针，范围见原始报告。P3极小合法deadzone下length下溢OPEN；旧摘要P3作者已更正，但保留senior被审快照。完整ABI、设备、任意分辨率与性能预算未关闭。

详见production/playtest-evidence/2026-09-11-pc-input-r3-r8.md与pc-input-r3-r8-2026-09-11/review-director.md。新Windows包导出及macOS PCK boot/ZIP CRC通过，Windows实机NOT_RUN；PCK SHA256 d21ce17a010ff9cc9d52ed1847dd56c49ffbda1bd91d0f73fd4d3c8f2fa86bb9。历史verdict保留为对应快照，不继续把其R1–R8状态当当前结论。
