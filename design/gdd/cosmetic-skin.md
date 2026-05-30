# Cosmetic / Skin System — Game Design Document

> **System**: Cosmetic / Skin System
> **Priority**: Alpha
> **Layer**: Presentation
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

---

## Table of Contents

1. [Overview](#1-overview)
2. [Player Fantasy](#2-player-fantasy)
3. [Detailed Rules](#3-detailed-rules)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

The Cosmetic / Skin System is the complete owner of how characters look and sound during a match, beyond their default appearance. It manages a catalog of skins organized into four tiers (Common, Rare, Epic, Legendary), each tier escalating in visual and audio scope from a simple color swap to a fully animated, voiced, and uniquely sound-designed character experience. Skins are purely cosmetic — they carry zero mechanical effect on any gameplay stat — and are associated one-to-one with a character. A player equips at most one skin per character at a time; the default skin is always available as a fallback and requires no ownership record. The system integrates with the Content Catalog as the authoritative registry of what skins exist, the Inventory / Entitlements system as the record of what a player owns, the Player Profile to persist and serve the `equippedSkins` map, the Currency System for in-shop purchases, the IAP System for bundle fulfillment, and the Battle Pass system for reward delivery. Asset delivery is handled via Expo asset bundles that are lazy-loaded on demand and cached locally so that players are never blocked from entering a match while a skin loads. A hard fairness constraint governs every skin at every tier: no skin may confer a competitive information advantage over the default skin.

---

## 2. Player Fantasy

### Self-Expression Through Appearance

A skin is the player's visual signature. When every character in BRAWLZONE starts from the same stat baseline, a skin is the most personal statement a player can make: "This is how I show up." The player who unlocks a Legendary Nyx skin is not buying power — they are buying an identity. Every match they enter announces something about who they are and how much they care.

### The Pride of a Rare Skin

Cosmetics derive a significant portion of their emotional value from visibility. A player who earns or purchases an Epic or Legendary skin wants to be seen. Pre-match character select screens display every player's chosen skin to all participants — the moment of recognition from opponents who notice a rare skin is a designed social reward. Wanting that recognition is a legitimate and healthy motivation to keep playing, to reach the next Battle Pass tier, or to return for a limited-time event.

### Personal Investment Across Time

Common and Rare skins give every player an affordable entry point to personalization. Epic and Legendary skins create aspirational goals that players work toward. The result is a skin collection that grows with the player: a new account has a handful of color swaps; a veteran's roster of Epics and Legendaries is a visible record of their investment in the game. The equip screen — browsing owned skins for a character before a match — should feel like opening a display case, not navigating a menu.

### The Default Skin Is Not a Punishment

The default skin is a first-class visual: clean, readable, and complete. A player using the default skin should never feel underdressed. Cosmetics must elevate, not shame. This has a functional corollary: the fairness constraint (Section 3.10) guarantees that a player in a default skin is never disadvantaged in terms of visual readability compared to a player in any paid skin.

---

## 3. Detailed Rules

### 3.1 Skin Tier Definitions

Every skin in BRAWLZONE belongs to exactly one of four tiers. Tier determines visual and audio scope, asset complexity budget, and pricing range. A skin's tier is immutable once assigned; it is set in the Content Catalog at authoring time and cannot be changed without a new catalog version.

#### Common Tier

**Scope**: Color swap only. The character's model, silhouette, proportions, and animations are identical to the default. Only the color palette (materials, textures) is modified. No new VFX. No new SFX. No new animations.

**Visual requirements**:
- Saturation and contrast of the new palette must pass fairness review (Section 3.10).
- Silhouette must be pixel-for-pixel identical to the default at all LOD levels.

**Audio requirements**: None — Common skins use the character's default sound set entirely.

**Example**: Vex "Crimson Strike" — Vex's outfit recolored in deep red and black.

#### Rare Tier

**Scope**: Alternate design. The character's model may be reskinned with new textures and a different thematic aesthetic (e.g., different outfit, different surface materials). The character's silhouette and bounding volumes must remain identical to the default. Particle effects on abilities may be recolored (hue-shifted) but not reshaped or rescaled. No new SFX. Idle and movement animations are the default set.

**Visual requirements**:
- Silhouette and hitbox-visible bounding volume: identical to default.
- Ability VFX may be recolored; particle counts and durations must match the default exactly.
- Unique portrait art required.

**Audio requirements**: None — Rare skins use the character's default sound set.

**Example**: Zook "Deep Recon" — Zook in a ghillie-adjacent tactical outfit with earth-tone palette; trap VFX recolored in dull green.

#### Epic Tier

**Scope**: Full visual redesign. The character model is replaced with a thematically distinct design (different costume, accessories, and surface reads) while maintaining identical silhouette and bounding volume. Ability VFX may be fully redesigned with new particle shapes, but must match default VFX in spatial footprint and duration so that readability is not affected. A unique hit VFX set (the flash on landing a hit) is included. No new SFX for character voice or ambience; ability sound effects may have new skins if they are judged to be equivalent in volume, spatial clarity, and mix balance to the defaults.

**Visual requirements**:
- Silhouette and hitbox-visible bounding volume: identical to default.
- Ability VFX redesigns must pass fairness review (Section 3.10): same area of effect footprint, same cast timing cues, same projectile speed where applicable.
- Unique portrait and thumbnail art required.
- Unique idle animation is permitted if it does not alter the character's standing hitbox volume or visual center point.

**Audio requirements**: Ability audio skins (if included) are optional. If included, each must pass mix review: volume, directionality, and mix priority must be equivalent to the default ability sounds, verified by the audio team before ship.

**Example**: Sera "Astral Sharpshot" — Sera reimagined as a cosmic-themed sniper; her shot VFX is a streak of stars rather than a bullet trace, same spatial footprint and travel speed.

#### Legendary Tier

**Scope**: Fully animated and uniquely characterized. Everything in Epic plus: animated elements on the model (e.g., flowing cape, pulsing energy patterns), a unique spawn animation played once when the character enters the arena at match start, unique voice lines for select events (spawn, kill, death — must not provide informational audio advantage), and a unique sound skin for all character audio (ambient, movement, ability sounds). This is the highest possible production tier; Legendary skins represent the character as a completely distinct persona.

**Visual requirements**:
- Silhouette and hitbox-visible bounding volume: identical to default. Animated elements (e.g., capes, auras) must not occlude the character's hitbox-significant body volume in a way that misleads opponents about collision areas.
- Unique spawn animation: plays only at match start; may not affect the character's starting position, starting HP, or first-frame combat readiness.
- Unique idle and death animations permitted under the same hitbox-volume constraint as Epic.

**Audio requirements**:
- Unique voice lines: The set must not provide informational advantage. Voice lines must not convey game state information that the default character does not convey (e.g., a Legendary skin must not call out an opponent's name, announce their own HP state in a way the default does not, or react to events in ways that a competitor could interpret as information cues).
- Unique sound skin: All sounds must pass the same mix review as Epic ability sounds (volume, directionality, mix priority equivalence to defaults).

**Example**: Grim "Iron Colossus" — Grim reimagined as a living statue of forged metal; animated rivets and cracks glow on impact, unique deep metallic movement sounds, a unique slow-rising-from-rubble spawn animation, and low stone-grind voice lines.

---

### 3.2 Skin Data Model

Every skin is defined as a record in the Content Catalog. The canonical source of truth for what skins exist, their IDs, associated characters, and their purchase metadata lives there. The Cosmetic / Skin System reads from that catalog but does not own or mutate it.

```typescript
interface SkinDefinition {
  // Identity
  skinId: string;              // Stable unique identifier, e.g. "skin_vex_crimson". Never changes post-ship.
  characterId: string;         // References a CharacterDefinition.id, e.g. "character:vex"
  name: string;                // Display name, e.g. "Crimson Strike". Localizable.
  tier: SkinTier;              // "common" | "rare" | "epic" | "legendary"
  assetBundleKey: string;      // Key used by the client asset loader to fetch the Expo bundle, e.g. "skin_vex_crimson_v2"

  // Pricing — which currencies are accepted and at what price
  costs: SkinCost[];           // At most two entries: one Coin price and/or one Diamond price

  // Availability — how and when this skin can be obtained
  availabilityType: SkinAvailabilityType;
  availabilityWindow?: {
    startsAt: string;          // ISO 8601 UTC timestamp; present for limited-time and event-exclusive
    endsAt: string;            // ISO 8601 UTC timestamp; present for limited-time and event-exclusive
  };
}

type SkinTier = "common" | "rare" | "epic" | "legendary";

type SkinAvailabilityType =
  | "permanent"          // Always in the shop; no availability window
  | "limited-time"       // Seasonal rotation; available between startsAt and endsAt; may return in a future season
  | "event-exclusive"    // Tied to a single event; available during the event window; not guaranteed to return
  | "battle-pass-only";  // Earnable exclusively via Battle Pass; never sold directly in the shop

interface SkinCost {
  currency: "coins" | "diamonds";
  amount: number;              // Positive integer; must be > 0
}
```

**Schema constraints enforced at catalog validation time:**
- `skinId` must be globally unique across all skin definitions.
- `characterId` must resolve to an existing `CharacterDefinition.id` in the catalog.
- `tier` must be one of the four defined values.
- `costs` must contain at least one entry for any skin with `availabilityType !== "battle-pass-only"`. Battle Pass skins have an empty `costs` array (they are not purchasable; they are awarded).
- `availabilityWindow` is required when `availabilityType` is `"limited-time"` or `"event-exclusive"`. It must be absent (or null) for `"permanent"` and `"battle-pass-only"` skins.
- Common tier skins may be priced in either Coins or Diamonds (or both). Rare, Epic, and Legendary skins must be priced in Diamonds only (no Coin pricing above Common tier). See Formulas, Section 4.1.

---

### 3.3 One Skin Equipped Per Character; Default Always Available

A player may equip at most one skin per character at a time. The equipped skin for a character is stored in the `equippedSkins` map on the Player Profile (keyed by `characterId`, value is `skinId`).

The **default skin** is an implicit entry: no record in `equippedSkins` for a given `characterId` means the default skin is active for that character. The default skin does not have a `skinId` in the catalog — it is the base character visual asset referenced by `CharacterDefinition.visual_asset_ids`. A player can always return to the default skin by removing the equipped skin entry from the map (no ownership required, no unlock condition).

```typescript
// Stored in PlayerProfile
equippedSkins: Record<string, string>;  // characterId → skinId
// Absence of a characterId key means "default skin equipped" for that character
```

**Invariant**: If `equippedSkins[characterId]` is set to a `skinId`, the player must own that skin in their Inventory at the time the match starts. The Match Server validates this. If the skin is no longer owned (revoked, refunded), the server silently falls back to the default skin for that character in the match session (see Edge Cases, Section 5.1).

---

### 3.4 Equip Flow

The equip flow is initiated by the player from either the Character/Deck Select screen or a dedicated Skin Select screen within the character's profile page.

```
1. Player taps a skin card they own in the skin roster for a character.
       │
       ▼
2. Client loads the skin's asset bundle (if not cached locally) for preview.
   - Asset load is performed on a background thread.
   - A loading indicator is shown on the skin card during load.
   - If asset load fails, the skin card shows a placeholder and the player is
     notified that the preview could not be loaded (see Edge Cases, Section 5.2).
       │
       ▼
3. Preview is shown: character model renders with the selected skin active in the
   character portrait/3D preview area. Animations and VFX play at idle speed.
   No change to equippedSkins yet — this is client-side preview state only.
       │
       ▼
4. Player taps "Equip" (confirmation action).
       │
       ▼
5. Client sends PATCH /profile/equipped-skins { characterId, skinId } to the API server.
       │
       ▼
6. Server validates:
   a. JWT is valid and identifies the player.
   b. characterId exists in the character roster.
   c. skinId exists in the Content Catalog and belongs to characterId.
   d. Player owns the skin: Inventory record exists with active = true for this skinId.
   If any check fails → return appropriate error code; equip is not applied.
       │
       ▼
7. Server writes equippedSkins[characterId] = skinId to player_profiles in PostgreSQL.
   Redis cache for this profile is invalidated.
       │
       ▼
8. Server returns HTTP 200 with updated equippedSkins map.
       │
       ▼
9. Client updates local equippedSkins state.
   Skin card now displays an "Equipped" badge.
   Analytics event skin_equipped is fired (skinId, characterId, tier, source = "equip_screen").
```

**Unequip flow** (return to default): Player taps the currently equipped skin card, then taps "Use Default". Client sends `PATCH /profile/equipped-skins { characterId, skinId: null }`. Server deletes `equippedSkins[characterId]` from the map. Default skin is now active.

---

### 3.5 Skin Preview

The preview system allows a player to inspect a skin — including owned and unowned skins — without equipping it. Preview is available in:

- **Character Select Screen**: Tapping a locked (unowned) skin shows it in the preview pane with the "Locked" overlay, its tier badge, its price, and a "Get This Skin" shortcut to the Shop (or "Available via Battle Pass" if it is battle-pass-only).
- **Skin Select Screen**: Full preview including idle animation loop, ability VFX preview trigger, and (for Legendary skins) a button to preview the spawn animation.

**Preview implementation rules**:
- The client loads the skin's asset bundle for preview purposes even if the skin is not owned. This is client-side only — no server call is made to equip.
- If the asset bundle is not cached and a network download is required, a loading state is shown. If the download fails, a static thumbnail from the Content Catalog metadata is displayed instead. The failure is logged but not surfaced as an error to the player.
- Preview state is ephemeral: it lives only in local component state and is not persisted.
- Previewing a skin does not trigger a `skin_equipped` analytics event. It triggers `skin_previewed` (skinId, characterId, tier, owned: boolean).
- A player may preview any skin that exists in the Content Catalog regardless of ownership status. If the skin's `availabilityType` is `"event-exclusive"` or `"limited-time"` and the availability window has closed, the skin is still previewable but the shop shortcut is replaced with "Currently Unavailable."

---

### 3.6 Skin Availability Types

| Availability Type | Shop Presence | Can Be Purchased | Notes |
|---|---|---|---|
| `permanent` | Always listed in the Shop under the character's skin section | Yes | No expiry; price is constant |
| `limited-time` | Listed in Shop only during `availabilityWindow`; shows countdown timer | Yes, during window | May return in a future season's window; no guarantee communicated |
| `event-exclusive` | Listed in the event shop UI during the event's `availabilityWindow` | Yes, during event | Tied to a specific in-game event; the skin page notes "May return for future events" |
| `battle-pass-only` | Never listed in the currency shop; listed on the Battle Pass reward track UI | No — earned only via Battle Pass | Cannot be purchased with any currency at any time; available on the track for the duration of the Battle Pass season |

**Expiry behavior for limited-time and event-exclusive skins**:
- When `endsAt` passes, the skin is immediately removed from the Shop UI. Players who already own the skin retain ownership permanently.
- If a player has the skin in their cart (local, pending purchase — see Edge Cases, Section 5.5) when the window closes, the purchase is rejected server-side with error `SKIN_AVAILABILITY_EXPIRED`. The player is notified and returned to the shop.

---

### 3.7 Skin Purchasing from the Shop

The purchase flow is initiated from the Shop screen. It follows a defined sequence that ensures atomicity between currency deduction and inventory grant.

```
1. Player taps "Buy" on a skin offer in the Shop.
       │
       ▼
2. Client shows a purchase confirmation modal:
   - Skin name, tier badge, price (currency type and amount), character name.
   - If the skin is limited-time or event-exclusive: remaining time in the window.
   - "Confirm Purchase" and "Cancel" buttons.
       │
       ▼
3. Player taps "Confirm Purchase".
       │
       ▼
4. Client sends POST /shop/purchase { skinId, currency, amount } to the API server.
       │
       ▼
5. Server performs the following in a single PostgreSQL transaction:
   a. Re-validate skin availability: skin must be in the Content Catalog, status = active,
      and if limited-time/event-exclusive, current timestamp must be within availabilityWindow.
      If not → ROLLBACK, return SKIN_AVAILABILITY_EXPIRED.
   b. Check player does not already own the skin (idempotency check).
      If already owned → ROLLBACK, return SKIN_ALREADY_OWNED (client should refresh inventory).
   c. Verify the player has sufficient balance for the requested currency:
      - Coins: check coin_balance >= amount
      - Diamonds: check diamond_balance >= amount
      If insufficient → ROLLBACK, return INSUFFICIENT_BALANCE.
   d. Deduct the currency amount atomically:
      - Coins: UPDATE player_profiles SET coin_balance = coin_balance - amount WHERE user_id = $1
      - Diamonds: UPDATE player_profiles SET diamond_balance = diamond_balance - amount WHERE user_id = $1
   e. Grant the skin entitlement via the Inventory System:
      INSERT INTO inventory (user_id, item_type, item_id, active) VALUES ($1, 'skin', $skinId, true)
      ON CONFLICT (user_id, item_type, item_id) DO NOTHING  (idempotent grant)
   COMMIT.
       │
       ▼
6. Server invalidates player's Redis profile cache.
   Server emits profile:refresh Socket.io event to the player (economy field changed).
   Server returns HTTP 200 with updated balance and the newly granted skinId.
       │
       ▼
7. Client receives success response.
   - Updated currency balance is displayed (from the confirmed server response — no optimistic update).
   - The purchased skin appears as owned in the skin roster for the character.
   - Client presents: "Equip now?" shortcut (tapping it immediately starts the equip flow, Section 3.4).
   Analytics event skin_purchased is fired (skinId, characterId, tier, currency, amount).
```

**No optimistic updates**: The client must not display the currency deduction or the skin as owned until the server responds with HTTP 200. If the request fails or times out, the player is notified and no state change is shown.

---

### 3.8 Asset Delivery

Skin assets are packaged as Expo asset bundles, separate from the main app bundle. This keeps the initial app download size controlled and allows individual skins to be loaded on demand.

**Bundle structure**:
- Each skin has a single asset bundle identified by `assetBundleKey` in the `SkinDefinition`.
- The bundle contains: the character model override (if any), texture atlases, VFX particle definitions (if any), audio files (if any), and portrait/thumbnail images.
- Bundles are versioned: if a skin's assets are updated (e.g., a bug fix to a texture), the `assetBundleKey` is incremented (e.g., `skin_vex_crimson_v2` → `skin_vex_crimson_v3`). Old cached bundles with stale keys are evicted.

**Load-on-demand policy**:
- Skins are not downloaded at install time or at first login. They are downloaded on first preview or first equip.
- The client checks its local bundle cache before initiating a network fetch. If a cached bundle exists and the `assetBundleKey` matches, no download occurs.
- During a preview or equip action, if the bundle is not cached, a download is initiated in the background. The UI shows a loading indicator. The player is not blocked from continuing other actions.

**Match-time asset resolution**:
- The Match Server sends `skinId` (not the full asset bundle) in the match session state for each player.
- The client resolves the `skinId` to an `assetBundleKey` via the local Content Catalog snapshot.
- The client loads the asset bundle from local cache. If the bundle is not cached (e.g., opponent's skin), it is downloaded before the match starts from the character select screen. Asset readiness is checked during the pre-match lobby phase: the client reports readiness only once all opponent skin bundles for the current match are resolved.
- Under no circumstances is skin asset data (bundle contents, texture data) transmitted between clients or included in match tick data. Only the `skinId` string travels over the wire.

**Cache eviction policy**:
- Asset bundles are stored in the device's local cache directory.
- Bundles are evicted using an LRU policy when the local skin cache exceeds `SKIN_ASSET_CACHE_SIZE_MB` (see Tuning Knobs, Section 7).
- Bundles for equipped skins are pinned and are never evicted while equipped.

---

### 3.9 Skin Application in Match

The match server does not apply or process skin data during gameplay. The skin system is purely client-side during a match.

**Data flow at match start**:
1. At match initialization, the Match Server constructs the match session state, which includes for each player: `playerId`, `characterId`, and `skinId` (read from `equippedSkins` on the player's profile, defaulting to `null` if no skin is equipped).
2. This session state is broadcast to all clients.
3. Each client receives the `{ characterId, skinId }` pair for every player and resolves it to an asset bundle key locally.
4. Client renders each character using its resolved asset bundle.

**Server trust boundary**: The server does not validate which `skinId` a client claims to be using within a match — only that the `skinId` it records in the session state came from the authenticated player profile. The client cannot inject a `skinId` it does not own: the session state is server-constructed from server-side profile data.

**Skin data volume**: The only skin-related data transmitted in match tick messages is zero bytes — `skinId` is resolved once at match start and is not included in any tick payload.

---

### 3.10 Fairness Constraint and Review Process

**The core rule**: No skin at any tier may provide a competitive information advantage over any other skin for the same character, including the default skin. This is an absolute constraint. Any skin that violates it must be revised before shipping.

**Specific prohibited characteristics**:
- **Size disparity**: The character's hitbox-significant silhouette and bounding volumes must be identical across all skins. A skin may not make the character appear smaller or larger than default. This is tested by overlaying the skin's sprite/model over the default at all animation frames.
- **Contrast manipulation**: A skin's palette must not make the character harder to distinguish from arena backgrounds at typical play resolution. The skin must pass a contrast ratio check against the five shipped arena backgrounds. No skin may use background-matching camouflage patterns.
- **Animation clarity**: Ability wind-up animations and telegraphs (the visual cue that an ability is about to fire) must be at least as readable as the default. A Legendary skin's unique animations may not obscure or shrink the wind-up visual cue.
- **Audio information asymmetry**: Unique sound skins on Epic and Legendary tiers must not provide audio information that the default sound set does not. For example: a Legendary skin's unique movement sounds must not be quieter than default (harder to detect) or louder in a way that reveals precise position more accurately than default. Spatial mixing must be equivalent.
- **Spawn animation timing**: A Legendary skin's spawn animation must complete within the standard match-start invincibility window and must not delay the character's first-frame availability relative to default.

**Review gate**: Every skin must pass a Fairness Review before it is added to the Content Catalog. The review is conducted by a designated reviewer (gameplay team + audio team) and produces a boolean PASS/FAIL. A FAIL result must include specific revision notes. The skin may not ship until a revised version passes. The review outcome is recorded in the skin's production record (outside this system's scope).

---

## 4. Formulas

### 4.1 Skin Tier Pricing Table

Prices are configurable via the `SKIN_PRICES` Remote Config key (see Tuning Knobs). The table below defines the default prices at launch. Common skins may be sold in Coins and/or Diamonds; all higher tiers are Diamonds-only.

| Tier | Coin Price | Diamond Price | Notes |
|---|---|---|---|
| Common | 500 Coins | 80 Diamonds | Coin pricing makes Common skins accessible without hard currency. Diamond option provided for convenience. Both prices are valid `SkinCost` entries. |
| Rare | — | 300 Diamonds | No Coin pricing above Common tier. |
| Epic | — | 800 Diamonds | |
| Legendary | — | 1,500 Diamonds | |

**Formula for Diamond equivalent of Coin price** (used for bundle discount validation, not player-facing):

```
diamond_coin_equivalent = coin_price / COIN_TO_DIAMOND_RATE
```

Where `COIN_TO_DIAMOND_RATE` is a configuration constant (see Tuning Knobs). Default value: `COIN_TO_DIAMOND_RATE = 10.0` (10 Coins = 1 Diamond).

**Example**: Common skin Coin price of 500 Coins:
```
diamond_coin_equivalent = 500 / 10.0 = 50 Diamonds
```
This is below the Diamond price of 80, which is intentional — Diamond convenience carries a slight premium over Coin equivalent to reward Coin earners.

**Bundle pricing**: Character bundles sold via IAP (e.g., a bundle containing a character + a Legendary skin) are priced by the IAP System. The Cosmetic / Skin System does not own bundle pricing. The bundle's skin grant payload is fulfilled through the Inventory System using the skin's `skinId`.

---

### 4.2 Asset Bundle Size Budget Per Tier

Every skin tier has a maximum asset bundle size. These budgets protect player bandwidth and device storage. Bundles that exceed their ceiling fail the asset pipeline validation step and must be optimized before they can be shipped.

| Tier | Maximum Bundle Size | What the Budget Covers |
|---|---|---|
| Common | 512 KB | Recolored texture atlas only; no additional model data or audio |
| Rare | 1,024 KB (1 MB) | Alternate texture atlas + unique portrait/thumbnail art |
| Epic | 3,072 KB (3 MB) | Alternate model textures + reskinned VFX particle definitions + unique portrait/thumbnail |
| Legendary | 8,192 KB (8 MB) | All Epic assets + unique audio files + spawn animation data + animated model elements |

**Formula for cumulative per-character skin footprint** (advisory, not enforced):

```
character_skin_footprint = Σ(bundle_size[skin_i]) for all owned skins on that character
```

**Example**: A player owns all 4 skins for Vex (1 Common, 1 Rare, 1 Epic, 1 Legendary):
```
footprint = 512 KB + 1,024 KB + 3,072 KB + 8,192 KB = 12,800 KB ≈ 12.5 MB
```
Under the LRU cache policy with `SKIN_ASSET_CACHE_SIZE_MB = 200`, this is well within budget. The pinned-skin guarantee (equipped skins are never evicted) applies to at most 8 skins simultaneously (one per character), for a maximum pinned footprint of:
```
max_pinned_footprint = 8 * 8,192 KB = 65,536 KB = 64 MB
```
This is well within the 200 MB total cache ceiling.

---

## 5. Edge Cases

### 5.1 Player Equips a Skin, Then the Skin Is Revoked

**Scenario**: A player has Skin X equipped for character Vex. The skin is subsequently revoked from their Inventory (e.g., IAP refund processed, fraudulent purchase reversed, manual support action).

**Handling**:
1. The skin entitlement record in Inventory is set to `active = false` (or deleted).
2. The player's `equippedSkins[character:vex]` in their profile still references the revoked `skinId`. This is a stale reference.
3. **At match start**: The Match Server reads `equippedSkins` and then validates the equipped skin against Inventory. If the skin's entitlement is `active = false` or missing, the server silently replaces `skinId` with `null` (default skin) for that character in the match session state. No error is surfaced to the player or their opponents.
4. **Post-match profile sync**: After the match, the server sends a `profile:refresh` event. When the client receives the refresh, it re-reads the equippedSkins from the server. The client silently finds no equipped skin for Vex and renders the default skin in the skin select UI.
5. The stale `equippedSkins[character:vex]` reference is cleaned up lazily: on the next `PATCH /profile/equipped-skins` call for any character, the server performs a sweep of `equippedSkins` and removes any entries where the referenced skin is no longer in the player's Inventory.
6. **No error message is shown to the player** during the match about the skin revocation. The transition to default is silent. A separate entitlement notification (outside this system's scope) may inform the player that their purchase was reversed.

---

### 5.2 Skin Asset Bundle Fails to Download

**Scenario**: A player (or their opponent) has a skin equipped that the client needs to load for a match or preview, and the asset bundle download fails (network error, CDN unavailable, corrupted download).

**Handling**:
1. The asset loader detects a download failure (non-200 HTTP response, network timeout, or checksum mismatch on the received bundle).
2. The client falls back to the character's default skin assets for that player in this session. The default skin bundle is always locally present (bundled with the base app install).
3. **No error is shown to opponents**: Other players' clients handle the asset resolution independently. Opponent A's client failing to load Opponent B's skin asset silently falls back to B's default skin from A's perspective. B's own client may successfully display their skin if their download succeeded.
4. The failure is logged client-side: `SKIN_ASSET_LOAD_FAILED: skinId={id}, assetBundleKey={key}, error={code}`. This log is surfaced to the monitoring dashboard and counted toward a per-skin error rate metric.
5. The download is not retried during the current match session. On the next session launch, the LRU cache will not have a valid entry for the bundle; the client will attempt the download again at that time.
6. The player is not notified that an asset load failed. The fallback is silent and transparent.

---

### 5.3 Content Catalog Update Changes a skinId (Key Migration)

**Scenario**: A skin's `skinId` changes in a Content Catalog update (this should never happen per catalog contract — canonical IDs are immutable — but must be handled defensively). The `equippedSkins` map references the old ID; the old ID is no longer in the catalog.

**Handling**:
1. By contract, canonical IDs (`skinId` values) in the Content Catalog must never change for the lifetime of the record. A `skinId` change is a catalog authoring error.
2. At match start, the server resolves `equippedSkins[characterId]` against the current catalog. If the `skinId` is not found in the catalog (status: missing or deprecated), the server logs `EQUIPPED_SKIN_CATALOG_MISS: skinId={old_id} for playerId={id}` and falls back to the default skin for that character in this match.
3. The stale entry is cleaned up from `equippedSkins` in the same lazy sweep described in Section 5.1 (step 5).
4. The catalog authoring team is alerted via the monitoring dashboard. The old record should be given a `deprecated` status (with an explanatory description noting the migration) rather than being deleted, to provide a historical reference.
5. Players whose Inventory references the old `skinId` retain the entitlement record. If a migration is needed (old ID → new ID), the Inventory System must run a batch migration job that updates the entitlement record; the Cosmetic / Skin System consumes the corrected Inventory state automatically on the next match start.

---

### 5.4 Player Owns a Skin for a Character They Do Not Own

**Scenario**: A player purchases an IAP bundle that includes a character + a Legendary skin for that character. The bundle fulfillment grants the skin via Inventory (Section 3.7 step 5e) but the character grant has not yet propagated (network latency, transient failure). Alternatively, a player is gifted or granted a skin for a character they do not yet own.

**Handling**:
1. The skin entitlement is valid in Inventory: `active = true` for the `skinId`.
2. The character is not owned: the player cannot select this character in a match.
3. In the Skin Select UI for this character, the skin appears in the owned section with its full art and tier badge, but the character's portrait has a "Locked" overlay and the equip button is replaced with "Unlock Character to Equip."
4. The player may preview the skin (Section 3.5) even though the character is locked.
5. When the character is subsequently unlocked (bundle fulfillment completes, progression threshold reached, etc.), the skin is immediately equippable. No additional steps are required.
6. The skin does not expire due to the character being unowned. Ownership is permanent once granted.

---

### 5.5 Limited-Time Skin Expires from Shop While in Player's Cart

**Scenario**: A player opens the Shop, views a limited-time skin, taps "Buy," and is on the purchase confirmation modal when the skin's `endsAt` timestamp passes (or the server receives the purchase request after `endsAt`).

**Handling**:
1. The server performs availability re-validation as the first step of the purchase transaction (Section 3.7, step 5a).
2. The server checks `current_timestamp <= skin.availabilityWindow.endsAt`. If the window has closed, the transaction is rolled back immediately with no currency deducted.
3. The server returns HTTP 409 with error code `SKIN_AVAILABILITY_EXPIRED`.
4. The client closes the confirmation modal and displays the notification: "This skin is no longer available. No charge was made." The player is returned to the Shop main screen.
5. The skin is removed from the Shop UI client-side immediately (the client refreshes the shop catalog upon receiving the error).
6. No currency is deducted from the player's balance under any failure path.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (Cosmetic / Skin System reads from these)

| System | What Is Read | When Read | If Unavailable |
|---|---|---|---|
| **Content Catalog** (`content-catalog.md`) | All `SkinDefinition` records (skinId, characterId, tier, assetBundleKey, costs, availabilityType, availabilityWindow); skin catalog status (active/inactive/deprecated) | Client: skin select UI load, shop load, preview; Server: purchase validation, match start validation | Server: if catalog unreachable at match start, server uses in-memory cache; if cache is stale, match uses `null` skinId (default skin) for all players and logs `SKIN_CATALOG_UNAVAILABLE`. Client: falls back to last cached catalog snapshot; shows stale shop data with a refresh prompt. |
| **Inventory / Entitlements** (`inventory-entitlements.md`) | Skin entitlement records: `{ user_id, item_type: "skin", item_id: skinId, active: boolean }` | Server: purchase validation (duplicate check), match start validation (ownership check), equip validation; Client: skin roster owned/locked state | If Inventory is unreachable at match start, match start is blocked and players are returned to lobby with `INVENTORY_SERVICE_UNAVAILABLE`. During skin UI load, cached Inventory state is used with a stale-data indicator. |
| **Player Profile** (`player-profile.md`) | `equippedSkins` map (characterId → skinId); `coin_balance`; `diamond_balance` | Server: match start (read equipped skin per character); purchase flow (balance check + deduct); equip flow (write equipped skin) | If Player Profile is unavailable at match start, match start is blocked. Profile writes (equip, purchase) fail with HTTP 503; client notifies player. |
| **Character System** (`character-system.md`) | `CharacterDefinition.id` (to validate characterId on skins); character ownership/availability per player (to determine if locked-character skin state applies) | Skin roster UI load; equip validation | Character definitions are loaded at server startup. If unavailable, equip flow degrades gracefully: server rejects equip attempts with `CHAR_DEFINITION_NOT_FOUND` rather than silently failing. |
| **Currency System** (`currency-system.md`) | Coin balance and Diamond balance read before purchase; currency deduction written during purchase (via Player Profile currency fields) | Purchase flow (step 5c–5d) | If currency fields are unreadable, the purchase is blocked with `BALANCE_CHECK_FAILED`. No deduction is made without a confirmed read. |
| **Remote Config** | `SKIN_PRICES` configuration (override default tier prices); `SKIN_ASSET_CACHE_SIZE_MB`; other tuning knobs | Server startup and periodic refresh | If Remote Config is unavailable, defaults from Tuning Knobs (Section 7) are used. No player-facing degradation. |

### 6.2 Downstream Consumers (these depend on Cosmetic / Skin System)

| System | What It Reads | How It Uses It |
|---|---|---|
| **Match Server** (`match-server.md`) | `equippedSkins[characterId]` from Player Profile; Inventory ownership of the equipped skin | Includes `skinId` in match session state broadcast; falls back to `null` if skin is not owned |
| **Character / Deck Select Screen** (`character-deck-select.md`) | Skin roster per character (owned/locked); equipped skin per character | Renders skin select UI in pre-match flow; shows equipped skin badge |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | `skin_equipped`, `skin_purchased`, `skin_previewed` events | Revenue analytics; skin popularity; conversion funnel |
| **Battle Pass System** (future) | `skinId` as reward payload for battle-pass-only skins | Fulfills the skin grant via Inventory when the player claims a Battle Pass reward tier |
| **IAP System** (`iap-system.md`) | Skin `skinId` in bundle grant payloads | Fulfills skin entitlement through Inventory on successful IAP |
| **Shop / Offers Screen** (future) | `SkinDefinition.costs`, `availabilityType`, `availabilityWindow` | Renders skin offers, pricing, countdown timers |

### 6.3 Logging and Monitoring

All significant events in the Cosmetic / Skin System are logged via the `ILogger` interface from `logging-monitoring.md`. PII policy: `user_id` may be logged; `display_name` is not logged in skin events; `skinId` is not PII.

Key log events:
- `SKIN_EQUIPPED`: `{userId, characterId, skinId, tier}` — on successful server-side equip write.
- `SKIN_PURCHASE_SUCCESS`: `{userId, skinId, tier, currency, amount}` — on successful purchase commit.
- `SKIN_PURCHASE_FAILED`: `{userId, skinId, reason}` — on any purchase error.
- `SKIN_REVOCATION_FALLBACK`: `{userId, characterId, skinId}` — when match start detects a revoked skin and falls back to default.
- `SKIN_CATALOG_MISS`: `{userId, skinId}` — when match start cannot resolve a skinId against the catalog.
- `SKIN_ASSET_LOAD_FAILED`: `{skinId, assetBundleKey, errorCode}` — client-side asset load failure.

---

## 7. Tuning Knobs

All values are configurable without a code deploy. Values marked * can be updated via Remote Config push; unmarked values require a server config or Content Catalog update.

| Knob | Default Value | Safe Range | Effect of Change |
|---|---|---|---|
| `SKIN_PRICE_COMMON_COINS` * | 500 Coins | 100–2,000 | Price of Common skins in Coins. Raise to slow Coin sinks; lower to accelerate skin collection for new players. |
| `SKIN_PRICE_COMMON_DIAMONDS` * | 80 Diamonds | 20–200 | Diamond price for Common skins. Keep above `SKIN_PRICE_COMMON_COINS / COIN_TO_DIAMOND_RATE` if Diamond convenience premium is desired. |
| `SKIN_PRICE_RARE_DIAMONDS` * | 300 Diamonds | 100–600 | Diamond price for Rare skins. |
| `SKIN_PRICE_EPIC_DIAMONDS` * | 800 Diamonds | 300–1,600 | Diamond price for Epic skins. |
| `SKIN_PRICE_LEGENDARY_DIAMONDS` * | 1,500 Diamonds | 800–3,000 | Diamond price for Legendary skins. Raise with caution — Legendary is the aspirational ceiling. Lowering risks devaluing the tier. |
| `COIN_TO_DIAMOND_RATE` * | 10.0 | 5.0–20.0 | Exchange rate used for bundle discount validation and analytics normalization only. Does not create a Coin-to-Diamond exchange for players. |
| `SKIN_ASSET_CACHE_SIZE_MB` * | 200 MB | 50–500 MB | Maximum local disk space for cached skin asset bundles. LRU eviction above this ceiling. Pinned (equipped) skins are excluded from eviction. Lower values increase re-download frequency on devices with limited storage. |
| `SKIN_ASSET_BUNDLE_CEILING_COMMON_KB` | 512 KB | 128–1,024 KB | Maximum asset bundle size for Common tier. Enforced by asset pipeline CI. |
| `SKIN_ASSET_BUNDLE_CEILING_RARE_KB` | 1,024 KB | 256–2,048 KB | Maximum asset bundle size for Rare tier. |
| `SKIN_ASSET_BUNDLE_CEILING_EPIC_KB` | 3,072 KB | 1,024–6,144 KB | Maximum asset bundle size for Epic tier. |
| `SKIN_ASSET_BUNDLE_CEILING_LEGENDARY_KB` | 8,192 KB | 3,072–16,384 KB | Maximum asset bundle size for Legendary tier. |
| `SKIN_ASSET_DOWNLOAD_TIMEOUT_MS` * | 10,000 ms | 5,000–30,000 ms | Timeout for a single skin asset bundle download attempt before the client falls back to default skin. Too low causes false fallbacks on slow connections; too high delays match-ready confirmation. |
| `SKIN_EQUIP_VALIDATION_ENABLED` * | true | true/false | If false, server skips ownership re-validation at equip time (emergency disable for Inventory service outage). Should never be false in production except under active incident response. |
| `SKIN_MATCH_VALIDATION_ENABLED` * | true | true/false | If false, server skips skin ownership check at match start and uses profile-stated skinId as-is. Emergency only. |

---

## 8. Acceptance Criteria

### AC-SKIN-01: Skin Tier Data Model Integrity

**Given** the Content Catalog contains `SkinDefinition` records for at least one skin at each tier (Common, Rare, Epic, Legendary) for at least one character  
**When** the server loads the catalog at startup  
**Then**:
- All four tier values are accepted without validation error.
- Each skin's `characterId` resolves to a valid character in the character roster.
- Common skins with `costs` entries for both Coins and Diamonds are accepted.
- Rare, Epic, and Legendary skins with any `costs` entry using `currency: "coins"` are rejected with a catalog validation error.
- Battle-pass-only skins with an empty `costs` array are accepted.
- Limited-time and event-exclusive skins without `availabilityWindow` fail catalog validation.
- Permanent and battle-pass-only skins with `availabilityWindow` present fail catalog validation.

---

### AC-SKIN-02: Default Skin Fallback

**Given** a player with no entry in `equippedSkins` for character `character:vex`  
**When** a match is initialized with this player selecting Vex  
**Then**:
- The match session state contains `{ characterId: "character:vex", skinId: null }` for this player.
- The client renders Vex using the default visual assets from `CharacterDefinition.visual_asset_ids`.
- No skin asset bundle download is triggered for this player-character pair.

---

### AC-SKIN-03: Equip Flow — Success

**Given** a player who owns skin `skin_vex_crimson` (Inventory record: `{ item_id: "skin_vex_crimson", active: true }`)  
**When** the player submits `PATCH /profile/equipped-skins { characterId: "character:vex", skinId: "skin_vex_crimson" }`  
**Then**:
- Server validates JWT, characterId, skinId, and Inventory ownership — all pass.
- `equippedSkins["character:vex"] = "skin_vex_crimson"` is written to `player_profiles` in PostgreSQL.
- Redis profile cache is invalidated.
- HTTP 200 is returned with the updated `equippedSkins` map.
- A `SKIN_EQUIPPED` log event is emitted.
- A `skin_equipped` analytics event is fired with `{skinId: "skin_vex_crimson", characterId: "character:vex", tier: "common"}`.

---

### AC-SKIN-04: Equip Flow — Unowned Skin Rejected

**Given** a player who does NOT own skin `skin_vex_astral` (no Inventory record or `active: false`)  
**When** the player submits `PATCH /profile/equipped-skins { characterId: "character:vex", skinId: "skin_vex_astral" }`  
**Then**:
- Server returns HTTP 403 with error code `SKIN_NOT_OWNED`.
- `equippedSkins` in PostgreSQL is unchanged.
- No log event or analytics event is fired for this attempt.

---

### AC-SKIN-05: Unequip Returns to Default

**Given** a player with `equippedSkins["character:vex"] = "skin_vex_crimson"`  
**When** the player submits `PATCH /profile/equipped-skins { characterId: "character:vex", skinId: null }`  
**Then**:
- The `equippedSkins["character:vex"]` entry is deleted from `player_profiles`.
- HTTP 200 is returned with the updated `equippedSkins` map (no entry for `character:vex`).
- The client renders Vex with the default skin in the skin select UI.

---

### AC-SKIN-06: Match Start — Skin Included in Session State

**Given** a player with `equippedSkins["character:zook"] = "skin_zook_deeprecon"` and a valid Inventory record for that skin  
**When** a match is initialized with this player selecting Zook  
**Then**:
- The match session state broadcast to all clients contains `{ playerId: "...", characterId: "character:zook", skinId: "skin_zook_deeprecon" }`.
- The `skin_zook_deeprecon` asset bundle key is resolved by each client via the local Content Catalog.
- No skin asset data (texture files, audio files) is included in match tick messages.

---

### AC-SKIN-07: Match Start — Revoked Skin Falls Back to Default

**Given** a player with `equippedSkins["character:nyx"] = "skin_nyx_spectral"` but the skin's Inventory record is `active: false`  
**When** a match is initialized with this player  
**Then**:
- The match session state contains `{ characterId: "character:nyx", skinId: null }` for this player.
- The client renders Nyx with the default skin.
- A `SKIN_REVOCATION_FALLBACK` log event is emitted with `{userId, characterId: "character:nyx", skinId: "skin_nyx_spectral"}`.
- No error is displayed to the player or their opponents during the match.

---

### AC-SKIN-08: Skin Purchase — Success

**Given** a player with `diamond_balance = 400` and no Inventory record for `skin_sera_astral` (Epic tier, 800 Diamonds)  
**When** the player purchases `skin_sera_astral`  
**Then**:
- The server returns HTTP 402 with error code `INSUFFICIENT_BALANCE` (400 < 800).
- No currency is deducted.
- No Inventory record is created.

**And given** a player with `diamond_balance = 900`  
**When** the player purchases `skin_sera_astral` (800 Diamonds)  
**Then**:
- A single PostgreSQL transaction deducts 800 Diamonds and inserts the Inventory record.
- `diamond_balance` becomes 100.
- Inventory record `{ item_id: "skin_sera_astral", active: true }` exists for the player.
- HTTP 200 is returned with updated balance.
- A `profile:refresh` Socket.io event is emitted.
- `skin_purchased` analytics event fired with `{skinId: "skin_sera_astral", tier: "epic", currency: "diamonds", amount: 800}`.

---

### AC-SKIN-09: Skin Purchase — Idempotency

**Given** a player who already owns `skin_vex_crimson` (Inventory: `active: true`)  
**When** the player attempts to purchase `skin_vex_crimson` again  
**Then**:
- Server returns HTTP 409 with error code `SKIN_ALREADY_OWNED`.
- No currency is deducted.
- Inventory record is unchanged.

---

### AC-SKIN-10: Skin Purchase — Expired Availability Window

**Given** a limited-time skin `skin_fen_aurora` whose `availabilityWindow.endsAt` is in the past  
**When** a player sends a purchase request for `skin_fen_aurora`  
**Then**:
- Server returns HTTP 409 with error code `SKIN_AVAILABILITY_EXPIRED`.
- No currency is deducted.
- No Inventory record is created.
- Client displays "This skin is no longer available. No charge was made."

---

### AC-SKIN-11: Asset Bundle Fallback on Download Failure

**Given** a player whose opponent has `skin_grim_colossus` (Legendary) equipped, and the asset bundle download for `skin_grim_colossus` fails on the first player's device  
**When** the match loads  
**Then**:
- The opponent's character (Grim) is rendered using the default Grim skin assets on the first player's screen.
- No error message is displayed to the first player.
- A `SKIN_ASSET_LOAD_FAILED` log entry is emitted on the first player's device.
- The opponent's own client still renders Grim with `skin_grim_colossus` if their own asset load succeeded.
- The opponent's displayed skin has no effect on the first player's hitbox or collision detection (which is server-authoritative).

---

### AC-SKIN-12: Skin Previewed Event

**Given** a player in the skin select screen viewing a skin they do not own  
**When** the skin preview loads and is displayed  
**Then**:
- A `skin_previewed` analytics event is fired with `{skinId, characterId, tier, owned: false}`.
- The `equippedSkins` map on the player's profile is unchanged.
- No ownership or Inventory record is created.

---

### AC-SKIN-13: Locked Character — Skin Visible but Not Equippable

**Given** a player who owns `skin_nyx_spectral` (Legendary) but does not own character `character:nyx`  
**When** the player opens the skin roster for Nyx  
**Then**:
- `skin_nyx_spectral` appears in the owned section of Nyx's skin list with full art and the Legendary tier badge.
- The character portrait shows a "Locked" overlay.
- The equip button is replaced with "Unlock Character to Equip."
- The player may tap the skin card to preview it.
- After the player subsequently unlocks `character:nyx`, the equip button becomes available on the next skin roster load without any additional skin-specific action.

---

### AC-SKIN-14: Battle Pass Only Skin Not Purchasable

**Given** a battle-pass-only skin `skin_dash_voltage` with an empty `costs` array  
**When** the player navigates to the Shop  
**Then**:
- `skin_dash_voltage` does not appear in the currency shop UI.
- `skin_dash_voltage` appears on the Battle Pass reward track UI with an "Earn via Battle Pass" label.
- Any direct purchase API call `POST /shop/purchase { skinId: "skin_dash_voltage" }` is rejected by the server with HTTP 403 error code `SKIN_NOT_FOR_SALE`.

---

### AC-SKIN-15: Fairness — Silhouette Parity

**Given** any shipped skin at any tier for any character  
**When** the skin's model is overlaid on the default skin model at all exported animation keyframes  
**Then**:
- The hitbox-significant silhouette deviation is 0 pixels at any standard play resolution (the skin passes the silhouette parity check in the asset pipeline).
- Any decorative animated elements (capes, auras) that extend beyond the default silhouette are confirmed to extend outside the hitbox volume.

---

### AC-SKIN-16: Skin Data Not Transmitted in Match Ticks

**Given** an active match in progress with two players each using non-default skins  
**When** match tick messages are captured from the server  
**Then**:
- No tick message contains `assetBundleKey`, texture data, audio data, or any skin asset binary content.
- Each player's skin is represented solely by the `skinId` string established in the match session state at match start.

---

*End of Cosmetic / Skin System GDD — Version 1.0 Draft*
