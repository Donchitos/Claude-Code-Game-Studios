# Agent Test Spec: unity-addressables-specialist

## Agent Summary
Domain: Addressable Asset System — groups, async loading/unloading, handle lifecycle management, memory budgeting, content catalogs, and remote content delivery.
Does NOT own: rendering systems (engine-programmer), game logic that uses the loaded assets (gameplay-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Addressables / asset loading / content catalogs / remote delivery)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over rendering systems or gameplay using the loaded assets

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Load a character texture asynchronously and release it when the character is destroyed."
**Expected behavior:**
- Produces the `Addressables.LoadAssetAsync<Texture2D>()` call pattern
- Stores the returned `AsyncOperationHandle<Texture2D>` in the requesting object
- On character destruction (`OnDestroy()`), calls `Addressables.Release(handle)` with the stored handle
- Does NOT use `Resources.Load()` as the loading mechanism
- Notes that releasing with a null or uninitialized handle causes errors — includes a validity check
- Notes the difference between releasing the handle vs. releasing the asset (handle release is correct)

### Case 2: Out-of-domain redirect
**Input:** "Implement the rendering system that applies the loaded texture to the character mesh."
**Expected behavior:**
- Does NOT produce rendering or mesh material assignment code
- Explicitly states that rendering system implementation belongs to `engine-programmer`
- Redirects the request to `engine-programmer`
- May describe the asset type and API surface it will provide (e.g., `Texture2D` reference once the handle completes) as a handoff spec

### Case 3: Memory leak — un-released handle
**Input:** "Memory usage keeps climbing after each level load. We use Addressables to load level assets."
**Expected behavior:**
- Diagnoses the likely cause: `AsyncOperationHandle` objects not being released after use
- Identifies the handle leak pattern: loading assets into a local variable, losing reference, never calling `Addressables.Release()`
- Produces an auditing approach: search for all `LoadAssetAsync` / `LoadSceneAsync` calls and verify matching `Release()` calls
- Provides a corrected pattern using a tracked handle list (`List<AsyncOperationHandle>`) with a `ReleaseAll()` cleanup method
- Does NOT assume the leak is elsewhere without evidence

### Case 4: Remote content delivery — catalog versioning
**Input:** "We need to support downloadable content updates without requiring a full app re-install."
**Expected behavior:**
- Produces the remote catalog update pattern:
  - `Addressables.CheckForCatalogUpdates()` on startup
  - `Addressables.UpdateCatalogs()` for detected updates
  - `Addressables.DownloadDependenciesAsync()` to pre-warm the updated content
- Notes catalog hash checking for change detection
- Addresses the edge case: what happens if a player starts a session, the catalog updates mid-session — defines behavior (complete current session on old catalog, reload on next launch)
- Does NOT design the server-side CDN infrastructure (defers to devops-engineer)

### Case 5: Context pass — platform memory constraints
**Input:** Platform context: Nintendo Switch target, 4GB RAM, practical asset memory ceiling 512MB. Request: "Design the Addressables loading strategy for a large open-world level."
**Expected behavior:**
- References the 512MB memory ceiling from the provided context
- Designs a streaming strategy:
  - Divide the world into addressable zones loaded/unloaded based on player proximity
  - Defines a memory budget per active zone (e.g., 128MB, max 4 zones active)
  - Specifies async pre-load trigger distance and unload distance (hysteresis)
- Notes Switch-specific constraints: slower load times from SD card, recommend pre-warming adjacent zones
- Does NOT produce a loading strategy that would exceed the stated 512MB ceiling without flagging it

---

## Protocol Compliance

- [ ] Stays within declared domain (Addressables loading, handle lifecycle, memory, catalogs, remote delivery)
- [ ] Redirects rendering and gameplay asset-use code to engine-programmer and gameplay-programmer
- [ ] Returns structured output (loading patterns, handle lifecycle code, streaming zone designs)
- [ ] Always pairs `LoadAssetAsync` with a corresponding `Release()` — flags handle leaks as a memory bug
- [ ] Designs loading strategies against provided memory ceilings
- [ ] Does not design CDN/server infrastructure — defers to devops-engineer for server side

---

## Coverage Notes
- Handle lifecycle (Case 1) must include a test verifying memory is reclaimed after release
- Handle leak diagnosis (Case 3) should produce a findings report suitable for a bug ticket
- Platform memory case (Case 5) verifies the agent applies hard constraints from context, not default assumptions
