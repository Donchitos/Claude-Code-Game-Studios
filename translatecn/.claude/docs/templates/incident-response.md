# Incident Response: [Incident Title]
# 事故响应：[事故标题]

**Severity**: [S1-Critical / S2-High / S3-Medium / S4-Low]
**Status**: [Active / Mitigated / Resolved / Post-Mortem Complete]
**Detected**: [Date Time UTC]
**Resolved**: [Date Time UTC or ONGOING]
**Duration**: [Total time from detection to resolution]
**Incident Commander**: [Name/Role]
**严重程度**：[S1-严重 / S2-高 / S3-中 / S4-低]
**状态**：[进行中 / 已缓解 / 已解决 / 复盘已完成]
**检测时间**：[Date Time UTC]
**解决时间**：[Date Time UTC 或 仍在进行]
**持续时间**：[从检测到解决的总时长]
**事故指挥官**：[Name/Role]

---

## Impact Summary
## 影响摘要

[2-3 sentences describing what players experienced. Write from the player
perspective, not the technical perspective.]
[2-3 句描述玩家经历了什么。从玩家视角书写，而非技术视角。]

- **Players affected**: [estimated count or percentage]
- **Platforms affected**: [PC / Console / Mobile / All]
- **Regions affected**: [All / specific regions]
- **Revenue impact**: [estimated if applicable]
- **受影响玩家**：[估计数量或百分比]
- **受影响平台**：[PC / 主机 / 移动端 / 全部]
- **受影响地区**：[全部 / 特定地区]
- **收入影响**：[如适用，估计值]

---

## Timeline
## 时间线

| Time (UTC) | Event | Action Taken |
| ---- | ---- | ---- |
| [HH:MM] | Incident detected via [monitoring/player report/etc.] | Incident commander assigned |
| [HH:MM] | Root cause identified | [Brief description of cause] |
| [HH:MM] | Mitigation deployed | [What was done] |
| [HH:MM] | Service restored / Fix confirmed | Monitoring for recurrence |
| [HH:MM] | All-clear declared | Post-mortem scheduled |

| 时间（UTC） | 事件 | 采取的行动 |
| ---- | ---- | ---- |
| [HH:MM] | 通过[监控/玩家报告等]检测到事故 | 已指派事故指挥官 |
| [HH:MM] | 定位根本原因 | [原因简述] |
| [HH:MM] | 已部署缓解措施 | [做了什么] |
| [HH:MM] | 服务恢复 / 修复确认 | 监控是否复发 |
| [HH:MM] | 宣布解除警报 | 已安排复盘 |

---

## Root Cause
## 根本原因

### What Happened
### 发生了什么
[Technical description of the root cause. Be specific about the chain of events
that led to the incident.]
[对根本原因的技术描述。具体说明导致该事故的事件链。]

### Why It Happened
### 为何发生
[Systemic cause — why did existing processes, tests, or safeguards fail to
prevent this? This is more important than the technical cause.]
[系统性原因 —— 现有流程、测试或防护措施为何未能阻止此事？这比技术原因更重要。]

### Contributing Factors
### 促成因素
- [Factor 1 — e.g., "Insufficient load testing for the new matchmaking system"]
- [因素 1 —— 例如“新匹配系统负载测试不足”]
- [Factor 2 — e.g., "Monitoring alert threshold was set too high"]
- [因素 2 —— 例如“监控告警阈值设置过高”]
- [Factor 3]
- [因素 3]

---

## Mitigation and Resolution
## 缓解与解决

### Immediate Actions (during incident)
### 即时行动（事故期间）
1. [Action taken to stop the bleeding]
1. [为快速止血而采取的行动]
2. [Action taken to restore service]
2. [为恢复服务而采取的行动]
3. [Action taken to verify resolution]
3. [为验证解决而采取的行动]

### Follow-Up Actions (after resolution)
### 后续行动（解决之后）
1. [Permanent fix if immediate action was a workaround]
1. [若即时行动是变通方案，则需永久修复]
2. [Additional testing or monitoring added]
2. [新增的测试或监控]
3. [Process changes to prevent recurrence]
3. [防止复发的流程变更]

