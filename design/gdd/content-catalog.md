# Content Catalog

> **Status**: Complete
> **Author**: game-designer + lead-programmer
> **Last Updated**: 2026-05-24
> **Implements Pillar**: Foundation — enables all game-content-dependent systems

## Summary

The Content Catalog is BRAWLZONE's authoritative registry of all static game content — characters, maps, game modes, loadout items, shop entries, and quest definitions. It operates as a hybrid: a versioned baseline catalog bundled with the client for cold-start and offline-safe startup, with a remote overlay layer that can update approved fields after launch for live ops, balance tuning, availability windows, and seasonal rotations. Every piece of game content is assigned a stable canonical ID at catalog design time; downstream systems reference content exclusively by these IDs. The catalog defines the versioning contract, cache invalidation strategy, and fallback behavior for all catalog-dependent systems.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None (zero upstream dependencies)`

## Overview

The Content Catalog is the single source of truth for all game content definitions in BRAWLZONE. It does not simulate, it does not apply business logic — it defines. Every character the player can select, every map the match server can load, every loadout item that can appear in the Deck system, every mode config that the Game Mode System can run, every shop entry the store can display, and every quest definition the Quest system can assign originates as a record in the Content Catalog.

The catalog operates in two layers. The **bundled baseline** ships inside the client binary as versioned, structured data. It is authoritative at cold start and guarantees the game can boot and reach a playable state without a network connection. The **remote overlay** is fetched on startup (and periodically during the session) from a server-side catalog service. It can update a defined set of approved fields — balance values, availability windows, rotation schedules, display metadata — without requiring an app update. Remote overlay data does not override security-sensitive fields or authority-critical game rules; those live exclusively in the bundled baseline and are validated server-side.

Every catalog record carries a **stable canonical ID** — a string identifier assigned at record creation that never changes for the lifetime of the record. Downstream systems (Character, Deck/Loadout, Map/Arena, Game Mode, Inventory, Shop, Quest, Tutorial) reference content exclusively by canonical ID. Display names, descriptions, and other presentation metadata may change via remote overlay; canonical IDs never do.

## Player Fantasy

The Content Catalog has no direct player fantasy. Players never open a catalog, browse a registry, or interact with a canonical ID. The fantasy is **what reliable content definitions enable**: a player who sees a new character in the roster knows exactly what that character can do — because the same definition that populates the selection screen, drives the in-match ability system, and fills the shop entry is the same record. Nothing drifts. Nothing contradicts itself.

The catalog's design target is **invisible coherence**: when a new season's character rotation appears overnight, it works. When a limited-time map shows up in matchmaking, it loads. When a balance patch adjusts an ability's value, the change propagates consistently to every system that reads it. The player experiences this as a game that feels maintained and reliable — content appears when it's supposed to, disappears when it should, and behaves the way it's described. The underlying mechanism is never visible.

## Detailed Design

### Core Rules

1. **Record types** — The catalog defines six record types. Each has a fixed schema and its own allow-list of remotely overridable fields:
   - `character` — character definition (identity, stats, unlock classification)
   - `map` — arena/map definition (geometry config, mode compatibility, availability)
   - `game_mode` — game mode configuration (player counts, win conditions, time limits)
   - `loadout_item` — ability or modifier available in the Deck/Loadout system
   - `shop_offer` — offer, bundle, or listing in the shop
   - `quest` — quest/mission definition

2. **Canonical IDs** — Every record carries a stable canonical ID of the form `{type}:{slug}` (e.g., `character:striker`, `map:urban_arena`, `game_mode:1v1_duel`). The `id` is assigned at record creation and **never changes**. It is on no record type's allow-list and cannot be overridden remotely. Downstream systems store and reference content by canonical ID only — never by display name, array index, or derived key.

3. **Common record fields** — All record types share:
   - `id` — canonical ID (immutable, bundled-only)
   - `type` — record type string (immutable, bundled-only)
   - `catalog_version` — the bundled catalog version in which this record was last modified
   - `status` — `active` | `inactive` | `deprecated` (overridable to transition `active` ↔ `inactive`; `deprecated` is terminal and bundled-only)
   - `display_name` — player-visible name (remotely overridable)
   - `description` — player-visible description (remotely overridable)

