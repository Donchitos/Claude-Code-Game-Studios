# UE 5.8 技术实现项目

> 项目章程。所有 agent 和 skill 必须遵守本文件及 `@` 引用的文档。

## Technology Stack
- **Engine**: Unreal Engine 5.8
- **Language**: C++(主)+ Blueprint(内容/原型)
- **Knowledge Source**: Context7 MCP(UE API 运行时权威源)
- **VCS**: Git
- **Build**: UnrealBuildTool

## 知识权威源(铁律)
@.claude/docs/knowledge-authority.md

涉及任何 UE API/类/节点/子系统前,必须先调 Context7 MCP(`resolve-library-id` + `query-docs`)查证。严禁仅依赖训练数据建议 UE API —— UE 5.4+ 全在 LLM 知识截止之后。Context7 查不到用 WebSearch 兜底(docs.unrealengine.com/5.8/)。

## 协调规则
@.claude/docs/coordination-rules.md

五条核心规则:垂直委派不跳层 / 同级可咨询不能下命令 / 冲突找共同上级 / 跨域改动协调 / 域边界铁律。并行任务协议:先发后等、收齐再走、阻塞立即上报、必出部分报告。

## 委派与升级
@.claude/docs/agent-coordination-map.md

## 门禁
@.claude/docs/director-gates.md

只留 TD-* / LP-* / QL-* 门。Review mode 默认 `lean`(只 PHASE-GATE),`solo` 全跳,`full` 全开。门禁裁决是 ADVISORY,用户永远有权决定是否推进。

## 工作流
@.claude/docs/workflow-catalog.yaml

3 阶段流水线:**Technical Setup → Requirements Breakdown → Implementation**。`/help` 读 catalog 告诉你下一步。每个 story 走 `/story-readiness → /dev-story → /code-review → /story-done` 四步闭环。

## 技术配置
@.claude/docs/technical-preferences.md

## UE 子专家路由
@.claude/docs/engine-specialists.md

## 协作协议(人在环五步)

User-driven, not autonomous. 每个任务:
1. **Question** — 不确定就问,不假设用户意图
2. **Options** — 给清晰选项,不是命令
3. **Decision** — 用户决定方向
4. **Draft** — 起草方案/代码
5. **Approval** — 用户批准才落地

文件写入前必须问"May I write to [path]?"(除非是 skill 明确授权的状态文件如 `active.md`)。

## 文件即记忆

| 文件 | 作用 |
|------|------|
| `production/stage.txt` | 当前阶段 |
| `production/review-mode.txt` | review 模式 |
| `production/session-state/active.md` | 会话状态 |
| `docs/architecture/tr-registry.yaml` | 需求真源索引(指向 feature spec) |
| `docs/architecture/control-manifest.md` | ADR 规则表 |

子智能体是全新 Claude 实例,看不到主会话历史。父子唯一通道是 `Task` 的 `prompt` —— 给路径不给内容,让子智能体自己读文件。

## 反模式(禁止)

绕过层级 / 跨域实现 / 影子决策 / 巨型任务 / 基于假设的实现。

## 快速开始

新项目:
1. `/start` — 检测状态,路由到正确阶段
2. `/setup-engine` — 配置技术契约(UE 5.8 已预填,只问 5 项)
3. `/architecture-decision` (×≥3) — 写 Foundation 层 ADR
4. `/create-architecture` → `/create-control-manifest` → `/architecture-review`
5. `/create-epics` → `/create-stories`
6. `/dev-story [path]` — 实现单故事
7. `/team-feature` — 复杂功能多 agent 并行

褐地项目:`/project-stage-detect` → `/adopt`(本版本可选,未含)
