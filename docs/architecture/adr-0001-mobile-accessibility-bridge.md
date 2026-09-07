# ADR-0001: Mobile Accessibility Bridge

## Status

Accepted for MVP design on 2026-09-03; semantic ABI and all-TopState adapter lifecycle revised under fourth-review authorization on 2026-09-07. Runtime and device evidence remain blocking for release.

## Date

2026-09-07 (original decision 2026-09-03)

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7.1 |
| **Domain** | UI / Input / Accessibility |
| **Knowledge Risk** | HIGH — engine version is post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/ui.md`, `breaking-changes.md`, `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Godot 4.5+ Control accessibility metadata; 4.7 `AccessibilityServer.AccessibilityLiveMode` type |
| **Verification Required** | Android TalkBack and iOS VoiceOver exported-build tree/action/focus/live-region traces; bridge capability handshake; 4.7.1 API compile check |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | None |
| **Enables** | Home, Prep, Pre-active choice, Battle pause, Settlement and controlled-fault mobile accessibility implementation |
| **Blocks** | Mobile accessibility release evidence until both platform adapters pass validation |
| **Ordering Note** | Build semantic snapshot and typed action adapter before platform plugins; device evidence cannot be replaced by desktop AccessKit evidence |

## Context

### Problem Statement

Godot Control accessibility metadata alone does not establish that exported Android and iOS builds expose a complete, actionable TalkBack/VoiceOver tree. Home, Prep, Pre-active choice, Battle pause, Settlement and controlled-fault surfaces require stable roles, selected/disabled state, geometry, reading order, dynamic localized values, live status announcements and activation without giving a native plugin authority over game or profile state.

### Constraints

- Android and iOS remain MVP target platforms.
- Godot is pinned to 4.7.1, whose accessibility API is post-training-cutoff and must be verified against the repository engine references and target builds.
- UI presenters remain consumer-only; platform code cannot write inventory, Save, TopState or gameplay authority.
- Touch focus and keyboard/screen-reader focus remain distinct.
- UI rebuild, stale generation and delayed native callbacks must not activate a new screen.

### Requirements

- Expose the same immutable semantic snapshot on both mobile platforms.
- Map native accessibility actions back to existing typed UI commands.
- Preserve deterministic reading order, radio-group position, selected/disabled state and live announcement priority.
- Fail closed when the bridge is unavailable or incompatible; never claim mobile accessibility support from Control properties alone.

## Decision

Adopt an app-scope `MobileAccessibilityBridgeV1` owned by the persistent app root and registered in the separate `AppAdapterTopologyManifestV2` row `MOBILE_ACCESSIBILITY`; it is not one of the five business `AppServiceTopologyManifestV1` rows and not a seven-phase participant. The bridge and platform adapter are constructed once on the main thread after persistent root creation, remain alive across every TopState, are pumped once per render frame in every TopState, stop accepting callbacks before UI presenters detach, drain/retire queued commands, then shut down before the persistent root is freed.

Each action-bearing presenter in `{HOME,PREP,PRE_ACTIVE_CHOICE,BATTLE_PAUSED,SETTLEMENT,CONTROLLED_FAULT}` publishes a complete immutable `AccessibleScreenSnapshotV2`; all other TopStates publish no interactive snapshot but still drain stale callbacks. The bridge validates and copies the snapshot into exactly one platform adapter. Android uses `AndroidAccessibilityAdapterV1` to expose an accessibility node provider for TalkBack, and iOS uses `IOSAccessibilityAdapterV1` to expose UIAccessibility elements for VoiceOver. Native callbacks may run on platform threads but can only copy a fixed command into a preallocated SPSC mailbox of capacity32. GameRoot's render-frame adapter pump drains that mailbox at most once per frame in every TopState, canonicalizes by native event sequence, and forwards `AccessibilityActionCommandV2` to the main-thread active presenter. Platform callbacks never call Godot Node, SceneTree, signals or business services directly.

The bridge does not infer semantics from visual Node traversal and does not call business services directly. A mobile build that declares screen-reader support must receive `SUPPORTED` from the platform adapter capability handshake before activating any of the six action-bearing states above. `UNAVAILABLE` or `INCOMPATIBLE` presents a noninteractive, localized support error and fails the accessibility release gate; it does not silently downgrade to unlabeled Controls.

### Architecture Diagram

