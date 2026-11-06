# /review-all-gdds — Phase 4: Cross-System Scenario Walkthrough
# /review-all-gdds — 阶段 4：跨系统场景走查

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 4: Cross-System Scenario Walkthrough
## 阶段 4：跨系统场景走查

Walk through the game from the player's perspective to find problems that only
appear at the interaction boundary between multiple systems — things static
analysis of individual GDDs cannot surface.

从玩家视角走查游戏，找出只在多个系统交互边界处才出现的问题——即单个 GDD 的静态分析无法
揭示的问题。

### 4a: Identify Key Multi-System Moments
### 4a：识别关键的多系统时刻

Scan all GDDs and identify the 3–5 most important player-facing moments where
multiple systems activate simultaneously. Look specifically for:

扫描所有 GDD，找出 3–5 个最重要的、面向玩家的、多个系统同时激活的时刻。特别留意：

- **Combat + Economy overlap**: killing enemies that drop resources, spending
  resources during combat, death/respawn interacting with economy state
- **Progression + Difficulty overlap**: level-up triggering mid-fight, ability
  unlocks changing combat viability, difficulty scaling at progression milestones
- **Narrative + Gameplay overlap**: dialogue choices locking/unlocking mechanics,
  story beats interrupting resource loops, quest completion triggering system
  state changes
- **3+ system chains**: any player action that triggers System A, which feeds
  into System B, which triggers System C (these are highest-risk interaction paths)

- **战斗 + 经济重叠**：击杀掉落资源的敌人、在战斗中花费
  资源、死亡/重生与经济状态相互影响
- **进阶 + 难度重叠**：战斗中触发升级、能力
  解锁改变战斗可行性、进阶里程碑处的难度缩放
- **叙事 + 玩法重叠**：对话选项锁定/解锁机制、
  剧情节点打断资源循环、任务完成触发系统
  状态变化
- **3 个以上系统的链式反应**：任何触发系统 A、A 又输入
  系统 B、B 又触发系统 C 的玩家行为（这些是风险最高的交互路径）

List each identified scenario with a one-line description before proceeding.

在继续之前，用一行描述列出每个已识别的场景。

### 4b: Walk Through Each Scenario
### 4b：走查每个场景

For each scenario, step through the sequence explicitly:

对每个场景，明确地逐步梳理其序列：

1. **Trigger** — what player action or game event starts this?
2. **Activation order** — which systems activate, in what sequence?
3. **Data flow** — what does each system output, and is that output a valid
   input for the next system in the chain?
4. **Player experience** — what does the player see, hear, or feel at each step?
5. **Failure modes** — are there any of the following?
   - **Race conditions**: two systems trying to modify the same state simultaneously
   - **Feedback loops**: System A amplifies System B which re-amplifies System A
     with no cap or dampener
   - **Broken state transitions**: a system assumes a state that a previous
     system may have changed (e.g., "player is alive" assumption after a combat
     step that could have caused death)
   - **Contradictory messaging**: player receives conflicting feedback from two
     systems reacting to the same event (e.g., "success" sound + "failure" UI)
   - **Compounding difficulty spikes**: two systems both scaling up at the same
     progression point, multiplying the intended difficulty increase
   - **Reward conflicts**: two systems both reacting to the same trigger with
     rewards that together exceed the intended value (double-dipping)
   - **Undefined behavior**: the GDDs don't specify what happens in this combined
     state (neither system's rules cover it)

1. **触发**——是什么玩家行为或游戏事件启动了它？
2. **激活顺序**——哪些系统被激活，按什么次序？
3. **数据流**——每个系统输出什么，该输出是否是链中下一个系统的
   有效输入？
4. **玩家体验**——玩家在每一步看到、听到或感受到什么？
5. **失效模式**——是否存在以下任一情况？
   - **竞态条件**：两个系统试图同时修改同一状态
   - **反馈循环**：系统 A 放大系统 B，系统 B 又再次放大系统 A，
     且没有上限或阻尼
   - **状态转换中断**：某系统假设了前一系统可能已经改变的状态
     （例如，一个可能导致死亡的战斗步骤之后仍假设“玩家存活”）
   - **消息矛盾**：玩家从两个对同一事件做出反应的系统中
     收到相互冲突的反馈（例如，“成功”音效 + “失败”界面）
   - **叠加的难度尖峰**：两个系统在同一进阶点同时上调，
     使预期的难度增长成倍放大
   - **奖励冲突**：两个系统对同一触发都给予奖励，
     合计超出预期值（重复领取）
   - **未定义行为**：GDD 未规定在这种组合状态下会发生什么
     （两个系统的规则都未覆盖）

```
Example walkthrough:
Scenario: Player kills elite enemy at level-up threshold during active quest

Trigger: Player lands killing blow on elite enemy
→ combat.md: awards kill XP (100 pts)
→ progression.md: XP total crosses level threshold → triggers level-up
  Output: new level, stat increases, ability unlock popup
→ quest.md: kill-count criterion met → triggers quest completion event
  Output: quest reward XP (500 pts), completion fanfare
→ progression.md (again): quest XP added → triggers SECOND level-up in same frame
  ⚠️  Data flow issue: quest.md awards XP without checking if a level-up
  is already in progress. progression.md has no guard against concurrent
  level-up events. Undefined behavior: does the player level up once or twice?
  Does the ability popup fire twice? Does the second level use the updated or
  pre-update stat baseline?
```

```
示例走查：
场景：玩家在任务进行中、恰好处于升级阈值的时刻击杀精英敌人

触发：玩家对精英敌人打出致命一击
→ combat.md：给予击杀经验值（100 点）
→ progression.md：经验值总量越过升级阈值 → 触发升级
  输出：新等级、属性提升、能力解锁弹窗
→ quest.md：击杀计数条件满足 → 触发任务完成事件
  输出：任务奖励经验值（500 点）、完成庆祝效果
→ progression.md（再次）：任务经验值被追加 → 在同一帧触发第二次升级
  ⚠️  数据流问题：quest.md 给予经验值时没有检查是否已有升级
  正在进行中。progression.md 没有针对并发升级事件的防护。
  未定义行为：玩家升级一次还是两次？
  能力弹窗会触发两次吗？第二次升级使用的是更新后的属性基线
  还是更新前的？
```

### 4c: Flag Scenario Issues
### 4c：标记场景问题

For each problem found during the walkthrough, categorize severity:

对走查中发现的每个问题，按严重程度分类：

- **BLOCKER**: undefined behavior, broken state transition, or contradictory
  player messaging — the experience is broken or incoherent in this scenario
- **WARNING**: compounding spikes, feedback loops without caps, reward conflicts —
  the experience works but produces unintended outcomes
- **INFO**: minor ordering ambiguity or messaging overlap — worth noting but
  unlikely to cause player-visible problems

- **BLOCKER（阻断）**：未定义行为、状态转换中断，或相互矛盾的
  玩家消息——该场景中的体验已损坏或前后不一致
- **WARNING（警告）**：叠加尖峰、无上限的反馈循环、奖励冲突——
  体验可以运行，但产生了非预期的结果
- **INFO（信息）**：轻微的次序歧义或消息重叠——值得记录，但
  不太可能造成玩家可见的问题

Add all findings to the output report under **"Cross-System Scenario Issues"**.
Each finding must cite: the scenario name, the specific systems involved, the
step where the issue occurs, and the nature of the failure mode.

把所有发现加到输出报告的 **“跨系统场景问题”** 之下。
每条发现都必须引用：场景名称、涉及的具体系统、
问题发生的步骤，以及失效模式的性质。

---
