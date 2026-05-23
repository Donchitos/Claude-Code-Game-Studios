# Story 001: UIService autoload + Theme load + viewport_resized signal

> **Epic**: UI Foundation
> **Status**: Complete (2026-05-23)
> **Layer**: Foundation (Core)
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimate**: 3 hours (M) — UIService autoload skeleton + Theme load (initial) + viewport_resized signal subscription + 8-10 unit tests
> **Performance**: No expected impact — _ready() boot (< 50ms target per control-manifest), viewport_resized debounced 50ms (no per-frame allocation)

## Context

**GDD**: `design/gdd/ui-foundation.md` §3.1 Core Rules (UIService autoload responsibility) + §10.1 AC-1 (service initialization)
**Requirement**: TR-ui-001 (UIService FIFTH→SECOND autoload — corrected to SECOND per ADR-0010)

**ADR Governing Implementation**: ADR-0010 §Decision (UIService autoload SECOND position) + amend-1 (G3 announce_text API stub deferred to story 005)
**ADR Decision Summary**: UIService is the Theme + Reduced Motion gateway + viewport reflow + announce_text SSOT. Autoload SECOND (after LibraryService FIRST). _ready() loads Theme, connects viewport_resized signal, exposes Theme as `UIService.theme: Theme` property for KrCustomControl base to read.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `get_viewport().size_changed` signal (4.0+ stable) + 50ms debounce Timer. `Theme.new()` instantiation + `Theme.set_font_size()` mutation (cascades NOTIFICATION_THEME_CHANGED automatically — VR-UI1 PASS confirmed).

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Foundation Layer Required/Forbidden/Guardrails apply

## Acceptance Criteria

- [x] AC-1 — UIService autoload _ready() loads Theme + connects `get_viewport().size_changed` signal + emits `ui_service_initialized()` signal (typed) — **DONE**
- [x] AC-1.2 — `UIService.theme: Theme` property exposed as read-only (getter only — direct assignment forbidden similar to WorkspaceData state Option C) — **DONE**
- [x] AC-1.3 — viewport_resized cascade: `get_viewport().size_changed` → debounced 50ms Timer → `viewport_reflow_needed()` typed signal emit — **DONE** (real 50ms timing verified structurally — headless Timer tick limitation noted; callback chain + coalescing covered)
- [x] AC-1.4 — `VIEWPORT_REFLOW_DEBOUNCE_MS` constant = 50 (from GDD §7.1) — **DONE**
- [x] AC-1.5 — UIService is a Node-derived autoload (not Resource — needs scene tree access for viewport signals) — **DONE**
- [x] AC-1.6 — Theme is initially empty (type variations populated by story 003; this story registers an empty Theme + cascade infrastructure) — **DONE**
- [x] AC-1.7 — Test: autoload spawns, _ready completes, theme is Theme instance, viewport_reflow_needed signal exists — **DONE** (`ui_service_test.gd` 12/12 PASS)

## Implementation Notes

Per ADR-0010 §Decision:

```gdscript
## UIService — autoload SECOND. Theme + Reduced Motion gateway + announce_text SSOT.
##
## Story 001 scope: Theme instance + viewport_resized signal + ui_service_initialized signal.
## Stories 003/004/005 populate Theme variations, add tween_property gateway, announce_text API.
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
class_name UIServiceClass extends Node

const VIEWPORT_REFLOW_DEBOUNCE_MS := 50

signal ui_service_initialized()
signal viewport_reflow_needed()

var _theme: Theme = Theme.new()
var _viewport_debounce_timer: Timer

var theme: Theme:
    get: return _theme
    set(value): push_error("UIService.theme is read-only. Use Theme.set_font_size/set_color via UIService methods.")

func _ready() -> void:
    _viewport_debounce_timer = Timer.new()
    _viewport_debounce_timer.wait_time = VIEWPORT_REFLOW_DEBOUNCE_MS / 1000.0
    _viewport_debounce_timer.one_shot = true
    _viewport_debounce_timer.timeout.connect(_on_viewport_debounce_timeout)
    add_child(_viewport_debounce_timer)
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    ui_service_initialized.emit()

func _on_viewport_size_changed() -> void:
    _viewport_debounce_timer.start()

func _on_viewport_debounce_timeout() -> void:
    viewport_reflow_needed.emit()
```