4. **Hybrid source model** — The catalog operates in two layers:
   - **Bundled baseline**: ships inside the client binary. Every record has all fields defined. Authoritative at cold start and offline-safe by construction.
   - **Remote overlay**: fetched from the catalog service at startup and on a configurable refresh interval. A patch document: it may only update fields on the record type's allow-list. Fields not on the allow-list are unconditionally read from the bundled baseline.

5. **Allow-list** — Each record type declares an explicit allow-list of fields the remote overlay may update. The allow-list is itself bundled with the client and cannot be changed remotely — the set of remotely overridable fields can only expand with an app update, not a server push.

   | Record Type | Bundled-Only Fields (never overridable) | Remotely Overridable Fields |
   |-------------|----------------------------------------|----------------------------|
   | `character` | `id`, `type`, `unlock_type`, `sku_id`, base combat model, server-authoritative simulation values | `display_name`, `description`, portrait/art references, `availability`, `featured`, explicitly approved balance knobs (only fields named in the character allow-list) |
   | `map` | `id`, `type` | `display_name`, `description`, `availability`, `rotation_weight` |
   | `game_mode` | `id`, `type`, `player_count_min`, `player_count_max`, `win_condition` | `display_name`, `description`, `enabled`, `availability`, `rotation_weight` |
   | `loadout_item` | `id`, `type`, `item_class` | `display_name`, `description`, `availability`, approved modifier values |
   | `shop_offer` | `id`, `type`, `sku_id`, `unlock_type`, `grant_payload` | `display_name`, `description`, `availability`, `featured`, merchandising metadata |
   | `quest` | `id`, `type` | `display_name`, `description`, `availability`, `target_value` |

   For `shop_offer`: actual sell price, tax, and platform currency formatting are owned by the store/platform layer (RevenueCat, App Store, Google Play). The catalog owns offer identity, availability, grant payload, and merchandising metadata. The catalog does not set prices.

   For `character`: remote balance overrides are only permitted for fields explicitly named in the character allow-list. Any balance field not on the allow-list is treated as bundled-only regardless of the remote overlay payload.

6. **Versioning** — The bundled baseline carries a monotonically increasing integer `catalog_version`. Remote overlays carry:
   - `overlay_version` — monotonically increasing; the client only applies a remote overlay if its version exceeds the last-applied cached version
   - `min_catalog_version` — the minimum bundled catalog version required for this overlay to be valid; if the client's bundled version is below this value, the overlay is rejected and the client falls back to bundled-only

7. **Cache invalidation** — The client maintains a local cache of the last successfully applied remote overlay. The cache is invalidated when:
   - A new overlay is fetched with a higher `overlay_version`
   - The overlay's `min_catalog_version` exceeds the client's bundled `catalog_version` (overlay rejected)
   - An explicit cache-bust signal arrives (server push event or startup flag)

8. **Fallback behavior on remote fetch failure**:
   - Fetch fails, cached overlay present → apply cached overlay over bundled baseline; game is playable with potentially stale remote fields
   - Fetch fails, no cached overlay → use bundled baseline only; game is fully playable
   - Fetch returns a malformed or partial response → discard entirely; fall back to cached overlay or bundled baseline
   - Bundled baseline corrupted → unrecoverable install error; client must prompt reinstall

9. **Record status lifecycle**:
   - `active` — record is available for normal use by all downstream systems
   - `inactive` — record is not surfaced to downstream systems. Inactive records remain retrievable by canonical ID for existing entitlements and historical references, but they are not surfaced in selection, matchmaking, shop, or tutorial flows. Existing entitlements referencing an inactive record are preserved.
   - `deprecated` — record is retained for backward compatibility only; it will never return to `active`. All downstream references must treat deprecated records as permanently unavailable. Transitioning a record to `deprecated` is bundled-only.

10. **Downstream read contract** — Downstream systems query the catalog by canonical ID and receive a single merged record (bundled baseline values + applied overlay fields for allow-listed fields). Downstream systems have no visibility into which layer a field value came from. The catalog module is the sole authority on merging.

### Canonical Record Definitions

> This subsection is the project-wide ground truth for all catalog content. Every system GDD that references a character ID, ability ID, game mode ID, or Diamond IAP pack **must** use the identifiers defined here. Discrepancies in other GDDs are errors to be corrected against this subsection.

