# ADR-0008: Workspace Layout — Pane Composition, Signal Topology, Drag-Drop API

## Status

Proposed

## Date

2026-05-07

## Last Verified

2026-05-07

## Decision Makers

kjuioqq8@gmail.com (PO) + technical-director (architecture lead) + godot-specialist (engine validation) + ux-designer + art-director (visual fitness review). Reasoning Workspace GDD #6 §6.4 Pending dependency closure.

## Summary

Reasoning Workspace의 DeskPane 내부 Control 토폴로지·CitationDrop signal vs Godot native drag-drop API 선택·메모 패널 위치 fallback ratify·gamepad two-step 패턴·트리 panning 구현을 잠금. Reasoning Workspace GDD §3.3 시그널 contract + Gate ③ 4 invariant를 위반하지 않는 범위에서 emitter·channel·layout 구체를 결정한다 (§8.1.1.b inner padding은 GDD에서 직접 lock된 상태이므로 본 ADR scope 외).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI / Scripting (Control hierarchy + native drag-drop callbacks + signal topology) |
| **Knowledge Risk** | MEDIUM — Godot 4.6 native drag-drop API (`_get_drag_data` / `_can_drop_data` / `_drop_data`)는 Godot 4.0+ stable이나 `at_position` coordinate space + `set_drag_preview()` Control 책임 + AccessKit 연동은 4.5/4.6 release 변동 가능성 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (4.6 pinned); `docs/engine-reference/godot/modules/control.md` 추정 — godot-specialist 2026-05-07 cycle 2 검증; `docs/engine-reference/godot/deprecated-apis.md` (`OS.get_ticks_msec` deprecated since 4.0 — `Time.get_ticks_msec` 사용); ADR-0004 (Theme type variations); ADR-0007 (EvaluationService autoload) |
| **Post-Cutoff APIs Used** | None — `Control._get_drag_data` / `_can_drop_data` / `_drop_data` 모두 4.0+ stable. AccessKit `accessibility_role` properties는 Godot 4.5+ — 본 ADR이 Godot 4.5+ 의존을 명시. |
| **Verification Required** | (1) `Control._drop_data(at_position: Vector2, data)` 호출 시 `at_position` 좌표계 (DeskPane local 추정 — godot-specialist Item 6 검증 의무); (2) `set_drag_preview(preview: Control)` ghost rendering이 70% opacity + grip dot indicator 정합성 — UI Foundation prototype 측정; (3) AccessKit `ROLE_TREE` + `ROLE_TREE_ITEM` 스크린 리더 출력 측정 (NVDA / VoiceOver / Orca 3 OS) — UI Foundation epic |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Library Storage Format — `LibraryService` autoload + Library ID 형식); ADR-0004 (Korean Text Rendering — Theme type variations + RichTextLabel + AccessKit 의존); ADR-0007 (Submission Evaluation Algorithm — `EvaluationService.submit()` + `submission_rejected` / `evaluation_completed` 시그널 입력 계약) |
| **Enables** | Reasoning Workspace GDD §6.4 Pending hard-gate 해제 (§9 PROVISIONAL → LOCKED 전환); UI Foundation epic 진입 (Workspace 화면 Control class 구체 ratify); #6 구현 스토리 시작 unblock |
| **Blocks** | Reasoning Workspace GDD #6 구현 스토리 전체 (본 ADR Accepted 전 시작 X); #2 UI Foundation epic Pane resizing 작업 (본 ADR이 layout topology 잠금) |
| **Ordering Note** | UI Foundation epic 진입 전 본 ADR Accepted 필수. #4 Settings & Accessibility GDD는 *parallel track* — 본 ADR과 무관하게 진행 가능 (Workspace 자체는 #4 reduced_motion / text_scale / KB remap API 의존, 그러나 Layout 결정은 #4 부재 시에도 가능). |

## Context

### Problem Statement

Reasoning Workspace GDD #6 §6.4 Pending dependency 4건 ratify 필요:

1. **OQ-W5 메모 패널 fallback ratify** — GDD §9.3에서 (A) inline 권고 + (B) fixed bottom-right fallback. Trigger threshold 명시 (DeskPane width < 720px 또는 inline panel overlap) 후 fallback 발동 시점 잠금 미완.
2. **OQ-W9 gamepad CitationDrop 두 단계 discrete 대안** — A button mark / A button attach / B button cancel 패턴 mirror, 정확한 floating 배지 위치·취소 경로·feedback 시점 잠금 미완.
3. **OQ-W10 트리 panning** — right-stick analog vs D-pad scroll vs auto-center on focused node, 4-deep + 3+ root at 566px DeskPane floor 시 동작 미잠금.
4. **OQ-W13 CitationDrop signal topology** — autoload `LibraryService` vs scene node `LibraryPane` 발신자 + Godot 4.6 native drag-drop API (`_get_drag_data` / `_can_drop_data` / `_drop_data`) vs autoload signal vs hybrid. Gate ③ contract만 잠금, 구체 위임.

GDD §3.3 Gate ③ 4 invariant는 본 ADR이 위반 부재로 보장 의무:
- Drag-start notification 정확히 1회 per drag
- Drop-completion 페이로드 `library_id` + `viewport_position` (또는 등가) 필수
- Workspace State == FROZEN/READ_ONLY 시 native API `_can_drop_data` callback false 반환 (또는 signal 채널 drop 무시)
- Library Subsystem은 Workspace hit-test 결과 직접 관찰 X — Workspace 자기 책임

### Constraints

- ADR-0001 + ADR-0007 두 ADR이 정의한 LibraryService / EvaluationService autoload 패턴 mirror.
- Reasoning Workspace GDD §8.1.1.b inner padding spec 본 GDD에서 lock — *본 ADR scope 외*.
- ADR-0004 forbidden_pattern `inline_theme_override_without_type_variation` — Workspace UI Control은 모두 Theme type variation 사용.
- Godot 4.6 native drag-drop API는 *function callbacks* (signal 아님) — `_get_drag_data`는 drag 초기화 시 *한 번* 호출, `_can_drop_data` / `_drop_data`는 hover/drop 시 호출.
- AccessKit role floor (Reasoning Workspace GDD §9.6 lock): canvas root `ROLE_TREE`, 노드 `ROLE_TREE_ITEM` — 본 ADR이 Control 선택에서 보장.
- Gamepad critical path 의무 (technical-preferences.md "Gamepad must support all critical gameplay paths") — Workspace는 critical 화면.

### Requirements

- DeskPane 3-pane 컴포지션 (CatalogPane | LibraryPane | DeskPane)에서 DeskPane 내부 Control 트리 구조 잠금.
- CitationDrop은 LibraryPane card → DeskPane node 단방향 — Workspace State guard (FROZEN/READ_ONLY 차단) 보장.
- KB CitationDrop (Reasoning Workspace §9.4.2 Space-mark/Space-attach) 구현 가능 — 두 단계 모두 application-level state.
- 1366×768 floor 해상도에서 4-deep tree + 3+ roots 렌더링 가능 (panning + reflow).

## Decision

### 1. DeskPane Control Hierarchy

DeskPane은 다음 Control 트리로 구성:

```
DeskPane (PanelContainer with theme_type_variation = &"DeskPane")
├── DeskCanvas (SubViewportContainer + SubViewport + Node2D for tree canvas)
│   ├── HypothesisNodeRoot (Node2D — tree container)
│   │   └── HypothesisNode × N (Control with theme_type_variation = &"HypothesisNode")
│   │       ├── LabelDisplay (Label, &"NodeLabel" type variation, ellipsis truncation)
│   │       ├── LabelEditor (LineEdit, &"NodeLabelEdit" — hidden until F2/double-click)
│   │       ├── EvidenceRule (ColorRect or Line2D — bottom evidence rule, ρ × 184px)
│   │       └── (no shadow — Art Bible §3 정합)
│   ├── TreeEdges (Line2D × M — orthogonal L-route, 0.5px 미드그레이 #8C8C8C)
│   └── DropZoneHint (Panel — invisible until citation_drag_started, 1px 점선 미드그레이)
├── MemoPanel (PanelContainer — position OQ-W5 resolution 아래)
│   ├── MemoLabel (RichTextLabel, &"MemoLabel" + scroll_active=true — 펼친 상태 display)
│   ├── MemoEdit (TextEdit, &"MemoEdit" — 펼친 상태 edit)
│   └── CharCounter (Label, &"CaptionLabel" — 500/500 with weight Medium on cap)
├── SubmitButton (Button, &"SubmitButton" — full-width DeskPane footer)
├── FreezeOverlay (CanvasLayer — DeskPane 전체 덮음, FROZEN 한정)
│   ├── OverlayDim (ColorRect — 80% 판결지 #F5F2EC)
│   └── FreezeBanner (PanelContainer — 64px ink-black, &"FreezeBanner")
│       └── BannerText (Label, &"CourtHeadline" — "제출이 처리 중입니다")
└── ReadOnlyIndicator (Label — sticky top, READ_ONLY 한정, "제출 완료 — 열람 전용")
```

