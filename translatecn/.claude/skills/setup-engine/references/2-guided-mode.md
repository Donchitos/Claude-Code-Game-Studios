# /setup-engine — Section 2: Guided Mode

# /setup-engine — 第 2 节：引导模式

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 2. Guided Mode (No Arguments)

## 2. 引导模式（无参数）

**In this file:**

- Check for existing game concept
- If the user wants to pick without a concept, ask in this order
- Produce a recommendation

**本文件内容：**

- 检查是否已有游戏概念
- 如果用户希望在没有概念的情况下进行选择，按以下顺序询问
- 产出一份推荐

If no engine is specified, run an interactive engine selection process:

如果未指定引擎，则运行一个交互式的引擎选择流程：

### Check for existing game concept
Read the design artifact for the resolved tier (see **Tier awareness** above), by
section: find the headings you need with the Grep tool (pattern `^#`, content
mode) and Read those ranges with offset and limit:
- **`standard` / `full`**: read `design/gdd/game-concept.md` if it exists —
  extract genre, scope, platform targets, art style, team size, and the engine
  preference `/brainstorm` recorded (an engine the user named, or "undecided":
  `/brainstorm` never recommends one, so the recommendation is made here).
- **`minimal`**: read `design/game-brief.md` if it exists — extract genre,
  scope, platform, and art direction from its fields. Its absence is **expected**
  at `minimal` (the brief is authored *after* engine setup in the minimal path), so
  do not treat a missing brief as a gap — proceed straight to guided selection.
- If no concept **or** brief exists, inform the user:
  > "No game concept found. Consider running `/brainstorm` first to discover what
  > you want to build — it records your engine preference if you have one. Or
  > tell me about your game and I can help you pick."

  (At `minimal` this is optional, not a prerequisite — you can pick an engine now
  and write the brief next.)

### 检查是否已有游戏概念
按章节读取已解析档位的设计资产（见上文 **档位感知**）：用 Grep 工具（模式 `^#`，内容
模式）找到所需的标题，再用 offset 和 limit 读取那些范围：
- **`standard` / `full`**：若 `design/gdd/game-concept.md` 存在则读取它 ——
  提取类型、范围、目标平台、美术风格、团队规模，以及 `/brainstorm` 记录的
  引擎偏好（用户点名的引擎，或"未决定"）：
  `/brainstorm` 从不推荐引擎，因此推荐在这里给出。
- **`minimal`**：若 `design/game-brief.md` 存在则读取它 —— 从其字段中提取类型、
  范围、平台和美术方向。在 `minimal` 档位下它缺失是**预期之内**的
  （在 minimal 路径中，简报到*引擎设置之后*才撰写），因此
  不要把缺失的简报视为缺口 —— 直接进入引导式选择。
- 如果**既**没有概念**也**没有简报，告知用户：
  > "未找到游戏概念。建议先运行 `/brainstorm` 来发现
  > 你想构建什么 —— 如果你有引擎偏好，它会记录下来。或者
  > 告诉我你的游戏，我可以帮你挑选。"

  （在 `minimal` 档位下这是可选的，不是前提条件 —— 你可以现在选定引擎，
  之后再写简报。）

### If the user wants to pick without a concept, ask in this order:

**Question 1 — Prior experience** (ask this first, always, via `AskUserQuestion`):
- Prompt: "Have you worked in any of these engines before?"
- Options: `Godot` / `Unity` / `Unreal Engine 5` / `Multiple — I'll explain` / `None of them`
- If they pick a specific engine → recommend that engine. Prior experience outweighs all other factors. Confirm with them and skip the matrix.
- If "None" or "Multiple" → continue to the questions below.

**Questions 2-6 — Decision matrix inputs** (only if no prior engine experience):

**Question 2 — Target platform** (ask this second, always, via `AskUserQuestion` — platform eliminates or heavily weights engines before any other factor):
- Prompt: "What platforms are you targeting for this game?"
- Options: `PC (Steam / Epic)` / `Mobile (iOS / Android)` / `Console` / `Web / Browser` / `Multiple platforms`
- Platform rules that feed directly into the recommendation:
  - Mobile → Unity strongly preferred; Unreal is a poor fit; Godot is viable for simple mobile
  - Console → Unity or Unreal; Godot console support requires third-party publishers or significant extra work
  - Web → Godot exports cleanly to web; Unity WebGL is functional; Unreal has poor web support
  - PC only → all engines viable; other factors decide
  - Multiple → Unity is the most portable across PC/mobile/console