#### Character Records (`character:` type)

Eight characters with identical base combat stats. All strategic differentiation comes from Deck/Loadout composition.

| Canonical ID | Display Name | Archetype | Passive Name | Unlock Type | Coin Cost | Diamond Cost |
|-------------|-------------|-----------|-------------|------------|-----------|--------------|
| `character:vex` | Vex | Brawler (offensive) | Momentum | free | — | — |
| `character:zook` | Zook | Sniper (offensive) | Residue | free | — | — |
| `character:sera` | Sera | Support (defensive) | Long Shot | free | — | — |
| `character:fen` | Fen | Trickster (utility) | Mend Aura | earnable | 800 | — |
| `character:grim` | Grim | Tank (defensive) | Stone Skin | earnable | 600 | — |
| `character:dash` | Dash | Speedster (offensive) | Afterburn | earnable | 1,200 | — |
| `character:colt` | Colt | Trapper (utility) | Static Field | premium | — | 500 |
| `character:nyx` | Nyx | Controller (utility) | Opener | premium | — | 500 |

**Unlock rules:**
- `free` — granted to all accounts at first login; cannot be revoked
- `earnable` — purchasable with Coins via the Shop; also grantable as Battle Pass free-track rewards at Tiers 6 (Fen), 15 (Grim), and 24 (Dash)
- `premium` — purchasable with Diamonds only; also available in IAP character bundles

> **Migration note**: Earlier GDD drafts used the character names `Syla` and `Volt`. These are now `Dash` (`character:dash`) and `Colt` (`character:colt`) respectively. All GDDs must use the IDs in this table.

---

#### Loadout Item Records (`loadout_item:` type)

Eighteen abilities in three archetypes × six abilities each. The affinity character receives a +10% `effectMagnitude` bonus when the ability is equipped.

**Offensive (6):**

| Canonical ID | Display Name | Effect Summary | Cooldown | Affinity |
|-------------|-------------|----------------|----------|----------|
| `loadout_item:ability_burstsurge` | Burst Surge | Directional shockwave; 30 damage in cone | 8s | `character:vex` |
| `loadout_item:ability_ragepulse` | Rage Pulse | +30% attack damage for 4s | 11s | `character:vex` |
| `loadout_item:ability_flashstrike` | Flash Strike | Teleport to and strike target ≤5 LGU for 25 damage | 9s | `character:nyx` |
| `loadout_item:ability_grenadebarrage` | Grenade Barrage | 3 grenades in spread; 12 damage each on impact | 12s | `character:zook` |
| `loadout_item:ability_overload` | Overload | Next attack within 3s deals ×2 damage + 0.5s stun | 10s | `character:colt` |
| `loadout_item:ability_pindownshot` | Pin-Down Shot | 20 damage + roots target for 1s | 13s | `character:sera` |

**Defensive (6):**

| Canonical ID | Display Name | Effect Summary | Cooldown | Affinity |
|-------------|-------------|----------------|----------|----------|
| `loadout_item:ability_ironwall` | Iron Wall | Shield absorbing up to 30 damage for 3s; stationary | 10s | `character:grim` |
| `loadout_item:ability_thornbarrier` | Thorn Barrier | 2s barrier; melee attackers receive 10 reflect damage | 11s | `character:grim` |
| `loadout_item:ability_rollaway` | Roll Away | Rapid dodge roll; 0.5s invulnerability frames | 7s | `character:dash` |
| `loadout_item:ability_phasestep` | Phase Step | Instant teleport 4 LGU in facing direction; no i-frames | 8s | `character:dash` |
| `loadout_item:ability_healfield` | Heal Field | +20 HP immediately; +5 HP/s for 3s | 15s | `character:fen` |
| `loadout_item:ability_smokecover` | Smoke Cover | 3-LGU smoke cloud for 4s; blocks auto-attack targeting | 14s | `character:nyx` |

**Utility (6):**