```text
Home / Prep / Pre-active / Pause / Settlement / Fault presenter
        |
        | immutable AccessibleScreenSnapshotV2
        v
MobileAccessibilityBridgeV1 (app root, main thread)
        |                         |
        v                         v
AndroidAccessibilityAdapterV1   IOSAccessibilityAdapterV1
        | TalkBack                  | VoiceOver
        +----------- native action --+
                         |
                         v
             AccessibilityActionCommandV2
                         |
                         v
          active presenter typed-command validation
```

### Key Interfaces

```text
AccessibilityRoleV1={HEADING=1,TEXT=2,BUTTON=3,
  RADIO_GROUP=4,RADIO_OPTION=5,STATUS=6}

AccessibilityActionV1={ACTIVATE=1,INCREMENT=2,DECREMENT=3,
  ESCAPE_OR_BACK=4}

AccessibilityLiveModeV1={OFF=0,POLITE=1,ASSERTIVE=2}

AccessibilityTextArgV1={
  kind:i32(INT64=1,FIXED_MILLI=2,LOCALIZATION_KEY=3),
  i64_value:i64,localization_key_id:i32
}

AccessibleNodeRowV2={
  stable_order:i32,node_id:i64,parent_node_id:i64,role:i32,
  name_localization_key_id:i32,value_localization_key_id:i32,
  state_localization_key_id:i32,enabled:i32,selected:i32,
  set_size:i32,position_in_set:i32,allowed_action_bits:i32,
  live_mode:i32,layout_generation:i64,
  bounds_x:i32,bounds_y:i32,bounds_width:i32,bounds_height:i32,
  visible:i32,clipped:i32,
  name_arg_start:i32,name_arg_count:i32,
  value_arg_start:i32,value_arg_count:i32,
  state_arg_start:i32,state_arg_count:i32,
  arg_count:i32,args:AccessibilityTextArgV1[8]
}

AccessibleScreenSnapshotV2={
  schema_version:i32=2,screen_id:i32,screen_generation:i64,
  profile_revision:i64,source_bundle_hash:Hash256,
  layout_generation:i64,row_count:i32,
  rows:AccessibleNodeRowV2[],initial_focus_node_id:i64,
  snapshot_hash:Hash256
}

AccessibilityActionCommandV2={
  schema_version:i32=2,screen_id:i32,screen_generation:i64,
  layout_generation:i64,node_id:i64,action_id:i32,
  native_event_sequence:i64,snapshot_hash:Hash256
}

MobileAccessibilityCapabilityV1={
  platform_id:i32,adapter_version:i32,
  status:i32(SUPPORTED=1,UNAVAILABLE=2,INCOMPATIBLE=3),
  supported_role_bits:i64,supported_action_bits:i64,
  supports_live_modes:i32
}

AccessibilityAdapterMailboxV1={
  schema_version:i32=1,process_epoch:i64,adapter_generation:i64,
  capacity:i32=32,read_index:i32,write_index:i32,overflowed:i32,
  rows:AccessibilityActionCommandV2[32]
}
```

`AccessibilityTextArgV1`固定16 bytes，`AccessibleNodeRowV2`固定248 bytes，`AccessibilityActionCommandV2`固定76 bytes，mailbox固定2468 bytes；均canonical little-endian/no-padding。每个screen的row capacity由对应UI manifest静态给出，unused row/arg tail全零并进入snapshot hash，运行时不得增长。

Rows are canonical by `stable_order ASC`; IDs and generations are positive checked integers。bounds使用当前safe-area内容坐标系的logical pixel整数，width/height必须正，interactive row必须`visible=1,clipped=0`且action point位于bounds内；每次reflow递增`layout_generation`并原子替换整棵tree。三个localization key分别通过start/count指向同一8-entry typed arg tail，范围不重叠、count和总量checked，禁止把预格式化动态String或视觉label猜测成可访问值。A snapshot is published atomically only after every row, parent relation, role/action combination, localization key+args, bounds, initial focus target and layout generation validates. A native action matching the current snapshot is consumed at most once by `{process_epoch,adapter_generation,screen_generation,layout_generation,native_event_sequence}`. Stale layout, stale screen, duplicate, unknown, invisible/clipped or disabled-node actions produce no typed business command。第33条未排空callback、index overflow、epoch/generation不匹配或producer/consumer线程违规均fail closed：锁存adapter diagnostic、停用交互screen并进入localized support error；不得覆盖未读command、动态扩容或静默丢弃后继续声称SUPPORTED。

## Alternatives Considered

### Alternative 1: Rely only on Godot Control accessibility metadata

