## SaveLoadService — autoload SIXTH. Atomic persistence SSOT for save/load.
##
## Story 001 scope: autoload skeleton + [code]user://saves/[/code] bootstrap +
## the atomic write wrapper. Later stories add the save-data Resource classes
## (002), signal-triggered autosave + debounce (003), boot load + corruption
## recovery (004), resolution/recovery cascades (005/006), Anti-Pillar guards
## (007), and the close-request forced flush (008).
##
## [b]Registration[/b]: [code]project.godot[/code] [autoload] section as
## [code]SaveLoadService="*res://src/services/save_load_service.gd"[/code] — SIXTH
## position per ADR-0011 (after LibraryService / UIService / CaseService; the
## intermediate EvaluationService THIRD + SettingsService FIFTH slots are not yet
## implemented — ordering is positional intent, not a hard prerequisite).
##
## [b]Class binding note[/b]: class_name is [code]SaveLoadServiceClass[/code] (not
## SaveLoadService) because Godot 4.6 rejects a script whose class_name equals the
## autoload node name ("Class X hides an autoload singleton"). The autoload
## registration publishes the [code]SaveLoadService[/code] global symbol independently.
## (Same pattern as [code]UIServiceClass[/code].)
##
## [b]Atomic write[/b]: [method _save_resource_atomic] writes to a [code].tmp[/code]
## sibling then [method DirAccess.rename_absolute] over the target — atomic on POSIX
## within one filesystem; Windows NTFS is best-effort (corruption detected on load
## via schema_version / loader error, ADR-0011 + current-best-practices.md). Never
## call [method ResourceSaver.save] directly onto the live target file.
##
## ADR: docs/architecture/adr-0011-save-load-storage-format.md
## TR:  TR-save-*
class_name SaveLoadServiceClass extends Node


# ─── Signals ──────────────────────────────────────────────────────────────────

## Emitted when a save file fails to load (corrupt / wrong type / future version).
## [param category] identifies which file (e.g. "active_case"). The file is renamed to
## [code].backup[/code] first. Consumers show a CriticalBanner (UI Foundation
## announce_text — deferred). AC-7.
signal save_corrupted(category: String)

## The single crash-recovery entry point (ADR-0011 + ADR-0001 amend-2 §C3): emitted at
## boot when an in-progress case was loaded. Subscribers (Workspace / Brief controllers —
## stories 006 / Brief epic) decide whether to auto-resubmit based on the recovered state.
signal active_case_recovered(workspace_data: WorkspaceData, brief_editor_data: Resource)

## Emitted after a Resolved case is archived to the casebook (story 005 resolution cascade).
signal casebook_entry_added(entry: CasebookEntry)


# ─── Constants ────────────────────────────────────────────────────────────────

## Root directory for all save data. Created on first [method _ready] if absent (EC-1).
## Settings are NOT stored here — they live in a separate [code]user://user_settings.cfg[/code]
## (ADR-0009 / Settings system), per forbidden pattern [code]save_load_settings_inclusion[/code].
const SAVES_DIR: String = "user://saves/"

## Current on-disk save schema version. Save Resources (story 002) carry a matching
## [code]save_file_version[/code]; a loaded file with a higher version is treated as
## corruption (story 002/004). ADR-0011 §Decision.
const CURRENT_SAVE_FILE_VERSION: int = 1

## Persisted file paths under [constant SAVES_DIR].
const ACTIVE_CASE_FILE: String = "user://saves/active_case.tres"
const CASEBOOK_FILE: String = "user://saves/casebook.tres"
const SESSION_META_FILE: String = "user://saves/session_meta.cfg"

## Per-category autosave debounce in milliseconds (ADR-0011 §Debounce Implementation).
## A value of 0 means "save immediately" (resolution / recovery-critical categories).
## Signal-triggered ONLY — never per-frame polling (forbidden: save_load_polling_based_autosave).
const DEBOUNCE_MS: Dictionary = {
	"workspace_state_changed": 250,
	"brief_editor_state_changed": 250,
	"brief_editor_submitted": 0,
	"evaluation_completed": 0,
	"submission_rejected": 0,
	"case_state_changed": 0,
}


# ─── Built-in virtual methods ─────────────────────────────────────────────────

## Ensures the save directory exists, then boot-loads persisted state and emits the
## crash-recovery entry point. Per-category autosave timers are created lazily (story 003).
func _ready() -> void:
	_ensure_saves_dir()
	# Intercept the window-close so a pending (debounced) save is flushed before quit.
	# Only affects WM_CLOSE_REQUEST; explicit get_tree().quit() (e.g. test runner) still works.
	get_tree().set_auto_accept_quit(false)
	await _boot_load()


