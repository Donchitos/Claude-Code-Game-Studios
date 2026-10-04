---
name: security-audit
description: "Security audit — save tampering, cheat vectors, network exploits, data exposure, input validation. Before public or multiplayer release."
argument-hint: "[full | network | save | input | quick]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Agent, Bash(bash "*/.claude/skills/security-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (resolved above) decides only what Phase 7 tells you about the
release gate: at `standard` and `full` it requires this report; at `minimal` it
does not. The audit itself runs the same at every tier.

# Security Audit

Security is not optional for any shipped game. Even single-player games have
save tampering vectors. Multiplayer games have cheat surfaces, data exposure
risks, and denial-of-service potential. This skill systematically audits the
codebase for the most common game security failures and produces a prioritised
remediation plan.

**Run this skill:**
- Before any public release (required for the Polish → Release gate at `workflow: standard` and `full`)
- Before enabling any online/multiplayer feature
- After implementing any system that reads from disk or network
- When a security-related bug is reported

**Output:** `production/security/security-audit-[date]-[scope].md` — the scope
in the name keeps a same-day `quick` or `save` run from overwriting the `full`
report the release gate reads.

---

## Phase 1: Parse Arguments and Scope

**Modes:**
- `full` — all categories (recommended before release)
- `network` — network/multiplayer only
- `save` — save file and serialization only
- `input` — input validation and injection only
- `quick` — high-severity checks only (fastest, for iterative use)
- No argument — run `full`

Read `project.yaml` to determine the following, falling back to `.claude/docs/technical-preferences.md` for engine/language/platforms when a key is absent or empty:
- `engine.name` and `engine.language` — **load-bearing: they select the Phase 3
  pattern set, and an engine with no sourced set for a category makes that
  category `NOT ASSESSED`.** If `engine.name` is absent or empty, say so in the
  report and treat every grep category as `NOT ASSESSED`; do not fall back to
  the Godot lists because they are the ones written out in full
- `platform.targets` (affects which attack surfaces apply)
- `platform.multiplayer` and `platform.online` — whether multiplayer/networking is
  in scope. `technical-preferences.md` has no equivalent fields, so the legacy
  fallback cannot supply them.

  > **ABSENT DOES NOT MEAN `false`.** These keys have a reader —
  > this skill — and **no writer in the setup flow**: neither
  > `/setup-engine` nor `/start` emits a `platform:` block, and only `/settings`
  > sets them, when someone runs it, so on most CCGS projects both keys are
  > absent. Defaulting them to `false` would skip **Category 2 (Network and
  > Multiplayer Security) on every project, genuinely multiplayer ones
  > included** — a security category failing open on a value nothing sets.
  >
  > When either key is absent or empty: **do not assume single-player, and do not
  > skip Category 2.** Ask the user whether the game has multiplayer or online
  > features. If you cannot ask, run Category 2 anyway and mark it
  > `NOT ASSESSED — multiplayer scope unconfirmed (platform.multiplayer unset —
  > set it with /settings)`, which makes `CLEAR TO SHIP` unreachable per Phase 5.
  > While the scope is unconfirmed, rate severity as for a multiplayer game — an
  > open HIGH is then DO NOT SHIP — and say in the report that the rating assumed
  > multiplayer, as `security-engineer` does.
  > Over-scanning a single-player game costs a few minutes; under-scanning a
  > multiplayer one ships the category unrun.
  >
  > Set them explicitly with `/settings platform.multiplayer=true` (they are
  > project-wide, so `--local` is refused). Recording it in `project.yaml` is the
  > fix; this rule is the guard for until someone does.

---

## Phase 2: Spawn Security Engineer

Spawn `security-engineer` via `Agent` — the audit is its job, so do not run the
categories in this session instead. If it cannot be spawned, say why, run the
scan here, and let the report's **Audited by** line say so.

**Send this fixed brief template.** Fill only the `{…}` slots, from
`project.yaml` (else technical preferences), the code root resolved per
`.claude/docs/code-root-resolution.md`, and the Phase 3 text copied as written.
Add nothing else: no view on the game's type, no expected severity, no opinion
on any finding — a sentence of your own is where a pre-rating gets in.

