# /create-architecture — Phase 3: Data Flow
# /create-architecture — 阶段 3：数据流

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 3: Data Flow
## 阶段 3：数据流

Define how data moves between modules during key game scenarios. Cover at minimum:
定义在关键游戏场景中数据如何在模块之间流动。至少覆盖：

1. **Frame update path**: Input → Core systems → State → Rendering
1. **帧更新路径**：输入 → 核心系统 → 状态 → 渲染
2. **Event/signal path**: How systems communicate without tight coupling
2. **事件/信号路径**：系统如何在无紧密耦合的情况下通信
3. **Save/load path**: What state is serialised, which module owns serialisation
3. **存档/读档路径**：哪些状态被序列化，哪个模块拥有序列化
4. **Initialisation order**: Which modules must boot before others
4. **初始化顺序**：哪些模块必须先于其它模块启动

Use ASCII sequence diagrams where helpful. For each data flow:
在有用之处使用 ASCII 时序图。对每个数据流：
- Name the data being transferred
- 命名被传输的数据
- Identify the producer and consumer
- 识别生产者和消费者
- State whether this is synchronous call, signal/event, or shared state
- 说明这是同步调用、信号/事件，还是共享状态
- Flag any data flows that cross thread boundaries
- 标记任何跨越线程边界的数据流

Get user approval on each scenario, then record it in
`production/session-state/active.md`; it is written at Phase 7.
取得用户对每个场景的批准，然后将其记录在
`production/session-state/active.md` 中；它会在阶段 7 写入。

---
