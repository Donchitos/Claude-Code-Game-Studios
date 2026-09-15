**Senior Verdict [creative-director]：STEAM_PC 的 R3–R8 局部整改 APPROVED WITH ADVISORIES；R1/R2 本地回归 CLOSED。整个 InputSystem 继续 In Review，`battle_ready=false`。**

本裁定只关闭上一轮报告中 R1–R8 的指定缺陷及覆盖缺口，不批准 Windows 发售，也不关闭完整七 phase、持久 identity、native ABI 或 MOBILE_TOUCH 的既有开放项。

已全文读取 PC 输入规格、三份专家报告、上一轮独立报告、P1 修复报告、CLAUDE.md 和 ADR-0005，并定向检查当前 InputSystem、PcInputSource、Meta dispatcher、GameRoot 恢复事务、BattleUI 及两处 PC/mobile 传播条款。已查看十二界面 contact sheet，并核对新增独立探针日志；本 senior reviewer 没有重新执行测试。

参与综合的是三个真实独立工作组：game/systems、Godot/GDScript/performance、UX/UI/accessibility/QA。领域标签不代表额外独立 agent。

| 条目 | Senior 裁定 | 关闭依据与边界 |
|---|---|---|
| **R1 / P1 恢复重入失焦** | **CLOSED，本地回归** | 恢复事务锁禁止嵌套 Continue 和事务内 gameplay tick；Input 在呈现与焦点操作期间保持关闭，gate acquire、unpause、hide/focus、release 后检查 battle identity、state、focus revision。六边界 71 checks 通过；独立 release→结束、release→替换探针各 11 checks 通过。旧恢复尾段未覆盖终止或新局。合成 focus 不等于 Windows AltTab。 |
| **R2 / P1 modal 焦点外泄** | **CLOSED，本地回归** | modal 背景 pause 明确 disabled＋FOCUS_NONE，关闭后恢复；BOOT 清除规格外默认 GUI 绑定，显式绑定的拒绝设备、release、echo 仍被消费。Godot 事件注入未复现 Up/Down/KpEnter 外泄，规范内导航及单次选择通过。 |
| **R3 / P2 real_t 配置域** | **CLOSED，原反例** | 转换后再次验证阈值，并早于 carrier/context/reader 绑定及 callback 开放；`0.999999999→1`、`1e-50→0` 被拒绝。极小合法阈值下的长度下溢另列 P3，不宣称全部合法数值域已证明正确。 |
| **R4 / P2 抵消 generation** | **CLOSED** | keyboard epoch 与 ZERO carrier 分离；W→W+S→W 保持同代且抵消 carrier generation=-1。完全释放、跨来源、从手柄进入抵消 ZERO 后再恢复等独立序列成立；generation 耗尽探针确认返回错误并清零。 |
| **R5 / P2 PC/mobile 传播** | **CLOSED，指定传播点** | 原两处冲突现明确为 move_* 仅 WASD、mapped 轴独立采样，以及 PC 零 VJ/零 touch bank、Meta dispatcher 路由；MOBILE_TOUCH 后置条件单列。不是对整篇移动合同的全面一致性批准。 |
| **R6 / P2 neutral 等待提示** | **CLOSED，本地范围** | GameRoot 只读 Input owner 的 `neutral_required`；HUD、普通暂停、升级 modal 和 active topology 等待路径均有提示及解除断言。UI 不重新采样、不清输入门。 |
| **R7 / P2 exact binding 与旁路覆盖** | **CLOSED，本地范围** | 独立预期表核对八行 Meta＋P/R 的键码、修饰键、事件数、deadzone、手柄按钮及 wildcard device；默认 GUI 路径和未知设备、echo 有事件级检查。已知非零物理 device 的实际接受路径仍待设备验证。 |
| **R8 / P2 多界面显示覆盖** | **CLOSED，现有本地图形范围** | Home/Active/Pause/Upgrade/Active-neutral/Settlement × 1280×720、960×540 共十二图；headless 几何、焦点、提示等 127 checks 通过。UX 组查看 contact sheet 及两张小尺寸原图；senior 查看 contact sheet，未发现需要推翻其裁定的遮挡。仅支持指定两个同宽高比尺寸。 |

