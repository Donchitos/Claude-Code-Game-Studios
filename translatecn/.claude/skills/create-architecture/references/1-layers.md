# /create-architecture — Phase 1: System Layer Mapping
# /create-architecture — 阶段 1：系统分层映射

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 1: System Layer Mapping
## 阶段 1：系统分层映射

Map every system from `systems-index.md` into an architecture layer. The standard
game architecture layers are:
将 `systems-index.md` 中的每个系统映射到一个架构层。标准的游戏架构层为：

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │  ← UI, HUD, menus, VFX, audio
├─────────────────────────────────────────────┤
│  FEATURE LAYER                              │  ← gameplay systems, AI, quests
├─────────────────────────────────────────────┤
│  CORE LAYER                                 │  ← physics, input, combat, movement
├─────────────────────────────────────────────┤
│  FOUNDATION LAYER                           │  ← engine integration, save/load,
│                                             │    scene management, event bus
├─────────────────────────────────────────────┤
│  PLATFORM LAYER                             │  ← OS, hardware, engine API surface
└─────────────────────────────────────────────┘
```

The Platform layer is the engine and OS the game runs on, not code the project
writes. No GDD system goes in it, so it has no epic, stories or control-manifest
rules: a system that wraps a platform or engine API belongs in Foundation.
Platform 层是游戏运行所依赖的引擎和操作系统，而不是项目编写的代码。没有 GDD
系统会放入其中，因此它没有史诗、故事或 control-manifest 规则：包装平台或引擎
API 的系统属于 Foundation 层。

For each GDD system, ask:
对每个 GDD 系统，询问：
- Which layer does it belong to?
- 它属于哪一层？
- What are its module boundaries?
- 它的模块边界是什么？
- What does it own exclusively? (data, state, behaviour)
- 它独占拥有什么？（数据、状态、行为）

Present the proposed layer assignment and ask for approval before proceeding to
the next section. Record the approved layer map in
`production/session-state/active.md`; it goes into the document at Phase 7.
呈现拟议的层分配，并在继续到下一小节之前请求批准。将已批准的层映射记录在
`production/session-state/active.md` 中；它会在阶段 7 进入文档。

**Engine awareness check**: For each system assigned to the Core and Foundation
layers, flag if it touches a HIGH or MEDIUM risk engine domain. Show the relevant
engine reference excerpt inline.
**引擎感知检查**：对分配到 Core 和 Foundation 层的每个系统，若它触及 HIGH 或
MEDIUM 风险的引擎领域，则标记它。内联展示相关的引擎参考摘录。

---