- **Pros**: Least custom platform code.
- **Cons**: Does not presently prove exported Android/iOS tree, action, focus or live-region behavior for this project.
- **Rejection Reason**: It cannot close the target-platform evidence gap and makes semantics dependent on scene-tree inspection.

### Alternative 2: Remove mobile screen-reader support from MVP

- **Pros**: No native bridge implementation cost.
- **Cons**: Narrows an existing mobile accessibility requirement and leaves key meta flows inaccessible.
- **Rejection Reason**: The authorized remediation keeps Android/iOS accessibility in MVP scope.

### Alternative 3: Platform plugins call Save or UI services directly

- **Pros**: Fewer adapter hops.
- **Cons**: Gives native callbacks business authority, bypasses generation checks and creates stale-callback races.
- **Rejection Reason**: Violates presenter-only ownership and typed-command boundaries.

## Consequences

### Positive

- One cross-platform semantic contract and one stale-action defense.
- Native adapters remain replaceable without changing business commands.
- Accessibility semantics are testable independently from visual layout.

### Negative

- Requires Kotlin/Android and Swift/iOS adapter work plus exported-device testing.
- Snapshot construction and localization-state coverage add authoring overhead.

### Risks

- Godot 4.7.1 accessibility APIs or export hooks may differ from assumptions; compile and exported-build spikes are mandatory.
- Native focus and Godot dual-focus may diverge; traces must validate both paths without sharing mutable focus state.
- Live announcements can become noisy; only state changes listed by each GDD may use POLITE/ASSERTIVE.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| `home-ui.md` | Stable reading order, recovery status and primary CTA | Immutable Home snapshot plus typed activation |
| `prep-ui.md` | Four-option radio semantics, stock/disabled state and live Save status | RADIO_GROUP/RADIO_OPTION rows and status live modes |
| `skill-draft-system.md` | Pre-active ordinary level-up choice before movement/survival | Full semantic choice rows, dynamic localized values and cancel/choose actions |
| `battle-ui.md` | Paused battle controls | Bounds-aware paused snapshot and typed resume/settings actions |
| `settlement-system.md` | Result-first reading order, Save state and resolved navigation | Ordered snapshot and generation-bound actions |
| `game-root-scene-flow.md` | Controlled-fault recovery and stale callback retirement | All-TopState pump plus fault-surface snapshot |
| `zhangtian-bottle.md` | Mobile TalkBack/VoiceOver architecture decision | Chooses native adapters without giving them inventory authority |

## Performance Implications

- **CPU**: Rebuild only on screen/bundle generation changes, never per gameplay tick.
- **Memory**: Each 248-byte row and eight-entry arg tail is covered by fixed per-screen row maxima in UI manifests; runtime maxima remain to be measured.
- **Load Time**: Adapter capability handshake occurs before interactive meta UI activation.
- **Network**: None.

## Migration Plan

1. Add the engine-independent semantic structs and validators.
2. Make Home, Prep, Pre-active choice, Battle pause, Settlement and controlled-fault presenters emit complete V2 snapshots from existing immutable presentation bundles.
3. Implement Android and iOS adapters behind the same bridge interface.
4. Add stale/duplicate action tests, then exported-device TalkBack/VoiceOver tree and interaction traces.
5. Keep `BLOCKED-MOBILE-A11Y-RUNTIME` until both target platform evidence sets pass.

## Validation Criteria

- Schema tests reject missing, duplicate, cyclic, unordered, stale or unsupported rows/actions.
- All six action-bearing TopStates publish expected semantic-tree goldens at 100/115/130% text, long locale, cutout and documented state combinations; non-action TopStates publish no interactive snapshot but still drain stale commands.
- Golden rows verify exact bounds, `layout_generation`, visible/clipped state and typed localization args; reflow followed by an old native callback produces zero business commands.
- TalkBack and VoiceOver can reach, identify and activate every enabled control in documented order; disabled items remain readable but not activatable.
- Native stale/duplicate callbacks produce zero business commands.
- Capability `UNAVAILABLE/INCOMPATIBLE` never activates an unlabeled interactive screen.
- Godot 4.7.1 `AccessibilityServer.AccessibilityLiveMode` usage compiles and behaves as recorded on target exports.

## Related Decisions

- `design/gdd/home-ui.md`
- `design/gdd/prep-ui.md`
- `design/gdd/settlement-system.md`
- `design/gdd/zhangtian-bottle.md`
- `.claude/docs/technical-preferences.md`
