# Cross-GDD Review Report

> **Date**: 2026-05-29
> **GDDs Reviewed**: 45 system GDDs + game-concept.md + game-pillars.md + systems-index.md
> **Scope**: Full re-review following the 2026-05-28 FAIL verdict and the 18-GDD revision batch
> **Entity Registry**: Empty at time of review — consistency checks relied on full GDD reads + targeted token sweeps
> **Verdict**: ✅ PASS — all 10 prior blocking issues resolved. Residual ID/mode-key drift found in unrevised GDDs was fixed inline during this review. Remaining items are non-blocking design/scenario warnings.

---

## 1. Resolution of the 2026-05-28 Blocking Issues

All ten blocking issues from the prior review are verified resolved:

| ID | Issue | Resolution Verified |
|----|-------|---------------------|
| C-01 | Character roster identity crisis | `content-catalog.md §Character Records` is the single source of truth (Vex/Zook/Sera free, Fen/Grim/Dash earnable, Colt/Nyx premium). Syla→Dash, Volt→Colt migration complete. |
| C-02 | Ability pool identity crisis | Single canonical 18-ability pool in content-catalog; `ability-skill.md` points to it; UPPER_SNAKE registry deprecated. |
| C-03 | Match duration override | Session Manager reads per-mode `maxDurationSec`; 600s is the Match Server outer cap only. |
| C-04 | Coin formula dual ownership | Reward System owns match Coin calculation; Currency System handles transactions only. |
| C-05 | Diamond IAP pack catalog | All references aligned to the 6-pack `shop_offer:` table. |
| C-06 | MMR trigger/ordering AC | AC-MMR-20 deleted; Match Flow owns the synchronous RPC; timeout → mmrDelta=0, fan-out proceeds. |
| C-07 | Free-character AC trilemma | Canonical free set `{character:vex, character:zook, character:sera}` across player-profile, inventory-entitlements, character-system. |
| D-01 | One-shot TTK (P1 violation) | POWER_SLAM (220 dmg) removed; canonical abilities are 12–30 damage. |
| S-01 | First-win triple ownership | Single authority: Reward System `first_win_claimed_date`; XP System reads it, maintains no independent flag. |
| S-02 | match_results_payload schema | `xpAtLevelStart`, `xpToNextLevel`, `timeAliveSec`, `matchStartedAt`, `damageDealt`, `abilityUseCounts`, `survived` present in fan-out contracts. |
| S-03 | IAP bundle → character-select chain | Bundle entitlements use canonical `character:colt` / `character:nyx`. |
| S-04 | Match Flow reconnect contract | `match-flow.md §3.7` defines `onPlayerReconnected(playerId): void` (wired in Vertical Slice). |

---

## 2. Residual Drift Found and Fixed in This Review

The 18-GDD revision batch normalized the core gameplay/economy GDDs but left
stale references in GDDs that were **not** in that batch. These contradicted the
now-canonical `content-catalog.md` and would have caused silent string-key lookup
misses at implementation time. All were fixed inline under standing authorization.

### 2.1 Character ID format (canonical: `character:{slug}`)
Normalized deprecated `char_{slug}` and double-prefixed `character:char_{slug}`
forms to canonical `character:{slug}` in:
- `inventory-entitlements.md` (entitlement rows, ACs, bundle map; removed a stale "consistency action item" note that referenced the old roster)
- `purchase-fulfillment.md` (character bundle grants, ACs)
- `cosmetic-skin.md` (equippedSkins map keys, schema example)
- `battle-pass.md` (RewardItem example)
- `bot-ai.md` (AC examples)
- `quest-mission.md` (PLAY_MATCHES_CHARACTER param)
- `xp-progression.md` (character_progress AC)
- `match-server.md` (PassiveState comment block + AC-MS-12)
- `combat-system.md` (ranged attack-type table: Syla→Dash, Volt→Colt)

### 2.2 Mode-ID vocabulary (canonical: `duel_1v1` / `squad_3v3` / `ffa_8`)
`content-catalog.md §166–176` mandates the slug keys for all string-keyed mode
references. Normalized legacy `duel` / `squad_brawl` / `ffa` (and `squad`) in:
- `reward-system.md` (BASE_COINS keys, ACs)
- `battle-pass.md` (BASE_BPXP keys, formula examples, ACs)
- `xp-progression.md` (BASE_XP table, formula variable tables, examples)
- `session-manager.md` (GameMode type, bot-fill tables, ACs)
- `match-server.md`, `disconnect-handler.md`, `moderation-reporting.md` (gameMode unions)
- `match-results.md`, `character-deck-select.md`, `map-arena.md` (payload/compat/ACs)
- `matchmaking-engine.md`, `realtime-transport.md` (request/event mode unions; `squad`→`squad_3v3`)
- `quest-mission.md` (WIN_MATCHES_MODE param)
- `push-notification.md` (`ffa_8p`→`ffa_8`)

### 2.3 Value & naming alignment
- `remote-config.md`: `matchmaking.maxSkillSpreadMMR` default `200`→`300` (matches matchmaking-engine + mmr-ranked).
- `remote-config.md` + `iap-system.md`: replaced fictional `brawler_kai` example IDs with canonical character IDs.

---

## 3. Carried-Forward Warnings (Non-Blocking)

These were warnings in the 2026-05-28 review and remain advisory. None block
architecture. They are design-judgment or playtest-gated items, not contradictions.

| # | Item | Recommendation |
|---|------|----------------|
| W-D-01 | Coin endgame surplus: faucets outnumber sinks once earnable characters are unlocked | Tracked in game-pillars.md; future skin-fragment conversion valve planned |
| W-D-02 | FFA cognitive load (5–6 active in-combat systems on touchscreen) | Explicit playtest gate for FFA before Alpha sign-off |
| W-D-03 | "Options ≠ Power" tension: loadout breadth as a soft strategic edge for higher-level players | Monitor in playtest; documented guardrail in game-pillars.md |
| W-D-04 | Battle Pass completion for low-win-rate Duel players relies on quest BPXP buffer | quest→BP `quest_completed_bpxp` signal now emitted; verify pacing in playtest |
| W-D-05 | Play Pass earn-multiplier fragility if a Coin-purchasable ability slot is ever added | Documented as an explicit F2P guardrail |
| S-W-03 | Multi-source wallet-cap truncation ordering undefined | Define a deterministic grant ordering before Currency System implementation |

---

## 4. Verdict: ✅ PASS

No blocking consistency, design-theory, or cross-system scenario issues remain.
The canonical character roster (`content-catalog.md §Character Records`), the
18-ability pool, the three mode IDs (`duel_1v1`/`squad_3v3`/`ffa_8`), economy
ownership, the match-results contract, and the MMR trigger model are all internally
consistent across the corpus. Architecture may begin.

The carried-forward warnings in §3 should be tracked through playtest and the
Currency System implementation but do not gate `/create-architecture`.

### Recommended next steps
1. `/gate-check systems-design` — validate the Systems Design phase gate (verdict now PASS).
2. `/create-architecture` — begin architecture on the now-consistent GDD set.
3. (Optional) `/consistency-check` — populate the entity registry so future reviews can grep-first instead of full-read.