| Canonical ID | Display Name | Effect Summary | Cooldown | Affinity |
|-------------|-------------|----------------|----------|----------|
| `loadout_item:ability_slowfield` | Slow Field | 3-LGU zone; 40% speed reduction for enemies inside for 4s | 12s | `character:zook` |
| `loadout_item:ability_trapmine` | Trap Mine | Invisible mine; 15 damage + knockback on first trigger | 11s | `character:zook` |
| `loadout_item:ability_disruptpulse` | Disrupt Pulse | Silence all enemy abilities within 4 LGU for 2s | 14s | `character:colt` |
| `loadout_item:ability_pullgravity` | Gravity Pull | Pull target within 6 LGU exactly 3 LGU toward caster | 10s | `character:colt` |
| `loadout_item:ability_debuffstrike` | Debuff Strike | Next attack applies −20% attack speed to target for 4s | 9s | `character:fen` |
| `loadout_item:ability_rallycry` | Rally Cry | 3v3: nearest ally +10 HP + 10% damage for 5s. 1v1/FFA: self +5 HP + 10% damage for 3s | 13s | `character:fen` |

**Ability unlock tiers** (by lifetime Account XP):

| Tier | Ability IDs | Account XP Threshold |
|------|------------|---------------------|
| Starter (always available) | `ability_burstsurge`, `ability_rollaway`, `ability_ironwall`, `ability_slowfield`, `ability_pindownshot`, `ability_healfield` | 0 (account creation) |
| Tier 1 | `ability_overload`, `ability_phasestep`, `ability_thornbarrier`, `ability_grenadebarrage`, `ability_disruptpulse`, `ability_debuffstrike` | 500 lifetime XP |
| Tier 2 | `ability_flashstrike`, `ability_ragepulse`, `ability_smokecover`, `ability_trapmine`, `ability_pullgravity`, `ability_rallycry` | 1,500 lifetime XP |

---

#### Game Mode Records (`game_mode:` type)

| Canonical ID | Display Name | Team Format | Max Players | Max Duration | Account Level Gate |
|-------------|-------------|------------|-------------|-------------|-------------------|
| `game_mode:duel_1v1` | 1v1 Duel | 1v1 | 2 | 180s | 1 |
| `game_mode:squad_3v3` | 3v3 Squad Brawl | 3v3 | 6 | 300s | 3 |
| `game_mode:ffa_8` | 8-Player FFA | FFA | 8 | 480s | 8 |

All modes share a hard outer cap of 600s (Match Server absolute timeout). Per-mode `maxDurationSec` must be read by Session Manager when building `MatchConfig`.

> **Mode ID shorthand**: Systems that reference modes by string key (matchmaking-engine, match-flow, analytics, remote-config) use the slug portion only: `"duel_1v1"`, `"squad_3v3"`, `"ffa_8"`. The full canonical ID with type prefix (`game_mode:duel_1v1`) is used only within the Content Catalog record-lookup API.

---

#### Diamond IAP Pack Records (`shop_offer:` type, `grant_type: diamonds`)

| Canonical ID | Display Name | Diamonds Granted | Value per $ | Note |
|-------------|-------------|-----------------|-------------|------|
| `shop_offer:diamonds_starter` | Starter Pack | 80 | 80.8/$ | Entry price point |
| `shop_offer:diamonds_small` | Small Pack | 200 | ~100/$ | ~10% bonus vs. Starter |
| `shop_offer:diamonds_medium` | Medium Pack | 500 | ~100/$ | Visible value step |
| `shop_offer:diamonds_large` | Large Pack | 1,100 | ~117/$ | Value label candidate |
| `shop_offer:diamonds_xlarge` | XL Pack | 2,400 | ~120/$ | |
| `shop_offer:diamonds_mega` | Mega Pack | 6,500 | ~130/$ | Best Value badge |

> Actual USD prices, tax, and platform currency formatting are owned by the store/platform layer (RevenueCat, App Store, Google Play). Dollar equivalents above are design-intent anchors only.

---

#### Skin Tier Pricing Reference

| Tier | Diamond Cost | Visual Scope |
|------|-------------|-------------|
| Common | 100 | Color swap, minor detail changes |
| Rare | 250 | Alternate design, new color palette |
| Epic | 500 | Full redesign + unique VFX |
| Legendary | 1,000 | Animated + unique SFX + unique spawn animation |

Skin `shop_offer` records each declare a tier; the Diamond cost is derived from this table, not stored per-record.

---

#### Canonical Pricing Summary