## Flushes any pending save on window close, then quits (story 008 / ADR-0011 §3.4).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_pending_save()
		get_tree().quit()


# ─── Public / internal methods ──────────────────────────────────────────────────

## Creates [constant SAVES_DIR] if it does not already exist.
##
## AC-1: silent — no [code]push_warning[/code] on the normal (absent-dir) path.
## A genuine failure to create the directory is an error worth surfacing.
func _ensure_saves_dir() -> void:
	if DirAccess.dir_exists_absolute(SAVES_DIR):
		return
	var err: Error = DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	if err != OK:
		push_error("SaveLoadService: failed to create %s (error %d)" % [SAVES_DIR, err])


## Atomically writes [param res] to [param target_path] via write-to-temp + rename.
##
## Steps: (1) [method ResourceSaver.save] to [code]<target>.tmp[/code]; (2)
## [method DirAccess.rename_absolute] the tmp over the target. Returns [code]true[/code]
## only when both succeed.
##
## AC-8: on success the target is fully replaced and no [code].tmp[/code] remains.
## AC-9: if the tmp write fails (e.g. disk full / unwritable), returns [code]false[/code]
## with a [code]push_error[/code] and the existing target file is left untouched —
## the partial write never reaches the live file.
##
## ADR-0011 + docs/engine-reference/godot/current-best-practices.md (atomic write).
func _save_resource_atomic(res: Resource, target_path: String) -> bool:
	# IMPORTANT: ResourceSaver.save() picks its format from the file EXTENSION. A bare
	# ".tmp" suffix yields ERR_FILE_UNRECOGNIZED, so the temp file must keep a recognized
	# extension. Insert ".tmp" BEFORE the extension: "case.tres" -> "case.tmp.tres".
	var tmp_path: String = "%s.tmp.%s" % [target_path.get_basename(), target_path.get_extension()]
	var save_err: Error = ResourceSaver.save(res, tmp_path)
	if save_err != OK:
		push_error(
			"SaveLoadService: temp write failed for %s (error %d) — target preserved" \
			% [target_path, save_err]
		)
		return false
	var rename_err: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(target_path),
	)
	if rename_err != OK:
		push_error(
			"SaveLoadService: rename failed %s -> %s (error %d) — target preserved" \
			% [tmp_path, target_path, rename_err]
		)
		# Best-effort cleanup of the stray temp file so it cannot be mistaken for data.
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
		return false
	return true


## Returns whether a loaded save Resource's [code]save_file_version[/code] can be read
## by this build's schema.
##
## AC-11: a version greater than [constant CURRENT_SAVE_FILE_VERSION] is a future-format
## file this build cannot understand — the caller (boot load, story 004) treats it as
## corruption (rename to .backup + recovery cascade) rather than loading it. A version
## less than current is forward-compatible — Godot [code]@export[/code] defaults fill any
## fields the older file lacks (AC-10), so older files load normally. Version 0 / negative
## is malformed.
func _is_save_version_supported(version: int) -> bool:
	return version >= 1 and version <= CURRENT_SAVE_FILE_VERSION


# ─── Signal-triggered autosave + debounce (story 003) ─────────────────────────

## The in-progress case snapshot autosaved on workspace/brief changes. Populated by
## the boot load (story 004) or the runtime controllers; null when no case is active.
var _active_case: ActiveCaseSaveData = null

## Per-category debounce timers, created lazily. category(String) -> Timer.
var _debounce_timers: Dictionary = {}

## Handler for `workspace_state_changed` — schedules a debounced active_case save.
## Connected (subscribe-if-present) to the live WorkspaceData / workspace controller
## when it exists; for now it is the public entry the workspace side calls.
func _on_workspace_changed(_old_state: int, _new_state: int) -> void:
	_schedule_save("workspace_state_changed")

## Schedules a save for [param category]. If the category's [constant DEBOUNCE_MS] is 0,
## saves immediately; otherwise (re)starts the category's debounce timer so a burst of
## changes within the window coalesces into a single save (EC-9).
##
## Signal-triggered only — there is deliberately no [code]_process[/code] /
## [code]_physics_process[/code] autosave (forbidden: save_load_polling_based_autosave).
func _schedule_save(category: String) -> void:
	var ms: int = int(DEBOUNCE_MS.get(category, 0))
	if ms == 0:
		_perform_save(category)
		return
	var timer: Timer = _debounce_timer_for(category)
	timer.wait_time = ms / 1000.0
	timer.start()   # restarts if already running → debounce coalescing