1. **What kind of game?** (2D, 3D, or both?)
2. **Primary input method?** (keyboard/mouse, gamepad, touch, or mixed?)
3. **Team size and experience?** (solo beginner, solo experienced, small team?)
4. **Any strong language preferences?** (GDScript, C#, C++, visual scripting?)
5. **Budget for engine licensing?** (free only, or commercial licenses OK?)

### 如果用户希望在没有概念的情况下进行选择，按以下顺序询问：

**问题 1 —— 过往经验**（总是最先询问，通过 `AskUserQuestion`）：
- 提示："你以前用过这些引擎中的哪些？"
- 选项：`Godot` / `Unity` / `Unreal Engine 5` / `Multiple — I'll explain` / `None of them`
- 如果他们选择了某个具体引擎 → 推荐该引擎。过往经验胜过所有其他因素。与他们确认并跳过决策矩阵。
- 如果选择 "None" 或 "Multiple" → 继续以下问题。

**问题 2-6 —— 决策矩阵输入**（仅在用户没有过往引擎经验时）：

**问题 2 —— 目标平台**（总是第二个询问，通过 `AskUserQuestion` —— 平台会在任何其他因素之前排除或大幅加权某些引擎）：
- 提示："你的这款游戏面向哪些平台？"
- 选项：`PC (Steam / Epic)` / `Mobile (iOS / Android)` / `Console` / `Web / Browser` / `Multiple platforms`
- 直接进入推荐的平台规则：
  - Mobile → 强烈偏好 Unity；Unreal 不太适合；Godot 对简单移动游戏可行
  - Console → Unity 或 Unreal；Godot 的主机支持需要第三方发行商或大量额外工作
  - Web → Godot 能干净地导出到 Web；Unity WebGL 可用；Unreal 的 Web 支持较差
  - 仅 PC → 所有引擎都可行；由其他因素决定
  - Multiple → Unity 在 PC/移动/主机之间最具可移植性

1. **什么样的游戏？**（2D、3D，还是两者兼具？）
2. **主要输入方式？**（键盘/鼠标、手柄、触控，还是混合？）
3. **团队规模与经验？**（单人新手、单人老手、小团队？）
4. **是否有强烈的语言偏好？**（GDScript、C#、C++、可视化脚本？）
5. **引擎授权预算？**（仅免费，还是商业授权也可？）

### Produce a recommendation

Do NOT use a simple scoring matrix that eliminates engines. Instead, reason through the user's profile against the honest tradeoffs below, then present 1-2 recommendations with full context. Always end with the user choosing — never force a verdict.

**Engine honest tradeoffs:**

**Godot 4**
- Genuine strengths: 2D (best in class), stylized/indie 3D, rapid iteration, free forever (MIT), open source, gentlest learning curve, best for solo devs who want full control
- Real limitations: 3D ecosystem is thin compared to Unity/Unreal (fewer tutorials, assets, community answers for 3D-specific problems); large open-world 3D is very hard and largely untested in Godot; console export requires third-party publishers or significant extra work; smaller professional job market
- Licensing reality: Truly free with no revenue thresholds ever. MIT license means you own everything.
- Best fit: 2D games of any scope; stylized/atmospheric 3D; contained 3D worlds (not open-world); first game projects where learning curve matters; projects where budget is a hard constraint at any scale

**Unity**
- Genuine strengths: Industry standard for mid-scope 3D and mobile; massive asset store and tutorial ecosystem; C# is a professional language; best console certification support for indie; strong community for almost every genre
- Real limitations: Licensing controversy in 2023 damaged trust (runtime fee was proposed then walked back — the risk of policy changes remains real); C# has a steeper initial curve than GDScript; heavier editor than Godot for simple projects
- Licensing reality: Free under $200K revenue AND 200K installs (Unity Personal/Plus). Only becomes costly if the game is genuinely successful — most indie games never hit this threshold. The 2023 controversy is worth knowing about but the actual current terms are reasonable for most indie developers.
- Best fit: Mobile games; mid-scope 3D; games targeting console; developers with C# background; projects needing large asset store; teams of 2-5

**Unreal Engine 5**
- Genuine strengths: Best-in-class 3D visuals (Lumen, Nanite, Chaos physics); industry standard for AAA and photorealistic 3D; large open-world support is mature and production-tested; Blueprint visual scripting lowers C++ barrier; strong for games targeting high-end PC or console
- Real limitations: Steepest learning curve; heaviest editor (slow compile times, large project sizes); overkill for stylized/2D/small-scope games; C++ is genuinely hard; not suitable for mobile or web; 5% royalty past $1M gross revenue
- Licensing reality: 5% royalty only applies AFTER $1M gross revenue per title. For a first game or any game that doesn't reach $1M, it costs nothing. This threshold is high enough that most indie developers will never pay it.
- Best fit: AAA-quality 3D; large open-world games; photorealistic visuals; developers with C++ experience or willing to use Blueprint; games targeting high-end PC/console where visual fidelity is a core selling point

### 产出推荐

**不要**使用会排除某些引擎的简单评分矩阵。相反，结合以下诚实的权衡，对用户的画像进行推理，然后给出 1-2 个附带完整背景的推荐。始终以用户自行选择收尾 —— 绝不强加结论。

**引擎的诚实权衡：**

**Godot 4**
- 真正的优势：2D（同类最佳）、风格化/独立 3D、快速迭代、永远免费（MIT）、开源、最平缓的学习曲线、最适合希望完全掌控的单人开发者
- 真实的局限：与 Unity/Unreal 相比，3D 生态较薄弱（针对 3D 特定问题的教程、资产、社区解答更少）；大型开放世界 3D 非常困难且在 Godot 中基本未经验证；主机导出需要第三方发行商或大量额外工作；专业就业市场较小
- 授权现实：真正免费，任何时候都没有收入门槛。MIT 许可意味着你拥有全部。
- 最适合：任何规模的 2D 游戏；风格化/氛围化 3D；封闭式 3D 世界（非开放世界）；学习曲线重要的首个游戏项目；在任何规模下预算都是硬约束的项目

**Unity**
- 真正的优势：中等规模 3D 和移动领域的行业标准；庞大的资产商店和教程生态；C# 是专业语言；对独立开发者的主机认证支持最佳；几乎每个品类都有强大的社区
- 真实的局限：2023 年的授权争议损害了信任（运行时费用先是被提出、随后被撤回 —— 政策变化的风险依然真实存在）；C# 的入门曲线比 GDScript 更陡；对简单项目而言编辑器比 Godot 更重
- 授权现实：收入低于 200K 美元**且**安装量低于 200K（Unity Personal/Plus）时免费。只有游戏真正成功时才会变得昂贵 —— 大多数独立游戏永远达不到这一门槛。2023 年的争议值得了解，但实际现行条款对大多数独立开发者来说是合理的。
- 最适合：移动游戏；中等规模 3D；面向主机的游戏；有 C# 背景的开发者；需要大型资产商店的项目；2-5 人的团队

**Unreal Engine 5**
- 真正的优势：同类最佳的 3D 视觉效果（Lumen、Nanite、Chaos 物理）；AAA 和写实 3D 的行业标准；大型开放世界支持成熟且经过生产验证；Blueprint 可视化脚本降低了 C++ 门槛；面向高端 PC 或主机的游戏表现出色
- 真实的局限：最陡峭的学习曲线；最重的编辑器（编译缓慢、项目体积大）；对风格化/2D/小规模游戏而言是杀鸡用牛刀；C++ 确实很难；不适合移动或 Web；总收入超过 100 万美元后抽成 5%
- 授权现实：5% 抽成仅在单个作品总收入**超过** 100 万美元后才适用。对于第一个游戏或任何未达到 100 万美元的游戏，它不产生任何费用。这一门槛足够高，大多数独立开发者永远不会支付。
- 最适合：AAA 品质的 3D；大型开放世界游戏；写实视觉效果；有 C++ 经验或愿意使用 Blueprint 的开发者；面向高端 PC/主机、且视觉保真度是核心卖点的游戏

**Genre-specific guidance** (factor this into the recommendation):
- 2D any style → Godot strongly preferred
- 3D stylized / atmospheric / contained world → Godot viable, Unity solid alternative
- 3D open world (large, seamless) → Unity or Unreal; Godot is not production-proven for this
- 3D photorealistic / AAA-quality → Unreal
- Mobile-first → Unity strongly preferred
- Console-first → Unity or Unreal; Godot console support requires extra work
- Horror / narrative / walking sim → any engine; match to art style and team experience
- Action RPG / Soulslike → Unity or Unreal for 3D; community support and assets matter here
- Platformer 2D → Godot
- Strategy / top-down / RTS → Godot or Unity depending on 2D vs 3D

**按品类给出的指引**（将此纳入推荐考量）：
- 任何风格的 2D → 强烈偏好 Godot
- 3D 风格化 / 氛围化 / 封闭世界 → Godot 可行，Unity 是稳妥的备选
- 3D 开放世界（大型、无缝） → Unity 或 Unreal；Godot 在这方面未经生产验证
- 3D 写实 / AAA 品质 → Unreal
- 移动优先 → 强烈偏好 Unity
- 主机优先 → Unity 或 Unreal；Godot 的主机支持需要额外工作
- 恐怖 / 叙事 / 步行模拟 → 任何引擎；与美术风格和团队经验相匹配
- 动作 RPG / 类魂 → 3D 用 Unity 或 Unreal；社区支持和资产在此很重要
- 2D 平台跳跃 → Godot
- 策略 / 俯视 / RTS → 视 2D 还是 3D 而定，选 Godot 或 Unity

**Recommendation format:**
1. Show a comparison table with the user's specific factors as rows
2. Give a primary recommendation with honest reasoning
3. Name the best alternative and when to choose it instead
4. Explicitly state: "This is a starting point, not a verdict — you can always migrate engines, and many developers switch between projects."
5. Use `AskUserQuestion` to confirm: "Does this recommendation feel right, or would you like to explore a different engine?"
   - Options: `[Primary engine] (Recommended)` / `[Alternative engine]` / `[Third engine]` / `Explore further` / `Type something`

**推荐格式：**
1. 展示一张以用户的具体因素为行的对比表
2. 给出一个附带诚实推理的主要推荐
3. 指出最佳备选，以及何时应改为选择它
4. 明确说明："这是一个起点，不是结论 —— 你随时可以迁移引擎，许多开发者在项目之间也会切换。"
5. 用 `AskUserQuestion` 确认："这个推荐是否合适，还是你想探索另一个引擎？"
   - 选项：`[Primary engine] (Recommended)` / `[Alternative engine]` / `[Third engine]` / `Explore further` / `Type something`

**If the user picks "Explore further":**
Use `AskUserQuestion` with concept-specific deep-dive topics. Always generate these options from the user's actual concept — do not use generic options. Always include at minimum:
- The primary engine's specific limitations for this concept (e.g., "How far can Godot 3D actually go for [genre]?")
- The alternative engine's specific tradeoffs for this concept
- Language choice impact on this concept's technical challenges
- Any concept-specific technical concern (e.g., adaptive audio, open-world streaming, multiplayer netcode)

The user can select multiple topics. Answer each selected topic in depth before returning to the engine confirmation question.

**如果用户选择 "Explore further"：**
使用 `AskUserQuestion`，配合概念特定的深入探讨主题。始终根据用户的实际概念生成这些选项 —— 不要使用通用选项。始终至少包含：
- 主要引擎对该概念的特定局限（例如："Godot 3D 在 [genre] 上究竟能走多远？"）
- 备选引擎对该概念的特定权衡
- 语言选择对该概念技术挑战的影响
- 任何概念特定的技术关切（例如：自适应音频、开放世界流式加载、多人网络代码）

用户可以多选主题。在回到引擎确认问题之前，逐一深入回答每个已选主题。

---
