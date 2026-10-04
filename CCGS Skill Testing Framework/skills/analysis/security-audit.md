# Skill Test Spec: /security-audit

## Skill Summary

`/security-audit` audits the codebase for common game security failures across
six categories: save/serialization, network/multiplayer, input validation, data
exposure, cheat/anti-tamper vectors, and dependencies. It takes a scope
(`full`, `network`, `save`, `input`, `quick`; no argument runs `full`), reads
`engine.name`, `engine.language`, `platform.targets`, `platform.multiplayer` and
`platform.online` from `project.yaml`, and spawns the `security-engineer` agent
with a fixed brief template — only its slots filled: the scope, the engine, the
`platform.*` values, the resolved code root, `assets/data/` and config files,
the categories and the report path — whose own text tells the agent to rate
every finding from its severity table and that game type never lowers a
rating. Grep patterns are chosen per engine from the
Phase 3 table; a category the table marks NOT SOURCEABLE for the engine is
NOT ASSESSED, and an absent `platform.multiplayer` is never read as `false`.
A skipped category is named with its reason, and an unresolved code root makes
the code categories NOT ASSESSED. Findings are classified CRITICAL / HIGH /
MEDIUM / LOW, each with file, line, attack scenario and remediation. The
report's release recommendation, first match wins, is DO NOT SHIP, FIX BEFORE
SHIPPING, NOT ASSESSED (e.g. INSUFFICIENT IMPLEMENTATION) or CLEAR TO SHIP.
The skill presents the executive summary and CRITICAL/HIGH
findings in conversation, then asks "May I write the full security audit report
to `production/security/security-audit-[date]-[scope].md`?" At
`workflow: minimal` the Phase 7 message says the release gate does not read the
report. No director gates are invoked.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: CLEAR TO SHIP, FIX BEFORE SHIPPING, DO NOT SHIP, NOT ASSESSED, and the severities CRITICAL / HIGH / MEDIUM / LOW
- [ ] Contains "May I write" language naming `production/security/security-audit-[date]-[scope].md`
- [ ] Has a next-step handoff (Phase 7: `/security-audit quick`, `/gate-check release`, `/launch-checklist`)

---

## Director Gate Checks

None. The skill spawns the `security-engineer` specialist to run the audit;
that is its core mechanism, not a director gate. No director gate is invoked in
any review mode.

---

## Test Cases

### Case 1: Happy Path — Single-player Godot project, no findings

**Fixture:**
- `project.yaml`: `engine.name: godot`, `engine.language: gdscript`, `platform.multiplayer: false`, `platform.online: false`, `modes.rigor: standard` (so `workflow` resolves to `standard`); `modes.automation` unset (collaborative)
- `src/` holds the implemented game: 42 `.gd` files across core, gameplay, UI and save systems
- `src/core/save_system.gd` opens saves with `FileAccess`, verifies a checksum, and bounds-checks every loaded value before use
- No API keys, secrets, passwords or tokens anywhere in `src/` or `assets/`
- `addons/gdUnit4/` is the only third-party dependency

**Input:** `/security-audit`

**Expected behavior:**
1. No argument → `full` scope
2. Skill reads engine, language and platform keys from `project.yaml`
3. Skill spawns `security-engineer` via `Agent` with the fixed brief template: the scope, Godot/GDScript, `platform.multiplayer: false`, `platform.online: false`, code root `src/`, `assets/data/` and config files, the categories to run, and the report path — nothing added outside the slots
4. Category 1 uses the Godot pattern list, including the Godot 4 name `FileAccess`; Category 2 is skipped because both platform keys are explicitly `false`, and the Executive Summary names the skip and its reason
5. Category 6 lists `addons/gdUnit4/` in the Dependency Inventory
6. Executive Summary shows zero findings at every severity over 42 source files; Release recommendation: **CLEAR TO SHIP**
7. Skill presents the summary, then asks "May I write the full security audit report to `production/security/security-audit-[date]-full.md`?"
8. After writing: "✅ No blocking security findings. Report written to `production/security/`. Include this path when running `/gate-check release`."

