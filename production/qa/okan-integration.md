# Okan selective integration

Baseline: main c040f031623416cf89cf341dcb57a58172999efe.
Source: Okan 68f3cbf6bad63f77fd01222b8c93b8f455aa9a4e.
Worktree: `.worktrees/p2-okan-integration`; branch `feat/alicomert/p2-okan-integration`.
No commit, push, or changes to main. UI prototype and Autopilot worktrees untouched.

## Decisions
- Imported role profiles, Kilit/Kirici/Yuk controllers, cargo physics/utility fixtures, electrical devices and regression tests.
- Preserved main 3D aiming, active reload/context cursor, feedback/recovery/menu and Scout. Added explicit Scout profile and single Q/F dispatcher.
- Removed general dash per project rule and owner approval. Legacy role components remain available to their unit tests; live lab uses integrated role dispatch.
- Cancel hack/cargo/drone state on appropriate pause/focus/reset/role transitions. Preserve cooldowns across switching.
- Added fuse line-of-sight filtering and blocked-by-wall tests; explicit shield placement collision mask.
- Kept main existing UID identities on overlap; added imported module UIDs. Godot-generated unrelated untracked UID sidecars are not staged.
- Manifest has explicit completed-task integration handoffs authorized by project owner, validated narrowly; active source tasks and uncovered overlaps remain rejected. This does not authenticate ownership or provide cross-clone locking.

## Verification (Godot 4.7.2)
- Parent rerun: 32 unit suites plus roles/cargo suites = 34/34 clean processes; no FAIL, SCRIPT ERROR or ERROR output. Roles 60 checks; cargo 46 checks.
- Parent rerun visible combat-lab: 29 checks, 0 failures.
- Parent rerun full P1 integration: 20 checks, 0 failures, clean shutdown output.
- Parent Python routing tests: 22 passed, including invalid/incomplete handoff regressions.
- Worker reports source/unit/integration parse successful; visible role input 18/18; visible cargo input 19/19; core integration 20/20; combat 60/60; phase packages 27/27.
- Git unmerged index entries empty; staged and unstaged diff --check passed.

## Issues found and resolved
- Visible combat repeated reload initially failed because autonomous enemies damaged/killed the stationary test player. Test now freezes only autonomous enemy physics and retains explicit damage/HUD checks. Screenshot evidence writes to user://integration-evidence rather than tracked repository PNGs. All original reload assertions retained and passed on parent rerun.
- Full integration initially leaked unattached standalone Node role fixtures. Explicit teardown added; RefCounted puller is NOT freed manually. Parent rerun clean.
- Typed laser exclusion-array assignment changed to assign() for GDScript compatibility.

## Remaining boundaries
- Real Windows OS keyboard automation did not deliver input; physical hardware movement/Space smoke is NOT VERIFIED. Synthetic visible role/cargo/combat paths are not equivalent to hardware verification.
- No claim of production-ready co-op synchronization, AI smoke occlusion or full inventory: cargo/utilities remain lab systems.
- Manual visual/menu/aim feel and two-machine multiplayer acceptance remain required before release.
- Changes remain uncommitted on isolated integration branch; main does not yet contain this work. No release gate approval implied.
