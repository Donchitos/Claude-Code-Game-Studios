# Agent Test Spec: unity-addressables-specialist

## Agent Summary
Domain: Addressable Asset System — groups, async loading/unloading, handle lifecycle management, memory budgeting, content catalogs, and remote content delivery.
Does NOT own: rendering systems (engine-programmer), game logic that uses the loaded assets (gameplay-programmer).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Addressables / asset loading / content catalogs / remote delivery)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
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
- Checks that the load succeeded (`handle.Status`) before using `Result`, and never releases a handle it does not hold (e.g., a character destroyed before its load was started)
- Uses `Addressables.Release(handle)` for loaded assets and reserves `Addressables.ReleaseInstance()` for `InstantiateAsync` results — does not mix the two

### Case 2: Out-of-domain redirect
**Input:** "Implement the rendering system that applies the loaded texture to the character mesh."
**Expected behavior:**
- Does NOT produce rendering or mesh material assignment code
- Explicitly states that rendering system implementation belongs to `engine-programmer`
- Redirects the request to `engine-programmer`
- Hands off the asset contract instead: the `Texture2D` comes from the handle's `Result` once the load succeeds, and stays valid only until the owning handle is released, so the consumer must not hold it past that point

### Case 3: Memory leak — un-released handle
**Input:** "Memory usage keeps climbing after each level load. We use Addressables to load level assets."
**Expected behavior:**
- Diagnoses the likely cause: `AsyncOperationHandle` objects not being released after use
- Identifies the handle leak pattern: loading assets into a local variable, losing reference, never calling `Addressables.Release()`
- Produces an auditing approach: pair every `LoadAssetAsync` with `Release()`, every `InstantiateAsync` with `ReleaseInstance()`, and every `LoadSceneAsync` with `UnloadSceneAsync()`
- Provides a corrected pattern: every active handle kept in a tracked collection and released when the level unloads, so nothing accumulates across level transitions
- Confirms the diagnosis with the Addressables Event Viewer (per-asset reference counts) or the Memory Profiler before concluding — does not assume the leak is elsewhere without evidence

### Case 4: Remote content delivery — catalog versioning
**Input:** "We need to support downloadable content updates without requiring a full app re-install."
**Expected behavior:**
- Produces the remote catalog update pattern documented in `docs/engine-reference/unity/plugins/addressables.md`:
  - `Addressables.CheckForCatalogUpdates()` on startup
  - `Addressables.UpdateCatalogs()` for detected updates
  - `Addressables.GetDownloadSizeAsync()` before downloading, then `Addressables.DownloadDependenciesAsync()` to pre-download the updated content
- Re-downloads only changed bundles; catalogs are versioned so clients fall back to cached content, and download failures retry with exponential backoff while showing progress
- Raises the mid-session case (a catalog update lands while a session is running) and asks the user which behavior they want, rather than silently picking one
- Plans the update-path tests: fresh install, V1 to V2, and V1 to V3 skipping V2
- Does NOT design the server-side CDN infrastructure (defers to devops-engineer)

### Case 5: Context pass — platform memory constraints
**Input:** Platform context: Nintendo Switch target, 4GB RAM, practical asset memory ceiling 512MB. Request: "Design the Addressables loading strategy for a large open-world level."
**Expected behavior:**
- References the 512MB memory ceiling from the provided context, and uses it in place of its own default console budget
- Designs a streaming strategy:
  - Additive scene streaming through `Addressables.LoadSceneAsync()` / `Addressables.UnloadSceneAsync()`, with groups organized per zone by loading context
  - A memory budget per active zone whose total stays under the 512MB ceiling, with zones unloaded on transition rather than accumulated
  - Essential zone content loaded first, optional content streamed after
- Defers where zone boundaries fall to `level-designer`
- Flags storage I/O speed on the target hardware as a load-time risk to verify on device, without quoting platform load speeds from memory
- Does NOT produce a loading strategy that would exceed the stated 512MB ceiling without flagging it

---

## Protocol Compliance

- [ ] Stays within declared domain (Addressables loading, handle lifecycle, memory, catalogs, remote delivery)
- [ ] Redirects rendering and gameplay asset-use code to engine-programmer and gameplay-programmer
- [ ] Returns structured output (loading patterns, handle lifecycle code, streaming zone designs)
- [ ] Always pairs `LoadAssetAsync` with a corresponding `Release()` — flags handle leaks as a memory bug
- [ ] Designs loading strategies against provided memory ceilings, which override its default per-platform budgets
- [ ] Specifies only the client-side contract (remote load path / URL structure, catalog versioning, cache-header requirement) and defers CDN hosting and the delivery pipeline to devops-engineer
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Handle lifecycle (Case 1) must include a test verifying memory is reclaimed after release
- Handle leak diagnosis (Case 3) should produce a findings report suitable for a bug ticket
- Platform memory case (Case 5) verifies the agent applies hard constraints from context, not default assumptions
