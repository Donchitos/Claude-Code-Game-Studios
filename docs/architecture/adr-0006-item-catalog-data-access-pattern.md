# ADR-0006: Item Catalog Data Access Pattern

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Persistence (Cloud Firestore read pattern + Riverpod caching — Platform-layer) |
| **Knowledge Risk** | LOW — a one-time Firestore `get()` on a collection + a Riverpod `FutureProvider` are stable, pre-cutoff patterns. The only ^5.x-era nuance is `GetOptions(source:)` cache/server behavior (see Verification Required). |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `current-best-practices.md`, `deprecated-apis.md`; `design/gdd/item-database.md`; ADR-0002, ADR-0003; flame-specialist validation (2026-07-07) |
| **Post-Cutoff APIs Used** | `cloud_firestore ^5.x` `CollectionReference.get()` / `Query.orderBy().get()`; optional `GetOptions(source: Source.serverAndCache)`. `flutter_riverpod` `FutureProvider`. |
| **Verification Required** | **Resolved (flame-specialist, 2026-07-07)**: `GetOptions.source` defaults to `Source.serverAndCache` (fresh when online, graceful cache fallback offline) — exactly the requirement — and has for the plugin's whole lifetime, so a plain `get()` already does the right thing. `orderBy('sortOrder')` needs **no** composite index (single-field indexes are automatic). No open API question remains. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema & Persistence) — establishes the persistence/path conventions this reconciles with; ADR-0002 (Auth) — the read Security Rule requires `request.auth != null`. |
| **Enables** | Shop System (#13), Gacha/Loot (#12), Pet Equipment (#15), Pet Room Screen UI (#18) — all read the catalog via `itemCatalogProvider`. |
| **Blocks** | Any implementation epic that displays, rolls, or renders items — needs the catalog access contract. |
| **Ordering Note** | This ADR owns the **global `items/` collection** and its read/cache pattern. It is a deliberately scoped exception to ADR-0003's `systems_building_own_firestore_paths` rule (see Decision §4): that rule governs family-tree *mutations* through the atomic repository; the catalog is global, read-only, static data with a different access model. |

## Context

### Problem Statement

Items are the vocabulary of self-expression (Pillar 5) — outfits, room decorations, and special collectibles. Three systems (Shop, Gacha, Pet Equipment) plus the Pet Room UI all need to read the same item definitions, and those definitions are static within a session (they change only when an admin seeds new items). The access pattern must be decided once: where the catalog lives, how it's read, how it's cached, who can write it, and how it relates to ADR-0003's persistence conventions. Reading it wrong (e.g. a realtime `snapshots()` listener per consumer) would waste Firestore reads on data that never changes mid-session. The `item-database.md` GDD specifies the pattern; this ADR ratifies it and settles the one boundary question (global-catalog path vs. the family-tree repository rule).

### Constraints
- **Static within a session**: the catalog changes only via admin seed/console writes; clients never write it.
- **Shared globally**: `items/` is a top-level collection, NOT scoped under `families/{parentId}` — every child reads the same catalog.
- **Read cost matters**: at 1000+ families, a per-consumer realtime listener would multiply reads for zero benefit.
- **Offline-first coexistence** (ADR-0003): offline persistence is on; a `get()` can serve from cache.
- **Auth-gated** (ADR-0002): only authenticated (parent) sessions may read.

### Requirements
- One-time fetch, session-cached; no repeat `get()` on navigation.
- Ordered by `sortOrder`.
- Read-only Security Rule (`allow read: if request.auth != null; allow write: if false`).
- A lookup-by-`itemId` accessor for Pet Equipment/Gacha.
- Graceful empty-catalog (unseeded) and missing-item (post-cache-load roll) handling.
- 500-item hard cap before pagination is required (MVP = 30).

## Decision

**1. Global `items/{itemId}` collection, one-time cached `get()` via a `FutureProvider`.**
The catalog is a top-level Firestore collection. It is fetched once per app session with `.orderBy('sortOrder').get()` and cached in a Riverpod `FutureProvider<List<ItemModel>>` (`itemCatalogProvider`). Consumers read from the cached provider; navigation triggers no repeat fetch. **Not `snapshots()`** — the catalog is static within a session, so a realtime listener is pure waste. **The provider must NOT be `.autoDispose`** — session-lifetime caching is the entire point; an `.autoDispose` variant would re-fetch every time the last consumer widget unmounts and a new one subscribes, silently breaking the one-read-per-session cost claim. The default `get()` source (`Source.serverAndCache`) already gives fresh-when-online / cache-fallback-when-offline, so no `GetOptions` argument is required (writing it explicitly is documentation-only).

**2. Read-only Security Rules.**
```
match /items/{itemId} {
  allow read: if request.auth != null;   // any authed (parent) session
  allow write: if false;                 // no client writes at all
}
```
Clients never write the catalog; content is seeded by an admin script/console (Admin SDK / console writes bypass Security Rules). Note: `write: if false` means there is **no** client-write path to guard, so the GDD's "price in [10,200]" is a content-authoring convention for the seed script, not an enforceable rule here. **This `items/` block and ADR-0003's `families/{parentId}` block must be merged into one `firestore.rules` file** (a project has a single rules file), both nested under one `match /databases/{database}/documents { }` root — they are not separately-deployable files.

**3. Session-cache semantics + graceful degradation.**
- Cache TTL = app session; re-fetch on cold start only.
- Empty catalog (unseeded) → provider returns `[]`; consumers render an empty state, never crash.
- Post-load missing item (Gacha rolls an `itemId` added to Firestore after this session's cache loaded) → `lookupById` returns null; the consumer renders a placeholder and may trigger a re-fetch. This is the accepted limitation of the one-time-load model — the item displays correctly after the next app restart.

**4. Scoped exception to `systems_building_own_firestore_paths` (ADR-0003).**
ADR-0003 forbids systems building Firestore paths directly, routing all access through `PersistenceRepository`. That rule exists to funnel **family-tree mutations** through the atomic write contracts. The item catalog is a different concern: **global, read-only, static** data with no atomic-write or per-child-scoping needs. Resolution:
- The `items` collection **path constant lives in the centralized path constants** (satisfying the rule's intent — no magic strings, one place to change).
- The **read is served by `itemCatalogProvider`'s cached `get()`**, not by `PersistenceRepository`'s mutation methods.
This is documented as an intentional, scoped distinction — the repository rule is about mutation atomicity, which does not apply to a read-only global catalog. Registered as a narrow carve-out (see registry update).

**5. No rarity system; `source` is acquisition, not visibility.**
Items have no rarity tier — differentiation is `price` + `source` (`shop`/`gacha`/`both`). `source` is where an item can be *acquired*, not a visibility flag: Shop filters out `source == 'gacha'` when rendering; Item Database only stores the field. (Consumer-side filtering owned by Shop/Gacha ADRs.)

### Architecture Diagram
```
items/{itemId}  (global, top-level — NOT under families/{parentId})
   │  read-only Security Rule: request.auth != null; write:false
   │  .orderBy('sortOrder').get()   (one-time, per session)
   ▼
itemCatalogProvider : FutureProvider<List<ItemModel>>   (session cache)
   │  lookupById(itemId) → ItemModel?
   ├──► Shop System (#13)      (filters source != 'gacha')
   ├──► Gacha/Loot (#12)       (filters source in {gacha, both})
   ├──► Pet Equipment (#15)    (assetId + slot by itemId)
   └──► Pet Room Screen UI (#18) (Wardrobe grid)

path constant "items" lives in centralized path constants (ADR-0003 intent);
read pattern is this provider, NOT the mutation repository (scoped carve-out, §4).
```

### Key Interfaces
```dart
// NOT .autoDispose (see Decision §1). Default get() source is already serverAndCache.
final itemCatalogProvider = FutureProvider<List<ItemModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestorePaths.items)   // centralized path constant (ADR-0003 intent)
      .orderBy('sortOrder')
      .get();
  return snap.docs.map(ItemModel.fromFirestore).toList();
});

// Lookup accessor for Gacha/Pet Equipment (O(1) after building a Map once).
extension ItemCatalogLookup on List<ItemModel> {
  ItemModel? lookupById(String itemId);  // null → caller renders placeholder
}
```
`ItemModel`: `itemId, name, description, category('mochi_outfit'|'room_decoration'|'special'), slot('body_outfit'|'hat'|'accessory'|null), price(int), source('shop'|'gacha'|'both'), assetId, sortOrder`.

**`fromFirestore` parsing rules (implementation landmines — flame-specialist, 2026-07-07):**
- Type the factory parameter as `QueryDocumentSnapshot<Map<String, dynamic>>` (what `snap.docs` yields) — its `.data()` is guaranteed non-null, unlike `DocumentSnapshot.data()`.
- **`slot` MUST be `data['slot'] as String?`, NOT `as String`** — 12 of 30 MVP items (`room_decoration` + `special`) store `slot: null`; a non-nullable cast throws `TypeError` on ~40% of the catalog at load.
- **`price`/`sortOrder`: use `(data['price'] as num).toInt()`, NOT `as int`** — Firestore's wire format doesn't reliably preserve int-vs-double, so an admin-entered `10.0` or a JS/Python seed script writing a float would crash an `as int` cast.

## Alternatives Considered

### Alternative A: One-time cached `get()` + FutureProvider (chosen)
- **Description**: Fetch once per session, cache in a FutureProvider, serve all consumers from cache.
- **Pros**: Minimal Firestore reads (1 per session per device); matches the static nature of the data; simple; offline-capable via the persistence cache.
- **Cons**: Mid-session catalog additions aren't seen until restart (accepted — items don't need realtime).
- **Rejection Reason**: N/A — chosen.

### Alternative B: Realtime `snapshots()` on the catalog
- **Description**: A live listener so catalog edits appear instantly.
- **Pros**: New items appear without restart.
- **Cons**: Multiplies read cost for data that changes maybe monthly; no player-visible benefit; every consumer or a shared listener adds ongoing cost at scale.
- **Rejection Reason**: Cost with negligible benefit for static content.

### Alternative C: Bundle catalog as a local app asset (JSON)
- **Description**: Ship the catalog as a bundled JSON file, no Firestore read.
- **Pros**: Zero read cost; instant load; works fully offline from first launch.
- **Cons**: Content can't change without an app-store release; can't add seasonal/event items server-side; diverges from Gacha/Shop expecting a queryable source.
- **Rejection Reason**: Loses server-side content updates — a real constraint for an evolving catalog, even if MVP is small.

## Consequences

### Positive
- One Firestore read per session; no realtime cost for static data.
- Single cached source shared by 4 consumers; consistent item definitions everywhere.
- Read-only rules make catalog integrity a non-issue (clients can't corrupt it).

### Negative
- Mid-session catalog changes require a restart to appear (accepted).
- A narrow, documented exception to the repository-path rule (justified by the read-only global nature).

### Risks
- **Unseeded catalog** on first deploy → empty Shop. *Mitigation*: `[]` → empty state, no crash; seed script must run before launch (GDD open question — owner needed).
- **Post-cache-load missing item** (Gacha rolls a just-added item). *Mitigation*: `lookupById` → null → placeholder + optional re-fetch; corrects on restart. Consumer ADRs (Gacha) own this handling.
- **Stale cache vs. server** under offline persistence: **resolved** — the default `get()` source (`Source.serverAndCache`) already fetches fresh when online and falls back to cache offline. No `GetOptions` change needed.
- **`fromFirestore` cast crash** (implementation landmine): `slot as String` throws on the 12 null-slot items; `price/sortOrder as int` throws on float-typed values. *Mitigation*: parsing rules in Key Interfaces — `slot as String?`, `(x as num).toInt()`.
- **Accidental `.autoDispose`** on `itemCatalogProvider` would break session caching. *Mitigation*: Decision §1 states it explicitly; LP-CODE-REVIEW checklist item.
- **Path-rule drift**: a future dev might read `items/` ad-hoc, bypassing `itemCatalogProvider`. *Mitigation*: path constant centralized; the carve-out is registered so the rule's scope is explicit.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| item-database.md | Global (non-family-scoped) catalog collection `items/{itemId}` (TR-item-database-001) | Decision §1, §4 |
| item-database.md | One-time `get()` + session-cached FutureProvider, NOT `snapshots()` (TR-item-database-002) | Decision §1 |
| item-database.md | Security Rule: catalog read-only for authed users, write:false (TR-item-database-003) | Decision §2 |
| item-database.md | Catalog hard cap 500 items (MVP=30) before pagination (TR-item-database-004) | Constraints + Requirements; single-`get()` fine to 500, paginate beyond |

## Performance Implications
- **CPU**: One map/parse of ≤500 docs per session — trivial.
- **Memory**: Full catalog held in memory (≤500 small models) — negligible.
- **Load Time**: One `get()` on cold start (<2s on 4G per the GDD's AC); cache-served thereafter.
- **Network**: 1 read-set per session per device; zero mid-session.

## Migration Plan
Greenfield. No GDD sync required — the GDD already specifies this pattern (provider code, Security Rules, cap). The only reconciliation is architectural (the §4 carve-out), captured here and in the registry, not a GDD edit.

## Validation Criteria
- Integration: cold start with 30 seeded docs → provider returns 30 `ItemModel` ordered by `sortOrder` in <2s; subsequent navigation triggers no repeat `get()`.
- Unit: empty collection → `[]`, empty state renders, no crash.
- Unit: `lookupById` returns null for an unknown id (placeholder path), correct model for a known id.
- Rules test (emulator): unauthenticated read denied; any client write denied.
- Verify `GetOptions(source:)` behavior with persistence on (cold-start freshness vs. offline fallback).

## Related Decisions
- ADR-0003 (Firestore Schema) — the repository/path-constant rule this ADR carves a scoped read-only exception from.
- ADR-0002 (Auth) — the `request.auth != null` read gate.
- Shop (#13) / Gacha (#12) / Pet Equipment (#15) ADRs (upcoming) — consumers; own their own `source`/`slot` filtering.
- `design/gdd/item-database.md` — the ratified design.