**Autoload registration**: `project.godot [autoload]` add `UIService="*res://src/ui/ui_service.gd"` SECOND position (after `LibraryService`, before `CaseService`).

**File path**: `src/ui/ui_service.gd` (NEW directory — first UI Foundation file).

## Out of Scope (deferred to later stories)

- Story 002: KrCustomControl base + KrControlHelper
- Story 003: 6 essential type variations (`&"Pane"` / `&"HypothesisNode"` / `&"MemoLabel"` / `&"MemoEdit"` / `&"Banner"` / `&"Button"`)
- Story 004: tween_property gateway + Reduced Motion path
- Story 005: announce_text API + AccessKit role helper
- AC-2 text_scale cascade (story 003 implements Theme runtime reload)
- AC-3/AC-4 Kr3PaneLayout (deferred — minimum-viable scope)
- AC-11/12 AccessKit verification gate (story 005)
- AC-15/16 tween_property tests (story 004)

## QA Test Cases

- **AC-1**: After autoload `_ready()`, assert `ui_service_initialized` signal fired once + `UIService.theme is Theme` true
- **AC-1.2**: `UIService.theme = Theme.new()` direct assignment → push_error fires, `theme` reference unchanged
- **AC-1.3**: Resize window programmatically (or fire `get_viewport().size_changed` mock) → wait 60ms → assert `viewport_reflow_needed` fired exactly once
- **AC-1.3-debounce**: Fire `size_changed` 3 times within 30ms → wait 60ms → assert `viewport_reflow_needed` fired exactly once (debounce coalescing)
- **AC-1.4**: Inspect `UIServiceClass.VIEWPORT_REFLOW_DEBOUNCE_MS` constant == 50
- **AC-1.5**: `UIService extends Node` (not Resource) — `is_node()` true
- **AC-1.6**: `UIService.theme.get_type_variation_list("Label")` returns empty array initially (no variations registered yet)
- **AC-1.7**: Run full test — see all above pass

Edge cases: ui_service_initialized fires before scene Controls _ready() complete (autoload ordering — UIService SECOND), multiple size_changed during debounce window.

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/ui_foundation/ui_service_test.gd` — gdunit4 v5.x (BLOCKING gate per control-manifest)

**Status**: [ ] Not yet created

## Dependencies

- Depends on: None (Foundation layer entry point)
- Unlocks: Stories 002/003/004/005 (all UI Foundation epic stories) + workspace 003b (HypothesisNode KrCard scene wrapping needs UIService.theme + signals)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 7/7 passing (AC-1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7).
**Files**:
- `src/ui/ui_service.gd` — `class_name UIServiceClass extends Node` (autoload name-collision avoidance), Theme + viewport debounce + `ui_service_initialized`/`viewport_reflow_needed` signals, read-only `theme` property (Option C guard). **Pre-existing from an earlier session.**
- `project.godot` — `UIService` autoload SECOND (after LibraryService, before CaseService). Pre-existing.
- `tests/unit/ui_foundation/ui_service_test.gd` — 12 tests.
**Bug fixed this session**: `test_debounce_timeout_callback_emits_viewport_reflow_needed` used a plain `int` counter inside a signal-callback lambda — GDScript captures primitives BY VALUE, so the outer counter stayed 0 and the test failed deterministically (the story had been left in Ready with this broken test). Fixed to the Array-accumulator pattern (documented in freeze_contract_test.gd header). Now 12/12 PASS.
**Test Evidence**: `tests/unit/ui_foundation/ui_service_test.gd` — 12/12 PASS, exit 0.
**Note on AC-1.3**: real 50ms debounce wall-clock timing is verified structurally (timer.start resets time_left, callback chain emits) rather than by awaiting the real timer — headless gdunit4 Timer-tick limitation, documented in the test file. Acceptable for a Logic story; real-timing belongs to an integration/manual pass.
**Code Review**: Production code pre-existing (reviewed when authored); this session's change is a one-line documented-pattern test fix — formal /code-review skipped per triviality.