两个 P3 **均不阻断上述局部关闭**：

1. **[systems-designer；creative-director 同意] 极小 deadzone 下长度计算下溢。** 独立日志确证 `d=1e-30` 初始化成功，`j=(1e-25,0)` 分量大于 d，但 `length()` 为零并输出 ZERO。该问题同时涉及移动判定及中立判定使用的长度计算；末端 scale-first 归一化不能保护此前比较。它是真实数值边界缺陷，应保留建议项，不能写成“所有合法配置均正确”。当前默认 `0.20` 不受影响，现有证据没有证明实际控制器会产生该量级轴值，因此不将其升级为当前配置的 P1/P2。后续应约束合理配置下界，或使用稳定长度比较，并补移动/neutral 两条路径的 oracle。

2. **[game-designer + systems-designer；creative-director 同意] InputSystem 头部进度摘要陈旧。** “R3–R8仍待推进”与当前实现、正文和 ADR 补充不一致。它不改变 runtime 行为，也没有推翻 R5 指定两处传播完成的事实。后续记录应区分“本轮 R1–R8 局部独立关闭”与“总体仍 In Review”，保留上一轮历史 verdict，不回写抹去历史失败证据。本次只读评审没有更新这些文件。

证据足以关闭指定问题，但不支持将 PC01–PC10 全部标记 PASS。专家独立执行了 profile 99、Meta 134、resume 71、surfaces 127 checks；新增 rules 21、source 24、结束及替换各 11 checks 提供额外反向覆盖。这些结果按各脚本范围解释，重复运行不累计成更广覆盖。图形截图来自既有本轮采集，专家和 senior 的查看不等于重新运行图形采集。

以下遗留项继续保持原状态：

- **Windows PC10 / 物理设备：NOT_RUN 或 OPEN。** 包括物理 WASD、mapped 控制器、实际断连重连、多设备、Steam Input remap、真实焦点切换及 Windows 导出后完整菜单旅程；应绑定最终 EXE/PCK hash。
- **完整集成与 ABI：OPEN。** 包括七 phase/barrier、Save durable identity、generated/native typed UI；PC 局部 context/lease 不能替代。
- **其余 AC 证据缺口：继续追踪。** 不因 R3/R4 关闭就自动补齐 PC03、PC04、PC06 所有未覆盖 oracle。
- **当前版本性能：未验收。** 只读 UI 更新的静态成本判断不是单 tick 尾延迟、allocation、真实控制器负载或发行帧预算证明；旧 A/B 不迁移为当前源码验收。
- **MOBILE_TOUCH 与原生无障碍等 future-port：保持开放。** 不以本次 PC 关闭倒推通过。
- **两项 P3：保留 advisory。** 其中数值域问题是真实限制，状态摘要问题是记录维护。

主 PC 规格八个必需章节齐全；GameRoot、PlayerController、BattleUI、Home GDD 和 ADR 文件存在，Settlement 由现有 GameRoot 路由承接。三个专家组没有相互冲突的结论：引擎组对 R8 仅签署几何/引擎部分，UX 组补足现有截图检查，属于证据互补。

**[creative-director] 最终判断：本次指定整改已消除上一轮 R1–R8 的关闭障碍，没有确认新增 P1/P2。允许关闭这些局部条目；总体仍 In Review，不能据此标记整个 InputSystem Approved、全面 implementation-ready 或 `battle_ready=true`。** 局部剩余建议的粗略范围信号为 S；总体遗留工作保持跨系统范围，需另行规划与验收。

<oai-mem-citation>
<citation_entries>
MEMORY.md:162-169|note=[kept historical slice evidence separate from current PC closure and overall readiness]
</citation_entries>
<rollout_ids>
01a08544-4656-7522-b1d1-98636bfc83bf
</rollout_ids>
</oai-mem-citation>

归档补充（不改写以上被审快照）：协调者告知，作者在本次审查期间已将 input-system.md 头部更新为“作者整改完成/复审裁定中”；以上原 P3 记录保留为被审快照，作者将在汇总中单独记录摘要已更新。本步骤仅原样归档及记录该后续说明，不构成重审，未修改源码。