**Note**: HypothesisNodeRoot 하위 노드는 `Control` (Node2D 아님) — `_get_drag_data` / `_drop_data` / `_can_drop_data` 콜백 사용 + AccessKit `accessibility_role` property 사용 가능. SubViewportContainer는 panning 지원 (3절 OQ-W10).

### 2. CitationDrop Signal Topology — Hybrid Native + Application-State (OQ-W13 closure)

**채택**: Godot 4.6 native drag-drop API + LibraryService autoload signal *hybrid*. 두 채널 동시 활용:

| Layer | 책임 |
|---|---|
| **Native API (`_get_drag_data` / `_can_drop_data` / `_drop_data`)** | LibraryPane 카드의 pointer drag → DeskPane node 직접 drop 경로 처리. KB CitationDrop의 *pointer mirror* — 동일 코드 path 재사용 |
| **LibraryService signal `citation_drag_started(library_id)`** | DropZoneHint 활성화 *전용* — drag UI 진입 시 LibraryPane이 emit, DeskPane이 hint 활성. exactly-once per drag (Gate ③ invariant 1) |
| **Application-level pending state (Workspace 자기 보유)** | KB 경로 (Space-mark + Tab + Space-attach) — `WorkspaceData.pending_citation: String` 단일 상태. Native drag와 KB pending은 *동시 활성 불가* — KB Space-mark 시 native drag 진행 중이면 거부 |

#### Signal contract 매핑 (GDD §3.3 ↔ ADR-0008)

| GDD §3.3 의미 | ADR-0008 구현 |
|---|---|
| `citation_drag_started(library_id)` 시그널 발신자 | **LibraryService autoload** (LibraryPane scene node가 카드 카드 drag 시작 시 LibraryService.emit_signal 호출 또는 KB Space-mark 시 동일 emit). 단일 emitter는 multi-LibraryPane 인스턴스 시에도 exactly-once 보장 — Gate ③ invariant 1 충족 |
| `citation_dropped(library_id, viewport_position)` | **Native `_drop_data(at_position, data)`** — DeskPane이 직접 hit-test (signal 없음). `at_position`은 DeskPane Control local 좌표 (Godot 4.6 native API spec) — viewport-to-local 변환 *불필요* (godot-specialist Item 6: GDD §3.3 "viewport_position을 DeskPane 로컬 좌표로 변환" 명시는 native API 채택 시 *no-op*) |

#### Workspace State guard (Gate ③ invariant 3)

DeskPane의 `_can_drop_data(at_position, data)` 콜백은:
```gdscript
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    if WorkspaceData.state != WorkspaceState.ACTIVE:
        return false  # FROZEN / READ_ONLY / INACTIVE 차단
    if not (data is Dictionary and data.has("library_id")):
        return false
    var library_id: String = data["library_id"]
    var target_node = _hit_test(at_position)
    if target_node == null:
        return false
    return _validate_citation_drop(library_id, target_node)  # Rule 4 정책 (cap·중복·타입)
```

#### Signal flow (drag start)

LibraryPane 카드 drag 시작 시:
```gdscript
# LibraryPane.gd
func _get_drag_data(at_position: Vector2) -> Variant:
    var card: LibraryCard = _card_at(at_position)
    if card == null:
        return null
    LibraryService.emit_signal("citation_drag_started", card.library_id)  # Gate ③ invariant 1
    var preview = _build_drag_preview(card)  # 70% opacity, no grip dot (library-source)
    set_drag_preview(preview)
    return {"library_id": card.library_id, "source": "library"}
```

KB Space-mark 시:
```gdscript
# LibraryPane.gd input handler
func _on_space_pressed_on_focused_card(card: LibraryCard) -> void:
    LibraryService.emit_signal("citation_drag_started", card.library_id)  # 동일 emit path
    WorkspaceData.pending_citation = card.library_id  # application-level state
    _show_pending_badge(card.library_id)  # 좌상단 floating
    _set_status_bar("[%s] 인용 대기 중. 노드 포커스 후 Space로 첨부" % card.library_id)
```