```text
Run a security audit of this project for /security-audit.

Scope: {full | network | save | input | quick}
Engine: {engine.name} {engine.version}, language {engine.language}
platform.multiplayer: {true | false | unset}    platform.online: {true | false | unset}    Phase 1 answer: {multiplayer | single-player | not asked}
Code root: {the resolved code root, or "unresolved"}
Also scan: {assets/data/ and the config files that exist, or "none"}
Categories to run, with their checks and grep patterns for this engine:
{each Phase 3 category this scope runs, copied as written, with the table's row for this engine}
NOT SOURCEABLE on this engine: {categories, or "none"} — report each NOT ASSESSED; never call it reviewed, verified safe or passed
Skipped, with reason: {e.g. "Category 2 — platform.multiplayer and platform.online are false", or "none"}
Report: production/security/security-audit-{date}-{scope}.md — return the report as text; /security-audit writes the file after asking

Severity (rate every finding yourself, against this table only):
- CRITICAL: Remote code execution, data breach, or trivially-exploitable cheat that breaks multiplayer integrity
- HIGH: Save tampering that bypasses progression, credential exposure, or server-side authority bypass
- MEDIUM: Client-side cheat enablement, information disclosure, or input validation gap with limited impact
- LOW: Defence-in-depth improvement — hardening that reduces attack surface but no direct exploit exists
Nothing in this brief sets or suggests a severity. The game's type never lowers a rating: a single-player game is rated on the same table. The one adjustment is upward — when the game is multiplayer, or its scope is unconfirmed (unset and not answered), a HIGH counts as CRITICAL; say so where it applies.
Report each finding as SEC-NNN with category, file:line, description, attack scenario, remediation and effort, grouped by severity.
```

The template carries the rating rule, so there is nothing to restate: the
table already rates save tampering that bypasses progression HIGH, the agent
rates each finding against it, and Phase 5 applies the multiplayer rule to the
recommendation.

If the code root is unresolved, do not pass a guessed one: every category that
scans code is `NOT ASSESSED — code root unresolved`, and the report says so. An
empty code root is the insufficient-implementation case in Phase 5, and each
category that scans code reads `NOT ASSESSED — no source under <root>`, not zero
findings. Neither is ever reported clean.

The security-engineer runs the audit across 6 categories (see Phase 3). Collect their full findings before proceeding.

---

## Phase 3: Audit Categories

The security-engineer evaluates each of the following. Skip categories not
applicable to the project scope, and name each skipped category and why in the
Executive Summary (`Category 2 — skipped: platform.multiplayer and
platform.online are false`).

### Engine pattern sets — read this before any Category below

**Every pattern list in Categories 1–3 was written for Godot.** On a Unity or
Unreal project they match nothing, and this skill already states what a zero-hit
scan means: it renders the report clean, "the most dangerous possible failure for
a security audit". That warning was earned along the **version** axis
(`File.open` vs `FileAccess`) and the identical hole along the **engine** axis
shipped anyway. Use the table for `engine.name` resolved in Phase 1.

| Category | Godot | Unity | Unreal |
|---|---|---|---|
| 1 — Save / serialization | the Godot list below | **NOT SOURCEABLE** | **NOT SOURCEABLE** |
| 2 — Network / multiplayer | the Godot list below | `ServerRpc`, `ClientRpc`, `NetworkVariable`, `NetworkObject`, `NetworkManager`, `NetworkBehaviour`, `IsServer`, `IsOwner` | `UFUNCTION`, `Server`, `Client`, `NetMulticast`, `Replicated`, `DOREPLIFETIME`, `GetLifetimeReplicatedProps`, `HasAuthority` |
| 3 — Input | the Godot list below | `InputSystem`, `PlayerInput`, `ReadValue`, `InputValue` | `EnhancedInput`, `UInputAction`, `InputMappingContext`, `BindAction`, `FInputActionValue` |
| 4 — Data exposure | engine-agnostic — the list below applies to all three | | |
| 5, 6 | judgement and manifests, not greps — no engine set needed | | |

