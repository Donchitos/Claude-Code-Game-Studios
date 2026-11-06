# /architecture-review — Phase 6: Architecture Document Coverage
# /architecture-review — 阶段 6：架构文档覆盖

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 6: Architecture Document Coverage
## 阶段 6：架构文档覆盖

**If `docs/architecture/architecture.md` does not exist, say so in the report** —
`Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
— and carry it into the Phase 7 verdict per the trigger list below. Silently
producing no Phase 6 findings reads as an architecture document that was checked
and found clean, which is the opposite of what happened.
**若 `docs/architecture/architecture.md` 不存在，在报告中说明这一点** —
`Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
— 并按下面的触发条件清单将其带入阶段 7 的裁决。静默地产出零条阶段 6 发现，
会被读作"架构文档已被检查且干净"，而这与实际情况正好相反。

If it exists, validate it against GDDs:
若它存在，对照 GDD 验证它：

- Does every system from `systems-index.md` appear in the architecture layers?
- `systems-index.md` 中的每个系统是否都出现在架构各层中？
- Does the data flow section cover all cross-system communication defined in GDDs?
- 数据流小节是否覆盖了 GDD 中定义的所有跨系统通信？
- Do the API boundaries support all integration requirements from GDDs?
- API 边界是否支持来自 GDD 的所有集成需求？
- Are there systems in the architecture doc that have no corresponding GDD
  (orphaned architecture)?
- 架构文档中是否存在没有对应 GDD 的系统（孤立架构）？

---