#### Library Subsystem 비관찰 (Gate ③ invariant 4)

LibraryService는 `_drop_data` 결과를 직접 관찰 X. Drop 완료 후 Workspace가 CitationDrop accept/reject 결과를 *자기 처리* + 필요시 `LibraryService.notify_citation_attached(library_id, node_id)` 등의 *명시적* 알림 메소드 호출 (LibraryService 측 책임은 logging + telemetry로 한정). LibraryService는 drag 결과를 polling 하지 않는다.

### 3. Memo Panel Position — OQ-W5 Fallback Lock

**채택**: GDD §9.3 (A) inline next to selected node *primary* + (B) fixed bottom-right *fallback* — fallback trigger 명시:

```
fallback_to_B = (
    DeskPane.size.x < 720
    OR
    (selected_node.global_position.x + selected_node.size.x + 16 + memo_panel_width)
    > DeskPane.global_position.x + DeskPane.size.x
)
```

여기서 `memo_panel_width = 320px` (메모 RichTextLabel 표시 영역 ~24자 width).

`DeskPane._on_node_selected(node)` 또는 `_on_resize()` 시점에 본 술어 평가, true 시 MemoPanel을 (B) 위치(DeskPane 우하단 320×220px 고정)로 reflow. 전환 시 0.15s opacity fade (Reduced Motion 시 즉시 snap — AC-40 정합).

DeskPane width 720px 미만은 1366×768 floor에서 occur 가능 (CatalogPane 480 + LibraryPane clamp 320 + DeskPane 566 → 566 < 720 fallback trigger). 즉 *floor 해상도에서는 (B)가 default*.

### 4. Tree Panning — OQ-W10 Lock

**채택**: SubViewportContainer + SubViewport + Camera2D 패턴 — Camera2D의 position이 panning 상태:

| Input | Action |
|---|---|
| Mouse middle-drag (Pan modifier) | Drag delta만큼 Camera2D position 이동 — 1:1 픽셀 panning |
| Right stick analog (gamepad) | 매 프레임 `camera.position += stick_vector * pan_speed * delta` (pan_speed = 600 px/s) |
| D-pad navigate (gamepad) | 노드 포커스 이동 후 자동 `camera.position` lerp to focused_node (0.2s) |
| Tab / Arrow (KB) | 노드 포커스 이동 후 동일 auto-center |
| Mouse scroll wheel | DeskPane 영역 내에서 vertical pan (스크롤이 0인 경우 default behavior) |

Camera2D 좌표 범위는 `HypothesisNodeRoot`의 bounding box + 200px padding으로 clamp — 트리 외부로 무한 panning 방지.

**1366×768 floor + 4-deep + 3+ root 동작**: 본 panning은 horizontal + vertical 모두 지원 — DeskPane 566px width에서 4-deep linear chain (4 × 200px + spacing ≈ 900px)이 *horizontal scroll* 가능. 3+ root는 vertical 또는 horizontal 분기로 표현 (Layout direction은 default `top-down vertical` per GDD §9.7 — 다중 루트는 horizontal 분기).

### 5. Gamepad CitationDrop Discrete Two-Step — OQ-W9 Lock

**채택**: KB Space-mark/Space-attach 패턴과 동일 mental model의 gamepad mirror:

| Gamepad input | Action |
|---|---|
| Focus LibraryPane (LB / RB pane switcher) → focus card (D-pad) | 카드 focus |
| **A button (LibraryPane card focused)** | "pending citation" 활성화 — 좌상단 floating 배지 + status bar 안내 (KB Space-mark mirror) |
| Focus DeskPane (LB / RB) → navigate node (D-pad) | 노드 focus |
| **A button (DeskPane node focused, pending 활성)** | pending 첨부 (Rule 4 정책 적용) |
| **B button (pending 활성)** | pending 취소 |

floating "인용 대기 중" 배지는 DeskPane 좌상단 inset 16px, 폭 280px 고정, z-order는 Confirmation dialogs 아래 + Tree canvas 위 (GDD §9.1 z-order table 갱신 항목). FROZEN 진입 시 pending이 활성이면 자동 cancel + status bar "제출 처리로 인용 대기 취소".

### 6. UI Foundation Epic 위임 항목 (post-ADR-0008)

다음 3건은 본 ADR이 *boundary*만 명시 + UI Foundation epic prototype에서 actual 측정 후 ratify:

