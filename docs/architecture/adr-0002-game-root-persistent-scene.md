# ADR-GR-001：GameRoot 采用 main-scene persistent root

- **Status**: Accepted for implementation scaffold
- **Date**: 2026-09-09
- **Owners**: Technical Director / GameRoot
- **Scope**: GameRoot lifetime、root Window/Viewport owner 与页面 child handoff

## Context

GameRoot 必须从 `BOOT` 持续存在到应用退出，且应用只能有一个 persistent root `Window`。HOME、PREP、Battle、Fault、Settlement 都是可替换 child scope；BattleUI、InputSystem、Stage 与各 battle participant 不能把 root Window 或 GameRoot 一起销毁。`gui_disable_input`、SceneTree pause 与 app-scope pump 也必须有唯一 owner。

## Decision

采用 **main-scene persistent root**：项目 `run/main_scene` 指向唯一的 persistent root scene，其根节点脚本就是 GameRoot。禁止把 GameRoot 注册为 Autoload，也禁止在页面切换或每局 battle 中重新实例化第二个 GameRoot。

固定结构：

```text
main scene
└── GameRoot (persistent live identity)
    ├── root Window / root Viewport ownership
    ├── app-scope services and fault presenter
    └── replaceable page/battle child scope
        ├── Stage
        ├── InputSystem / VirtualJoystickHost
        └── BattleUiRoot
```

GameRoot 通过受控 child handoff 替换页面或 battle scope；root scene 不切换。唯一 root Window/Viewport identity、`gui_disable_input` writer、SceneTree pause writer、app adapter pump 与生命周期 callback owner 均归 GameRoot。当前 `production/input-vertical-slice/main.tscn` 是该决策的最小实现 scaffold，`GameRootSlice` 仅作为实现起点，不代表完整 production runtime。

## Consequences

- 页面切换只允许 `stage → detach → frame-end barrier → attach destination child`，不得用 `change_scene` 替换 persistent root。
- 每局只创建/销毁 battle child；Input、BattleUI、Stage、lease、bank、participant 与 callback 必须在 cleanup 后逻辑 detach，root Window 与 GameRoot 不销毁。
- 可用 root identity、root Viewport identity、battle child generation 和 callback/writer census 对生命周期做运行时断言。
- Autoload 不再是 GameRoot 的实现路径；其它 app-scope service 是否 Autoload 仍须遵循 `AppServiceTopologyManifestV1`，不得借此创建第二个 GameRoot。
- 本 ADR 不决定 battle/outcome identity 生成、Save 恢复、Viewport setter 重入、设备验证或性能阈值；这些仍由 OQ2–OQ8 管理。

## Acceptance evidence for implementation

实现阶段至少需要：

1. main scene root class 唯一为 GameRoot，运行期间 live identity 不变；
2. 两次 battle replacement 后 root Window/Viewport、pause writer、gate writer 与 app pump identity 不变；
3. HOME/SETTLEMENT 中旧 battle child、callback、lease、bank 与 borrow 引用为零；
4. root Viewport gate 的 `PRE_ACQUIRE → GATE_HELD → ACTIVATION_SUCCESS release` trace 与 GameRoot/Viewport route test 通过。

这些是实现与运行证据门，不由 ADR 的 Accepted 状态替代。