**Assertions:**
- [ ] `security-engineer` is spawned with the fixed brief template — scope, engine/language, the `platform.*` values and a source manifest rooted at `src/` — and the brief adds no severity and no remark on the game's type
- [ ] Save handling is checked with Godot 4 names (`FileAccess`), not only the Godot 3 `File.open`
- [ ] Hardcoded-credential patterns (`api_key`, `secret`, `password`, `token`, `private_key`) are scanned
- [ ] The Executive Summary says Category 2 was skipped because `platform.multiplayer` and `platform.online` are `false` — the skip is not silent
- [ ] Release recommendation is CLEAR TO SHIP
- [ ] "May I write" precedes the report write

---

### Case 1b: Single-player, One HIGH Finding — FIX BEFORE SHIPPING

**Fixture:**
- Same as Case 1, except `src/core/save_system.gd` loads save values with no
  checksum or bounds check, so an edited save file unlocks late-game progression
- No other findings

**Input:** `/security-audit`

**Expected behavior:**
1. The save finding is classified **HIGH** (save tampering that bypasses progression)
   and is **not** raised to CRITICAL, because `platform.multiplayer` is `false`
2. Release recommendation: **FIX BEFORE SHIPPING** — an open HIGH, no CRITICAL
3. After the write: "⚠️ 1 HIGH finding(s) are open. The Polish → Release gate's
   security audit item requires none — fix them and re-run `/security-audit quick`
   before `/gate-check release`."

**Assertions:**
- [ ] The brief sent to `security-engineer` is the fixed template: it does not call the save finding HIGH (or any severity), and does not say a single-player game lowers the bar — the agent rates it from its own table
- [ ] The finding is HIGH, not CRITICAL, in a single-player game
- [ ] Release recommendation is FIX BEFORE SHIPPING — never CLEAR TO SHIP with a HIGH open, and not DO NOT SHIP without a CRITICAL
- [ ] The ⚠️ HIGH message names the release gate's security audit item as the requirement, and names `/security-audit quick` and `/gate-check release`
- [ ] Variant — at `modes.rigor: minimal` the recommendation is still FIX BEFORE SHIPPING, and the message says the `minimal` release gate does not read this report instead of naming the gate item

---

### Case 2: Multiplayer Critical — Client-authoritative RPC and a hardcoded key

**Fixture:**
- `project.yaml`: `engine.name: godot`, `platform.multiplayer: true`, `platform.online: true`
- `src/net/combat_sync.gd` line 42: `@rpc("any_peer") func apply_damage(target_id, amount)` applies `amount` with no sender or range validation
- `src/online/leaderboard_client.gd` line 8: `const API_KEY = "sk_live_..."`

**Input:** `/security-audit full`

**Expected behavior:**
1. Category 2 runs (multiplayer is `true`) with the Godot network patterns (`MultiplayerPeer`, `rpc`, `@rpc`, …)
2. The unvalidated `apply_damage` RPC is a CRITICAL finding (client dictates outcomes, breaking multiplayer integrity)
3. The hardcoded key is a credential exposure (HIGH), treated as CRITICAL because the game is multiplayer
4. Each finding is written as `SEC-NNN` with Category, File and line, Description, Attack scenario, Remediation and Effort
5. Release recommendation is DO NOT SHIP — an open CRITICAL decides it
6. Skill presents the executive summary and CRITICAL/HIGH findings, then asks "May I write"
7. Phase 7: "⛔ CRITICAL security findings must be resolved before any public release. Do not proceed to `/launch-checklist` until these are addressed." and re-run `/security-audit quick` before `/gate-check release`

