# Adoption Plan
# 采纳计划

> **Generated**: [date]
> **Project phase**: [phase]
> **Engine**: [name + version, or "Not configured"]
> **Template version**: v1.0+
> **生成时间**：[date]
> **项目阶段**：[phase]
> **引擎**：[名称 + 版本，或“未配置”]
> **模板版本**：v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.
按顺序完成以下步骤。每完成一项就勾选一项。
可随时重新运行 `/adopt` 检查剩余缺口。

---

## Step 1: Fix Blocking Gaps
## 步骤 1：修复阻塞性缺口

[One sub-section per blocking gap with problem, fix command, time estimate, checkbox]
[每个阻塞性缺口一个子节，包含问题、修复命令、时间估计和复选框]

---

## Step 2: Fix High-Priority Gaps
## 步骤 2：修复高优先级缺口

[One sub-section per high gap]
[每个高优先级缺口一个子节]

---

## Step 3: Bootstrap Infrastructure
## 步骤 3：引导基础设施

[At `workflow: minimal`, replace 3a–3d with one line: "Not on the minimal path —
the brief's build order is the plan. Next: `/create-stories` (or `/dev-story`
once stories exist)."]
[当 `workflow: minimal` 时，将 3a–3d 替换为一行：“不在最小路径上 —
简报的构建顺序就是计划。下一步：`/create-stories`（若故事已存在，则为 `/dev-story`）。”]

### 3a. Register existing requirements (creates tr-registry.yaml)
### 3a. 注册现有需求（创建 tr-registry.yaml）
Run `/architecture-review` — even if ADRs already exist, this run bootstraps
the TR registry from your existing GDDs and ADRs.
**Time**: 1 session (review can be long for large codebases)
- [ ] tr-registry.yaml created
运行 `/architecture-review` — 即使 ADR 已存在，本次运行也会从现有 GDD 与 ADR 引导生成 TR 注册表。
**时间**：1 个会话（大型代码库的审查可能较长）
- [ ] tr-registry.yaml 已创建

### 3b. Create control manifest
### 3b. 创建控制清单
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created
运行 `/create-control-manifest`
**时间**：30 分钟
- [ ] docs/architecture/control-manifest.md 已创建

### 3c. Create sprint tracking file
### 3c. 创建冲刺跟踪文件
Run `/sprint-plan update`
**Time**: 5 min (if sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created
运行 `/sprint-plan update`
**时间**：5 分钟（若冲刺计划已以 markdown 存在）
- [ ] production/sprint-status.yaml 已创建

### 3d. Set authoritative project stage
### 3d. 设定权威项目阶段
Run `/gate-check [current-phase]` (the gate into the phase the project is in;
at Concept there is none — Concept is the default stage, nothing to run)
**Time**: 5 min
- [ ] `project.stage` in `project.yaml` written (legacy `production/stage.txt` also updated)
运行 `/gate-check [current-phase]`（进入项目当前所在阶段的关卡检查；
在概念阶段没有关卡 — 概念是默认阶段，无需运行）
**时间**：5 分钟
- [ ] `project.yaml` 中的 `project.stage` 已写入（遗留的 `production/stage.txt` 也已更新）

---

## Step 4: Medium-Priority Gaps
## 步骤 4：中优先级缺口

[One sub-section per medium gap]
[每个中优先级缺口一个子节]

---

## Step 5: Optional Improvements
## 步骤 5：可选改进

[One sub-section per low gap]
[每个低优先级缺口一个子节]

---

## What to Expect from Existing Stories
## 对现有故事的预期

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.
现有故事可继续与所有模板技能配合使用。当相关字段缺失时，新的格式检查
（TR-ID 校验、清单版本过期检查）会自动通过 — 因此不会中断。在重新生成之前，
它们不会受益于过期跟踪。不要重新生成正在进行或已完成的故事。

---

## Re-run
## 重新运行

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
完成步骤 3 后再次运行 `/adopt`，以验证所有阻塞性和高优先级缺口均已解决。
新的运行将反映项目的当前状态。
