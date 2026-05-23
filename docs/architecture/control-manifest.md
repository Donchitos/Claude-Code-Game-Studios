# Control Manifest

> **Engine**: Godot 4.6 (runtime confirmed 4.6.1.stable.official.14d19694e via VR-UI6 prototype 2026-05-17)
> **Last Updated**: 2026-05-18
> **Manifest Version**: 2026-05-18
> **ADRs Covered**: ADR-0001 + amend-1 + amend-1.1 + amend-2, ADR-0002 main (amend-1 Proposed — rules pre-applied via source verification), ADR-0003, ADR-0004 + amend-1, ADR-0006, ADR-0007 + amend-1 + amend-2, ADR-0008 + amend-1 + amend-2 + amend-3 + amend-4, ADR-0009, ADR-0010 + amend-1, ADR-0011
> **Status**: Active — regenerate with `/create-control-manifest update` when new ADRs are Accepted or existing ADRs revised

`Manifest Version` is the date this manifest was generated. Story files embed this date at creation time. `/story-readiness` compares a story's embedded version to this field to detect stories written against stale rules. `Last Updated` = `Manifest Version` (same date, separate consumers).

This manifest is a programmer's quick-reference extracted from all Accepted ADRs, `.claude/docs/technical-preferences.md`, and `docs/engine-reference/godot/`. For the *reasoning* behind each rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: Legal Reference Library (#20), Case Data Schema (#1), UI Foundation (#2), Save/Load (#3) — initialisation, persistence, and core data services.*

### Required Patterns

