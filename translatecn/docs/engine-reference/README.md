# Engine Reference Documentation
# 引擎参考文档

This directory contains curated, version-pinned documentation snapshots for the
game engine(s) used in this project. These files exist because **LLM knowledge
has a cutoff date** and game engines update frequently.
本目录包含为本项目所使用的游戏引擎精心整理、按版本锁定的文档快照。这些文件之所以存在，是因为 **LLM 知识具有截止日期**，而游戏引擎更新频繁。

## Why This Exists
## 为何需要这些文档

Claude's training data has a knowledge cutoff (currently May 2025). Game engines
like Godot, Unity, and Unreal ship updates that introduce breaking API changes,
new features, and deprecated patterns. Without these reference files, agents will
suggest outdated code.
Claude 的训练数据存在知识截止时间（目前为 2025 年 5 月）。Godot、Unity 和 Unreal 等游戏引擎发布的更新会引入破坏性 API 变更、新功能以及被弃用的模式。如果没有这些参考文件，智能体就会建议使用过时的代码。

## Structure
## 结构

Each engine gets its own directory:
每个引擎都有各自的目录：

```
<engine>/
├── VERSION.md              # Pinned version, verification date, knowledge gap window
├── breaking-changes.md     # API changes between versions, organized by risk level
├── deprecated-apis.md      # "Don't use X → Use Y" lookup tables
├── current-best-practices.md  # New practices not in model training data
└── modules/                # Per-subsystem quick references (~150 lines max each)
    ├── rendering.md
    ├── physics.md
    └── ...
```

## How Agents Use These Files
## 智能体如何使用这些文件

Engine-specialist agents are instructed to:
引擎专家智能体被指示：

1. Read `VERSION.md` to confirm the current engine version
1. 读取 `VERSION.md` 以确认当前引擎版本

2. Check `deprecated-apis.md` before suggesting any engine API
2. 在建议任何引擎 API 之前查阅 `deprecated-apis.md`

3. Consult `breaking-changes.md` for version-specific concerns
3. 查阅 `breaking-changes.md` 以了解版本相关的注意事项

4. Read relevant `modules/*.md` for subsystem-specific work
4. 阅读相关的 `modules/*.md` 以处理特定子系统的工作

## Maintenance
## 维护

### When to Update
### 何时更新

- After upgrading the engine version
- 升级引擎版本之后

- When the LLM model is updated (new knowledge cutoff)
- LLM 模型更新时（新的知识截止时间）

- After running `/setup-engine refresh`
- 运行 `/setup-engine refresh` 之后

- When you discover an API the model gets wrong
- 当你发现某个 API 模型回答错误时

### How to Update
### 如何更新

1. Update `VERSION.md` with the new engine version and date
1. 用新的引擎版本和日期更新 `VERSION.md`

2. Add new entries to `breaking-changes.md` for the version transition
2. 针对版本过渡，在 `breaking-changes.md` 中添加新条目

3. Move newly deprecated APIs into `deprecated-apis.md`
3. 将新弃用的 API 移入 `deprecated-apis.md`

4. Update `current-best-practices.md` with new patterns
4. 用新模式更新 `current-best-practices.md`

5. Update relevant `modules/*.md` with API changes
5. 用 API 变更更新相关的 `modules/*.md`

6. Set "Last verified" dates on all modified files
6. 在所有修改过的文件上设置"Last verified"日期

### Quality Rules
### 质量规则

- Every file must have a "Last verified: YYYY-MM-DD" date
- 每个文件都必须有"Last verified: YYYY-MM-DD"日期

- Keep module files under 150 lines (context budget)
- 模块文件保持在 150 行以下（上下文预算）

- Include code examples showing correct/incorrect patterns
- 包含展示正确/错误模式的代码示例

- Link to official documentation URLs for verification
- 链接到官方文档 URL 以供核验

- Only document things that differ from the model's training data
- 仅记录与模型训练数据不同的内容