---

## Player Communication
## 玩家沟通

### Initial Acknowledgment
### 初次确认
*Sent: [Time] via [channel]*
*发送时间：[Time]，渠道：[channel]*
> [Exact text of the first public message acknowledging the issue]
> [确认该问题的第一条公开消息原文]

### Status Updates
### 状态更新
*Sent: [Time] via [channel]*
*发送时间：[Time]，渠道：[channel]*
> [Text of each subsequent update]
> [每条后续更新的文本]

### Resolution Notice
### 解决通知
*Sent: [Time] via [channel]*
*发送时间：[Time]，渠道：[channel]*
> [Text announcing the fix and any compensation]
> [宣布修复及任何补偿的文本]

### Compensation (if applicable)
### 补偿（如适用）
- **What**: [description of compensation — e.g., "500 premium currency + 24-hour XP boost"]
- **Who**: [all players / affected players only / players who logged in during incident]
- **When**: [delivery date and method]
- **Rationale**: [why this compensation is appropriate for the impact]
- **内容**：[补偿描述 —— 例如“500 高级货币 + 24 小时经验加成”]
- **对象**：[所有玩家 / 仅受影响玩家 / 事故期间登录的玩家]
- **时间**：[发放日期与方式]
- **理由**：[为何该补偿与影响程度相称]

---

## Prevention
## 预防

### What We Are Changing
### 我们正在做出的改变

| Action Item | Owner | Deadline | Status |
| ---- | ---- | ---- | ---- |
| [Specific preventive measure] | [Role] | [Date] | [TODO/Done] |
| [Add monitoring for X] | [Role] | [Date] | [TODO/Done] |
| [Add test coverage for Y] | [Role] | [Date] | [TODO/Done] |
| [Update runbook for Z] | [Role] | [Date] | [TODO/Done] |

| 行动项 | 负责人 | 截止日期 | 状态 |
| ---- | ---- | ---- | ---- |
| [具体预防措施] | [Role] | [Date] | [TODO/已完成] |
| [为 X 增加监控] | [Role] | [Date] | [TODO/已完成] |
| [为 Y 增加测试覆盖] | [Role] | [Date] | [TODO/已完成] |
| [更新 Z 的运行手册] | [Role] | [Date] | [TODO/已完成] |

### Process Improvements
### 流程改进
- [Process change to prevent similar incidents]
- [防止类似事故的流程变更]
- [Monitoring/alerting improvement]
- [监控/告警改进]
- [Testing improvement]
- [测试改进]

---

## Lessons Learned
## 经验教训

### What Went Well
### 表现良好之处
- [Positive aspect of incident response — e.g., "Detection was fast due to
  monitoring alerts"]
- [事故响应的积极面 —— 例如“得益于监控告警，检测很快”]
- [Positive aspect]
- [积极面]

### What Went Poorly
### 表现不佳之处
- [Problem with response — e.g., "Took 20 minutes to identify the correct
  on-call person"]
- [响应中的问题 —— 例如“花了 20 分钟才找到正确的值班人员”]
- [Problem]
- [问题]

### Where We Got Lucky
### 我们侥幸之处
- [Factor that reduced impact by chance rather than design — these are hidden
  risks to address]
- [因偶然而非设计而降低影响的因素 —— 这些是需要处理的隐藏风险]

---

## Sign-Offs
## 签署确认

- [ ] Technical Director — Root cause accurate, prevention plan sufficient
- [ ] 技术总监 — 根本原因准确，预防计划充分
- [ ] QA Lead — Test coverage gaps addressed
- [ ] QA 负责人 — 测试覆盖缺口已处理
- [ ] Producer — Timeline and communication reviewed
- [ ] 制作人 — 时间线与沟通已评审
- [ ] Community Manager — Player communication reviewed
- [ ] 社区经理 — 玩家沟通已评审

---

*This document is filed in `production/hotfixes/` and linked from the
release notes for the fix version.*
*本文件归档于 `production/hotfixes/`，并从修复版本的发布说明中链接。*