The Unity and Unreal names above are **sourced from this repo's pinned
references** (`docs/engine-reference/unity/modules/{networking,input}.md`,
`docs/engine-reference/unreal/modules/{networking,input}.md`), not from recall.
Verify them against the pin before use and add what the reference documents that
this table omits — it is a floor, not a complete set.

> **`NOT SOURCEABLE` is a verdict, not a gap to fill from memory.** Neither
> reference tree carries a serialization/save module, so the save-API names for
> Unity and Unreal cannot be confirmed here. **Do not write them from training
> data.** A confidently wrong pattern list is worse in this skill than in any
> other: it produces a scan that looks thorough, finds nothing, and reads as a
> pass. Where the table says NOT SOURCEABLE, that category is **`NOT ASSESSED`**
> for this engine — see Phase 5. To close it properly, add a save/serialization
> module, sourced like the others, to `docs/engine-reference/<engine>/modules/`;
> when one is there, take the category's pattern names from it, cite it in the
> report, and the category runs.


### Category 1: Save File and Serialization Security
- Are save files validated before loading? (no blind deserialization)
- Are save file paths constructed from user input? (path traversal risk)
- Are save files checksummed or signed? (tamper detection)
- Does the game trust numeric values from save files without bounds checking?
- Are there any eval() or dynamic code execution calls near save loading?

Grep patterns — **check the pinned engine reference before trusting this list**
(see the API-name warning below): `FileAccess`, `File.open`, `open(`, `load`,
`deserialize`, `parse`, `parse_string`, `from_json`, `read_file`, `get_var`,
`bytes_to_var` — check each for validation.

> **API names are version-specific and this list is a starting point, not a
> complete set.** `File.open` is **Godot 3.x**; Godot 4 renamed the class to
> `FileAccess` (`docs/engine-reference/godot/breaking-changes.md`). Before relying
> on these patterns, read `docs/engine-reference/<engine>/` for the version this
> project pins and add the names it documents. A grep for a class that no longer
> exists returns zero hits, and **zero hits in this category renders the report
> clean** — which is the most dangerous possible failure for a security audit.
> Searching only `File.open` against a Godot 4 project finds nothing and reports
> CLEAR TO SHIP on a codebase nobody checked. If you cannot confirm the correct
> names for the pinned version, say so in the report rather than presenting a
> zero-hit scan as a pass.

### Category 2: Network and Multiplayer Security (skip if single-player only)
- Is game state authoritative on the server, or does the client dictate outcomes?
- Are incoming network packets validated for size, type, and value range?
- Are player positions and state changes validated server-side?
- Is there rate limiting on any network calls?
- Are authentication tokens handled correctly (never sent in plaintext)?
- Does the game expose any debug endpoints in release builds?

Grep for: `recv`, `receive`, `PacketPeer`, `socket`, `MultiplayerPeer`,
`ENetMultiplayerPeer`, `NetworkedMultiplayerPeer`, `rpc`, `rpc_id`,
`@rpc` — check each call site for validation.

> Same version caveat as Category 1. `NetworkedMultiplayerPeer` is **Godot 3.x**;
> Godot 4 uses `ENetMultiplayerPeer`
> (`docs/engine-reference/godot/modules/networking.md`). The bare substring
> `MultiplayerPeer` matches both and is the safer probe.

### Category 3: Input Validation
- Are any player-supplied strings used in file paths? (path traversal)
- Are any player-supplied strings logged without sanitization? (log injection)
- Are numeric inputs (e.g., item quantities, character stats) bounds-checked before use?
- Are achievement/stat values checked before being written to any backend?

Grep for: `get_input`, `Input.get_`, `input_map`, user-facing text fields — check validation.

### Category 4: Data Exposure
- Are any API keys, credentials, or secrets hardcoded in the code root or `assets/`?
- Are debug symbols or verbose error messages included in release builds?
- Does the game log sensitive player data to disk or console?
- Are any internal file paths or system information exposed to players?

Grep case-insensitively in release-facing code for: `api[_-]?key`, `secret`,
`password`, `token`, `private[_-]?key`, `sk_live`, `BEGIN PRIVATE KEY`, `DEBUG`,
and the engine's print call (`print(` on Godot, `Debug.Log` on Unity, `UE_LOG`
on Unreal).

