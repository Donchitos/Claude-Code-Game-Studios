# /create-architecture — Phase 2: Module Ownership Map
# /create-architecture — 阶段 2：模块归属映射

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 2: Module Ownership Map
## 阶段 2：模块归属映射

For each module defined in Phase 1, define ownership:
对阶段 1 中定义的每个模块，定义归属：

- **Owns**: what data and state this module is solely responsible for
- **Owns（拥有）**：此模块独自负责哪些数据和状态
- **Exposes**: what other modules may read or call
- **Exposes（暴露）**：其它模块可以读取或调用什么
- **Consumes**: what it reads from other modules
- **Consumes（消费）**：它从其它模块读取什么
- **Engine APIs used**: which specific engine classes/nodes/signals this module
  calls directly (with version and risk level noted)
- **Engine APIs used（使用的引擎 API）**：此模块直接调用哪些具体的引擎类/节点/
  信号（注明版本和风险等级）

Format as a table per layer, then as an ASCII dependency diagram.
按层组织成表格，然后以 ASCII 依赖图呈现。

**Engine awareness check**: For every engine API listed, verify against the
relevant module reference doc. If an API is post-cutoff, flag it:
**引擎感知检查**：对列出的每个引擎 API，对照相关模块参考文档进行验证。若某个
API 属于训练截止后，则标记它：

```
⚠️  [ClassName.method()] — Godot 4.7 (post-cutoff, HIGH risk)
    Verified against: docs/engine-reference/godot/modules/[domain].md
    Behaviour confirmed: [yes / NEEDS VERIFICATION]
```

Get user approval on the ownership map, then record it in
`production/session-state/active.md`; it is written at Phase 7.
取得用户对归属映射的批准，然后将其记录在
`production/session-state/active.md` 中；它会在阶段 7 写入。

---
