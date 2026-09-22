本独立工作组覆盖 **game-designer + systems-designer 两个领域，是一个真实 agent 工作组**。就原问题定义，**R3、R4、R5均可关闭**；本范围未发现新增 P1/P2。保留两项 P3 建议，不据此重开原 P2。R6–R8由相应专家裁定，本报告不替代 senior verdict。

| 条目 | 裁定 | 独立依据 |
| --- | --- | --- |
| R3 real_t 配置域 | **CLOSED（原反例）** | [input_system.gd:38](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/input_system.gd:38) 在绑定 carrier、context、reader 和开启 callbacks 前验证转换后阈值；`0.999999999→1`、`1e-50→0`均被拒绝，保持 UNARMED、carrier=null、callbacks=false。 |
| R4 抵消 generation | **CLOSED** | [input_system.gd:112](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/input_system.gd:112) 将 source epoch 与 ZERO carrier 分离。同一键盘 epoch 抵消时保留 source/generation，carrier generation=-1；完全释放或来源退休后的非零输入才增代。 |
| R5 PC/mobile传播 | **CLOSED（指定两处）** | [input-system.md:426](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/design/gdd/input-system.md:426) 明确 move_* 仅 WASD、PcInputSource 独立采轴；[input-system.md:558](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/design/gdd/input-system.md:558) 将 STEAM_PC 无 VJ/Shield 后置条件与 MOBILE_TOUCH 路由分开。 |

**独立运行证据**

使用本机 Godot `4.7.1.stable.official.a13da4feb`，仅运行 headless 临时 fixture，未修改生产、现有测试或报告。

- [独立 fixture](/tmp/pc-rules-review-20260911.gd)
- [最终原始日志](/tmp/pc-rules-review-20260911.log)
- 结果：`PC_RULES_REVIEW checks=21 failures=0`；最终运行无 ERROR/SCRIPT ERROR。

八次采样的 source/generation 轨迹：

| 输入条件 | source | generation | carrier generation |
| --- | --- | --- | --- |
| W；手柄同时向右 | KEYBOARD | 1 | 1 |
| W+S；手柄仍向右 | KEYBOARD | 1 | -1 |
| 松 S，保留 W | KEYBOARD | 1 | 1 |
| 松开全部键盘；手柄仍向右 | GAMEPAD | 2 | 2 |
| W+S；手柄仍向右 | NONE | 2 | -1 |
| 松开全部键盘；手柄仍向右 | GAMEPAD | 3 | 3 |
| 所有来源中立 | NONE | 3 | -1 |
| 新 W | KEYBOARD | 4 | 4 |

这独立验证了原抵消反例、直接 source switch、从其他 source 进入抵消 ZERO、完整中立再输入；不是仅复读作者测试结果。输入为可控 reader 合成采样，**不是物理键盘/控制器事件证据**。

**建议项**

1. **[P3][systems-designer] 允许的极小 deadzone 域存在长度下溢。**  
   位置：[input-steam-pc.md:28](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/design/gdd/input-steam-pc.md:28)、[input_system.gd:109](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/input_system.gd:109)、[pc_input_source.gd:35](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/src/input/pc_input_source.gd:35)。  
   新独立数值探针：`d=1e-30`初始化成功，`j=(1e-25,0)`的有效 real_t 分量明确大于 d，但 `Vector2.length()` 下溢为零，因此输出 ZERO。公式的 scale-first 保护在半径比较之后，不能保护这一步。建议约束可调死区的现实下界，或为长度比较采用稳定数值算法。默认 `0.20`不受影响；没有证据表明真实 mapped controller 能产生这类轴值，故按低优先级数值域建议处理，**不重开 R3 原缺陷**。

2. **[P3][game-designer + systems-designer] 当前摘要仍把作者已实施整改写成尚待推进。**  
   [input-system.md:5](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/design/gdd/input-system.md:5) 仍称“R3–R8及独立复审仍待推进”，与当前正文、代码和 ADR 的整改补充不一致。建议改为“R3–R8作者整改完成，独立复审待裁定”。`In Review / Re-review Pending`和历史独立 verdict 应继续保留。历史 P1 报告不要求回写。

**设计、消费边界与 AC 判断**

- 主目标八个必需章节齐全。满速转向、抵消即时停止、禁止旧输入跨恢复继续移动，与 Player Fantasy 一致；没有发现本次整改改变移速或自动攻击数值。
- [ADR-0005:50](/Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios/docs/architecture/adr-0005-release-input-profiles.md:50) 已传播转换后阈值域及 keyboard epoch 语义。
- Player 消费端检查绑定对象身份、open/retired/consumed、lease、written_tick、finite/unit/ZERO generation 等；本次 generation 修复没有改变位置消费接口或要求 Player 重新解释 ZERO epoch。
- PC01–PC03 的配置、阈值、抵消、neutral barrier与首恢复 tick 条件均可拆成独立 oracle。恢复首 tick ZERO 与 held 持续阻断应继续分别取证；本独立 fixture **没有覆盖整个 PC03**。
- PC04 的各类旧 identity/lease 与位置零修改仍须分项验证；读取消费检查不等于完成这些运行矩阵。
- 本组没有重跑现有完整 profile/integration 测试，没有查看本轮 UI 图片，也不裁定 PC07/PC09 或 R6–R8覆盖闭合。
- Windows、完整七 phase、Save durable identity和发行性能不在本轮关闭范围。

**实际阅读范围**

全文读取：design-review skill、CLAUDE.md、PC 输入规格、ADR-0005、上一轮独立报告、P1 修复报告、PC review log、ProductionInputSystem、PcInputSource、PcMovementContext、PlayerController、MovementIntentCarrier、现有 PC profile 测试。针对性读取：InputSystem 的 profile 路由/PC传播/Integration Gates与最新 review log、BattleScope 输入—Player消费链、GameRoot设备失效入口、引擎 VERSION、中文 MVP 的产品形态/操作与战斗支柱片段。

依赖核查确认 GameRoot、PlayerController、BattleUI、Home GDD及 ADR 文件存在；Settlement 在该切片由 GameRoot UI dispatcher承接，本组未将其视为一个声称存在的独立 `settlement-ui.md`。标准 game-concept/narrative 缺失是既有情况，不作为新增 R3–R8 blocker。

内存仅用于提醒区分历史 slice 与当前生产证据；所有本轮关闭结论均依据当前文件与新增运行结果。

<oai-mem-citation>
<citation_entries>
MEMORY.md:162-171|note=[kept historical slice evidence separate from current production review]
</citation_entries>
<rollout_ids>
01a08544-4656-7522-b1d1-98636bfc83bf
</rollout_ids>
</oai-mem-citation>

归档补充：独立 fixture 与原始日志已分别复制至 `production/playtest-evidence/pc-input-r3-r8-2026-09-11/independent-rules.gd.txt`、`production/playtest-evidence/pc-input-r3-r8-2026-09-11/independent-rules.log`；本步骤仅归档，不构成新的审查或测试。
