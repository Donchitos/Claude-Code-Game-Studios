# Unreal Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Unreal Engine 5.8 |
| **Release Date** | June 2026 |
| **Project Pinned** | 2026-08-16 |
| **Last Docs Verified** | 2026-08-16 |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Unreal Engine up to ~5.3. Versions 5.4, 5.5,
5.6, 5.7, and 5.8 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Unreal API calls.

> **UE 5.8 is the final planned UE5 release.** Epic has stated 5.8 closes out the
> UE5 roadmap as work ramps up on UE6. Prefer the production-ready 5.8 systems
> (MegaLights, Iris, Mutable) and fix deprecation warnings
> now rather than carrying them into a future UE6 migration.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 5.4 | ~Mid 2025 | HIGH | Motion Design tools, animation improvements, PCG enhancements |
| 5.5 | ~Sep 2025 | HIGH | MegaLights (massive dynamic light counts), animation authoring, MegaCity demo |
| 5.6 | ~Oct 2025 | MEDIUM | Performance optimizations, bug fixes |
| 5.7 | Nov 2025 | HIGH | PCG production-ready, Substrate production-ready, AI assistant |
| 5.8 | Jun 2026 | HIGH | MegaLights production-ready, Mesh Terrain, Lumen Lite, Iris production-ready, WASAPI audio default — final UE5 release |

## Major Changes from UE 5.3 to UE 5.8

### Breaking Changes
- **Substrate Material System**: New material framework (replaces legacy materials)
- **PCG (Procedural Content Generation)**: Production-ready, major API changes
- **MegaLights**: New lighting system — production-ready in 5.8 (hundreds of dynamic shadow-casting lights)
- **Animation Authoring**: New rigging and animation tools
- **WASAPI Audio Backend (5.8)**: Windows default audio backend switched from XAudio2 to WASAPI
- **Enhanced Input + CommonUI Unified (5.8)**: Single input system eliminating duplicate input assets
- **AI Assistant**: In-editor AI guidance (experimental), MCP Server plugin (5.8, experimental)

### New Features (Post-Cutoff)
- **MegaLights**: Dynamic lighting at massive scale — production-ready in 5.8, 60fps target on current-gen consoles
- **Lumen Lite (5.8, Beta)**: Medium-quality GI via Irradiance Fields — 2x faster than Lumen high quality, targets 60fps on PS5
- **Mesh Terrain (5.8, Experimental)**: Next-gen mesh-based terrain (caves, overhangs, overlapping geometry) built on Nanite + virtual textures
- **Substrate Materials**: Production-ready modular material system; NPR/toon shading experimental in 5.8
- **PCG Framework**: Production-ready in 5.7; 5.8 adds manual (non-destructive) editing, complex attributes, embedded subgraphs, GPU runtime performance parity with landscape grass
- **Iris Replication (5.8)**: Production-ready replacement replication system
- **Mutable (5.8)**: Production-ready character customization system
- **MetaHuman Collections / Crowd (5.8, Experimental)**: Hundreds of MetaHumans on mobile, thousands on high-end, via Mass + Nanite
- **Mass Framework Overhaul (5.8)**: Lock-free scheduling, sparse fragments, multi-core "MassCore" module
- **Audio Insights (5.8)**: Production-ready audio monitoring/debugging suite
- **AI Assistant**: In-editor AI help (experimental); MCP Server plugin for AI tool integration (5.8, experimental)

### Deprecated Systems
- **Legacy Material System**: Migrate to Substrate for new projects
- **Old PCG API**: Use new production-ready PCG API (5.7+)
- **XAudio2 (Windows)**: Now opt-in fallback — WASAPI is the default backend (5.8)
- **QueueSubtitle**: Replaced by `QueueSingleSubtitle` / `QueueSubtitlesFromAsset` (5.8)
- **Legacy replication path**: Iris is production-ready — evaluate for new multiplayer projects (5.8)

## Migration Notes — 5.7 → 5.8

No hard breaking changes: a well-structured 5.7 project compiles on 5.8, but with
deprecation warnings worth fixing before UE6. Key items:

- **Toolchain**: Visual Studio 2026 / MSVC v145 required — UBT rejects VS2022's v143 toolset
- **Build rules**: `DefaultBuildSettings = BuildSettingsVersion.V7`, `IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8` in `.Target.cs` files
- **Cleanup**: Delete `Binaries/`, `Intermediate/`, `DerivedDataCache/`, `.vs/`, `.sln`; regenerate project files; install the 5.8 VC++ redistributables if the built project won't launch
- **Audio**: WASAPI replaces XAudio2 as Windows default (opt-in config to restore XAudio2)
- **Zenserver**: `AllowRemoteNetworkService` renamed to `RemoteNetworkService` (enum: None/Unsecured/GeneratedStaticKey); Zen cooked-output store is now default
- **Animation**: Sequencer section looping redefined (completion-based); `KeepState`/`RestoreState` behavior changed
- **OpenXR**: Stereo layers now priority-ordered; `xr.OpenXRSortFaceLockedLayersAboveOtherLayers=1` restores pre-5.8 order
- **Plugins**: Inventory binary vs source plugins, bump `.uplugin` EngineVersion, full Blueprint compile pass, watch LogLinker

See `breaking-changes.md` and `deprecated-apis.md` for the full details.

## Verified Sources

- Official docs: https://docs.unrealengine.com/5.8/
- UE 5.8 release notes: https://dev.epicgames.com/documentation/unreal-engine/unreal-engine-5-8-release-notes
- What's new in 5.8: https://dev.epicgames.com/documentation/en-us/unreal-engine/whats-new
- UE 5.8 announcement: https://www.unrealengine.com/news/unreal-engine-5-8-is-now-available
- UE5 migration guide: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-migration-guide
- 5.7→5.8 C++ migration notes: https://jakubpradeniak.com/posts/dev-notes/migrating-unreal-engine-5-8-cpp-project/