**Assertions:**
- [ ] The RPC finding cites `src/net/combat_sync.gd` with its line and an attack scenario
- [ ] The hardcoded key is raised to CRITICAL in the multiplayer context
- [ ] Every finding carries a specific remediation
- [ ] Release recommendation is DO NOT SHIP (open CRITICAL findings) — never FIX BEFORE SHIPPING or CLEAR TO SHIP
- [ ] The ⛔ message is shown and `/launch-checklist` is held back

---

### Case 3: Multiplayer Scope Unset — Absent is not `false`

**Fixture:**
- `project.yaml`: `engine.name: godot`; no `platform` block at all
- `src/networking/lobby.gd` defines `@rpc` functions `join_lobby()` and `send_chat()`
- `modes.automation` unset (collaborative)

**Input:** `/security-audit`

**Expected behavior:**
1. Skill finds `platform.multiplayer` and `platform.online` absent
2. Skill does not assume single-player and does not skip Category 2
3. Skill asks the user whether the game has multiplayer or online features
4. On "yes", Category 2 runs with the Godot network patterns and checks each `@rpc` call site for validation

**Assertions:**
- [ ] Absent `platform.multiplayer` / `platform.online` are not treated as `false`
- [ ] Skill asks the user whether the game has multiplayer or online features
- [ ] Category 2 is not skipped on the absent keys
- [ ] Unvalidated `@rpc` entry points in `lobby.gd` are checked and any gap is reported with a remediation
- [ ] Variant — with `modes.automation: autonomous` the question cannot be asked: Category 2 still runs, is marked `NOT ASSESSED — multiplayer scope unconfirmed`, and the recommendation is never CLEAR TO SHIP

---

### Case 4: No Implemented Surface — NOT ASSESSED — INSUFFICIENT IMPLEMENTATION

**Fixture:**
- `project.yaml`: `engine.name: godot`, `platform.multiplayer: false`, `platform.online: false`
- `src/` exists but contains no source files; `assets/data/` is empty

**Input:** `/security-audit`

**Expected behavior:**
1. The code root resolves to `src/`, but there is nothing in it to audit
2. Every code-scanning category has zero files to scan, so each is NOT ASSESSED rather than clean
3. Release recommendation: **NOT ASSESSED — INSUFFICIENT IMPLEMENTATION**
4. The report names what was missing (no source under `src/`) and which skill produces it
5. CLEAR TO SHIP is not reported

**Assertions:**
- [ ] The empty code root leaves every code-scanning category NOT ASSESSED; none is reported clean or as zero findings
- [ ] Release recommendation is NOT ASSESSED — INSUFFICIENT IMPLEMENTATION
- [ ] Output names what was missing and which skill produces it
- [ ] CLEAR TO SHIP is not reachable from a scan with nothing to look at
- [ ] Variant — with no `engine.name`, `technical-preferences.md` at `[TO BE CONFIGURED]`, and both `src/` and `Source/` present, the code root is unresolved: no root is guessed, the code categories read `NOT ASSESSED — code root unresolved`, and the recommendation is never CLEAR TO SHIP

---

### Case 5: Unity Project in Full Review Mode — NOT SOURCEABLE category, no gates

**Fixture:**
- `project.yaml`: `engine.name: unity`, `engine.language: csharp`, `platform.multiplayer: true`, `platform.online: true`, `modes.review_mode: full`
- `Assets/Scripts/Save/SaveManager.cs` reads and writes save data
- `Assets/Scripts/Net/PlayerNet.cs` has `[ServerRpc]` methods that validate their inputs
- No findings in the categories that can run

**Input:** `/security-audit`

**Expected behavior:**
1. The manifest passed to `security-engineer` is rooted at `Assets/`, not `src/`
2. Category 1 is `NOT SOURCEABLE` for Unity → `NOT ASSESSED`; no Unity save-API names are written from memory
3. Categories 2 and 3 use the Unity names from the Phase 3 table (`ServerRpc`, `ClientRpc`, `NetworkVariable`, …; `InputSystem`, `PlayerInput`, …), not the Godot lists
4. The Executive Summary names Category 1 as NOT ASSESSED; Release recommendation: `NOT ASSESSED — Save / serialization has no sourced pattern set for Unity`
5. The Phase 7 NOT ASSESSED message names Category 1 as NOT SOURCEABLE on Unity and its fix — a save/serialization module in `docs/engine-reference/unity/modules/` — not `engine.name`, the code root or the multiplayer scope, which were all supplied
6. No director gate is invoked regardless of review mode
7. Skill asks "May I write" before writing the report

