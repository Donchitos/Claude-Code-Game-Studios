# 20 · Claude Code Memory 机制详解 —— 为什么项目用 active.md 而不是 Auto Memory

这是被反复问的一个问题：

> "Claude Code 自己不是有 Memory 机制吗？为什么项目不用，反而自己搞一套 active.md？这么做意图是什么、好处是什么？项目又是如何配合 Claude Code 自带记忆的？"

这一篇给初学者讲清楚。读完你能回答：

- Claude Code 自带的 Memory 是什么样的（CLAUDE.md + Auto Memory 双轨）
- Auto Memory 的能力上限、老化问题、为什么不适合做"工作状态恢复"
- 项目为什么用 active.md 这套自建机制做状态恢复
- 项目如何配合 Claude Code 自带记忆（不是"二选一"而是"分工"）
- 初学者迁移到自己项目时该怎么选

---

## 第一部分：Claude Code 自带的 Memory 是什么样的

Claude Code 的 Memory 是**双轨制**，两套机制互补但不互通。

### 1. 第一轨：CLAUDE.md（你手写的规则）

**是什么**：项目根目录（或 home 目录）下的一个 markdown 文件，**你手写**，Claude Code 在每个会话开始时自动加载。

**装什么**：

- 项目概述、技术栈
- 编码规范、命名约定
- 构建/测试命令
- 哪些文件不能动
- 项目级"硬规则"（如"必须用 TypeScript"、"不能引入新依赖"）

**特点**：

- **你掌控**：你写什么，Claude 就读什么
- **静态**：不会自动更新
- **每次会话都加载**：进入上下文是基线
- **可版本控制**：提交到 git，团队共享