1. **AccessKit 스크린 리더 출력 검증** — NVDA (Windows) / VoiceOver (macOS) / Orca (Linux) 3 OS 출력이 GDD §9.6 expected text와 일치하는지 (ROLE_TREE / ROLE_TREE_ITEM + name + description). 미일치 시 ADR-0004 Theme type variation 또는 본 ADR Control 선택 amendment.
2. **Drag preview 70% opacity 시각 검증** — `set_drag_preview(preview)` Godot 4.6 rendering이 ghost 70% opacity 정합. node-source ghost는 grip dot indicator (좌상단 6×6px 잉크블랙, ux-designer cycle 2 IMPORTANT closure) — library-source ghost는 indicator 부재.
3. **AC-49 60fps 30-node 측정** — 본 ADR Control class 결정으로 unblock. 미달 시 본 ADR amendment (Control class 변경 또는 SubViewport rendering 최적화).

## Consequences

### 긍정

- GDD §3.3 Gate ③ 4 invariant 모두 보장 — *implementation-level* 검증 가능 (signal flow + state guard + payload contract).
- KB CitationDrop과 pointer drag가 *동일 code path 재사용* — `WorkspaceData.pending_citation` 단일 상태 + LibraryService signal 단일 emitter. KB·gamepad·pointer 3 modality 일관.
- §8.1.1.b inner padding이 GDD에서 lock된 상태에서 본 ADR scope 축소 — Control 토폴로지 + signal topology + panning에 집중.
- AccessKit role floor가 GDD에서 lock된 상태에서 본 ADR Control 선택이 floor 보장 — UI Foundation epic 진입 시 prototype 측정만 책임.
- OQ-W5 fallback trigger가 floor 해상도에서 *(B) default* — 1366×768 사용자도 안정적 UX.
- Panning Camera2D 패턴 — 4-deep + 3+ root + 1366×768 floor 모두 수용.

### 부정 / Trade-off

- Hybrid native + signal topology — code path 2 (native drag + KB pending) maintain 부담. KB와 pointer 의 동기화 (예: pointer drag 진행 중 Space 입력 거부)는 명시적 guard 필요.
- SubViewportContainer + Camera2D — UI 렌더링 비용 추가 (off-screen rendering buffer). 30-node 60fps 검증 의무 (AC-49 unblock 의존).
- Library Subsystem 비관찰 (Gate ③ invariant 4) — LibraryService가 telemetry collection 하려면 Workspace 측의 *명시적 알림* 호출 필요 — coupling 1 추가.
- Memo panel (A) → (B) fallback이 floor 해상도에서 default → playtest는 1080p+ 와 floor 모두 측정 의무.
- Gamepad pane switcher (LB/RB)가 GDD §9.4.3에 미명시 — 본 ADR 추가 결정 사항. UI Foundation epic이 gamepad input mapping 잠그는 시점에 LB/RB 의미 ratify.

### Migration Plan

