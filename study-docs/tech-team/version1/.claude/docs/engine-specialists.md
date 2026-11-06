# Engine Specialists — UE 子专家路由表

> 本文件由 `/setup-engine` 写入(UE 5.8 + 4 子专家固定),被 `/dev-story` / `/code-review` / `/team-feature` 读取。
> 决定"涉 UE 哪个域时派哪个 ue-*-specialist 副手"。

---

## 引擎与团队
- **Engine**: Unreal Engine 5.8
- **Team Leader**: `unreal-specialist`(sonnet,有 Task 工具可委派子专家)
- **Knowledge Source**: Context7 MCP(见 [knowledge-authority.md](file:///workspace/study-docs/tech-team/version1/.claude/docs/knowledge-authority.md))

---

## 子专家路由表

| 触发条件(关键词/文件模式) | 派哪个子专家 | 职责 |
|------------------------------|--------------|------|
| GAS / GameplayAbility / GameplayEffect / AttributeSet / GameplayTag | `ue-gas-specialist` | GAS 架构、Ability/Effect/Tag 体系、属性复制 |
| Blueprint 资产(`Content/**/*.bp`) / BP↔C++ 边界 / BlueprintNativeEvent / BlueprintCallable | `ue-blueprint-specialist` | BP 架构、BP/C++ 边界、图标准 |
| UMG / CommonUI / Widget / Slate / MVVM / `Source/ui/**` | `ue-umg-specialist` | 控件层级、数据绑定、CommonUI 规范 |
| 复制 / RPC / Replication / Prediction / Relevancy / Iris [多人时] | `ue-replication-specialist` [opt] | 属性复制、RPC、预测、相关性 |
| 无法归入上述任一 | `unreal-specialist` | UE 总权威,BP/C++ 边界、子系统把关 |

---

## 委派规则

1. `unreal-specialist` 是 UE 子团队 leader,可进一步派 4 个子专家(垂直委派不跳层)。
2. 子专家是 OPTIONAL 的(`ue-replication-specialist` 仅多人项目启用)。
3. **所有 UE 子专家建议任何 API 前必须先调 Context7**(`resolve-library-id` + `query-docs`),严禁仅依赖训练数据。
4. 子专家是全新 Claude 实例,看不到主会话历史。`unreal-specialist` 派子专家时,prompt 必须写明:相关文件路径、要查的 API、验证戳要求。

---

## dev-story 路由集成

`/dev-story` 路由表的"副手(引擎风险 HIGH 时)"列,按本表选择:

| 故事上下文 | 主 agent | 副手(本表映射) |
|-----------|----------|------------------|
| Foundation 层 | engine-programmer | unreal-specialist |
| UI 类型 | ui-programmer | ue-umg-specialist |
| Visual/Feel | gameplay-programmer | unreal-specialist |
| 玩法机制(涉 GAS) | gameplay-programmer | ue-gas-specialist |
| AI 行为 | ai-programmer | unreal-specialist |
| 网络/复制 [多人] | network-programmer | ue-replication-specialist |

引擎风险级别由 `/dev-story` Phase 2 评估(涉 UE 5.4+ API 即 HIGH),HIGH 时强制派副手,副手先调 Context7 验证。

---

## 启用状态
> **Team Status**: Configured(UE 5.8 + 4 子专家)
> 多人项目时启用 `ue-replication-specialist`,在此行标注 `[ENABLED]`。