| Item | Currency | Canonical Price |
|------|---------|----------------|
| Fen character unlock | Coins | 800 |
| Grim character unlock | Coins | 600 |
| Dash character unlock | Coins | 1,200 |
| Colt character (premium) | Diamonds | 500 |
| Nyx character (premium) | Diamonds | 500 |
| Battle Pass (seasonal) | Diamonds | 950 |
| Play Pass subscription | USD via IAP | Platform pricing |

---

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| **Initializing** | App cold start | Bundled catalog loaded | Load bundled baseline into memory; downstream systems blocked until complete |
| **Ready — bundled only** | Bundled catalog loaded; remote fetch not yet complete or failed with no cache | Remote fetch success → Ready (merged); remote fetch failure with cache → Ready (cached) | Downstream reads return bundled values only; remote fetch in-flight |
| **Fetching overlay** | Startup remote fetch initiated; periodic refresh triggered | Fetch completes success or failure | Catalog reads continue to serve current merged state during fetch; no read blocking |
| **Ready — merged** | Remote overlay successfully applied | Periodic refresh triggered → Fetching overlay | Downstream systems read merged catalog (bundled + overlay); normal operating state |
| **Ready — cached overlay** | Remote fetch failed; cached overlay present | Periodic refresh succeeds → Ready (merged) | Downstream reads use cached overlay over bundled baseline; background re-attempt may be scheduled |
| **Overlay rejected** | Remote overlay `min_catalog_version` > client's bundled `catalog_version` | App update → catalog re-initializes | Overlay cannot be applied; use bundled only; client surfaces an app-update prompt if game content depends on the rejected overlay |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Character System | Catalog → Character | Queries catalog by `character:{id}`; receives merged record. Character definitions, stat profiles, and unlock classification originate here. |
| Map/Arena System | Catalog → Map | Queries catalog by `map:{id}`; receives merged record. Map availability and rotation weight are remotely overridable. |
| Game Mode System | Catalog → Game Mode | Queries catalog by `game_mode:{id}`; `enabled` field controls which modes are active. Win conditions and player counts are bundled-only. |
| Deck/Loadout System | Catalog → Deck | Reads all active `loadout_item` records to build the pool of available items. Loadout slot rules and item definitions originate in the catalog. |
| Inventory/Entitlements | Catalog → Inventory | Inventory validates owned items against catalog records. Entitlements on `inactive` records are preserved but not surfaced. |
| Shop & Offers Screen | Catalog → Shop | Shop reads `shop_offer` records for offer identity, availability, grant payload, and merchandising metadata. Actual pricing, tax, and currency formatting are owned by the platform store layer. |
| Quest/Mission System | Catalog → Quest | Quest system reads `quest` records to determine available missions, target values, and display text. |
| Tutorial/Onboarding | Catalog → Tutorial | Tutorial reads catalog to determine which content to reference during onboarding flows. Content Catalog availability gates which tutorial steps can be shown. |
| Remote Config | Remote Config → Catalog | Remote Config may provide timing signals (e.g., force-refresh catalog) and feature flags affecting fetch behavior. Remote Config does not modify catalog record fields directly. |
| Match Server | Catalog ↔ Server | The server maintains its own authoritative catalog snapshot for any values it trusts during simulation. The client catalog is never trusted for authority-critical decisions. |

## Formulas

The Content Catalog owns no game-balance or economy formulas. The only derived values this system defines are operational thresholds:

### Overlay Applicability Check