## Returns (creating on first use) the one-shot debounce Timer for [param category].
func _debounce_timer_for(category: String) -> Timer:
	if _debounce_timers.has(category):
		return _debounce_timers[category]
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func() -> void: _perform_save(category))
	add_child(timer)
	_debounce_timers[category] = timer
	return timer

## Writes the save category to disk via the atomic wrapper. Story 003 implements the
## active_case path (workspace/brief categories); resolution/recovery categories
## (casebook/career) are wired in stories 005/006.
func _perform_save(category: String) -> void:
	match category:
		"workspace_state_changed", "brief_editor_state_changed", "brief_editor_submitted":
			if _active_case == null:
				return   # nothing to persist yet
			_save_resource_atomic(_active_case, ACTIVE_CASE_FILE)
		_:
			pass   # casebook / career / lifecycle categories — stories 005/006


# ─── Boot load + crash-recovery entry (story 004) ─────────────────────────────

## The eager-loaded casebook (story 004). Empty until loaded.
var _casebook: Casebook = null

## Session-meta values loaded from `session_meta.cfg` (AC-16). Consumers (Browser auto-entry,
## Workspace F2-toast suppression) read these; they default safely when the file is absent.
var last_active_case_id: String = ""
var workspace_f2_hint_seen: bool = false

## Boot sequence: eager-load casebook + session meta, load (or recover) the active case,
## then emit [signal active_case_recovered] for the crash-recovery subscribers (story 006).
func _boot_load() -> void:
	_casebook = _load_casebook()
	_load_session_meta()
	_active_case = _load_active_case_or_recover()
	# Defer the recovery emit one frame so subscriber autoloads/controllers have run
	# their _ready (ADR-0001 amend-2 §C3 pattern).
	await get_tree().process_frame
	if _active_case != null:
		active_case_recovered.emit(_active_case.workspace_data, _active_case.brief_editor_data)

## Loads the active case, or returns null. On corruption (load failure / wrong type /
## unsupported version) renames the file to `.backup`, emits [signal save_corrupted],
## and returns null so the boot continues with a fresh state (AC-7 / EC-3). Absent file
## → null with no side effects (EC-2 fresh start).
func _load_active_case_or_recover() -> ActiveCaseSaveData:
	if not FileAccess.file_exists(ACTIVE_CASE_FILE):
		return null
	var res: Resource = ResourceLoader.load(ACTIVE_CASE_FILE, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null or not (res is ActiveCaseSaveData) or not _is_save_version_supported((res as ActiveCaseSaveData).save_file_version):
		push_error("SaveLoadService: active_case load failed/corrupt — renaming to .backup")
		_rename_to_backup(ACTIVE_CASE_FILE)
		save_corrupted.emit("active_case")
		return null
	return res as ActiveCaseSaveData

## Eager-loads the casebook, or returns a fresh empty [Casebook] when absent (EC-2).
## A corrupt casebook is recovered the same way as the active case (.backup + signal).
func _load_casebook() -> Casebook:
	if not FileAccess.file_exists(CASEBOOK_FILE):
		return Casebook.new()
	var res: Resource = ResourceLoader.load(CASEBOOK_FILE, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null or not (res is Casebook) or not _is_save_version_supported((res as Casebook).save_file_version):
		push_error("SaveLoadService: casebook load failed/corrupt — renaming to .backup")
		_rename_to_backup(CASEBOOK_FILE)
		save_corrupted.emit("casebook")
		return Casebook.new()
	return res as Casebook

## Loads session meta (last active case + UI hints) from the `.cfg`. Missing file → defaults.
func _load_session_meta() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SESSION_META_FILE) != OK:
		return   # absent / unreadable → keep safe defaults
	last_active_case_id = cfg.get_value("session", "last_active_case_id", "")
	workspace_f2_hint_seen = cfg.get_value("hints", "workspace_f2_hint_seen", false)

## Renames [param path] to [code]<path>.backup[/code] (best-effort), so a corrupt file is
## preserved for diagnostics and not overwritten in place.
func _rename_to_backup(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(path + ".backup"),
	)


# ─── Anti-Pillar serialization guards (story 007) ─────────────────────────────

## Validates an active-case snapshot before it is persisted.
##
## AC-13: the embedded chain_data must not contain ephemeral / non-allow-listed fields
## (`chain_data_include_ephemeral_field`). This delegates to the SINGLE canonical
## validator [method WorkspaceData.validate_chain_data] — the allow-list is never
## duplicated here (`chain_data_schema_allow_list_duplication`). On a violation that
## validator emits `submission_rejected` and returns false.
##
## AC-12 (Settings exclusion, `save_load_settings_inclusion`) is structural: an
## [ActiveCaseSaveData] has no Settings fields — Settings persist separately in
## `user://user_settings.cfg` (ADR-0009). There is nothing to strip at write time.
func _validate_active_case(active: ActiveCaseSaveData) -> bool:
	if active == null or active.workspace_data == null:
		return true   # nothing to validate
	return active.workspace_data.validate_chain_data(active.workspace_data.chain_data_snapshot)


# ─── Close-request forced flush (story 008) ───────────────────────────────────

## Drains any pending debounced save synchronously (EC-10) so the final edits are not
## lost when the app is closing. For every running per-category debounce timer, the save
## is performed immediately instead of waiting for its timeout. A no-op when nothing is
## pending (no dirty timer).
func _flush_pending_save() -> void:
	for category: String in _debounce_timers:
		var timer: Timer = _debounce_timers[category]
		if timer != null and not timer.is_stopped():
			timer.stop()
			_perform_save(category)


# ─── Resolution cascade + revert guard (story 005) ────────────────────────────

## Returns true if a case with [param case_id] is already archived in the casebook
## (i.e. Resolved). Used by the anti-save-scumming revert guard.
func _casebook_has(case_id: String) -> bool:
	if _casebook == null:
		return false
	for entry: CasebookEntry in _casebook.entries:
		if entry.case_id == case_id:
			return true
	return false

## Resolution cascade: archive the Resolved case to the casebook (immediate write),
## delete the active case (anti-save-scumming), and announce the new entry.
##
## AC-3. The [param result] is duck-typed (`case_id` / `verdict` / `final_score`) because
## the `EvaluationResult` class lives in the Submission/Evaluation epic. This handler is
## the subscriber for `EvaluationService.evaluation_completed`; that subscription is
## DEFERRED until EvaluationService is implemented. (TD-001 RESOLVED 2026-05-23: the
## EvaluationService entry point is `submit(submission: PlayerSubmission)` per ADR-0007 —
## the control-manifest was corrected to match.)
func _on_evaluation_completed(result: Object) -> void:
	if _casebook == null:
		_casebook = Casebook.new()
	var entry := CasebookEntry.new()
	entry.case_id = result.get("case_id")
	entry.verdict = result.get("verdict")
	entry.final_score = result.get("final_score")
	_casebook.entries.append(entry)
	_save_resource_atomic(_casebook, CASEBOOK_FILE)   # immediate (0ms) — write casebook BEFORE deleting active
	if FileAccess.file_exists(ACTIVE_CASE_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ACTIVE_CASE_FILE))
	_active_case = null
	casebook_entry_added.emit(entry)