### Category 5: Cheat and Anti-Tamper Vectors
- Are gameplay-critical values stored only in memory, not in easily-editable files?
- Are any critical game progression flags (e.g., "has paid for DLC") validated server-side?
- Is there any protection against memory editing tools (Cheat Engine, etc.) for multiplayer?
- Are leaderboard/score submissions validated before acceptance?

Note: Client-side anti-cheat is largely unenforceable. Focus on server-side validation for anything competitive or monetised.

### Category 6: Dependency and Supply Chain
- Are any third-party plugins or libraries used? List them.
- Do any plugins have known CVEs in the version being used?
- Are plugin sources verified (official marketplace, reviewed repository)?

Glob for: `addons/`, `plugins/`, `third_party/`, `vendor/` — list all external dependencies.

---

## Phase 4: Classify Findings

For each finding, assign:

**Severity:**
| Level | Definition |
|-------|-----------|
| **CRITICAL** | Remote code execution, data breach, or trivially-exploitable cheat that breaks multiplayer integrity |
| **HIGH** | Save tampering that bypasses progression, credential exposure, or server-side authority bypass |
| **MEDIUM** | Client-side cheat enablement, information disclosure, or input validation gap with limited impact |
| **LOW** | Defence-in-depth improvement — hardening that reduces attack surface but no direct exploit exists |

**Status:** Open / Accepted Risk / Out of Scope

---

## Phase 5: Generate Report

```markdown
# Security Audit Report

**Date**: [date]
**Scope**: [full | network | save | input | quick]
**Engine**: [engine + version]
**Audited by**: [security-engineer via /security-audit | this session — security-engineer not spawned: reason]
**Files scanned**: [N source files, N config files]

---

## Executive Summary

| Severity | Count | Must Fix Before Release |
|----------|-------|------------------------|
| CRITICAL | [N] | Yes — all |
| HIGH | [N] | Yes — all |
| MEDIUM | [N] | Recommended |
| LOW | [N] | Optional |

**Release recommendation**: [NOT ASSESSED — INSUFFICIENT IMPLEMENTATION / CLEAR TO SHIP / FIX BEFORE SHIPPING / DO NOT SHIP]

Choose it by the open findings, first match wins:
- **DO NOT SHIP** — any open CRITICAL finding (in a multiplayer game, any open HIGH
  counts as CRITICAL)
- **FIX BEFORE SHIPPING** — open HIGH findings and no CRITICAL; the Polish → Release
  gate needs zero open HIGH (at `standard` and `full`)
- **NOT ASSESSED** — per the rule below, when the scan could not cover the surface.
  It ranks below both failure values — a known finding is more actionable than an
  unscanned category, and still has to be fixed — and above CLEAR TO SHIP
- **CLEAR TO SHIP** — no open CRITICAL or HIGH (MEDIUM and LOW may remain)

> **`NOT ASSESSED` is required when there was not enough implemented surface to
> audit**, or when the API names for the pinned engine version could not be
> confirmed — **in place of CLEAR TO SHIP, never of a failure value.** An open
> CRITICAL or HIGH still decides the recommendation (first match above): a run
> with an unscanned category and an open HIGH is FIX BEFORE SHIPPING, and names
> the unscanned category beside it. A zero-finding scan over two files of source is not a clean bill of
> health, and `CLEAR TO SHIP` must never be reachable by having nothing to look
> at. Name what was missing and which skill produces it.
>
> **The engine axis is part of that rule, not a separate one.** If
> the Phase 3 table marks a category `NOT SOURCEABLE` for this project's
> `engine.name`, that category is `NOT ASSESSED` — state it by name in the
> Executive Summary, and **`CLEAR TO SHIP` is unreachable for the run**. The
> category reads `NOT ASSESSED — <category> has no sourced pattern set for
> <engine>`; the release recommendation is still the first match above, so it is
> NOT ASSESSED only where the run would otherwise have been CLEAR TO SHIP. Never
> report the category as reviewed by other means: files it covers may still be
> read for another category, and a finding that read turns up is reported, but
> the category stays NOT ASSESSED — never "reviewed", "verified safe" or passed.
> A scan that could not look is not a scan that found nothing, and only the
> report can tell the reader which of the two happened.

---

## CRITICAL Findings

### SEC-001: [Title]
**Category**: [Save / Network / Input / Data / Cheat / Dependency]
**File**: `[path]` line [N]
**Description**: [What the vulnerability is]
**Attack scenario**: [How a malicious user would exploit it]
**Remediation**: [Specific code change or pattern to apply]
**Effort**: [Low / Medium / High]

[repeat per finding]

---

## HIGH Findings

[same format]

---

## MEDIUM Findings

[same format]

---

## LOW Findings

[same format]

---

## Accepted Risk

[Any findings explicitly accepted by the team with rationale]

---

## Dependency Inventory

| Plugin / Library | Version | Source | Known CVEs |
|-----------------|---------|--------|------------|
| [name] | [version] | [source] | [none / CVE-XXXX-NNNN] |

---

## Remediation Priority Order

1. [SEC-NNN] — [1-line description] — Est. effort: [Low/Medium/High]
2. ...

---

## Re-Audit Trigger

Run `/security-audit` again after remediating any CRITICAL or HIGH findings.
At `workflow: standard` and `full`, the Polish → Release gate requires this report with no open CRITICAL or HIGH items.
```