**Assertions:**
- [ ] The source manifest uses the Unity code root `Assets/`
- [ ] Category 1 is NOT ASSESSED for Unity and no save-API pattern list is invented
- [ ] Category 2 uses the Unity network names, not the Godot list
- [ ] CLEAR TO SHIP is unreachable; the recommendation names the unsourced category
- [ ] The NOT ASSESSED message points at a serialization module under `docs/engine-reference/unity/modules/` as the fix
- [ ] No director gate is invoked in any review mode

---

### Case 5b: Ranking — An open HIGH outranks an unsourced category

**Fixture:**
- `project.yaml`: `engine.name: unity`, `engine.language: csharp`, `platform.multiplayer: false`, `platform.online: false`
- `Assets/Scripts/` holds the implemented game (35 `.cs` files), including `Assets/Scripts/Save/SaveManager.cs`
- `Assets/Scripts/Analytics/Telemetry.cs` line 12: `const string ApiKey = "sk_live_...";`
- No other findings

**Input:** `/security-audit`

**Expected behavior:**
1. Category 1 is `NOT SOURCEABLE` for Unity, so it is NOT ASSESSED; Category 2 is skipped (both platform keys `false`) and the skip is named
2. The hardcoded key is a credential exposure: HIGH, and not raised to CRITICAL because the game is single-player
3. Release recommendation: **FIX BEFORE SHIPPING** — the open HIGH is matched before NOT ASSESSED
4. The Executive Summary still names Category 1 as NOT ASSESSED

**Assertions:**
- [ ] Release recommendation is FIX BEFORE SHIPPING, not NOT ASSESSED — a known failure is not buried behind an unscanned category
- [ ] Category 1 is still reported NOT ASSESSED in the Executive Summary
- [ ] CLEAR TO SHIP is not reported

---

## Protocol Compliance

- [ ] Reads `engine.name`, `engine.language` and the `platform.*` keys from `project.yaml` before auditing
- [ ] Spawns `security-engineer` via `Agent` with the fixed brief template — only its named slots filled (scope, engine/language, `platform.*` values, the resolved code root, `assets/data/` and config files, the categories, the report path) — and no sentence of the orchestrator's own: no pre-rated finding, no "single-player lowers the stakes"; an unresolved code root makes the code categories NOT ASSESSED, never clean
- [ ] Uses the Phase 3 pattern set for the resolved engine; a NOT SOURCEABLE category is NOT ASSESSED and makes CLEAR TO SHIP unreachable
- [ ] Never treats an absent `platform.multiplayer` / `platform.online` as `false`
- [ ] Names every skipped category and why in the Executive Summary
- [ ] Each finding carries severity, category, file and line, attack scenario and remediation
- [ ] Release recommendation, first match: DO NOT SHIP, FIX BEFORE SHIPPING, NOT ASSESSED, CLEAR TO SHIP
- [ ] Presents the executive summary and CRITICAL/HIGH findings before asking "May I write" for `production/security/security-audit-[date]-[scope].md`; writes only after approval
- [ ] No director gates are invoked
- [ ] Ends with the Phase 7 gate-integration guidance

---

## Coverage Notes

- The `network`, `save`, `input` and `quick` scopes are not tested individually;
  they restrict the categories run by the same rules.
- An absent `engine.name` with a resolvable tree (every grep category NOT
  ASSESSED, with no fallback to the Godot lists) is not tested separately.
- Unreal follows the same engine table as Case 5 and is not tested separately.