```
overlay_applicable = (overlay.overlay_version > cached_overlay_version)
                   AND (client_catalog_version >= overlay.min_catalog_version)
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Overlay version | `overlay.overlay_version` | int | 1–∞ | Monotonically increasing version of the remote overlay document |
| Cached overlay version | `cached_overlay_version` | int | 0–∞ | Version of the last successfully applied overlay; 0 if no overlay has ever been applied |
| Client catalog version | `client_catalog_version` | int | 1–∞ | Version of the bundled baseline shipped with the client binary |
| Minimum catalog version | `overlay.min_catalog_version` | int | 1–∞ | Minimum bundled version required for this overlay to be valid |
| Overlay applicable | `overlay_applicable` | bool | true/false | True if the overlay should be applied; false if it should be rejected or ignored |

**Output**: If `overlay_applicable` is `true`, the overlay is merged over the bundled baseline and the cached overlay version is updated. If `false`: if `overlay.overlay_version <= cached_overlay_version`, the overlay is stale (no-op). If `client_catalog_version < overlay.min_catalog_version`, the overlay is rejected and an app-update prompt may be shown.

**Example**: Client has `client_catalog_version = 4`, `cached_overlay_version = 7`. Remote overlay arrives with `overlay_version = 9`, `min_catalog_version = 3`. Since 9 > 7 and 4 ≥ 3 → `overlay_applicable = true`. Overlay is applied and cache updated to version 9.

*No other formulas are owned by Content Catalog. Downstream systems (Character, Game Mode, Deck/Loadout) define their own game-logic formulas using catalog record field values as inputs.*

## Edge Cases

1. **Remote overlay references a canonical ID not present in the bundled baseline** — The unknown record is silently ignored; valid records in the same overlay document still apply. The unknown entry is logged once per overlay document, not per downstream read.

2. **Remote overlay attempts to update a bundled-only field** — The field update is discarded per record; the merged record serves the bundled value for that field. The violation is logged once per overlay document, not per downstream read. No error is surfaced to the player.

3. **Two remote overlay fetches arrive simultaneously (race condition)** — The overlay with the higher `overlay_version` wins. If both overlays arrive with the same `overlay_version`, the client applies the one with the later fetch timestamp; if timestamps are equal, the currently cached version is kept. In-flight fetches are not cancelled; the applicability check at merge time resolves which result is used.

4. **Client's bundled `catalog_version` is newer than the remote overlay's `min_catalog_version`** — Normal operation. The overlay is applicable as long as its `overlay_version` is greater than the cached version.

5. **Client's bundled `catalog_version` is older than the remote overlay's `min_catalog_version`** — Overlay rejected. Client falls back to bundled-only. If the rejected overlay contains availability or rotation changes that affect the game session, the client surfaces an app-update prompt. The game remains playable with the bundled baseline.

6. **Catalog fetch returns HTTP 200 but with an empty or null overlay document** — Treated as a no-op: the cached overlay (if any) remains applied, the cached version is not updated, and no error is surfaced. Logged for diagnostics.

7. **A downstream system requests a canonical ID that does not exist in the catalog** — The catalog returns a null/not-found result. The requesting system is responsible for handling this gracefully (treating it as an unavailable or unknown item). The catalog does not throw on a miss.

8. **A record's `status` is changed from `active` to `inactive` via remote overlay mid-session** — The `inactive` status applies immediately to new catalog reads and future entry points (selection screen, matchmaking rotation, shop, tutorial). Already-instantiated in-session objects — such as a character already selected and loaded for an in-progress match — may continue operating until the current session or match ends.

9. **A `deprecated` transition is attempted via remote overlay** — Rejected. Transitioning a record to `deprecated` is bundled-only. The attempt is logged once per overlay document; the record's status remains unchanged.

10. **Bundled baseline contains records with duplicate canonical IDs** — A build-time packaging failure. Build-time validation must reject a catalog package that contains duplicate canonical IDs; this must not reach a production client. As a defensive runtime fallback only, if duplicates are detected at init time the catalog logs a critical error and retains the first occurrence — but this state is not considered recoverable in production.

## Dependencies

### Upstream Dependencies (Content Catalog depends on these)

| System | Type | Dependency |
|--------|------|------------|
| **Network Layer** | Platform capability | Required to fetch remote overlay at startup and on refresh intervals; supports fallback, retry, and malformed-response handling |
| **Local Storage** | Platform capability | Caches the last successfully applied overlay across sessions; partial, rejected, or malformed overlay data is never written to cache |
| **Client Build Pipeline** | Build-time process | Packages the bundled baseline and validates schema conformance, duplicate canonical IDs, and allow-list compliance before build; a package that fails any of these checks must not be released |

### Downstream Dependents (these depend on Content Catalog)

| System | Dependency on Catalog |
|--------|-----------------------|
| **Character System** | Reads `character` records for all character definitions and unlock classifications |
| **Map/Arena System** | Reads `map` records for all arena definitions and availability |
| **Game Mode System** | Reads `game_mode` records for mode configs; `enabled` field gates which modes are active |
| **Deck/Loadout System** | Reads `loadout_item` records to build the available item pool |
| **Inventory/Entitlements** | Cross-references owned entitlements against catalog records; uses `status` to determine whether items are surfaced, selectable, or grantable in the current context |
| **Shop & Offers Screen** | Reads `shop_offer` records for offer identity, availability, and merchandising metadata |
| **Quest/Mission System** | Reads `quest` records for mission definitions, target values, and display text |
| **Tutorial/Onboarding** | Reads catalog availability to determine which onboarding steps and content to surface |
| **Remote Config** | May trigger catalog fetch timing or cache-bust behavior, but never edits catalog fields, record schemas, or catalog versioning rules directly |

### Bidirectionality Note

Every downstream dependent listed above will reference Content Catalog as an upstream dependency in its own GDD's Dependencies section.

## Tuning Knobs

| Knob | Symbol | Default | Safe Range | Effect |
|------|--------|---------|------------|--------|
| **Overlay refresh interval** | `CATALOG_REFRESH_INTERVAL_S` | 300 s | 60–3600 s | How often the client re-fetches the remote overlay during an active session. Controls **periodic background refresh only** — startup fetch behavior is governed by `CATALOG_FORCE_REFRESH_ON_START`. Lower values keep content more current at the cost of more frequent network calls. Values below 60 s risk unnecessary traffic on mobile networks. |
| **Overlay fetch timeout** | `CATALOG_FETCH_TIMEOUT_MS` | 5000 ms | 2000–15000 ms | How long the client waits for a remote overlay response before treating the fetch as failed and falling back. Too low causes false fallbacks on slow connections; too high delays cold start on unreachable catalog service. |
| **Overlay fetch retry count** | `CATALOG_FETCH_MAX_RETRIES` | 2 | 0–4 | Number of retry attempts after a failed overlay fetch before the client gives up and uses the cached or bundled baseline. Higher values improve resilience on intermittent connections at the cost of extended startup time. |
| **Overlay fetch retry backoff base** | `CATALOG_FETCH_BACKOFF_BASE_MS` | 1000 ms | 500–5000 ms | Delay before the first retry; subsequent retries multiply this value. Too low risks hammering the catalog service under degraded network conditions. |
| **Force-refresh on session start** | `CATALOG_FORCE_REFRESH_ON_START` | true | true/false | If `true`, always attempts a fresh overlay fetch on app launch, even when a valid cached overlay exists. If `false`, the client serves the cached overlay immediately on launch and performs a background refresh according to the refresh interval. Setting to `true` ensures players receive current availability and rotation data at the start of every session. |

**Fetch deduplication rule**: Fetch requests for the same overlay version must be deduplicated per client session. Only one in-flight fetch for a given `overlay_version` may exist at any time. Concurrent triggers (e.g., a startup fetch and a forced refresh arriving simultaneously) must be collapsed into a single request; the result is shared by all waiting callers.

## Visual/Audio Requirements

Content Catalog has no owned visual or audio assets. All catalog data is consumed by downstream systems that own their own visual presentation. No VFX, animations, sounds, or UI components are defined by this system.

## UI Requirements

Content Catalog has no player-facing UI. It is queried by UI systems (Shop, Character Select, Main Menu) but does not define any screens or components. If a catalog fetch causes a delay at startup (with `CATALOG_FORCE_REFRESH_ON_START = true`), the loading state is owned by the startup/home flow UI, not by Content Catalog.

## Cross-References

- `design/gdd/systems-index.md` — Content Catalog row (Block 1, MVP Foundation layer)
- `design/gdd/authentication.md` — Authentication is a peer Foundation system; no direct dependency, but both must be initialized before any downstream system can operate
- `design/gdd/character-system.md` — reads `character` records
- `design/gdd/map-arena.md` — reads `map` records
- `design/gdd/game-mode.md` — reads `game_mode` records; `enabled` field gates active modes
- `design/gdd/deck-loadout.md` — reads `loadout_item` records
- `design/gdd/inventory-entitlements.md` — validates entitlements against catalog `status`
- `design/gdd/shop-offers.md` — reads `shop_offer` records for offer identity and availability
- `design/gdd/quest-mission.md` — reads `quest` records
- `design/gdd/tutorial-onboarding.md` — reads catalog availability to gate onboarding steps
- `design/gdd/remote-config.md` — may trigger catalog fetch timing; does not own catalog fields

## Acceptance Criteria

**Cold Start and Fallback**

- [ ] On a clean install with no cached overlay, the game boots to a playable state using the bundled baseline with no network connection required
- [ ] On launch with `CATALOG_FORCE_REFRESH_ON_START = true`, the client attempts a startup overlay fetch before surfacing the home screen; if the fetch succeeds, the merged catalog is used
- [ ] On launch with `CATALOG_FORCE_REFRESH_ON_START = false`, the client serves the cached overlay immediately on launch and initiates a background refresh without blocking the home screen
- [ ] If the overlay fetch fails at startup and a cached overlay exists, the cached overlay is applied over the bundled baseline and the game is playable
- [ ] If the overlay fetch fails at startup with no cached overlay, the bundled baseline is used and the game is playable

**Overlay Application**

- [ ] A remote overlay with a higher `overlay_version` than the cached version is applied; the cached version is updated
- [ ] A remote overlay with an equal or lower `overlay_version` than the cached version is not applied (no-op)
- [ ] A remote overlay whose `min_catalog_version` exceeds the client's bundled `catalog_version` is rejected; the client falls back to bundled-only and may surface an app-update prompt
- [ ] A remote overlay field update targeting a bundled-only field is silently discarded; the bundled value is served for that field
- [ ] If two valid overlays share the same `overlay_version`, the later fetch timestamp wins; if timestamps match, the currently cached overlay remains in place

**Record Contract**

- [ ] Every record returned by the catalog has a stable canonical ID that matches the `{type}:{slug}` format
- [ ] A catalog lookup by canonical ID for an `active` record returns the merged record (bundled + overlay)
- [ ] A catalog lookup by canonical ID for an `inactive` record returns the record for entitlement/history checks, but it is not selectable, grantable, or surfaced in gameplay, shop, or tutorial flows
- [ ] A catalog lookup for a canonical ID that does not exist returns a null/not-found result without throwing
- [ ] An attempt to transition a record to `deprecated` via remote overlay has no effect; the record's status is unchanged

**Versioning and Build**

- [ ] The bundled catalog build fails if any two records share the same canonical ID
- [ ] The bundled catalog build fails if any record field violates the allow-list schema
- [ ] A fetched overlay with a malformed or partial payload is discarded as a whole; the cached overlay or bundled baseline is used instead, with no partial merge applied
- [ ] The fetch deduplication rule is enforced: only one in-flight fetch per `overlay_version` exists at any time; concurrent triggers share the same response

**Periodic Refresh**

- [ ] After the refresh interval elapses during an active session, the client initiates a background overlay fetch without blocking the UI or ongoing match
- [ ] If the background refresh succeeds with a higher `overlay_version`, the merged in-memory catalog and the cached overlay state are both updated; downstream reads after the refresh receive the new values

## Open Questions

1. **Remote catalog service infrastructure** — The remote overlay is fetched from a "catalog service." This could be a dedicated server endpoint, Supabase edge functions, a CDN-hosted JSON file, or Remote Config's backend. Needs an ADR before implementation begins, because the hosting choice determines cache headers, invalidation model, latency profile, rate limits, rollout workflow, and operational ownership.

2. **Allow-list evolution** — The character balance allow-list mentions "explicitly approved balance knobs" but does not enumerate them. Before the Character System GDD is authored, the specific remotely tunable character fields must be defined and locked.

3. **Overlay format** — The overlay document format must be explicitly chosen as one of: full replacement, sparse field patch, or structured diff. This decision defines merge semantics, payload size, validation rules, and what counts as a malformed or partial payload.

4. **Build-time validation tooling** — The bundled baseline requires build-time validation for duplicate IDs, schema conformance, and allow-list compliance. Who owns this tooling and where it runs in the pipeline (local pre-commit, CI, or both) is not yet defined.

5. **Catalog record schema versioning** — Record schemas may need to evolve (new fields added). The current design does not specify how schema migrations are handled when the bundled baseline introduces new fields that an older cached overlay does not include. Preferred direction: additive schema evolution only, with safe defaults for new fields and backward-compatible readers.
