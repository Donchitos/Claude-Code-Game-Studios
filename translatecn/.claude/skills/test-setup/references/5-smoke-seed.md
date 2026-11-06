# /test-setup — Phase 5: Create Smoke Test Seed

# /test-setup — 第 5 阶段：创建冒烟测试种子

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/test-setup` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 5: Create Smoke Test Seed

## 第 5 阶段：创建冒烟测试种子

Create `tests/smoke/critical-paths.md`:

创建 `tests/smoke/critical-paths.md`：

```markdown
# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to main menu without crash
2. New game / session can be started from the main menu
3. Main menu responds to all inputs without freezing

## Core Mechanic (update per sprint)

<!-- Add the primary mechanic for each sprint here as it is implemented -->
<!-- Example: "Player can move, jump, and the camera follows correctly" -->
4. [Primary mechanic — update when first core system is implemented]

## Data Integrity

5. Save game completes without error (once save system is implemented)
6. Load game restores correct state (once load system is implemented)

## Performance

7. No visible frame rate drops on target hardware (60fps target)
8. No memory growth over 5 minutes of play (once core loop is implemented)
```

```markdown
# 冒烟测试：关键路径

**目的**：在任何 QA 交接之前，用 15 分钟以内的时间运行这 10-15 项检查。
**运行方式**：`/smoke-check`（它会读取本文件）
**更新**：在实现新的核心系统时添加新条目。

## 核心稳定性（始终运行）

1. 游戏能启动到主菜单且不崩溃
2. 能从主菜单开始新游戏 / 新会话
3. 主菜单响应所有输入且不卡死

## 核心机制（每个冲刺更新）

<!-- 每个冲刺在实现主要机制后，将其添加到这里 -->
<!-- 示例：“玩家可以移动、跳跃，并且相机正确跟随” -->
4. [主要机制 —— 在第一个核心系统实现时更新]

## 数据完整性

5. 存档完成且无错误（在存档系统实现之后）
6. 读档恢复正确的状态（在读档系统实现之后）

## 性能

7. 目标硬件上没有可见的帧率下降（目标 60fps）
8. 游玩 5 分钟内没有内存增长（在核心循环实现之后）
```

---
