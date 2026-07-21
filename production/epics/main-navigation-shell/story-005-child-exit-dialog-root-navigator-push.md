# Story 005: Child Back-Button Exit Dialog & Root-Navigator Push Contract

> **Epic**: Main Navigation Shell
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: —

## Context

**GDD**: `design/gdd/main-navigation-shell.md`
**Requirement**: `TR-navshell-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Navigation Shell & Route Guard Architecture (Accepted), Decision §6 (Child-tab-root case) and §7 (root-navigator push contract)
**ADR Decision Summary**: Child tab-root screens show a kid-styled confirm dialog (**P17**, "Thoát PetQuest?") on back-press, using `PopScope(canPop: false, onPopInvokedWithResult: ...)` — never `WillPopScope`. Separately, this story registers the sanctioned root-navigator-push mechanism (`Navigator.of(context, rootNavigator: true).push(...)`) future non-dismissible ceremony overlays (e.g. Shop & Reward's Chest Open) will use, so the bottom nav bar stays hidden/untappable behind them.

**Engine**: Flutter 3.44.4 | **Risk**: LOW (both mechanisms fully verified against installed source during ADR-0014's authoring — `PopScope.onPopInvokedWithResult`'s real signature, `Navigator.of(context, rootNavigator: true)`'s standard API)
**Engine Notes**: `WillPopScope` was removed in Flutter 3.22+ — registered forbidden pattern (`will_pop_scope_usage`, `docs/registry/architecture.yaml`). Do not reach for it even if training-data familiarity suggests it.

**Control Manifest Rules (this layer)**:
- Forbidden: `WillPopScope` — registered forbidden pattern
- Required: `PopScope.onPopInvokedWithResult`, not the also-deprecated `onPopInvoked`
- Required: root-navigator push (not branch-scoped push) for non-dismissible overlays — the bottom nav bar lives at the Scaffold level, outside any branch `Navigator`; a branch-scoped push leaves it visible/tappable, defeating "non-dismissible"

**Performance Budget**: No dedicated latency budget — dialog show/dismiss is standard Material 3 timing, not separately specified by the GDD.

---

## Acceptance Criteria

*From GDD Acceptance Criteria AC-10, plus TR-navshell-004's root-navigator-push contract (no live consumer yet — Shop & Reward UI has no epic — but the mechanism itself must exist and be tested):*

- [ ] **AC-10**: GIVEN bé back-press trên Child tab root screen (Pet Room/Tasks/Shop), THEN dialog "Thoát PetQuest?" hiện — [Ở lại] dismiss dialog (stay in app), [Thoát] exit app.
- [ ] **Dialog only on tab roots, not sub-screens**: GIVEN bé ở `/child/tasks/new` (sub-screen), WHEN back-press, THEN dialog KHÔNG hiện — behavior is Story 002's AC-12 (navigate to `/child/tasks`), not this story's exit dialog. Verify the two code paths don't collide.
- [ ] **Parent tab root, NOT in override — no dialog**: GIVEN Parent Shell active, `sessionState != parentView` (this shouldn't normally happen since Parent Shell only renders under `parentAuthed`/`parentView`, but verify the guard doesn't accidentally show the kid-styled dialog on the Parent side under any reachable state) — direct exit, no dialog (adult tone).
- [ ] **Root-navigator push contract exists and is testable**: a reusable helper/pattern for `Navigator.of(context, rootNavigator: true).push(...)` is available for future non-dismissible overlays; test that a pushed root-navigator route visually covers the bottom nav bar (not just the branch content area).

---

## Implementation Notes

*Derived from ADR-0014 Decision §6 and §7:*

1. Child tab-root screens (Pet Room, Tasks, Shop — NOT `/child/tasks/new`) wrap their content in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, result) async { if (didPop) return; final shouldExit = await showDialog<bool>(context: context, builder: (_) => const ExitConfirmDialog()); if (shouldExit ?? false) SystemNavigator.pop(); }, child: ...)` — exact pattern from ADR-0014 Decision §6's first code sample.
2. `ExitConfirmDialog` — kid-styled `AlertDialog`, **P17** (Disruption-not-destruction confirm dialog, already in `design/ux/interaction-patterns.md`). [Ở lại] / [Thoát] buttons, no red/alarming color (Art Bible no-red rule).
3. Determining "is this a tab-root screen" — this should key off `activeChildBranchIndexProvider`'s current value paired with whether the navigator's own back-stack for that branch is empty (i.e., no sub-route pushed) — do not hardcode a route-string check if a cleaner signal is available from go_router's own state.
4. Root-navigator push: expose a small reusable function (e.g. `pushNonDismissibleOverlay(BuildContext context, Widget overlay)`) wrapping `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => overlay, fullscreenDialog: true))` — per ADR-0014 Decision §7's code sample. This story has no real ceremony overlay to push yet (Shop & Reward UI has no epic) — test with a placeholder full-screen widget and assert it visually covers the bottom nav bar, proving the mechanism works for whichever future epic needs it.
5. Do not conflate this story's `PopScope` usage with Story 004's (override-exit) or Story 003's (Parent-not-in-override, `canPop: true`) — three distinct configurations exist across this epic; keep them as separate, clearly-named widgets/functions rather than one parameterized mega-component that's easy to misconfigure.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 002**: sub-screen back navigation (`/child/tasks/new` → `/child/tasks`) — native go_router behavior, not this story's dialog.
- **Story 004**: Parent-Shell-in-override back-press behavior (a third, different `PopScope` configuration).
- **Story 003**: Parent-Shell-not-in-override back-press (`canPop: true`, no dialog at all) — trivial, but owned by that story's own Scaffold setup, not duplicated here.
- The actual ceremony overlay content (Chest Open, etc.) — Shop & Reward UI's future epic. This story only proves the push mechanism works with a placeholder.

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria — QL-STORY-READY gate skipped (Solo mode). This is a UI-type story — manual verification steps per the coding-standards.md advisory tier, plus one Logic-adjacent assertion for the root-navigator mechanism.*

- **AC-1 (Exit dialog — manual check)**
  - Setup: navigate to any Child tab root (Pet Room, Tasks, or Shop)
  - Verify: back-press (Android back button or gesture) shows "Thoát PetQuest?" dialog with [Ở lại]/[Thoát] buttons, kid-styled tone, no red color
  - Pass condition: [Ở lại] dismisses the dialog and stays in-app; [Thoát] exits the app entirely

- **AC-2 (Sub-screen — no dialog — manual check)**
  - Setup: navigate to `/child/tasks/new`
  - Verify: back-press does NOT show the exit dialog — navigates to `/child/tasks` instead
  - Pass condition: dialog never appears on this route

- **AC-3 (Root-navigator push — automated)**
  - Given: a placeholder full-screen widget pushed via the root-navigator helper
  - When: pushed while the bottom nav bar is visible
  - Then: the bottom nav bar is no longer visible/tappable (covered by the pushed route) — assert via widget-tree hit-testing, not just visual inspection

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/child-exit-dialog-evidence.md` — manual walkthrough for AC-1/AC-2
- `tests/integration/main-navigation-shell/root_navigator_push_test.dart` — automated test for AC-3 (root-navigator push is a testable mechanism even though the story's primary criterion is UI-tier)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Root Redirect), Story 002 (Child Shell — for tab-root detection) must be Complete.
- Unlocks: None further within this epic. Enables future Shop & Reward UI epic's ceremony overlays (no epic yet).
