# PC 输入整改后独立 full 复审

## 结论与基线

**Senior Verdict: MAJOR REVISION NEEDED。PC05、PC07 FAIL；In Review / Re-review Pending，battle_ready=false。**

目标：`design/gdd/input-system.md` 与 `design/gdd/input-steam-pc.md`，以及相关实现和依赖合同。基线为 `e45f1350757bb8e217199444fe4adff51217e570` 加已有未提交 PC 整改。复审期间生产源码与配置未变；文件 SHA256 清单见 `pc-input-review-2026-09-11/source-hashes.json`。

依据仓库 `.claude/skills/design-review/SKILL.md` 的 full 流程，三个真实独立、无作者会话上下文的专家分组并行取证，全部完成后由 fresh-context creative-director 综合。没有将分组中的每个角色冒充为单独 agent。

| 独立任务 | 专家域 | 阅读及新增验证 |
| --- | --- | --- |
| `/root/review_game_systems` | game-designer、systems-designer | 两个主目标全文；相关 GDD 针对性；输入与 Player 源码全文；数值转换验证 |
| `/root/review_engine_performance` | Godot、GDScript、performance | 两个主目标和生产输入链源码全文；相关 GDD 针对性；真实 setter 重入 fixture |
| `/root/review_ux_qa` | UX、UI、accessibility、QA | 两个主目标、BattleUI/GameRoot GDD 全文补读完成；两张暂停截图查看；默认 GUI 导航 fixture |
| `/root/review_creative_director` | senior synthesis | 全部专家结论、补读声明及协调者直接提供的 ADR/PC/历史 blocker 原文；未自行重跑测试或声称独立读取全部文件 |

结构检查：两主目标均 8/8 必需章节；原 IS 有 35 个 unique AC，PC 有 10 个 AC。GameRoot、PlayerController、BattleUI 依赖 GDD 均存在。标准 `game-concept.md` 与 `design/narrative/` 缺失，仓库有既有中文 MVP 概念文档；这不是本次新引入的 broken dependency。

## 必须关闭的问题

### R1 / P1：恢复尾段的重入失焦被 ACTIVE 提交覆盖

来源：Godot/GDScript 专家；creative-director 确认。

`src/core/game_root.gd:304–315` 仅在 unpause 后复核焦点。`current_battle.resume()` 已打开 Input，随后 `hide_modal()` 会触发同步 visibility/focus 回调；外层没有再检查，直接提交 BATTLE_ACTIVE。此时 focus-loss handler 在 RESUME_PREPARING 不调用 pause，导致恢复返回成功且 tree 未暂停。只回焦即可再次推进 tick，违反显式 Continue 合同。

实际 Godot 4.7.1 headless fixture：正常开始、暂停，将 overlay.visibility_changed 一次性连接既有 focus-loss handler，再 resume、回焦和单个 physics tick。

```text
REENTRY_AFTER_RESUME status=0 focused=false tree_paused=false root=3 input=2 ingress=true ticks=0
REENTRY_AFTER_REFOCUS focused=true tree_paused=false root=3 input=2 ticks=1
```

root=3 为 BATTLE_ACTIVE，input=2 为 ACTIVE。`pc-input-review-2026-09-11/pc_resume_reentry_review.gd` 与同名 `.log` 为原始证据。退出码 0 表示探针执行成功，不表示被审实现通过。真实 setter 信号加合成 focus 回调，不是 Windows AltTab 实测。

关闭标准：所有可重入呈现/focus 操作后复核原 revision、focus 和 state；失败关闭 Input 并安全收敛到暂停；回焦后 tick 不得推进，直到新的显式 Continue。覆盖 visibility、focus 与 gate release 边界。**PC05 FAIL。**

### R2 / P1：升级 modal 焦点可进入背景暂停按钮

来源：UX/UI/QA 专家；creative-director 确认。

`src/core/game_root.gd:137–147` 只消费自定义映射，Godot 默认 ui_up/ui_down 仍可走 GUI；`src/ui/battle_ui.gd:67–85` 开 modal 时未把背景暂停按钮移出焦点域。

真实 Godot headless 注入两次一致：初始 Choice0 → KEY_UP → PauseButton；KEY_DOWN 才返回 Choice0/Choice1/Choice2。见 `pc-input-review-2026-09-11/pc_ui_bypass_review.gd` 与同名日志。不是物理键盘验收。

关闭标准：modal 背景控件退出焦点域，默认导航与应用 dispatcher 收敛；覆盖 Up/Down/KpEnter、背景焦点和单次激活。**PC07 FAIL。**

未知手柄 South 绕过仅为被检验的假设：device 919 注入后仍 HOME、generation=0，未复现，已撤回，不列为缺陷。

## 其它修订与建议