- **Autoload registration order locked**: `LibraryService` FIRST, `UIService` SECOND, `CaseService` THIRD, `EvaluationService` FOURTH, `SettingsService` FIFTH, `SaveLoadService` SIXTH in `project.godot [autoload]` section — source: ADR-0001, ADR-0007 §2, ADR-0010, ADR-0011, ADR-0009
- **LibraryService FIRST `_ready()` fail-fast guard**: `assert(library_data_loaded)` before any consumer access — source: ADR-0001 amend-1 / amend-1.1
- **CaseService `_ready()` awaits `LibraryService.library_loaded` signal before validating `correct_citations`** — source: ADR-0003 (Implementation Guideline #1)
- **Library `.tres` data load via `ResourceLoader.load()` only** (NOT `FileAccess.open` raw parsing) — source: ADR-0001 §Decision
- **Library `holding_id` is canonical key — never synthesized at call sites; always read from `LibraryHolding.holding_id` field** — source: ADR-0001 amend-1
- **Library search index format**: in-memory `Dictionary` keyed by case_id + holding_id; built at LibraryService `_ready()` post-load — source: ADR-0002
- **Use `Time.get_ticks_msec()` for performance instrumentation** (NOT deprecated `OS.get_ticks_msec()`) — source: ADR-0002 amend-1, `docs/engine-reference/godot/deprecated-apis.md`
- **Case Data Schema**: each case file is `Resource` (`.tres`) with required fields `case_id`, `holdings`, `correct_citations` (Array[String] of `holding_id`) — source: ADR-0003
- **Lazy `full_opinion` storage**: long opinion text in side-car `.txt`; `LibraryHolding.full_opinion` field is empty string until `LibraryService.load_full_opinion(holding_id)` called — source: ADR-0006
- **UIService autoload SECOND**: owns Theme + KrCustomControl tree + Theme runtime reload + Kr3PaneLayout primitive + KrFreezeOverlay + Reduced Motion gateway + dual focus ring composite + `tween_property()` gateway + `announce_text(source, message, priority)` live-region API — source: ADR-0010 + amend-1 §G3
- **KrCustomControl base class `_ready()` auto-subscribes** to `SettingsService` 3 signals (`display.text_scale` / `display.reduced_motion` / `accessibility.focus_indicator_thickness_px`) via `KrControlHelper.setup(self)` — source: ADR-0010 §Decision
- **KrCustomControl subclasses use composition + static helper pattern** (NOT multiple inheritance — GDScript doesn't support it); each Kr* class extends appropriate Godot base + calls `KrControlHelper.setup(self)` in `_ready()` — source: ADR-0010 §Decision Note (godot-specialist 2026-05-17 redefine)
- **`UIService.tween_property(target, property, final_value, duration)` gateway**: returns `null` when `display.reduced_motion == true` → caller sets property immediately; otherwise creates `Tween` and returns it — source: ADR-0010 §Decision + §Risk R7 enforcement
- **17 Theme type variations registered**: `&"Pane"`, `&"Header"`, `&"Card"`, `&"LibraryCard"`, `&"HypothesisNode"`, `&"EnvelopeCard"`, `&"GroundsCard"`, `&"Dialog"`, `&"Button"`, `&"Banner"`, `&"ReadOnlyBanner"`, `&"CriticalBanner"`, `&"ToastBanner"`, `&"BodyLabel"`, `&"CommentLabel"`, `&"MemoLabel"`, `&"CourtHeadline"`, `&"CaptionLabel"`, `&"MemoEdit"` — source: ADR-0004 amend-1, ADR-0010 §17 Theme Type Variations
- **`Theme.set_font_size()` runtime reload triggers automatic `NOTIFICATION_THEME_CHANGED` cascade** to all dependent Controls — VR-UI1 PASS confirmed; do NOT call `theme.emit_changed()` after setter (double-emit) — source: ADR-0004 amend-1, ADR-0010 §Risk R1, VR-UI1 prototype 2026-05-17
- **AccessibilityRole assignment via `Control.accessibility_role = AccessibilityRole.ROLE_*`**; use ONLY constants that exist in Godot 4.6 `DisplayServer.AccessibilityRole` enum (46 entries 0..45) — source: ADR-0008 amend-4 §F1, ADR-0010 amend-1 §G1, VR-UI6 dump 2026-05-17
- **Live-region announcement**: call `UIService.announce_text(source, message, priority)` — wraps `DisplayServer.accessibility_update_set_live(rid, mode)` + `accessibility_update_set_name(rid, message)`; mode enum `DisplayServer.LIVE_OFF=0 / LIVE_POLITE=1 / LIVE_ASSERTIVE=2` — source: ADR-0010 amend-1 §G3, VR-UI6 PASS
- **KrBanner subclass `_ready()` MUST call `super._ready()`** which auto-invokes `UIService.announce_text(self, text, priority)` — source: ADR-0010 amend-1 §G5
- **SaveLoadService SIXTH autoload**: 4-Resource splits (`active_case.tres` + `casebook.tres` + `career.tres` + `session_meta.cfg`) under `user://saves/` — source: ADR-0011 §Decision
- **Atomic write pattern**: write-to-temp + `DirAccess.rename_absolute()` — POSIX guaranteed within same filesystem; Windows NTFS best-effort — source: ADR-0011 §F3, `docs/engine-reference/godot/current-best-practices.md` (File I/O section)
- **Autosave is signal-trigger ONLY**: subscribe to typed signals (`workspace_state_changed`, `brief_editor_state_changed`, `brief_editor_submitted`, `evaluation_completed`, `submission_rejected`, `case_state_changed`); 250ms debounce except `casebook` immediate-write — source: ADR-0011 §Decision
- **Crash recovery cascade entry point**: `SaveLoadService.active_case_recovered(case_id, snapshot)` signal — single subscriber-entry for both Workspace FROZEN auto-resubmit + Brief SUBMITTING auto-resubmit — source: ADR-0011 §3

### Forbidden Approaches

- **Never use `FileAccess.open` to read Library data files** — Use `ResourceLoader.load()`. ADR-0001 §Alternatives rejected raw parsing. Pattern: `library_data_load_via_FileAccess`
- **Never synthesize `holding_id` in caller code** (e.g. `case_id + "-" + index`) — always read from `LibraryHolding.holding_id`. Pattern: `library_holding_id_synthesis_in_callers`
- **Never call external API at runtime for library data** (Naver / Casenote etc.) — Library is pre-bundled `.tres`. Pattern: `library_runtime_external_api_call`
- **Never violate autoload order** — moving EvaluationService from FOURTH breaks LibraryService FIRST + CaseService THIRD dependency chain. Pattern: `autoload_order_violation_evaluation`
- **Never subscribe to non-typed signals via string-keyed `emit_signal("name", args)`** — always use typed `.emit(args)` syntax. Pattern: `signal_emit_string_keyed_when_typed_available` — source: ADR-0008 amend-1 §A5, amend-3 §E2 cascade
- **Never extend Control directly bypassing KrCustomControl tree** — Pattern: `custom_control_outside_kr_hierarchy` — source: ADR-0010 §Forbidden Patterns
- **Never use `create_tween()` directly** — always route through `UIService.tween_property()` (Reduced Motion gateway). Exception: UIService implementation itself. Pattern: `direct_create_tween_bypassing_reduced_motion`
- **Never apply inline `theme_override_*` properties** to a Control — always use Theme + `theme_type_variation`. Pattern: `inline_theme_override_without_type_variation`
- **Never open two `KrDialog popup_exclusive` simultaneously within one system** (e.g. Workspace cannot show submit confirmation + delete confirmation at once). Pattern: `dialog_concurrent_open_within_system`
- **Never use a font outside the 3-family set** (`court_title` 본명조 MSDF + `body_sans` Pretendard + `code_mono` IBM Plex Mono). Pattern: `font_outside_three_family_set` — source: ADR-0004
- **Never use `TextServer.SIMPLE` for Korean text** — must use complex/advanced text shaping for ㅇ/ㅎ ligatures + diacritics. Pattern: `text_server_simple_for_korean`
- **Never bundle full glyph set for MSDF fonts** — generate per-codepoint MSDF only for KS X 1001 commonly-used subset (~2350 glyphs). Pattern: `font_msdf_full_glyph_set`
- **Never use plain `Label` for long body text** — use `RichTextLabel` for paragraphs (bbcode + autowrap). Pattern: `label_for_long_body_text`
- **Never assign hallucinated AccessibilityRole names** — `ROLE_REGION`, `ROLE_GROUP`, `ROLE_HEADING`, `ROLE_STATUS`, `ROLE_ALERT`, `ROLE_RADIO_GROUP`, `ROLE_COMBO_BOX`, `ROLE_CHECKBOX` (one word), `ROLE_TEXT_AREA` — none exist in 4.6 enum (PR review gate `accessibility_role_pre_verification_implementation`) — source: ADR-0008 amend-4 §F1, `docs/engine-reference/godot/modules/ui.md`
- **Never display KrBanner subclass dynamically without calling `UIService.announce_text`** — live-region absence in role enum requires explicit announce. Pattern: `kr_banner_dynamic_show_without_announce`
- **Never use polling-based autosave** (e.g. `_process` timer) — only signal-trigger. Pattern: `save_load_polling_based_autosave`
- **Never write non-atomic to `user://`** — bypass of atomic-rename pattern can corrupt save on crash. Pattern: `save_load_non_atomic_write`
- **Never serialize a preloaded Resource instance** — Resource refs in `.tres` cause Godot to attempt re-load by path; use Resource UID or build-from-data pattern. Pattern: `save_load_serialize_preloaded_resource_instance`
- **Never declare a `class_name` that collides with an autoload name** (e.g. `class_name LibraryService` clashes with autoload). Pattern: `class_name_collides_with_autoload_name`

### Performance Guardrails

- **LibraryService boot**: < 200ms to load + index 100+ holdings — source: ADR-0001 §Performance Implications
- **LibraryService search latency**: < 1ms average over first 100 `search()` calls — source: ADR-0002 §Validation Criteria #5
- **SaveLoadService atomic write**: ≤ 16ms per save (1 frame) for typical Resource size (< 1MB) — source: ADR-0011 §Performance
- **UIService Theme reload cascade**: < 50ms for 21+ KrCustomControl scene — source: ADR-0010 §Performance + VR-UI1 PASS confirmation
- **`NOTIFICATION_WM_CLOSE_REQUEST` synchronous save budget**: OS provides multi-second graceful close window; ≤16ms save completes well within — source: ADR-0011 §VR-SL3 + `docs/engine-reference/godot/current-best-practices.md`

---

## Core Layer Rules

*Applies to: Korean text rendering (cross-system #5/#6/#7/#10/#20), Settings & Accessibility (#4) — engine-facing infrastructure shared by all gameplay systems.*

### Required Patterns

- **Korean text uses MSDF font for `court_title` family (본명조)** + standard TTF for `body_sans` (Pretendard) + monospace for `code_mono` (IBM Plex Mono) — hybrid by family per ADR-0004 §Decision
- **Font subset = KS X 1001 commonly-used + ASCII** (~2350 + 95 glyphs); never bundle full glyph set — source: ADR-0004 §Decision
- **`SettingsService` autoload FIFTH position**: `user://user_settings.cfg` ConfigFile single-file (5 카테고리 sections + `[meta]` `schema_version=1`) — source: ADR-0009 §Decision
- **5-step `set()` cascade order**: validation → in-memory apply → typed `setting_changed.emit(key, old, new)` → direct engine API call (AudioServer/InputMap/Theme) → 100ms debounced persist — source: ADR-0009 §Decision Architecture
- **Direct engine API ownership (SettingsService ONLY)**: `AudioServer.set_bus_volume_db()`, `InputMap.action_add_event/erase_events/action_has_event`, `DisplayServer.is_screen_reader_running()` — source: ADR-0009 §Decision + forbidden_pattern `settings_direct_engine_api_bypass`
- **`SettingsService.get(key, default)` is the only read path** — never cache settings values in member variables; always re-query or subscribe to `setting_changed` — source: ADR-0009 §Decision + forbidden_pattern `settings_local_cache`
- **`text_scale` apply path**: `UIService.theme.set_font_size(...)` for each type variation; NOTIFICATION_THEME_CHANGED auto-cascades to dependent Controls (VR-UI1 PASS) — source: ADR-0009 §Decision + ADR-0004 amend-1
- **`reduced_motion` apply path**: signal-only — subscribers use `UIService.tween_property()` gateway which checks setting internally; no per-control logic needed — source: ADR-0010 §Decision
- **`keyboard_shortcut_remap` apply path**: `InputMap.action_add_event` for each remapped action; reject reserved keys (Esc/Space/Tab/Enter/arrows) + conflict-detect (last-registration wins + warning dialog) — source: ADR-0009 + GDD §3.1.3
- **Crash recovery on settings parse error**: `DirAccess.rename_absolute(user://user_settings.cfg → user://user_settings.cfg.backup.YYYYMMDD-HHMMSS)` + reset to defaults + `UIService.announce_text(self, msg, ASSERTIVE)` + CriticalBanner — source: ADR-0009 §Decision Crash Recovery

### Forbidden Approaches

- **Never include SettingsService values in `EvaluationService.submit()` or `PlayerSubmission`** — Pillar 1 violation. Pattern: `settings_value_in_evaluation`
- **Never include SettingsService values in `chain_data` Dictionary** — Pattern: `settings_in_chain_data` (mirrors `chain_data_include_ephemeral_field`)
- **Never cache SettingsService.get() result in member variable** — SSOT violation. Pattern: `settings_local_cache`
- **Never call `AudioServer.set_bus_volume_db()` / `InputMap.action_add_event()` outside SettingsService** — Pattern: `settings_direct_engine_api_bypass`
- **Never use `DisplayServer.ime_get_text()` cross-platform without `OS.get_name() == "macOS"` guard** — method is macOS-only; silent no-op on Windows/Linux. Pattern: `ime_get_text_cross_platform_assumption` — source: `docs/engine-reference/godot/modules/input.md`
- **Never use `TextEdit.composition_finished` signal** — does NOT exist in Godot 4.6 stable. Pattern: `ime_path_a_composition_finished_use` — source: ADR-0008 amend-4 §F2, `docs/engine-reference/godot/modules/ui.md`

### Performance Guardrails

- **SettingsService boot `_ready()`**: 5-20ms (ConfigFile.load + `_apply_all_to_engine`) — source: ADR-0009 §Performance
- **`set()` call latency**: < 1ms (in-memory + signal + engine API; persist is debounced) — source: ADR-0009 §Performance
- **`persist()` flush**: < 16ms (ConfigFile.save + rename_absolute) — source: ADR-0009 §Performance
- **`screen_reader_detected` polling**: 30s interval Timer × ~0.1ms per check — negligible — source: ADR-0009 §Performance

---

## Feature Layer Rules

*Applies to: Reasoning Workspace (#6), Brief Editor (#7), Submission & Evaluation (#9), Case File Browser (#5) — gameplay systems built on Foundation + Core.*

### Required Patterns

- **WorkspaceData state machine 4 states**: `INACTIVE = 0`, `ACTIVE = 1`, `FROZEN = 2`, `READ_ONLY = 3`; transitions only via `_transition_to_active()` / `_transition_to_frozen()` / `_transition_to_read_only()` — source: ADR-0008 §1
- **State transitions emit typed signal `workspace_state_changed(old: int, new: int)`** — source: ADR-0008 §1 + amend-1 §A5
- **chain_data Dictionary is fully constructed new Dict literal** — never reference live WorkspaceData fields; each node's `evidence: Array[String]` field explicitly `.duplicate()` called — source: ADR-0008 §3.1 Rule 6 normative (cycle 4 godot-specialist IMPORTANT-1)
- **chain_data nodes[] array follows BFS canonical ordering**: roots sorted by `node_id` lexicographically → BFS within each subtree with children sorted by `node_id` at each depth — source: ADR-0008 §1 + systems-designer F3 BLOCKING closure
- **chain_data contains ONLY Variant primitives**: String / int / float / bool / Array / Dict — no Resource refs, no Object refs — source: ADR-0007 amend-1
- **chain_data schema_version=1 locked**: any v2+ bump requires explicit migration ADR — source: ADR-0007 amend-1
- **chain_data allow-list validator**: per-node fields restricted to `node_id`, `label`, `parent_id`, `evidence`, `depth`, `child_count`, `evidence_count`; forbidden field injection → `push_error` + `submission_rejected("schema_violation")` — source: ADR-0008 amend-1 §A6
- **Disposition enum MVP scope locked to 4 values**: `ACCEPT`, `REJECT`, `PARTIAL_ACCEPT`, `REMAND` — case content must use only these; v1+ extension via explicit ADR — source: ADR-0007 amend-2
- **CitationDrop hybrid signal topology**: Godot 4.6 native drag-drop callbacks (`_get_drag_data` / `_can_drop_data` / `_drop_data`) + LibraryService `citation_drag_started(library_id)` typed signal + application-level `WorkspaceData.pending_citation: String` for KB Space-mark/attach + Gamepad A→A two-step — source: ADR-0008 §2 + amend-1 §A3
- **Drop target state guard scope**: DeskPane HypothesisNode `_can_drop_data` rejects when `WorkspaceData.state != ACTIVE`; Brief Editor CitationPanel is independent guard — source: ADR-0008 amend-3 §E1
- **Cross-viewport drag-drop confirmed dispatch**: native callbacks fire across SubViewport boundary (VR-D6 PASS 2026-05-17 — 4/4 prototype drags); DragManager autoload fallback NOT needed — source: ADR-0008 amend-3 §E3 + VR-D6 prototype
- **Hit-test tie-break**: when overlapping nodes receive drop, topmost (highest z-index then latest add) wins — source: ADR-0008 amend-1 §A3
- **MemoPanel layout**: default (B) fixed bottom-right; (A) inline next to selected node activates when `root_count ≤ 2 AND DeskPane.size.x ≥ 720`; 0.15s opacity fade via `UIService.tween_property()` — source: ADR-0008 §3 + amend-1 §A4
- **Tree panning Camera2D**: mouse middle-drag 1:1, gamepad right-stick analog 600 px/s (deadzone from `input.gamepad_stick_deadzone`), D-pad/Tab/Arrow auto-center via 0.2s lerp, scroll wheel vertical pan; clamp to HypothesisNodeRoot bounding box + 200px padding — source: ADR-0008 §4
- **Gamepad CitationDrop two-step**: A on LibraryPane card (mark pending) → A on DeskPane node (attach) → B cancel; FROZEN state auto-cancels pending — source: ADR-0008 §5
- **Brief Editor data lifecycle**: BriefEditorData is single-owner Resource owned by transient SaveLoadService (boot path) → BriefEditor scene receives via `active_case_recovered` signal; never accessed via direct NodePath before signal arrival — source: ADR-0001 amend-2
- **Brief Editor IMPORTING transition**: ≤150ms from `workspace_state_changed(ACTIVE, FROZEN)` arrival to `brief_editor.state == IMPORTING` — source: ADR-0001 amend-2 + TR-brief-001
- **Submit confirmation dialog (Pillar 3 anchor)**: KrDialog `popup_exclusive=true`, default focus = [취소] (NOT [제출]) — source: Workspace cycle 3 Decision 2, ADR-0008 amend-2 §D2
- **EvaluationService submission pipeline**: `submit(submission: PlayerSubmission)` validates schema → calls grading algorithm → emits `evaluation_completed(result: EvaluationResult)` typed signal — source: ADR-0007 §Decision. *(Corrected 2026-05-23, TD-001: prior text said `submit(chain_data: Dictionary)`, which is insufficient — the grading algorithm scores `player_disposition` + `player_citations` (Set ops vs correct/missed/redundant), neither of which is in `chain_data`. `PlayerSubmission` bundles `case_id` + `player_disposition` + `player_citations` + `chain_data` + `submission_time_ms`. ADR-0007 §Decision is authoritative; the manifest had misquoted it. No version bump — correction to match the cited source, not a new rule.)*
- **IME composition detection (cross-platform)**: `_gui_input` override + analyze `InputEventKey` `unicode == 0 AND keycode == 0` pattern for composition state — source: ADR-0008 amend-4 §F3 (`docs/engine-reference/godot/modules/input.md`)
- **TextEdit signal handling**: 4.6 stable signals are `caret_changed / gutter_added / gutter_clicked / gutter_removed / lines_edited_from / text_changed / text_set`; `set_text()` and `clear()` fire `text_set` only (VR-D3 PASS) — source: ADR-0008 amend-4 §F5 + VR-D3 prototype 2026-05-17
- **`_text_changed_guard` defensive flag**: retain in TextEdit subscribers as zero-cost protection against future engine behavior changes — source: ADR-0008 amend-4 §F5
- **Project Settings lock**: `display/window/subwindows/embed_subwindows = true` (4.6 default — verified VR-D1 PASS) + `project.godot` explicit lock as defense-in-depth — source: ADR-0008 amend-2 §D2, `docs/engine-reference/godot/current-best-practices.md`

### Forbidden Approaches

- **Never include ephemeral fields in chain_data**: forbidden field names include `memo_text`, `chain_data_internal`, `__debug_payload`, `evaluator_hint`, `cached_score`. Pattern: `chain_data_include_ephemeral_field` — source: ADR-0008 amend-1 §A6, AC-52
- **Never include Resource or Object value in chain_data Dictionary** — Pattern: `chain_data_include_resource_or_object_value` — source: ADR-0007 amend-1
- **Never modify chain_data from Brief Editor** — chain_data is Workspace-owned, Brief receives read-only copy. Pattern: `brief_editor_modify_chain_data`
- **Never extend disposition enum in case content** (e.g. case .tres declares `disposition: "OVERRULE"`) — case content is consumer of enum, not authority. Pattern: `disposition_enum_extension_in_case_content`
- **Never extend disposition enum at runtime** — Pattern: `disposition_enum_runtime_extension`
- **Never add a 5th disposition enum prematurely (before v1+ playtest data)** — Pattern: `premature_disposition_enum_extension`
- **Never start a 2nd `EvaluationService.submit()` while previous is in flight** — Pattern: `submit_during_active_evaluation`
- **Never override per-case verdict thresholds in case files** — thresholds are global. Pattern: `per_case_verdict_threshold_override`
- **Never cache EvaluationResult by case_id** in EvaluationService — fresh evaluation per submit. Pattern: `evaluation_caching_by_case_id`
- **Never let Library subsystem observe drop result** — Library is data source only, never observer of UI events. Pattern: `library_subsystem_observe_drop_result`
- **Never mutate PackedArray value inside Dict value in-place** — Godot Dict values are copies for primitives but PackedArray inside Dict requires explicit reassignment. Pattern: `dict_value_packed_array_inplace_mutation`
- **Never duplicate allow-list validator logic across multiple call sites** — single canonical `WorkspaceData.validate_chain_data()` function. Pattern: `chain_data_schema_allow_list_duplication`
- **Never access BriefEditorData via direct NodePath** — use `active_case_recovered` signal subscriber. Pattern: `brief_editor_data_direct_node_path_access`
- **Never access BriefEditorData before the `brief_editor_data_recovered` signal arrives** — Pattern: `brief_editor_data_pre_signal_access`
- **Never let Brief Editor `popup_exclusive` Window become a native OS window** (`embed_subwindows` lockdown). Pattern: `brief_editor_window_native_os_mode` — source: ADR-0008 amend-2 §D2

### Performance Guardrails

- **EvaluationService.submit() pipeline**: < 50ms for typical chain_data (~10 nodes × 3 evidence) — source: ADR-0007 §Performance
- **Workspace freeze cascade**: ≤16ms from submit_confirmed click to FROZEN state (UI tween 별도) — source: ADR-0008 §Performance + ADR-0001 amend-2
- **Brief IMPORTING handoff**: ≤150ms from workspace_state_changed FROZEN to brief.state == IMPORTING — source: ADR-0001 amend-2 + TR-brief-001
- **Workspace 60fps target with 5 root × 3 deep × 5 evidence (~117 nodes)** — source: AC-49 (stub test until VR-OQ-W10 ratify per gdunit4 v5.x skip parameter)
- **MemoPanel A↔B fade transition**: 0.15s opacity tween (Reduced Motion → instant) — source: ADR-0008 §3 + amend-1 §A4

---

## Presentation Layer Rules

*Applies to: rendering pipeline, UI Theme application, AccessKit role assignment, audio cue mixing, dual focus ring composite, drag preview visuals.*

### Required Patterns

- **KrCustomControl `_apply_access_kit_role()` override hook**: each subclass overrides to set `accessibility_role` after `super._ready()` — source: ADR-0010 §Decision
- **Use corrected AccessibilityRole mapping (amend-4 §F1 + amend-1 §G1)**:
  - KrPane → `ROLE_PANEL` (=6)
  - KrHeader → `ROLE_STATIC_TEXT` (=4)
  - KrCard base → `ROLE_PANEL` (=6); subclasses override (LibraryCard → ROLE_LIST_ITEM=30, HypothesisNode → ROLE_TREE_ITEM=28, EnvelopeCard → ROLE_BUTTON=7, GroundsCard → ROLE_CHECK_BOX=9)
  - KrDialog → `ROLE_DIALOG` (=44)
  - KrButton → `ROLE_BUTTON` (=7)
  - KrSlider → `ROLE_SLIDER` (=15)
  - KrRadioGroup → `ROLE_PANEL` (=6); children → `ROLE_RADIO_BUTTON` (=10)
  - KrCheckBox → `ROLE_CHECK_BOX` (=9, two-word)
  - KrDropdown → `ROLE_LIST_BOX` (=31)
  - KrLineEdit → `ROLE_TEXT_FIELD` (=18, single-line)
  - KrTextEdit → `ROLE_MULTILINE_TEXT_FIELD` (=19)
  - KrBanner family (ReadOnlyBanner / CriticalBanner / ToastBanner) → `ROLE_STATIC_TEXT` (=4) + `UIService.announce_text` mandatory
- **`accessibility_name` populated for each Control** with semantically meaningful text (e.g. HypothesisNode = "label (증거 N개)") — distinguishes elements with same role — source: ADR-0010 amend-1 §R3 Risk mitigation
- **Dual focus ring composite**: inner 2px solid 잉크블랙 (fixed) + outer dashed 1-4px (from `accessibility.focus_indicator_thickness_px` setting); implement via Control `_draw()` override + custom dashed line routine (ADR-0010 R8 option 2) — source: ADR-0010 §Dual Focus Ring Composite + R8
- **Drag preview**: 70% transparent KrCard ghost via `set_drag_preview(duplicate())` in `_get_drag_data` — source: ADR-0008 §2 drag preview pattern
- **HypothesisNode bottom evidence rule**: discrete steps (cap=5 → 6 ρ values {0.0, 0.2, 0.4, 0.6, 0.8, 1.0}); 200×48 hero shape; rule length = ρ × 184px (inner padding) drawn via Control `_draw()` — source: ADR-0008 §1, GDD §8.1.1.b
- **Audio cues via `AudioService.play(event_name)` autoload**: 21-event catalog per GDD §8.2 (e.g. `weight-stamp` for evidence attach, `paper-blocked` for invalid drop, `ink-pen-mark` for memo char) — source: GDD §8.2 audio-director catalog (no dedicated ADR yet — pending ADR-0012 Audio Cue Registry per delta report)

### Forbidden Approaches

- **Never use deprecated rendering APIs** (per `deprecated-apis.md` Patterns table): manual post-process viewport chains (use Compositor instead), Texture2D in shader params (use Texture base type), GodotPhysics3D for new projects (Jolt is 4.6 default) — source: `docs/engine-reference/godot/deprecated-apis.md`
- **Never assume `AccessibilityServer` is a standalone class** — it's not; AccessKit is exposed via `DisplayServer.accessibility_*` 76 methods. Source: VR-UI6 dump 2026-05-17, `docs/engine-reference/godot/modules/ui.md`
- **Never assume `StyleBoxFlat` supports native dashed borders** — it doesn't; choose ADR-0010 R8 option (_draw override, overlap StyleBox, or shader). Source: ADR-0010 §Risk R8
- **Never animate without checking Reduced Motion** — always route through `UIService.tween_property()` gateway. Pattern: `direct_create_tween_bypassing_reduced_motion` (also Foundation-layer)

### Performance Guardrails

- **Drag preview render**: < 1ms per mouse motion event — source: ADR-0008 §2 + Performance
- **Theme cascade on `text_scale` change**: < 50ms for ~21 KrCustomControl scene (VR-UI1 PASS, automatic) — source: ADR-0010 §Performance
- **UIService.announce_text call**: < 0.5ms per call (1 API call; fallback +2 calls for focus-shift if VR-UI6 had failed — fallback NOT used post-VR-UI6 PASS) — source: ADR-0010 amend-1 §Performance

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController`, `WorkspaceData`, `HypothesisNode` |
| Variables | snake_case | `move_speed`, `chain_data_snapshot`, `pending_citation` |
| Signals / Events | snake_case past tense | `health_changed`, `enemy_defeated`, `workspace_state_changed`, `citation_drag_started` |
| Files | snake_case matching class | `player_controller.gd`, `workspace_data.gd`, `hypothesis_node.gd` |
| Scenes / Prefabs | PascalCase matching root node | `PlayerController.tscn`, `DeskPane.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH`, `EVIDENCE_CAP`, `MAX_DEPTH` |
| Theme type variations | `&"PascalCase"` StringName | `&"HypothesisNode"`, `&"MemoEdit"`, `&"CourtHeadline"` |

Source: `.claude/docs/technical-preferences.md` §Naming Conventions

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16.6 ms total (~11 ms CPU / ~5 ms GPU starting split) |
| Draw calls | < 2000 per frame (Forward+ desktop) |
| Memory ceiling | 2 GB working set (initial target — refine when target hardware fixed) |

Source: `.claude/docs/technical-preferences.md` §Performance Budgets

### Approved Libraries / Addons

- **gdunit4** v5.0+ — GDScript test framework (Godot 4.4+ ready). Approved 2026-05-09. Skip API uses **function signature parameter pattern** (`_do_skip := true, _skip_reason := "..."`); imperative `skip("reason")` call is NOT supported in GDScript (only C# variant). Source: `.claude/docs/technical-preferences.md` §Allowed Libraries + reasoning-workspace AC-49 stub pattern

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or unverified for Godot 4.6. Use the right column instead:

| Deprecated | Use Instead | Since |
|------------|-------------|-------|
| `TileMap` | `TileMapLayer` | 4.3 |
| `VisibilityNotifier2D` / `VisibilityNotifier3D` | `VisibleOnScreenNotifier2D` / `VisibleOnScreenNotifier3D` | 4.0 |
| `YSort` | `Node2D.y_sort_enabled` property | 4.0 |
| `Navigation2D` / `Navigation3D` | `NavigationServer2D` / `NavigationServer3D` | 4.0 |
| `EditorSceneFormatImporterFBX` | `EditorSceneFormatImporterFBX2GLTF` | 4.3 |
| `yield()` | `await signal` | 4.0 |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | 4.0 |
| `instance()` / `PackedScene.instance()` | `instantiate()` | 4.0 |
| `get_world()` | `get_world_3d()` | 4.0 |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | 4.0 |
| `duplicate()` for nested resources | `duplicate_deep()` | 4.5 (for Resource trees only; primitive Variant containers can still use `.duplicate(true)`) |
| `Skeleton3D bone_pose_updated` signal | `skeleton_updated` | 4.3 |
| `AnimationPlayer.method_call_mode` | `AnimationMixer.callback_mode_method` | 4.3 |
| `AnimationPlayer.playback_active` | `AnimationMixer.active` | 4.3 |
| `TextEdit.composition_finished` signal | **does not exist** — use `_gui_input` `InputEventKey` analysis | 4.6 (sprint VR-D2 FAIL — never existed) |
| Hallucinated AccessibilityRole names | Use corrected mapping (see Foundation + Presentation rules) | 4.6 (sprint VR-UI2 FAIL — never existed) |

Source: `docs/engine-reference/godot/deprecated-apis.md` + `verification-sprint-2026-05-17.md` corrections

### Cross-Cutting Constraints

- **Engine version**: project pinned to Godot 4.6 — do not introduce features requiring Godot 4.7+ (none anticipated for MVP)
- **Knowledge cutoff awareness**: LLM training data ~Godot 4.3; ALWAYS check `docs/engine-reference/godot/` snapshots before suggesting any 4.4/4.5/4.6 API. If snapshot is silent, WebFetch official docs (`https://docs.godotengine.org/en/stable/`) before committing
- **Trunk-based development**: changes go to `main` directly (with PR review for non-trivial changes). No long-lived feature branches
- **Tests are blocking CI gate**: never disable or skip failing tests to make CI pass; fix the underlying issue. gdunit4 skip API uses function-signature parameter pattern for *stub* tests pending VR closure — not for hiding failures
- **All gameplay values data-driven**: balance numbers, formulas, caps from external config (entities.yaml, ADR-registered constants) — never hardcoded magic numbers
- **All public methods must be unit-testable**: prefer dependency injection over singleton direct calls (exception: autoload services accessed via typed signal subscribe)
- **Commits must reference relevant design document or task ID** (story ID, ADR number, or GDD section)
- **Verification-driven development**: write tests first for Logic stories; verify UI changes with screenshots; compare expected output to actual before marking work complete
- **Korean text in user-facing strings**: all user-facing text in Korean (project is `config/name="파기"`, Korean appellate court simulation). Code identifiers + comments may be English
- **Custom mouse cursor**: `Input.set_custom_mouse_cursor(image: Resource, shape: CursorShape = 0, hotspot: Vector2 = Vector2(0, 0))` — `image` must be `Texture2D` (Resource); pass `CURSOR_DRAG` shape when grab/grabbing cursor active. Source: ADR-0008 amend-1 §A2, `docs/engine-reference/godot/modules/input.md`

---

## Manifest Regeneration Triggers

Re-run `/create-control-manifest` (full regeneration) when:

- Any new ADR transitions Proposed → Accepted
- Any existing Accepted ADR is revised (amendment added)
- `docs/registry/architecture.yaml` forbidden_patterns / api_decisions / interfaces section changes
- `.claude/docs/technical-preferences.md` Performance Budgets / Approved Libraries / Naming Conventions changes
- `docs/engine-reference/godot/` is updated (new deprecated APIs surface or post-cutoff API rules added)
- Engine version pin changes (Godot 4.6 → 4.7)

When regenerating, increment `Manifest Version` to the new date. Stories created with the old `Manifest Version` will be flagged by `/story-readiness` as stale — author must re-confirm rules apply or re-decompose.
