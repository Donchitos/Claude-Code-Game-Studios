# Unreal Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Unreal Engine 5.8 |
| **Release Date** | June 2026 |
| **Project Pinned** | 2026-08-18 |
| **Last Docs Verified** | 2026-08-18 |
| **LLM Knowledge Cutoff** | May 2026 |

> **5.8 is the last planned major Unreal Engine 5 release.** Epic has stated it is
> ramping up work on UE6 and will keep UE5 on bug-fix and regression support, with
> another release only if circumstances warrant it. Plan long-lived projects with
> a UE6 migration in mind rather than assuming a 5.9.

## Knowledge Gap Warning

The LLM's training data likely covers Unreal Engine through **5.7** (released
November 2025). **5.8 shipped in June 2026 and is the real gap** — it is the version
this project is pinned to, and the model has not seen it.

The 5.4–5.7 material in this directory is retained as a cross-check, but those
versions are now inside the training window rather than beyond it.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 5.4 | Mid 2025 | LOW (in training data) | Motion Design tools, animation improvements, PCG enhancements |
| 5.5 | Sep 2025 | LOW (in training data) | Megalights (experimental), animation authoring |
| 5.6 | Oct 2025 | LOW (in training data) | Performance optimizations, bug fixes |
| 5.7 | Nov 2025 | MEDIUM (edge of training data) | PCG production-ready, Substrate production-ready, AI assistant |
| 5.8 | Jun 2026 | **HIGH — POST-CUTOFF** | Megalights + Iris production-ready, Lumen Lite, Mesh Terrain, WASAPI audio default |

## What 5.8 Added

**Rendering**
- **Megalights → Production Ready** — reduced noise, performance tuned for 60fps
- **Lumen Lite** — medium-quality global illumination, roughly 2× faster than
  Lumen high quality; aimed at handhelds and lower-spec targets
- **Toon Shader** for stylized rendering
- X-Rite AxF material support (automotive / industrial visualization)

**Worldbuilding**
- **Mesh Terrain (Experimental)** — mesh-based landscape replacing the heightfield-only
  constraint, so cliffs, overhangs, and caves are authorable in the terrain system
- **Procedural Vegetation Editor** for biologically accurate vegetation authoring
- Fast Geometry Streaming enhancements; HLOD UX improvements (batched deletion,
  perceptual-difference heuristics)

**Character & Animation**
- Modular Control Rig hierarchy management improvements
- **Control Rig Physics → Beta** (force-based)
- New **Control Rig Dynamics** plugin — reported ~5× runtime performance improvement
- Direct Mesh Controls — animators manipulate character surfaces directly
- MetaHuman Animator now available on Linux and macOS

**Framework & Networking**
- **Iris replication → Production Ready**
- Mass Framework overhaul with better multi-core CPU utilization
- StateTree gains flexible starting-state definitions

**Audio**
- **WASAPI replaces XAudio2 as the default Windows audio backend** — see
  `breaking-changes.md`, this is a behavioral change for shipped audio setups
- Audio Insights → Production Ready, with loudness metering
- Audio subtitles; Waveform Editor improvements

**Platform & Tooling**
- iOS and iPadOS support keyboard and mouse input
- Android controller mapping improvements
- MCP plugin connecting large language models directly to the engine

## Freshness of This Directory

Refreshed on 2026-08-18 against the 5.8 release notes and announcement:
`VERSION.md` and the 5.7 → 5.8 section of `breaking-changes.md`.

**`modules/*.md`, `plugins/*.md`, `PLUGINS.md`, `deprecated-apis.md`, and
`current-best-practices.md` were NOT re-verified against 5.8** — they carry their own
`Last verified: 2026-02-13` headers and describe 5.7. Epic's 5.8 release notes do not
publish a consolidated deprecation list, so treat those files as 5.7-accurate and
confirm anything version-sensitive against the official 5.8 docs.

## Verified Sources

- Official docs: https://dev.epicgames.com/documentation/en-us/unreal-engine
- UE 5.8 release notes: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes
- UE 5.8 announcement: https://www.unrealengine.com/news/unreal-engine-5-8-is-now-available
- UE 5.8 release thread: https://forums.unrealengine.com/t/unreal-engine-5-8-released/2729274
- UE 5.7 release notes: https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-7-release-notes
