# 08 状态、注册表与证据链

## 1. 为什么需要可追踪性

长项目最危险的不是忘记一句对话，而是多个文档各自保存不同版本的事实。CCGS 用稳定 ID、注册表、ADR 和版本戳把“为什么做、决定怎么做、实际做了什么、如何证明”连起来。

## 2. 两类注册表

### 设计事实注册表

`design/registry/entities.yaml` 保存跨系统共享的：

- entities；
- items；
- formulas；
- constants。

每条记录带 `source`、`referenced_by`、`status`、`added`、`revised`。事实只能有一个权威来源；废弃时标记 deprecated，而不是直接删除历史。

### 架构决定注册表

`docs/registry/architecture.yaml` 保存跨 ADR 的：

- state ownership；
- interface contracts；
- performance budgets；
- API decisions；
- forbidden patterns。

它帮助 `/architecture-review` 检测两个 ADR 是否声称不同的状态所有者、通信方式或性能预算。

## 3. TR 注册表

`docs/architecture/tr-registry.yaml` 给技术需求稳定编号，例如：

```text
TR-MOV-001
```

Story 引用 TR-ID，`/dev-story` 再从注册表读取最新 `requirement` 文本。这样需求措辞更新时，不必在所有故事中复制修改；ID 永不重排，只追加或标记状态。

## 4. 完整追踪链

```text
游戏支柱
  └─ GDD 验收标准
       └─ TR-ID
            └─ Accepted ADR
                 └─ Control Manifest 规则
                      └─ Epic / Story
                           ├─ 实现文件
                           └─ Test Evidence
```

各层回答不同问题：

- 支柱/GDD：玩家应该体验什么、规则是什么？
- TR：工程必须满足什么可验证要求？
- ADR：选择了什么技术方案，为什么？
- Manifest：程序员必须遵守哪些简化规则？
- Story：本次实现的边界和验收标准是什么？
- Evidence：有什么实际证据证明完成？

## 5. Manifest 版本

Control Manifest 头部有日期版本，Story 嵌入使用的版本。`/dev-story` 和 `/story-done` 会检查是否过期。若 ADR 发生变化，旧 Story 即使内容没变也可能需要重新确认，以避免按旧架构实施。

## 6. 三种状态

不要混用：

| 状态 | 文件 | 作用 |
|---|---|---|
| 项目阶段 | `production/stage.txt` | Concept 到 Release 的当前位置 |
| 评审强度 | `production/review-mode.txt` | full、lean、solo |
| 当前会话 | `production/session-state/active.md` | 当前任务、进度、决定和未决问题 |

此外，Sprint/Story 自己还会有 status 字段。项目阶段是宏观状态，Story 状态是工作项状态，不能互相替代。

## 7. 变更传播

当 GDD 改动时，不能只改一个文件。`/propagate-design-change` 用于找出：

- 受影响的实体/公式注册项；
- 对应 TR；
- 相关 ADR 和 Control Manifest；
- 尚未完成或已完成的 Stories；
- 需要更新的测试与 UX/资产资料。

已实现功能的设计变化可能形成新 Story，而不是直接悄悄改旧 Story。Producer 负责跨部门协调影响。

## 8. 手工追踪练习

为“玩家移动速度”写一条纸面追踪链：

1. GDD：玩家 0.3 秒内能响应方向输入；速度来自配置；
2. TR：`TR-MOV-001`，移动读取输入并按 delta time 更新；
3. ADR：选择 CharacterBody2D，并通过配置资源注入速度；
4. Manifest：禁止在玩家脚本硬编码速度；
5. Story：实现移动与边界碰撞；
6. Test：固定 delta 下验证位移，边界处不越界。

然后假设速度配置格式改变，逐层指出哪些文件必须重新检查。重点不是文件数量，而是不能遗漏消费这个决定的下游。

## 本课检查

1. 设计注册表与架构注册表分别防止哪类冲突？
2. 为什么 TR-ID 不应重排？
3. Manifest 版本过期意味着什么？
4. 项目阶段、会话状态和 Story 状态有何差异？

