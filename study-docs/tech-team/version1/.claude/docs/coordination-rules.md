# Coordination Rules — 技术实现团队协调规则

> 三层规则的"第 3 层:公司制度"。被 `CLAUDE.md` `@` 引用,所有 agent 和 skill 必须遵守。
> 沿袭原项目 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md),精简到技术域。

---

## 三层 Agent 结构

```
Tier 1  technical-director (opus, memory: user)
Tier 2  lead-programmer (sonnet, memory: project)  |  qa-lead (sonnet)
Tier 3  engine / gameplay / ai / ui / qa-tester / [network] / [tools] / [performance]
        unreal-specialist → ue-gas / ue-blueprint / ue-umg / [ue-replication]
```

---

## 五条核心规则

### 1. 垂直委派不跳层
主管委派给专家,不跨层。`technical-director` 不能直接派 `gameplay-programmer`,要走 `lead-programmer`。`unreal-specialist` 委派 UE 子专家同理。

### 2. 同级可咨询不能下命令
`gameplay-programmer` 可问 `ai-programmer`"敌人 AI 怎么接收伤害事件",但不能直接改它的文件。同级之间是咨询关系,不是指挥关系。

### 3. 冲突找共同上级
- 两个程序员分歧 → `lead-programmer`
- 代码架构分歧 → `technical-director`
- UE 子专家与 gameplay-programmer 对 GAS 用法分歧 → `unreal-specialist` → `technical-director`
- 引擎 API 风险(Context7 查证后仍有分歧)→ `technical-director`
- 性能预算冲突 → `technical-director`
- 跨系统代码冲突 → `lead-programmer` → `technical-director`

### 4. 跨域改动协调
一个改动影响多个子系统,由 `lead-programmer` 协调(原项目是 producer,本方案 producer 被砍,职责归 lead-programmer)。协调方式:列出受影响文件 → 分派给各域 owner → 收齐再集成。

### 5. 域边界铁律(不许改别人家的文件)
`gameplay-programmer` 不能改 `Source/ui/` 下的文件。要改得让 `ui-programmer` 来,或由 `lead-programmer` 显式委派。每个 agent 的 owning domains 在其档案里写明。

---

## 并行任务协议(沿袭原项目)

当多个独立任务可同时执行时(如 `/team-feature` Phase 3 并行实现):

1. **先发后等** — 所有独立的 Task 调用一起发出,不要发一个等一个
2. **收齐再走** — 所有结果收齐再进依赖阶段
3. **阻塞立即上报** — 任何智能体 BLOCKED 立刻告诉用户,给三选项(跳过/重试/停下)
4. **必出部分报告** — 哪怕部分阻塞也要汇报已完成的部分

---

## 五大反模式(禁止)

1. **绕过层级** — 跳过主管直接派专家
2. **跨域实现** — 改不属于自己域的文件
3. **影子决策** — 在 ADR 之外做影响架构的决定
4. **巨型任务** — 给子智能体一个过大任务(应拆成有边界的子任务)
5. **基于假设的实现** — 不读 ADR/feature spec 就凭猜测实现

---

## 人在环五步协议(沿袭原项目)

每个任务执行:

1. **Question** — 不确定就问,不假设用户意图
2. **Options** — 给清晰选项,不是命令
3. **Decision** — 用户决定方向
4. **Draft** — 起草方案/代码
5. **Approval** — 用户批准才落地

**用户永远有权决定是否推进**。门禁裁决是 ADVISORY(建议性),不硬阻塞。

---

## 文件即记忆(沿袭原项目)

| 文件 | 作用 |
|------|------|
| `production/session-state/active.md` | 当前会话状态(dev-story 每轮追加) |
| `production/stage.txt` | 当前阶段(technical-setup / requirements-breakdown / implementation) |
| `production/review-mode.txt` | review 模式(full / lean / solo) |
| `docs/architecture/tr-registry.yaml` | 需求真源索引(指向 feature spec) |
| `docs/architecture/control-manifest.md` | ADR 扁平化规则表 |

子智能体是全新 Claude 实例,**看不到主会话历史**。父子唯一通道是 `Task` 的 `prompt`。所以 skill 给子智能体的 prompt 要写明:相关文件路径、要遵守的 ADR、涉及 UE API 时调 Context7。
