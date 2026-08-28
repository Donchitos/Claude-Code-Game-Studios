# Cocos Creator — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Cocos Creator 3.8.6 |
| **Release Date** | April 2026 |
| **Project Pinned** | 2026-06-27 |
| **Last Docs Verified** | 2026-06-27 |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Cocos Creator up to ~3.8.0 / early 3.8.x.
Versions 3.8.4+ introduced changes that the model may NOT know about.
Always cross-reference this directory before suggesting Cocos Creator API calls.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 3.8.0 | Late 2023 | LOW | Procedural Animation, High Precision Text, Custom Render Pipeline, Character Controller (in training data) |
| 3.8.1–3.8.3 | 2024 | LOW–MEDIUM | Bug fixes and minor improvements |
| 3.8.4 | Late 2024 | MEDIUM | Stability improvements, minor API additions |
| 3.8.5 | Early 2025 | MEDIUM | Performance work, shader improvements |
| 3.8.6 | April 2026 | HIGH | Bundle size optimization, Spine 4.2, UISkew, Node.x/y/z accessors, Box2D C++ native, HarmonyOS Next |
| 3.8.7+ | In development | HIGH | Bundle/perf continued, prefab multi-tab, AI-friendly editor plugins |

## Major Themes Since 3.8.0

- **3.8.6 size optimization** — "Compress engine internal properties" feature (160KB savings), fine-grained 2D module stripping (RichText, Mask, Graphics, UISkew, AffineTransform), multi-preset feature cropping per platform
- **3.8.6 Spine upgrade** — Spine 4.2 support (alongside Spine 3.8), Spine physics, shared texture atlas
- **3.8.6 physics** — Box2D JSB (C++ native) variant for 2D physics, significant iOS performance gain (no JIT)
- **3.8.6 platform** — Honor Mini Game added, HarmonyOS Next perf/memory/power improvements, ArkTS↔engine communication completed, WebGPU support strengthened
- **3.8.6 type safety** — Generic `getComponent<T>()`, `isValid` type safety, `js.isNumber` / `js.isString` improvements, `UIComponent` type restored (no more `as any`)

## Verified Sources

- Official docs: https://docs.cocos.com/creator/3.8/manual/en/
- v3.0 upgrade guide: https://docs.cocos.com/creator/3.8/manual/en/release-notes/upgrade-guide-v3.0.html
- Asset Manager upgrade: https://docs.cocos.com/creator/3.8/manual/en/asset/asset-manager-upgrade-guide.html
- Release notes (CN): https://www.cocos.com/creator-download
- Engine source: https://github.com/cocos/cocos-engine
- Forum: https://forum.cocos.org/
