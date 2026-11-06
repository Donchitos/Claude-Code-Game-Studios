> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# AD-CONCEPT-VISUAL — Visual Identity Anchor

# AD-CONCEPT-VISUAL — 视觉识别锚点

Agent: `art-director` | Model tier: session (inherit) | Domain: Visual identity, art bible, visual production readiness

智能体：`art-director` | 模型层级：session（继承）| 领域：视觉识别、美术圣经、视觉制作就绪度

**Trigger**: After game pillars are locked (brainstorm Phase 4), in parallel with CD-PILLARS

**触发时机**：游戏支柱锁定后（头脑风暴第 4 阶段），与 CD-PILLARS 并行执行

**Context to pass**:
- Game concept (elevator pitch, core fantasy, unique hook)
- Full pillar set with names, definitions, and design tests
- Target platform (if known)
- Any reference games or visual touchstones mentioned by the user

**需传入的上下文**：
- 游戏概念（电梯陈述、核心幻想、独特钩子）
- 完整支柱集合，含名称、定义与设计测试
- 目标平台（若已知）
- 用户提到的任何参考游戏或视觉参照物

**Prompt**:
> "Based on these game pillars and core concept, propose 2-3 distinct visual identity
> directions. For each direction provide: (1) a one-line visual rule that could guide
> all visual decisions (e.g., 'everything must move', 'beauty is in the decay'), (2)
> mood and atmosphere targets, (3) shape language (sharp/rounded/organic/geometric
> emphasis), (4) color philosophy (palette direction, what colors mean in this world).
> Be specific — avoid generic descriptions. One direction should directly serve the
> primary design pillar. Name each direction. Recommend which best serves the stated
> pillars and explain why."

**提示词**：
> “基于这些游戏支柱与核心概念，提出 2-3 个彼此不同的视觉识别方向。为每个方向提供：(1) 一条可指导所有视觉决策的视觉法则（例如“一切皆须动起来”“美在衰败之中”），(2) 情绪与氛围目标，(3) 形状语言（锐利/圆润/有机/几何化的侧重），(4) 色彩哲学（色板方向、色彩在这个世界中的含义）。要具体——避免泛泛而谈的描述。其中一个方向应直接服务于首要设计支柱。为每个方向命名。推荐哪个方向最能服务于所述支柱，并解释原因。”

**Verdicts**: CONCEPTS (multiple valid options — user selects) / STRONG (one direction clearly dominant) / CONCERNS (pillars don't provide enough direction to differentiate visual identity yet — name each pillar that gives none, and which of the four elements above it leaves open)

**裁定**：CONCEPTS（存在多个有效选项——由用户选择）/ STRONG（某一方向明显占优）/ CONCERNS（支柱目前尚未提供足够方向以区分视觉识别——列出未提供任何方向的每个支柱，以及它使上述四个要素中的哪些仍悬而未决）
