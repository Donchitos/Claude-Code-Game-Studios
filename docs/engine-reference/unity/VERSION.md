# Unity Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Unity 6.3 LTS |
| **Release Date** | December 2025 |
| **Project Pinned** | 2026-02-13 |
| **Last Docs Verified** | 2026-02-13 |
| **Version Pin Re-checked** | 2026-08-18 — still current |
| **LLM Knowledge Cutoff** | May 2026 |

> **Pin re-checked 2026-08-18:** Unity 6.4 shipped as a **Supported** (non-LTS) release
> and has already reached end of life. **6.3 LTS remains the current LTS**, supported
> until December 2027, so the pin is unchanged. Only the version status was re-verified
> on this pass — the API content in this directory still carries its 2026-02-13
> verification date.

## Knowledge Gap Warning

The LLM's training data likely covers Unity through **~6.3 LTS**, which is the version
this project is pinned to — so for Unity there is currently **no version gap**, unlike
Godot and Unreal.

That does not make this directory redundant. The model's Unity knowledge is weighted
heavily toward the long 2019–2022 LTS era, so it still tends to reach for pre-Unity-6
idioms (legacy Input Manager, Resources.Load, built-in render pipeline assumptions,
pre-1.0 Entities APIs). Cross-reference `deprecated-apis.md` before accepting a
suggested Unity API, even though the version itself is inside the training window.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 6.0 | Oct 2024 | LOW (in training data) | Unity 6 rebrand, new rendering features, Entities 1.3, DOTS improvements |
| 6.1 | Nov 2024 | LOW (in training data) | Bug fixes, stability improvements |
| 6.2 | Dec 2024 | LOW (in training data) | Performance optimizations, new input system improvements |
| 6.3 LTS | Dec 2025 | MEDIUM (in training data) | First LTS since 6.0, production-ready DOTS, enhanced graphics features |
| 6.4 | 2026 | N/A — not adopted | Supported (non-LTS) release, now end-of-life. Stay on 6.3 LTS. |

## Major Changes from 2022 LTS to Unity 6.3 LTS

### Breaking Changes
- **Entities/DOTS**: Major API overhaul in Entities 1.0+, complete redesign of ECS patterns
- **Input System**: Legacy Input Manager deprecated, new Input System is default
- **Rendering**: URP/HDRP significant upgrades, SRP Batcher improvements
- **Addressables**: Asset management workflow changes
- **Scripting**: C# 9 support, new API patterns

### New Features (Post-Cutoff)
- **DOTS**: Production-ready Entity Component System (Entities 1.3+)
- **Graphics**: Enhanced URP/HDRP pipelines, GPU Resident Drawer
- **Multiplayer**: Netcode for GameObjects improvements
- **UI Toolkit**: Production-ready for runtime UI (replaces UGUI for new projects)
- **Async Asset Loading**: Improved Addressables performance
- **Web**: WebGPU support

### Deprecated Systems
- **Legacy Input Manager**: Use new Input System package
- **Legacy Particle System**: Use Visual Effect Graph
- **UGUI**: Still supported, but UI Toolkit recommended for new projects
- **Old ECS (GameObjectEntity)**: Replaced by modern DOTS/Entities

## Verified Sources

- Official docs: https://docs.unity3d.com/6000.0/Documentation/Manual/index.html
- Unity 6 release: https://unity.com/releases/unity-6
- Unity 6.3 LTS announcement: https://unity.com/blog/unity-6-3-lts-is-now-available
- Migration guide: https://docs.unity3d.com/6000.0/Documentation/Manual/upgrade-guides.html
- Unity 6 support: https://unity.com/releases/unity-6/support
- C# API reference: https://docs.unity3d.com/6000.0/Documentation/ScriptReference/index.html