| ID | 等级 | 位置/事实 | 关闭方向 |
| --- | --- | --- | --- |
| R3 | P2 | input_system.gd:33–35,51：float64 校验后转 real_t 未再校验；0.999999999→1.0，1e-50→0.0 | 验证转换后的合法域，补边界 fixture；当前默认0.20不触发，数值证据不是Godot运行证明 |
| R4 | P2 | input_system.gd:108–117：W保持→加S抵消→松S会generation++，无完整中立或物理source变化 | source 与非零输出状态分离，冻结序列 oracle；当前未证实位置错误 |
| R5 | P2 | input-system.md:426,558：仍称move action注册mapped轴和PC UI→Shield→VJ | 同步独立轴与零VJ，分开IG-IS4的PC/mobile后置条件 |
| R6 | P2 | battle_ui.gd:70,80,88–90,125：neutral说明仅普通暂停可见 | 升级恢复、active hotplug等待时条件性提示，解除后消失 |
| R7 | P2 | pc_meta_input_test.gd:35–36,56–65：仅binding数量，未覆盖默认GUI入口 | 比较具体事件/modifier/额外binding，增加默认导航反例 |
| R8 | P2 | pc_meta_input_test.gd:74–84：PC09只有普通暂停/Continue矩形 | 覆盖Home/升级/Settlement/active neutral×尺寸，Windows另记 |

推荐增加 PC 穿缝/反向操作的玩家体验 oracle。MOBILE_TOUCH F1 中 finite/gate 优先级的相反旧句仅作为 future-port 待办，不能升级为本次 PC blocker。

## 历史八组关闭矩阵

| 组 | 本轮裁定 |
| --- | --- |
| B1 profile/双采样/触控正文 | PC裁定与运行隔离 CLOSED；传播 PARTIAL（R5） |
| B2 deadzone/generation/多tick复用 | PARTIAL：常规路径整改成立，R3/R4待修 |
| B3 七phase/lease/typed identity | PARTIAL：PC局部lease成立；完整七phase/barrier/Save durable identity OPEN |
| B4 UI/VJ/Shield/resize | PC N/A；MOBILE_TOUCH FUTURE-PORT OPEN |
| B5 pause/background/resume | REOPENED：R1覆盖正常流程静态结论 |
| B6 Meta/typed UI/跨局ABA | PARTIAL：跨局identity局部关闭；R2未关闭；完整native typed UI未关闭 |
| B7 ASN/manifest/oracle | PC隔离与ASN算术 CLOSED；完整generated/native部分未关闭；21−4+7=24，28为union，不能恢复历史必然溢出判断 |
| B8 Windows/输入workload | OPEN：物理设备及发行性能证据未完成 |

## PC AC 证据状态

| AC | 状态与边界 |
| --- | --- |
| PC01 | 本地有限支持，未知任意profile字符串未独立断言 |
| PC02 | 本地数学fixture支持；新增real_t配置极值待补 |
| PC03 | PARTIAL；首恢复tick需与held持续ZERO独立断言 |
| PC04 | PARTIAL；hitch/closed lease有证据，逐类旧identity/lease位置不变oracle不全 |
| PC05 | FAIL，R1引擎内反例；不是Windows结论 |
| PC06 | PARTIAL；设备选择/多控制器/hotplug/remap未完成 |
| PC07 | FAIL，R2默认导航反例 |
| PC08 | 局部PASS，第二局首击/旧局/duplicate，不是native/物理设备 |
| PC09 | PARTIAL，仅已有两尺寸普通暂停截图已查看 |
| PC10 | NOT_RUN，Windows物理设备门 |

此前24项headless、81 checks、Meta26/30均为作者记录；本次新增验证仅上述探针，不将其表述为全部重新执行。Input P95=2.516us是128tick批均摊百分位，含lease/Player且零控制器idle，不能替代单tick尾延迟、物理设备或allocation证明。

## 分歧与后续

系统专家的正常流程静态 B5 CLOSED，在收到 R1 运行证据后明确改为 PARTIAL/OPEN；B6 identity 局部关闭与 modal FAIL 并存。两个 P1 优先于结构完整和常规路径通过。Mobile未来证据不再泛化阻断Steam，但当前PC自身仍有两个确认缺陷。

粗略范围信号：当前PC修订 L；完整跨系统合同 XL（协调者规划估计，非新增架构裁定）。

按用户既有授权继续第二步同环境性能 A/B，再第三步 Windows 实机可用性与证据检查。本轮复审不自动实施代码整改，不能自批准；Windows物理实测、完整ABI、性能与商业原创化保持各自独立门。

后续执行已完成本机可执行部分：性能A/B及Windows包检查见 `2026-09-11-pc-input-performance-ab.md`；实机仍NOT_RUN。
