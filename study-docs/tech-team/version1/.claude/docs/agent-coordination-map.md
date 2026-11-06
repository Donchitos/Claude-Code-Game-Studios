# Agent Coordination Map — 委派与升级表

> 精简后的委派关系、域边界、升级路径。被 skill 路由表(如 dev-story)参考。

---

## 委派关系

```
technical-director (opus, memory: user)
  ├─ lead-programmer (sonnet, memory: project)
  │    ├─ engine-programmer        owning: Source/core/**
  │    ├─ gameplay-programmer      owning: Source/gameplay/**
  │    ├─ ai-programmer            owning: Source/ai/**
  │    ├─ ui-programmer            owning: Source/ui/**
  │    ├─ network-programmer [opt] owning: Source/network/**
  │    ├─ tools-programmer [opt]   owning: Source/tools/**, Editor/**
  │    └─ performance-analyst [opt] owning: (只读分析,不改代码)
  ├─ qa-lead (sonnet)
  │    └─ qa-tester                owning: tests/**
  └─ unreal-specialist (sonnet)
       ├─ ue-gas-specialist         owning: GAS 相关 (Source/**/AbilitySystem/**)
       ├─ ue-blueprint-specialist   owning: Content/**/*.bp, Blueprint 资产
       ├─ ue-umg-specialist         owning: Source/ui/** (UMG/CommonUI 细节)
       └─ ue-replication-specialist [opt]  owning: 复制相关代码
```

---

## 域边界(谁拥有什么)

| Agent | 拥有路径 | 可读 | 可写 |
|-------|----------|------|------|
| engine-programmer | Source/core/** | 全部 | Source/core/** |
| gameplay-programmer | Source/gameplay/** | 全部 | Source/gameplay/** |
| ai-programmer | Source/ai/** | 全部 | Source/ai/** |
| ui-programmer | Source/ui/** | 全部 | Source/ui/** |
| network-programmer [opt] | Source/network/** | 全部 | Source/network/** |
| tools-programmer [opt] | Source/tools/**, Editor/** | 全部 | Source/tools/**, Editor/** |
| qa-tester | tests/** | 全部 | tests/** |
| unreal-specialist | (验证为主,不直接写业务代码) | 全部 | 见下 |
| ue-gas-specialist | Source/**/AbilitySystem/** | 全部 | GAS 相关文件 |
| ue-blueprint-specialist | Content/**/*.bp | 全部 | Blueprint 资产 |
| ue-umg-specialist | Source/ui/** (UMG 细节) | 全部 | UMG 控件 |
| ue-replication-specialist [opt] | 复制相关 | 全部 | 复制代码 |

**铁律**:任何 agent 不得写自己 owning 之外的文件,除非由 `lead-programmer` 显式委派。

---

## 升级路径

| 场景 | 升级给 |
|------|--------|
| 两个程序员实现分歧 | lead-programmer |
| 代码架构分歧 | technical-director |
| UE 子专家 vs gameplay-programmer(GAS 用法) | unreal-specialist → technical-director |
| 引擎 API 风险(Context7 查证后仍分歧) | technical-director |
| 性能预算冲突 | technical-director |
| 跨系统代码冲突 | lead-programmer → technical-director |
| 测试覆盖率争议 | qa-lead → technical-director |
| 需求歧义(feature spec 不清楚) | 用户(直接问,不升级给 agent) |

---

## dev-story 路由表(UE 5.8 版)

| 故事上下文 | 主 agent | 副手(引擎风险 HIGH 时) |
|-----------|----------|------------------------|
| Foundation 层 | engine-programmer | unreal-specialist |
| UI 类型 | ui-programmer | ue-umg-specialist |
| Visual/Feel | gameplay-programmer | unreal-specialist |
| 玩法机制 | gameplay-programmer | ue-gas-specialist(若涉 GAS) |
| AI 行为 | ai-programmer | unreal-specialist |
| 网络/复制 [opt] | network-programmer | ue-replication-specialist |
| Config/Data | 无 agent | 直接改数据文件(主会话执行) |

---

## 可选 agent 启用条件

| Agent | 启用条件 |
|-------|----------|
| network-programmer | 项目含多人游戏 |
| ue-replication-specialist | 项目含多人游戏 |
| tools-programmer | 需要编辑器扩展/自定义工具 |
| performance-analyst | 进入性能优化阶段 |

未启用的 agent 不在委派表里,dev-story 路由表对应行也不激活。