## Persists the active case, UNLESS its case_id is already Resolved (in the casebook).
##
## AC-4 / EC-5: a Resolved case cannot be re-saved (anti-save-scumming,
## `save_load_revert_resolved`, Pillar 1 irreversibility). Returns false + push_error
## without touching `active_case.tres` in that case.
func save_active_case() -> bool:
	if _active_case == null:
		return false
	if _casebook_has(_active_case.case_id):
		push_error(
			"save_load_revert_resolved: case '%s' is Resolved — cannot re-save" \
			% _active_case.case_id
		)
		return false
	return _save_resource_atomic(_active_case, ACTIVE_CASE_FILE)


# ─── Crash-recovery branch contract (story 006) ───────────────────────────────

## Decides which auto-resubmit branch a recovered case takes (ADR-0011 recovery cascade).
## The actual resubmit (calling EvaluationService.submit) is performed by the Workspace /
## Brief controllers subscribing to [signal active_case_recovered] — DEFERRED until those
## controllers + EvaluationService exist. This pure helper locks + tests the decision.
##
## Precedence: a FROZEN workspace (committed submission awaiting evaluation) wins over a
## SUBMITTING brief. Returns "workspace_resubmit" / "brief_resubmit" / "none".
func recovery_branch_for(workspace_data: WorkspaceData, brief_editor_data: Object) -> String:
	if workspace_data != null and workspace_data.state == WorkspaceData.WorkspaceState.FROZEN:
		return "workspace_resubmit"
	if brief_editor_data != null and brief_editor_data.get("state") == BRIEF_SUBMITTING:
		return "brief_resubmit"
	return "none"

## BriefEditorData SUBMITTING state value. The BriefEditorData enum lives in the Brief
## Editor epic; this mirrors its SUBMITTING ordinal until that class exists. (Brief
## lifecycle per ADR-0001 amend-2.)
const BRIEF_SUBMITTING: int = 3