**和项目的关系**：项目的 [CLAUDE.md](file:///workspace/CLAUDE.md) 就是这一轨。里面写了协作协议（Question→Options→Decision→Draft→Approval）、必须更新 active.md、文件即记忆等"硬规则"。

### 2. 第二轨：Auto Memory（Claude 自己写的笔记）

**是什么**：Claude Code 在工作中**自动**给自己写的笔记，存到 `~/.claude/projects/<repo>/memory/` 下，跨会话保留。

**装什么**（官方分四类）：

| 类型 | 内容 | 衰减速度 |
|------|------|----------|
| **user** | 用户角色、专业领域、沟通偏好、技能 | 慢（半年不变） |
| **feedback** | 用户给的纠正、被验证的方法、要避免的坑 | 慢（季度级） |
| **project** | 截止日期、决策、在飞的工作、动机 | **快**（每天变） |
| **reference** | 指向外部系统的指针（Linear、Slack、仪表盘） | 中 |

**存储结构**：

```
~/.claude/projects/<your-repo>/
├── memory/
│   ├── MEMORY.md           # 索引（≤200 行 / 25KB 硬上限）
│   ├── user_role.md        # 一个文件一个事实
│   ├── feedback_*.md
│   ├── project_*.md
│   └── reference_*.md
└── sessions/
    └── <session-uuid>.jsonl  # 完整对话流水，append-only
```

**关键约束**：

1. **一个文件一个事实**（原子化）
2. **MEMORY.md 索引 ≤ 200 行 / 25KB**（超出会**静默截断**底部，Claude 自己不知道被截了）
3. **每条记忆超过 1 天会带"新鲜度警告"**（Claude 被告知"这条可能过期了"）
4. **不该存的不存**：能 `git log` / `git blame` 查到的、在飞任务状态、调试 recipe、对话绑定细节 —— 这些明令禁止存

**怎么审计**：用 `/memory` 命令查看和编辑。

### 3. 两轨的分工

| 维度 | CLAUDE.md | Auto Memory |
|------|-----------|-------------|
| 谁写 | 你手写 | Claude 自动写 |
| 装什么 | 规则、约定、命令 | 事实、偏好、纠正 |
| 加载时机 | 每次会话开始 | 每次会话开始 |
| 位置 | 项目根 / home | `~/.claude/projects/<repo>/memory/` |
| 版本控制 | git tracked | **不进 git**（在 home 目录） |
| 团队共享 | 是 | **否**（每人私有） |
| 静态/动态 | 静态 | 动态（自动更新） |

**关键观察**：两轨都不在项目仓库里强绑定（CLAUDE.md 在 repo，Auto Memory 在 home）。**两轨都是"上下文作为软约束"**——Claude 把它们当上下文读，但可以不遵守。要硬约束必须用 hook（如 PreToolUse）。

---

## 第二部分：Auto Memory 的局限 —— 为什么不能拿来做"状态恢复"

这是回答用户问题的核心。Auto Memory 看起来正好能解决"中断后回来接着干"——但**不能拿来做工作状态恢复**。原因有六条。

### 1. 局限一：新鲜度天生不足

Auto Memory 的 **project 类**记忆衰减最快（每天变），但 Claude Code 给它的"新鲜度警告"阈值是**1 天**。

意思是：你周一晚下班，Claude 把"在做 combat-damage-calc 故事，第 3 节"存进 project memory。周二早上回来，这条记忆已经带"可能过期"警告。Claude 会**怀疑它**而不是**信任它**。

> 业界有句评论一针见血："stale memory is worse than no memory"（陈旧记忆比没记忆更糟）。AI 信任了过期记忆会比"啥都不知道"更糟——它会**自信地做错**。

### 2. 局限二：200 行 / 25KB 硬上限

MEMORY.md 索引有 200 行或 25KB 上限。超出会**静默截断底部**，Claude 自己不知道被截了。

一个稍微复杂的项目（10 个系统、每个 GDD 8 节、20 个 story、3 个 sprint）的工作状态远远超过这个容量。**状态恢复需要的细节量级，Auto Memory 装不下**。

### 3. 局限三：明令禁止存"在飞任务状态"

这是最直接的限制。Claude Code 的 Auto Memory **明确告诉 Claude 不要存**这些：

- 能用 `git log` / `git blame` 查到的事
- **在飞任务状态**（in-progress task state）
- 调试 recipe
- 对话绑定细节

而 active.md 装的恰恰就是"在飞任务状态"——当前任务、进度清单、未解决问题、改了哪些文件。**用 Auto Memory 装这些违反设计意图**，Claude 会拒绝写或写得不全。

### 4. 局限四：不在 git 里，团队不共享

Auto Memory 存在 `~/.claude/projects/<repo>/memory/`，**在用户的 home 目录**，不进项目 git。

这意味着：

- **团队成员之间不共享**：你的 Auto Memory 不是我的 Auto Memory
- **跨机器不同步**：你在公司电脑和家里电脑的 Auto Memory 是两份
- **不可审计**：团队里没人能看你写了什么

但工作状态往往需要团队共享——"昨天我做完 combat 的 damage calc，今天该接手 hitbox"，这个状态如果只在我的 Auto Memory 里，团队其他人看不到。

### 5. 局限五：自动提取 ≠ 精确控制

Auto Memory 是 Claude **自动**提取并写的。你不能精确控制：

- 什么时候写（Claude 觉得值得记就记）
- 写什么（Claude 自己决定字段）
- 写多详细（Claude 自己决定粒度）

而状态恢复需要**精确控制**：每个里程碑后必须更新、字段必须完整（Current Task / Progress / Decisions / Files / Open Questions）、粒度必须一致。这种精确性是 skill 正文 + Edit 工具才能保证的，自动提取做不到。

### 6. 局限六：压缩时不会被特殊保护

Claude Code 的 Auto Memory 在会话开始时加载，**压缩时不享受特殊保护**——它和对话里其它内容一样可能被摘要算法精简掉。

而项目的 active.md 有 **pre-compact.sh + post-compact.sh 双 hook**专门在压缩前后提醒大模型"读 active.md 恢复"。这是 Auto Memory 没有的待遇。

### 6 条局限总结表

| 局限 | 后果 |
|------|------|
| 新鲜度阈值 1 天 | 状态恢复时 Claude 怀疑记忆 |
| 200 行 / 25KB 上限 | 装不下复杂项目状态 |
| 明令禁止存"在飞任务状态" | 直接违反设计意图 |
| 不进 git，团队不共享 | 跨人协作断裂 |
| 自动提取不可控 | 字段不完整、粒度不一致 |
| 压缩时不特殊保护 | 可能被摘要算法丢掉 |

**结论**：Auto Memory 是"长期、模糊、个人化"的记忆，不是"精确、可审计、团队共享"的工作状态。**拿它做状态恢复是错配**。

---

## 第三部分：active.md 为什么是更好的选择

对比 Auto Memory 的六条局限，active.md 每一条都正好补上。

### 1. 对比表

| 维度 | Auto Memory | active.md |
|------|-------------|-----------|
| 新鲜度 | 1 天带警告 | **每次里程碑都更新**，永远新鲜 |
| 容量 | 200 行 / 25KB | **无上限**（但靠"只写当前快照"控制） |
| 内容限制 | 禁止存"在飞任务状态" | **专为存"在飞任务状态"设计** |
| Git | 不进 git | **进 git**（除 session-state/ 是 gitignored） |
| 团队共享 | 否 | **是**（除个人会话状态） |
| 写入控制 | Claude 自动提取 | **skill 正文强制规定字段和时机** |
| 压缩保护 | 无 | **pre-compact + post-compact 双 hook** |
| 审计轨迹 | 无 | **session-stop.sh 归档到 session-log.md** |

### 2. 设计意图

**active.md 不是"另一个 Memory"，是"工作状态检查点"**。两者的根本区别：

- **Auto Memory** 回答"Claude 长期记得什么"——是**知识**层
- **active.md** 回答"我现在手头在干什么"——是**状态**层

知识是慢变、模糊、可叠加的；状态是快变、精确、需覆盖的。**把它们放进同一个机制是设计错配**。

业界那句话再复习一遍：

> Memory is the background. The spec is the contract. Confuse the two and you get an agent that remembers everything and is sure about nothing.
> （记忆是背景。规约是契约。混淆两者你会得到一个记得一切却什么都不确定的 agent。）

**active.md 是契约，Auto Memory 是背景**。两者都需要，但职责不同。

### 3. 好处

#### 好处一：精确恢复

skill 在每个里程碑后用 Edit 工具**精确更新** active.md 的特定字段。下次会话恢复时，大模型读到的不是"模糊记得在做战斗系统"，而是：

```
Current Task: Implementing hitbox detection for combat system
Progress:
  - [x] Damage calculation formula locked
  - [x] Weapon types defined (3 melee, 2 ranged)
  - [ ] Hitbox detection (in progress)
  - [ ] Status effects
Files In Progress:
  - src/combat/hitbox.gd —— adding shape intersection
  - tests/unit/test_hitbox.gd —— 3 of 5 cases passing
Open Questions:
  - Should hitbox use Area3D or RayCast3D? —— waiting on ADR-007
```

这种精确度 Auto Memory 给不了。

#### 好处二：跨会话稳定

active.md 是磁盘文件，**不会随 Claude 的"自动提取"漂移**。今天写什么，明天读就是什么。

#### 好处三：跨人共享

虽然 `production/session-state/active.md` 本身是 gitignored（个人当前快照），但同结构的内容写到 `production/sprints/sprint-03.md`、`production/sprint-status.yaml` 这些 **git tracked** 文件里。团队成员拉代码就能看到所有人的工作状态。

#### 好处四：可审计

`session-stop.sh` 每次会话结束把 active.md 追加到 `production/session-logs/session-log.md`。**完整审计轨迹**——一周后你能查"上周三我做到哪了"。

#### 好处五：压缩时被保护

pre-compact.sh 在压缩前把 active.md 全文注入摘要输入；post-compact.sh 在压缩后立刻提醒读 active.md。**两道保险**，Auto Memory 没有这待遇。

#### 好处六：写入可控

skill 正文用指令性语言强制："After each milestone, update active.md"。字段、时机、粒度都是项目作者设计的，不是 Claude 自己决定的。

---

## 第四部分：项目如何配合 Claude Code 自带记忆

这是用户问题的第三部分——**项目不是"不用 Memory"，是"分工"**。

### 1. 三层分工模型

```
┌─────────────────────────────────────────────────────────────┐
│                  项目里的"记忆"三层分工                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─ 第一层：CLAUDE.md（项目自带，规则）────────────────┐   │
│  │  装什么：协作协议、硬规则、命名约定                  │   │
│  │  谁写：项目作者手写                                 │   │
│  │  何时读：每次会话开始                               │   │
│  │  例子：                              │   │
│  │  - "Every task follows: Question→Options→Decision"  │   │
│  │  - "Agents MUST update active.md after milestone"   │   │
│  │  - "The file is the memory, not the conversation"   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─ 第二层：active.md + production/（项目自建，状态）──┐   │
│  │  装什么：当前任务、进度、决策、文件、未解问题       │   │
│  │  谁写：skill 在里程碑后用 Edit 精确更新             │   │
│  │  何时读：session-start hook 提醒读、压缩前后提醒读  │   │
│  │  例子：active.md 里 "Current Task: hitbox detection"│   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─ 第三层：Auto Memory（Claude 自带，知识）───────────┐   │
│  │  装什么：用户偏好、长期反馈、参考指针               │   │
│  │  谁写：Claude 自动提取                              │   │
│  │  何时读：每次会话开始（Claude Code 默认行为）       │   │
│  │  例子：                                             │   │
│  │  - "用户偏好简短回复"（user 类）                    │   │
│  │  - "用户不喜欢 emoji"（feedback 类）                │   │
│  │  - "项目用 Godot 4.6"（project 类，慢变）           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**三层各司其职**：

| 层 | 装什么 | 谁写 | 例子 |
|----|--------|------|------|
| **CLAUDE.md** | 规则、约定 | 项目作者手写 | "必须问 May I write 才能写文件" |
| **active.md** | 当前状态 | skill 强制更新 | "在做 hitbox，第 3 节" |
| **Auto Memory** | 长期知识 | Claude 自动 | "用户偏好 TypeScript" |

**关键洞察**：项目不是"放弃 Auto Memory"，而是**不让 Auto Memory 装工作状态**。Auto Memory 该装的（user / feedback / 慢变 project 类）依然让它装，但"在飞任务状态"这种快变精确数据，**强制走 active.md**。

### 2. CLAUDE.md 怎么引导 Auto Memory

项目的 [CLAUDE.md](file:///workspace/CLAUDE.md) 里写了：

> Every task follows: Question -> Options -> Decision -> Draft -> Approval
> Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
> Agents MUST update production/session-state/active.md after each milestone

这三条是给大模型的**硬规则**。它们的作用：

- **第一条**：让大模型知道每次决策要走选项循环（配合 skill 正文）
- **第二条**：让大模型不擅自写文件（配合 AskUserQuestion）
- **第三条**：让大模型主动更新 active.md（配合 skill 里的 Edit 调用）

**注意**：CLAUDE.md 是"软约束"——大模型读到时**应该**遵守，但不是 100% 保证。所以第三条"必须更新 active.md"在关键 skill 里**还会再用 skill 正文重复一遍**，并配合 hook 做兜底。

### 3. Auto Memory 在项目里装什么

虽然项目不直接管 Auto Memory，但 Auto Memory 在这个项目里**自然**会积累这些：

| 类型 | 项目里会装什么 |
|------|----------------|
| user | "用户是游戏设计师，对机制平衡敏感"、"用户偏好中文回复" |
| feedback | "用户不喜欢 agent 一次性写完整个 GDD，要分节确认"、"用户要求代码必须有单元测试" |
| project（慢变） | "项目是 2D 俯视角 roguelike"、"用 Godot 4.6"、"目标平台 Steam" |
| reference | "Linear 看任务"、"设计参考文档在 design/gdd/" |

**这些项目不管，让它自然积累**。Claude Code 会自动提取，下次会话自动加载。

### 4. Auto Memory 不该装什么（项目用 active.md 替代）

| 不该装的 | 项目用谁装 |
|----------|------------|
| "当前在做 hitbox 故事" | active.md 的 Current Task |
| "已完成第 1-4 节" | active.md 的 Progress Checklist |
| "决策：用 Area3D 不用 RayCast3D" | active.md 的 Key Decisions（永久版进 ADR） |
| "改了 src/combat/hitbox.gd" | active.md 的 Files In Progress |
| "卡在 ADR-007 等架构决策" | active.md 的 Open Questions |

**分工原则**：**慢变、模糊、个人化 → Auto Memory；快变、精确、需共享 → active.md**。

### 5. 协作示意

```
会话开始
   ↓
Claude Code 引擎自动加载：
   ├─ CLAUDE.md（项目规则）       ← 你手写
   ├─ .claude/rules/*.md（路径规则）← 你手写
   └─ ~/.claude/.../memory/（Auto Memory）← Claude 自动
   ↓
session-start.sh hook 自动跑：
   └─ 检测 active.md → 预览最后 20 行 → 提醒大模型读全文
   ↓
大模型读 active.md 全文（恢复工作状态）
   ↓
工作中……
   ↓
完成一个里程碑 → skill 正文要求 → 大模型用 Edit 更新 active.md
   ↓
（同时 Claude 可能自动往 Auto Memory 写：用户偏好、长期反馈）
   ↓
会话结束 → session-stop.sh hook 把 active.md 归档到 session-log.md
```

**三层并行运作**，互不冲突。

---

## 第五部分：为什么这么设计 —— 意图与好处

把前面所有部分总结成"设计意图"。

### 意图一：把"快变状态"从 Auto Memory 里剥离

Auto Memory 是为"长期、慢变"设计的（user / feedback 类半年不变）。把"今天做到哪了"塞进去会**污染**它——状态变化太快，Auto Memory 来不及更新就过期了。

**剥离的好处**：

- Auto Memory 保持干净（只装真正长期的事）
- 工作状态有专用通道（active.md），更新及时、字段完整

### 意图二：让状态进 git，让 Auto Memory 不进 git

Auto Memory 在 home 目录，**不进项目 git**。这是 Claude Code 的设计选择——Auto Memory 是个人化的。

但工作状态往往需要团队共享。所以 active.md（个人当前快照）gitignored，但 `production/sprint-status.yaml`、`production/sprints/*.md` 这些**结构化状态文件**进 git。**团队共享的部分进 git，个人化的部分不进**。

### 意图三：精确控制 vs 自动提取

Auto Memory 是"AI 觉得值得记就记"。这种自动性适合"长期偏好"，但不适合"工作状态"——后者必须**精确**：

- 必须每个里程碑都更新（不能漏）
- 字段必须完整（Current Task / Progress / Decisions / Files / Open Questions）
- 粒度必须一致（不能这次写一段下次写一行）

精确性靠 skill 正文强制 + Edit 工具原子更新。**这是自动提取给不了的**。

### 意图四：契约 vs 背景

回到那句业界格言：

> Memory is the background. The spec is the contract.

- **背景**（Auto Memory）：辅助、模糊、可错。Claude 参考，但不依赖。
- **契约**（active.md + GDD + sprint-status.yaml）：精确、权威、必遵。Claude 依赖它做恢复。

**混淆两者是大问题**——拿背景当契约会"自信地做错"；拿契约当背景会"啥都不确定"。项目把两者明确分开。

### 意图五：可审计、可回溯

Auto Memory 不可审计——Claude 写了什么你不太清楚，且会自动演化。

active.md 有完整审计轨迹：

- 每次会话结束 session-stop.sh 归档到 session-log.md
- 每次压缩 pre-compact.sh 写一行到 compaction-log.txt
- GDD 文件本身的增量写入是 git 历史

**一周后你能查"上周三我做到哪了、做了什么决策、改了哪些文件"**。Auto Memory 给不了这个。

### 意图六：压缩时被特殊保护

Auto Memory 在压缩时和对话里其它内容一样，可能被摘要算法精简。

active.md 有 **pre-compact.sh + post-compact.sh 双 hook**：

- 压缩前把 active.md 全文注入摘要输入（让摘要有内容可保留）
- 压缩后立刻喊"读 active.md 恢复"（让大模型重新加载）

**两道保险**确保压缩不丢工作状态。Auto Memory 没这待遇。

---

## 第六部分：初学者迁移指南

### 1. 该不该禁用 Auto Memory

**不该**。Auto Memory 在它擅长的领域（user / feedback / 慢变 project）很有用。禁了反而失去 Claude Code 的一个能力。

**正确做法**：让 Auto Memory 装它该装的，另建 active.md 装工作状态。

### 2. 何时该用 Auto Memory，何时该建自己的状态文件

判断流程：

```
这个信息是……
   ↓
┌─ 慢变（月级以上不变）？─── 是 → 考虑 Auto Memory
│                              （让 Claude 自动提取）
│
├─ 快变（每天/每会话变）？── 是 → 建 active.md
│                              （skill 强制更新）
│
├─ 需要团队共享？───────── 是 → 进 git 的状态文件
│                              （如 sprint-status.yaml）
│
└─ 个人化？────────────── 是 → 不进 git
                              （如 session-state/active.md）
```

### 3. 具体例子

| 信息 | 该装哪 |
|------|--------|
| "用户偏好 TypeScript" | Auto Memory（user 类，慢变，个人化） |
| "用户不喜欢长解释" | Auto Memory（feedback 类，慢变，个人化） |
| "项目用 React 18" | CLAUDE.md（项目级规则，团队共享） |
| "在做用户登录功能，写到第 3 步" | active.md（快变，工作状态） |
| "决定用 JWT 不用 session" | ADR（决策永久记录）+ active.md（当前会话引用） |
| "改了 src/auth.ts" | active.md 的 Files In Progress |

### 4. 迁移步骤

#### Step 1：保留 Auto Memory 默认开启

不动 Claude Code 的 Auto Memory 设置。

#### Step 2：写 CLAUDE.md

把项目级硬规则写进 CLAUDE.md。关键加一条：

```markdown
## Context Management

The file is the memory, not the conversation.
Agents MUST update production/session-state/active.md after each milestone.
```

这条让大模型知道"工作状态走 active.md，不走 Auto Memory"。

#### Step 3：建 active.md 机制

照 [18 篇第四部分](file:///workspace/study-docs/18-会话状态保存与选项澄清机制.md) 的 12 步落地。

#### Step 4：在 skill 里强制更新 active.md

每个 skill 在里程碑后加："Use Edit to update active.md's [field]"。

#### Step 5：不阻止 Auto Memory 自然积累

用户偏好、长期反馈——让 Claude 自己写 Auto Memory，不管它。

### 5. 验证

跑一段时间后检查：

- [ ] active.md 在每个里程碑后都被更新（看 git log 或文件 mtime）
- [ ] 压缩后大模型能正确恢复（看 post-compact 后的对话）
- [ ] 中断重启后大模型主动说"上次做到 X，要继续吗"
- [ ] Auto Memory 没装"在飞任务状态"（用 `/memory` 检查）
- [ ] Auto Memory 装了用户偏好和长期反馈（用 `/memory` 检查）

---

## 第七部分：常见误区

### 误区一："既然有 Auto Memory，active.md 是多此一举"

**错**。两者职责不同：Auto Memory 是背景知识，active.md 是工作契约。**背景不能替代契约**。详见第二部分六条局限。

### 误区二："把所有东西塞进 Auto Memory 就行了"

**错**。Auto Memory 有 200 行 / 25KB 上限、禁止存"在飞任务状态"、不进 git、压缩时不保护。**塞不进也装不好**。

### 误区三："禁用 Auto Memory 才干净"

**错**。Auto Memory 在它擅长的领域（user / feedback / 慢变 project）很有用。禁了失去 Claude Code 一个能力。**正确做法是分工**。

### 误区四："CLAUDE.md 是记忆"

**部分错**。CLAUDE.md 是"规则"，不是"记忆"。它装的是"必须遵守的约定"，不是"现在的状态"。**规则不变，状态常变**。

### 误区五："active.md 是 Memory 的一种"

**错**。active.md 是**状态检查点**，不是 Memory。Memory 是长期知识，状态是当前快照。**混淆会导致用错**。

### 误区六："Auto Memory 会自动恢复工作状态"

**错**。Auto Memory 明令禁止存"在飞任务状态"。它装的是"用户偏好"和"长期反馈"，不是"今天做到哪了"。

### 误区七："Hook 能替代 Auto Memory"

**错**。Hook 是事件触发的脚本，不是记忆系统。hook 只能提醒大模型"读 active.md"，不能存储知识。**hook、active.md、Auto Memory 三者并行**。

---

## 第八部分：一张图总结

```
┌──────────────────────────────────────────────────────────────────┐
│            Claude Code 项目里"记忆"的完整生态                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─ 上下文层（每次会话加载）─────────────────────────────┐      │
│  │                                                       │      │
│  │  CLAUDE.md         ← 你手写的项目规则                 │      │
│  │  .claude/rules/    ← 路径相关的编码规范               │      │
│  │  Auto Memory       ← Claude 自动写的长期笔记          │      │
│  │  (user/feedback/   (在 ~/.claude/.../memory/)         │      │
│  │   project/reference)                                  │      │
│  │                                                       │      │
│  │  → 都是"软约束"，大模型读到时应该遵守                  │      │
│  │  → 硬约束要靠 hook（如 PreToolUse）                    │      │
│  └───────────────────────────────────────────────────────┘      │
│                                                                  │
│  ┌─ 状态层（项目自建，hook 提醒读）──────────────────────┐      │
│  │                                                       │      │
│  │  active.md              ← 当前任务快照（gitignored）  │      │
│  │  production/sprint-status.yaml ← 故事状态机           │      │
│  │  production/stage.txt   ← 项目阶段                    │      │
│  │  production/sprints/*.md ← 冲刺计划                   │      │
│  │  production/epics/**    ← 故事文件                    │      │
│  │                                                       │      │
│  │  → 精确、可审计、团队共享（除 session-state/）        │      │
│  │  → skill 强制写入，hook 强制提醒读                    │      │
│  └───────────────────────────────────────────────────────┘      │
│                                                                  │
│  ┌─ 审计层（追加，gitignored）───────────────────────────┐      │
│  │                                                       │      │
│  │  session-logs/session-log.md     ← 会话归档           │      │
│  │  session-logs/compaction-log.txt ← 压缩事件           │      │
│  │                                                       │      │
│  │  → 只追加不覆盖                                       │      │
│  └───────────────────────────────────────────────────────┘      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

         Auto Memory 装什么             active.md 装什么
         ─────────────────              ─────────────────
         ✓ 用户偏好                     ✓ 当前任务
         ✓ 长期反馈                     ✓ 进度清单
         ✓ 慢变项目事实                 ✓ 本次会话决策
         ✓ 外部系统指针                 ✓ 正在改的文件
                                        ✓ 未解决问题
         ✗ 在飞任务状态
         ✗ 今天做到哪                   ✗ 用户偏好（让 Auto Memory 装）
         ✗ 改了哪些文件                 ✗ 长期反馈（让 Auto Memory 装）
```

---

## 附录：关键源码索引

| 文件 | 看什么 |
|------|--------|
| [CLAUDE.md](file:///workspace/CLAUDE.md) | 项目根规则，引导大模型"工作状态走 active.md" |
| [.claude/docs/context-management.md](file:///workspace/.claude/docs/context-management.md) | "文件即记忆"原则的正式表述 |
| [.claude/hooks/session-start.sh](file:///workspace/.claude/hooks/session-start.sh) | 检测 active.md 并提醒大模型读 |
| [.claude/hooks/pre-compact.sh](file:///workspace/.claude/hooks/pre-compact.sh) | 压缩前把 active.md 注入摘要输入 |
| [.claude/hooks/post-compact.sh](file:///workspace/.claude/hooks/post-compact.sh) | 压缩后提醒读 active.md |
| [.claude/hooks/session-stop.sh](file:///workspace/.claude/hooks/session-stop.sh) | 归档 active.md 到 session-log.md |
| [18-会话状态保存与选项澄清机制.md](file:///workspace/study-docs/18-会话状态保存与选项澄清机制.md) | active.md 状态环完整讲解 |
| [19-Claude-Code工具系统详解.md](file:///workspace/study-docs/19-Claude-Code工具系统详解.md) | Edit/Read 等 tools 如何精确更新 active.md |

---

## 小测验

1. **Claude Code 的 Auto Memory 分哪四类？哪一类衰减最快？**
   <details><summary>答案</summary>
   分 user / feedback / project / reference 四类。project 类衰减最快（每天变），所以"今天做到哪"这种工作状态如果塞进 project 类，第二天就带新鲜度警告。其它三类衰减慢（user/feedback 季度级，reference 中等）。
   </details>

2. **Auto Memory 的 MEMORY.md 索引有容量上限吗？超出会怎样？**
   <details><summary>答案</summary>
   有上限：200 行或 25KB，谁先到算谁。超出会"静默截断"底部条目——Claude 自己不知道被截了，也不会警告用户。这是 Auto Memory 最被诟病的弱点之一，复杂项目状态远超这个容量。
   </details>

3. **为什么 Auto Memory 明令禁止存"在飞任务状态"？**
   <details><summary>答案</summary>
   因为在飞任务状态变化太快，存进去立刻过期。Claude Code 的设计者明白：stale memory is worse than no memory（陈旧记忆比没记忆更糟）——AI 信任过期记忆会比"啥都不知道"更糟，会"自信地做错"。所以禁止存这种快变状态，让 Claude 用 git log / 文件系统去查最新状态。
   </details>

4. **active.md 和 Auto Memory 的根本区别是什么？**
   <details><summary>答案</summary>
   Auto Memory 是"长期、模糊、个人化"的知识层（背景）；active.md 是"快变、精确、可审计"的状态层（契约）。前者回答"Claude 长期记得什么"，后者回答"我现在手头在干什么"。混淆两者会得到"记得一切却什么都不确定"的 agent。
   </details>

5. **项目为什么要保留 Auto Memory 而不是禁用？**
   <details><summary>答案</summary>
   因为 Auto Memory 在它擅长的领域（user / feedback / 慢变 project / reference）很有用。它能自动积累"用户偏好简短回复"、"用户不喜欢 emoji"等长期反馈，不需要用户每次重说。禁了反而失去 Claude Code 一个能力。正确做法是分工：Auto Memory 装长期知识，active.md 装工作状态。
   </details>

6. **CLAUDE.md 里的"必须更新 active.md"是硬约束还是软约束？项目如何补强？**
   <details><summary>答案</summary>
   软约束。CLAUDE.md 是大模型读到时"应该"遵守的，但不是 100% 保证（probability-driven）。项目用两种方式补强：(1) 在每个 skill 正文里重复"update active.md"指令并规定字段和时机；(2) 用 hook 做"读"侧的兜底——session-start / pre-compact / post-compact 三个 hook 强制提醒大模型读 active.md。写靠 skill，读靠 hook。
   </details>

7. **团队协作时，为什么 active.md 的 gitignored 版本不进 git，但 sprint-status.yaml 进 git？**
   <details><summary>答案</summary>
   active.md 是个人"当前在干什么"的私有快照，跨开发者协作时每人不同，且历史已归档到 session-logs/。sprint-status.yaml 是团队共享的故事状态机，所有人都需要看到"哪个故事做到哪了"。判断标准：这个文件对其他开发者有价值吗？有 → 进 git；没 → gitignore。
   </details>

8. **压缩时 Auto Memory 和 active.md 待遇有什么不同？**
   <details><summary>答案</summary>
   Auto Memory 在压缩时和对话里其它内容一样，可能被摘要算法精简，没有特殊保护。active.md 有 pre-compact.sh + post-compact.sh 双 hook：前者在压缩前把 active.md 全文注入摘要输入（让摘要有内容可保留），后者在压缩后立刻喊"读 active.md 恢复"。两道保险确保压缩不丢工作状态。
   </details>

9. **业界那句"Memory is the background. The spec is the contract."在项目里对应什么？**
   <details><summary>答案</summary>
   background（背景）对应 Auto Memory——长期、模糊、可错，Claude 参考但不依赖。contract（契约）对应 active.md + GDD + sprint-status.yaml——精确、权威、必遵，Claude 依赖它做恢复。项目明确把两者分开：Auto Memory 装背景知识，active.md 装工作契约。混淆会得到"记得一切却什么都不确定"的 agent。
   </details>

10. **初学者迁移时该怎么处理 Auto Memory 和自建 active.md 的关系？**
    <details><summary>答案</summary>
    三步：(1) 保留 Auto Memory 默认开启，不阻止它自然积累用户偏好和长期反馈；(2) 写 CLAUDE.md 时加一条"工作状态走 active.md"，让大模型知道分工；(3) 建 active.md 机制（12 步落地）并在 skill 里强制更新。验证标准：Auto Memory 没装"在飞任务状态"（用 /memory 检查），active.md 在每个里程碑后都被更新。
    </details>
