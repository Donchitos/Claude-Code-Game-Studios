# UE 5.8 技术实现团队编排 — 文档索引

> 从 [Claude Code Game Studios](file:///workspace/README.md) 裁剪出"需求 → 技术实现"的 Agent 协作编排方案,以 Unreal Engine 5.8 为技术栈,Context7 MCP 为引擎知识权威源。

---

## 文档

| 文档 | 核心问题 |
|------|----------|
| [UE 5.8 技术实现团队编排方案](file:///workspace/study-docs/tech-team/UE5.8技术实现团队编排方案.md) | 怎么从原项目抽出技术实现部分,搭一套 UE 5.8 的 agent 协作? |

---

## 一句话总览

> **保留原项目技术骨架(三层 agent + 三层规则 + dev-story 主链 + 代码类 hook/rule + 人在环五步 + 文件即记忆),砍掉所有非代码域,7 阶段压成 3 阶段,9 个 team-* 压成 1 个 /team-feature,Godot/Unity 团队换成 UE 5.8 子团队,静态引擎参考换成 Context7 运行时查询。**

---

## 方案要点速查

### 裁剪结果
- **Agent**:49 → 12 核心 + 4 可选 + 4 UE 子专家(可 +1 replication)
- **Skill**:73 → 12 核心 + 5 可选
- **阶段**:7 → 3(技术准备 → 需求拆解 → 实现循环)

### 保留的核心机制
- 三层 agent(总监/主管/专家)+ 垂直委派不跳层
- 三层规则源(agents/skills/docs)
- dev-story 7 Phase 主链 + 路由表 + 错误恢复协议
- 5 条协调规则 + 并行任务协议 + 五大反模式
- 人在环五步(Question→Options→Decision→Draft→Approval)
- 文件即记忆(active.md/stage.txt/review-mode.txt)+ agent memory
- 三态门禁(APPROVE/CONCERNS/REJECT)+ review mode(full/lean/solo)

### 关键改造
- `/setup-engine` 轻量化:UE 5.8 + Context7 预填,只问 5 项配置
- 9 个 `team-*` 压成 1 个 `/team-feature` 通用编排
- 门禁只留 TD-*/LP-*/QL-*,砍掉 CD/PR/AD/ND
- 引擎参考从静态 `docs/engine-reference/` 改为 Context7 运行时查询
- TD-ENGINE-RISK 门改用 Context7 验证 API

### 最大风险
UE 5.8 远超 LLM 知识截止(May 2025),5.4+ 全部 HIGH 风险。**必须强制走 Context7,严禁仅依赖训练数据建议 UE API。**

---

## 落地路径

照主文档第 13 节 8 步走,核心原则:**先跑通单 agent,再增量扩展,每加一层验证不破坏已有流程**。

---

## 参考来源

本方案所有机制均可在原项目找到对应实现,主文档每节都标注了来源链接。完整学习材料见 [study-docs](file:///workspace/study-docs/README.md)。