1. `src/data/chain_data_schema.gd` 신규 — `SCHEMA_V1_ALLOWED_FIELDS` + `SCHEMA_V1_NODE_FIELDS` const (Reasoning Workspace cycle 2 BLOCKING #13 closure 정합).
2. `src/data/workspace_data.gd` 신규 — `class_name WorkspaceData extends Resource` + state machine + pending_citation property + invariant 검증 메소드.
3. `src/scenes/workspace/desk_pane.tscn` + `desk_pane.gd` 신규 — 본 ADR §1 Control 트리.
4. `src/scenes/workspace/hypothesis_node.tscn` + `hypothesis_node.gd` 신규 — `_get_drag_data` / `_can_drop_data` / `_drop_data` 구현.
5. `src/scenes/workspace/memo_panel.tscn` + `memo_panel.gd` — (A) inline + (B) fallback reflow 로직.
6. ADR-0004 Theme type variation 등록 — `&"DeskPane"`, `&"HypothesisNode"`, `&"NodeLabel"`, `&"NodeLabelEdit"`, `&"DropZoneHint"`, `&"FreezeBanner"`, `&"SubmitButton"` 추가 (현재 ADR-0004 §4에 미등록 — amendment 트리거).
7. `LibraryService` autoload에 `signal citation_drag_started(library_id: String)` 추가 (ADR-0001 amendment 트리거).
8. Architecture Registry (`docs/registry/architecture.yaml`) 갱신:
   - api_decisions: `citation_drop_signal_topology_hybrid`, `memo_panel_inline_fallback_threshold`, `tree_panning_camera2d`, `gamepad_pane_switcher_lb_rb`
   - state_ownership: `workspace_pending_citation_application_level`
   - forbidden_patterns: `library_subsystem_observe_drop_result` (Gate ③ invariant 4), `chain_data_schema_allow_list_duplication` (cycle 2 BLOCKING #13 closure)
   - performance_budgets: AC-48 (16ms chain_data build) + AC-49 (60fps 30-node) — 후자는 Workspace Layout ADR Accepted 후 unblock

## ADR Dependencies

본 ADR이 enables / blocks:

- **Enables**: Reasoning Workspace GDD §6.4 Pending hard-gate 해제 + UI Foundation epic 진입 + #6 구현 스토리 시작.
- **Blocks** (until Accepted): #6 구현 스토리, AC-49 hard gate.

본 ADR이 depends on:

- **Depends on**: ADR-0001 (LibraryService signal addition amendment), ADR-0004 (Theme type variations amendment), ADR-0007 (EvaluationService autoload signal contract).

본 ADR이 trigger amendment 의무:

- **ADR-0001 amendment** — `LibraryService.citation_drag_started` signal 추가 등록.
- **ADR-0004 amendment** — Theme type variations 7건 추가 (DeskPane, HypothesisNode, NodeLabel, NodeLabelEdit, DropZoneHint, FreezeBanner, SubmitButton + MemoLabel/MemoEdit는 cycle 2에서 이미 surface — 모두 ADR-0004 §4 등재 의무).

## GDD Requirements Addressed

### Reasoning Workspace GDD #6 §6.4 Pending hard-gate (4건 ratify)

- OQ-W5 메모 패널 fallback trigger ratified (§3 본 ADR)
- OQ-W9 gamepad CitationDrop two-step ratified (§5 본 ADR)
- OQ-W10 트리 panning ratified (§4 본 ADR)
- OQ-W13 CitationDrop signal topology + drag-drop API ratified (§2 본 ADR — hybrid native + LibraryService signal)

### Reasoning Workspace GDD §3.3 Gate ③ 4 invariant 보장

- Invariant 1 (Drag-start exactly-once): LibraryService autoload single emitter
- Invariant 2 (Drop-completion 페이로드): native `_drop_data(at_position, data)` data Dictionary `{"library_id", "source"}` + `at_position` Vector2 (DeskPane local)
- Invariant 3 (FROZEN/READ_ONLY 차단): `_can_drop_data` Workspace State guard
- Invariant 4 (Library Subsystem 비관찰): LibraryService는 drop 결과 polling X — Workspace 자기 책임

### Reasoning Workspace GDD §9.6 AccessKit role floor 보장

- Canvas root `ROLE_TREE` (DeskCanvas Control)
- 노드 `ROLE_TREE_ITEM` (HypothesisNode Control)
- 메모 `accessibility_name = node.memo` programmatic 설정 (RichTextLabel 한계 회피)

### TR-WORKSPACE-LAYOUT-001 ~ 005 (tr-registry 등록 신규)

- TR-WORKSPACE-LAYOUT-001: DeskPane Control hierarchy 잠금 (§1)
- TR-WORKSPACE-LAYOUT-002: CitationDrop hybrid signal topology (§2)
- TR-WORKSPACE-LAYOUT-003: MemoPanel inline + fallback (§3)
- TR-WORKSPACE-LAYOUT-004: Tree panning Camera2D (§4)
- TR-WORKSPACE-LAYOUT-005: Gamepad two-step CitationDrop (§5)

## Open Questions / Future Work

본 ADR은 OQ-W7 (AccessKit verification) deferred 상태 유지 — UI Foundation epic prototype 측정 의무 (§6 위임 항목 1).

본 ADR은 ADR-0001 / ADR-0004 amendment 트리거 — 본 ADR Accepted 시점에 두 amendment 동시 작성 의무 (체인 amendment).

v1+ 검토 항목:
- Tree panning *minimap* 도입 — 4-deep + 5+ root 시점에 panning 만으로 부족 가능 (post-MVP playtest 측정).
- Memo panel (C) modal option — Pillar 3 contemplative flow 침해 우려로 cycle 1 reject되었으나, floor 해상도 사용자 비율이 v1+ telemetry에서 30%+ 도달 시 재검토.
