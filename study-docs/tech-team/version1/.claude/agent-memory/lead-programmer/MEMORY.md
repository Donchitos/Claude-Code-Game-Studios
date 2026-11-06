# Lead Programmer — Agent Memory

## Skill Authoring Conventions

### Frontmatter
- Fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- Read-only analysis skills that run in isolation also carry `context: fork` and `agent:`
- Interactive skills (write files, ask questions) do NOT use `context: fork`
- `AskUserQuestion` is a usage pattern described in skill body text — it is NOT listed
  in `allowed-tools` frontmatter (no existing skill does this)

### File Layout
- Skills live in `.claude/skills/<name>/SKILL.md` (subdirectory per skill, never flat .md)
- Section headers use `##` for phases, `###` for sub-sections
- Phase names follow "Phase N: Verb Noun" pattern (e.g., "Phase 1: Find the Story")
- Output format templates go in fenced code blocks

### Known Canonical Paths (verify before referencing in new skills)
- Tech debt register: `docs/tech-debt-register.md` (NOT `production/tech-debt.md`)
- Sprint files: `production/sprints/`
- Epic story files: `production/epics/[epic-slug]/story-[NNN]-[slug].md`
- Architecture & ADRs: `docs/architecture/` (`architecture.md`, `adr-*.md`, `control-manifest.md`)
- Control manifest: `docs/architecture/control-manifest.md`
- Session state: `production/session-state/active.md`
- Engine reference: Context7 MCP（运行时查 UE 5.8 API — `resolve-library-id` + `query-docs`）

### Skills Completed
- `start` — 项目状态检测 + 阶段路由
- `help` — 读 workflow-catalog,提示下一步
- `setup-engine` — 固化 UE 5.8 技术契约 + UE 子专家路由表
- `architecture-decision` — 写 ADR（≥3 个 Foundation 层,Step 1 调 Context7 查域内 API）
- `create-architecture` — 主架构文档
- `create-control-manifest` — 从 ADR 扁平化程序员规则表
- `architecture-review` — ADR 覆盖度 / 依赖顺序 / 引擎兼容（Context7）验证
- `create-epics` — 按 feature spec 拆 epic
- `create-stories` — epic 拆 story
- `story-readiness` — 实现前 story 就绪校验
- `dev-story` — 核心主链:加载上下文→路由→实现→测试→汇总
- `code-review` — 架构 + 质量 + ADR 合规审查
- `story-done` — 验收标准核对、关单
- `qa-plan` — epic/sprint 测试计划
- `team-feature` — 复杂功能多 agent 并行编排（6 阶段）
- `gate-check` — 阶段切换裁决（只过 TD-PHASE-GATE）
