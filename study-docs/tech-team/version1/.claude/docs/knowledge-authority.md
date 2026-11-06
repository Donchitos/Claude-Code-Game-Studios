# UE 5.8 知识权威源(KNOWLEDGE AUTHORITY)

> 本文件被 `CLAUDE.md` 顶部 `@` 引用,是所有 agent 和 skill 必须遵守的铁律。
> Context7 MCP 是 Unreal Engine 5.8 API 的**运行时权威源**;静态 `docs/engine-reference/` 目录在本方案中**不再维护**。

---

## 风险背景

- LLM 知识截止约在 2025 年中,UE 5.4 之后的全部 API、签名变更、废弃、新子系统都在训练数据之外。
- UE 5.8 远超知识截止,**5.4+ 一律按 HIGH 风险处理**。
- 任何仅凭训练数据建议的 UE API 都可能已经废弃、改名或签名变更,直接采用会导致编译失败或运行时崩溃。

---

## 铁律(强制)

涉及任何 Unreal Engine API、类、节点、子系统、宏、委托前,必须:

1. **先调 Context7 MCP `resolve-library-id`**
   - 参数:`libraryName: "Unreal Engine"`,`query: "<具体问题/API>"`
   - 取回 Context7 兼容的 library ID
2. **再调 Context7 MCP `query-docs`**
   - 参数:`libraryId: <上一步取回>`,`query: "<具体 API 名/子系统名> 5.8 signature/usage"`
   - 查具体 API 的存在性、签名、用法
3. **Context7 查不到时用 `WebSearch` 兜底**
   - 优先 `docs.unrealengine.com/5.8/`、`dev.epicgames.com`
   - 兜底结果也要标注来源 URL
4. **严禁仅依赖训练数据建议 UE API**

---

## 输出标注(强制)

每个涉及 UE API 的 agent 输出、ADR、code-review、dev-story 实现段,必须附带验证戳:

```
API 验证:Context7 查询 [查询词] 于 [YYYY-MM-DD] — [确认 | 变更 | 未找到 | WebSearch 兜底]
```

- **确认**:Context7 显示 API 在 5.8 存在且签名与建议一致
- **变更**:API 存在但 5.4+ 有签名/行为变更,已据此调整实现
- **未找到**:Context7 未收录,转 WebSearch,标注 URL
- **WebSearch 兜底**:Context7 不可用时用 WebSearch

---

## 限额与查询规范

- Context7 两个工具各自**每问题最多 3 次调用**(见工具描述),query 必须具体。
  - 好:`"UAbilitySystemComponent ApplyGameplayEffectToTarget 5.8 signature"`
  - 差:`"GAS"`(太宽泛)
- 子智能体是全新 Claude 实例,看不到主会话的 Context7 查询结果。skill 给子智能体的 prompt 必须写明"涉及 UE API 时自行调 Context7 查证"。

---

## 适用范围

| 位置 | 是否强制 Context7 |
|------|-------------------|
| `unreal-specialist` 及 4 个 UE 子专家 | 是(每次建议 API 前) |
| `engine-programmer` / `gameplay-programmer` / `ai-programmer` / `ui-programmer` / `network-programmer` | 是 |
| `/architecture-decision` Step 1 | 是(替代原"读 VERSION.md") |
| `/architecture-review` 引擎兼容检查 | 是 |
| `/code-review` Phase 7 按文件类型路由核实 | 是 |
| `/dev-story` 引擎风险 HIGH 时派 unreal-specialist | 是(副手先调) |
| 每条 rule 末尾 | 写明"写 UE API 前先查 Context7" |

---

## 与原项目的差异

原项目靠静态 `docs/engine-reference/unreal/VERSION.md` + `breaking-changes.md` + `deprecated-apis.md` 校验知识缺口。本方案改为 Context7 运行时查询,优势:

- 知识始终最新,无需手动维护静态文档
- 可针对具体 API 精确查询
- 跨 agent 一致(都查同一源)

代价:依赖 Context7 可用性。Context7 不可用时降级为 WebSearch,不可降级为"仅用训练数据"。