---

## Phase 6: Write Report

Present the report summary (executive summary + CRITICAL/HIGH findings only) in conversation.

Ask: "May I write the full security audit report to `production/security/security-audit-[date]-[scope].md`?"

Write only after approval.

---

## Phase 7: Gate Integration

This report is a required artifact for the **Polish → Release gate** at `workflow: standard` and `full`; the `minimal` gate drops it with everything but smoke and S1 bugs. Say which applies to this project, from the `workflow` resolved above.

After remediating findings, re-run: `/security-audit quick` to confirm CRITICAL/HIGH items are resolved before running `/gate-check release`.

Branch on the release recommendation, not on the finding counts alone:

If it is **DO NOT SHIP** (an open CRITICAL, or an open HIGH in a multiplayer game):
> "⛔ CRITICAL security findings must be resolved before any public release. Do not proceed to `/launch-checklist` until these are addressed."

If it is **FIX BEFORE SHIPPING** (open HIGH findings, no CRITICAL, single-player):
> At `workflow: standard`/`full`: "⚠️ [N] HIGH finding(s) are open. The Polish → Release gate's security audit item requires none — fix them and re-run `/security-audit quick` before `/gate-check release`."
>
> At `minimal`: "⚠️ [N] HIGH finding(s) are open — fix them and re-run `/security-audit quick` before you ship. The `minimal` release gate does not read this report; the open HIGH still makes the recommendation FIX BEFORE SHIPPING."

If it is **NOT ASSESSED**:
> "Security audit NOT ASSESSED — [each category not assessed, and why]. The report is
> written. [At `workflow: standard`/`full`:] `/gate-check release` will report its
> security item NOT ASSESSED until [the missing input] is supplied and the audit
> re-run. [At `minimal`:] The `minimal` release gate does not read this report,
> but those categories stay unscanned until [the missing input] is supplied."
>
> Name the missing input for each category: `engine.name`, the code root, the
> multiplayer scope (`/settings platform.multiplayer=…`), or — for a category the
> Phase 3 table marks NOT SOURCEABLE on this engine, the usual cause on Unity and
> Unreal — a save/serialization module in `docs/engine-reference/<engine>/modules/`
> (Phase 3), naming that category.

If it is **CLEAR TO SHIP**:
> "✅ No blocking security findings. Report written to `production/security/`. Include this path when running `/gate-check release`."

---

## Collaborative Protocol

- **Never assume a pattern is safe** — flag it and let the user decide
- **Accepted risk is a valid outcome** — some LOW findings are acceptable trade-offs for a solo team; document the decision
- **Multiplayer games have a higher bar** — any HIGH finding in a multiplayer context should be treated as CRITICAL
- **This is not a penetration test** — this audit covers common patterns; a real pentest by a human security professional is recommended before any competitive or monetised multiplayer launch
