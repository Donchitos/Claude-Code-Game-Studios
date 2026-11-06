# /create-architecture — Phase 4: API Boundaries
# /create-architecture — 阶段 4：API 边界

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 4: API Boundaries
## 阶段 4：API 边界

Define the public contracts between modules. For each boundary:
定义模块之间的公共契约。对每个边界：

- What is the interface a module exposes to the rest of the system?
- 一个模块向系统其余部分暴露的接口是什么？
- What are the entry points (functions/signals/properties)?
- 入口点是什么（函数/信号/属性）？
- What invariants must callers respect?
- 调用方必须遵守哪些不变量？
- What must the module guarantee to callers?
- 模块必须向调用方保证什么？

Write in pseudocode or the project's actual language (from technical preferences).
These become the contracts programmers implement against.
用伪代码或项目实际使用的语言（来自技术偏好）书写。这些将成为程序员据以实现
的契约。

**Engine awareness check**: If any interface uses engine-specific types (e.g.
`Node`, `Resource`, `Signal` in Godot), flag the version and verify the type
exists and has not changed signature in the target engine version.
**引擎感知检查**：若任何接口使用引擎特有的类型（例如 Godot 中的 `Node`、
`Resource`、`Signal`），标记版本，并验证该类型在目标引擎版本中存在且签名未
改变。

Get user approval on the API boundaries, then record them in
`production/session-state/active.md`; they are written at Phase 7.
取得用户对 API 边界的批准，然后将其记录在
`production/session-state/active.md` 中；它们会在阶段 7 写入。

---
