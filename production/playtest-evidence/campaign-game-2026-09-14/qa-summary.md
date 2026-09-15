# 独立QA实现与旅程验证 — 2026-09-14

结论：本轮自动化实现验收 PASS；没有剩余已复现的功能 blocker。该结论不代表商业完整性、20小时体验、Windows/Steam认证或人工手感验收。

## 最终版本与范围

- 原始目录 SHA256/content_hash：`71d615925151600c8a1255808f20a03d5d44f5fa4efd9f047874e231f45949ca`。
- 最终源码/测试 SHA256 见 `qa-final-hashes.json`。64顺序进程开始17:34:47，Arena/Combat/Codec最后修改分别17:34:36/17:33:45/17:32:38；实际使用最终冻结战斗源码。
- 唯一作者写集：两个integration脚本与本目录qa-*。没有修改生产源码、生产数值、存档服务或其他worker测试。
- 合成夹具与原始目录旅程分开：前者缩短目标/降低敌HP/加快XP，后者保留原始HP、伤害、任务时长和完整目录。没有直接写finished、victory、completed或伤害结果。

## 最终运行结果

| 测试 | 实际结果 | 证据 |
|---|---:|---|
| journey：六目标、24主动、24辅助、构筑、事件、root磁盘旅程 | 286/0 | qa-journey-final.log / qa-journey.json |
| snapshot：严格恢复及反例 | 301/0 | qa-snapshot-final.log / qa-snapshot-safety.json |
| 原始目录新档64顺序旅程 | 275/0，64/64胜利 | qa-production-sequential-r1.log / qa-sequential-matrix.json |
| 独立复跑战斗worker自然进化路径 | 287/0 | qa-combat-independent.log |
| root单独退出清理复查 | 46/0，无leak错误 | qa-root-final.log |

- 六类目标全部用configure/advance/移动/自动攻击/合法选择达成真实胜利，并验证terminal snapshot。SURVIVE/CLEANSE/ESCORT有离开目标区域不能只靠计时胜利的反例。
- 24主动逐项造成真实伤害；24辅助经真实XP选择获得，与amount=0对照组执行相同刺激并比较模拟输出。拾取半径用85距离（70~95之间）；炮塔距离用相对炮塔475（450~500之间）；雪旗宽度用半径90、敌半径18、中心114（108~121.5边界之间）。其余辅助覆盖控制、标记、伤害、冷却等对应刺激；这些是隔离机制证据，非所有构筑平衡证明。
- 构筑测试实际消费40+次合法选择，验证三选候选去重、4+4槽、5级上限、进化5+5要求；safe/risk资源或压力不同、不能重复消费。
- 普通快照、已有pendingchoice快照及合法A07→A04非字典序/自然同tick冷却到期场景，JSON往返后下200实际tick逐步canonical(snapshot)完全相同。未放宽为epsilon；连续pending级别先在两侧消费同一合法选择，再计实际tick。
- hash/mission/必要字段/非法数值/容量、合法但不同角色/分支/初始seed、numeric_bits缺/多节点/NaN/Inf/镜像不符/decoded负subnormal跨HP0边界均拒绝；语义攻击重建匹配bits，避免仅测到镜像不同而漏掉decoded验证。
- root在真实待选升级时写独立双槽文件→退出→新root/profile/storage重新打开→保持pendingchoice与RNG→同输入/choice续200tick exact→真实首胜结算→重复finish不增加奖励→下一任务解锁。最终正常savehome、audio.shutdown、释放并等待音频清理；最终日志无ObjectDB/resource泄漏错误。
- 独立复跑自然进化：原始目录、首角色、新档completed0、seed42，25.55秒/22击杀/等级11/HP160，A01与P01各5级后选择V01；不修改HP/XP/敌人。这条路径不是完整20小时玩家试玩。

## 真实新档顺序链路

- 从空Profile和空双槽开始；每关begin_run从持久化元数据配置Arena，胜利必须来自真实advance，然后finish_run实际结算，下一关才解锁。只使用已挣得奖励购买分支，未改completed/奖励/关卡数据。首角色、普通难度、无丹药，safe事件选择。
- 第8/16/24/32/40/48/56/64关后关闭storage并重开磁盘，比较完整Profile相等。最终completed=64且ending_seen=true。章节绑定与累计时间见qa-sequential-chapters.json。
- 两个磁盘QA文件对仅在本evidence目录，运行前删除同名旧测试文件，运行后保留最终快照便于审计；未访问真实user://玩家档：qa-root-a.save / qa-root-b.save、qa-sequential-a.save / qa-sequential-b.save。

### 第一章（64顺序链路的实际前八关）

| 任务 | 实际模拟秒 | 结束等级 | 合法选择数 | 击杀 | 结果 |
|---|---:|---:|---:|---:|---|
| S1-M01-01 | 72.18 | 13 | 12 | 82 | 胜利 |
| S1-M01-02 | 12.62 | 4 | 3 | 10 | 胜利 |
| S1-M01-03 | 17.58 | 4 | 3 | 11 | 胜利 |
| S1-M01-04 | 7.37 | 1 | 0 | 2 | 胜利 |
| S1-M01-05 | 18.63 | 4 | 3 | 15 | 胜利 |
| S1-M01-06 | 93.33 | 28 | 27 | 154 | 胜利 |
| S1-M01-07 | 10.03 | 1 | 0 | 6 | 胜利 |
| S1-M01-08 | 15.78 | 6 | 5 | 15 | 胜利 |

## 仍未证明的产品要求

- 64任务bot累计模拟战斗时间 **2115.80秒（35.26分钟）**；第一章247.53秒。该数值不计菜单、叙事阅读和人类反应，不能直接代表玩家通关时间，但与20小时有效内容目标存在显著差距，不能据64次胜利宣布该目标完成。
- 本轮是Mac Godot4.7.1 headless确定性和可达性证据；没有Windows最低配置、Steam发行、手柄物理链路、画面/音频人工质量或多名首次玩家时长验收。
- 早期0/8 bot、StringName保存拒绝、JSON浮点/遍历顺序、夹具刺激不足和退出清理失败均保留旧qa日志供追溯；最终结论仅引用上表最终日志，不沿用旧PASS或把旧FAIL作为当前状态。

## 复现命令

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/campaign_journey_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/campaign_snapshot_safety_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/campaign_journey_test.gd -- --qa-production-sequential
```
