# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7 ("Lights, Camera, Action!") |
| **Release Date** | June 2026 |
| **Project Pinned** | 2026-08-18 |
| **Last Docs Verified** | 2026-08-18 |
| **LLM Knowledge Cutoff** | May 2026 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot through **4.6** (released January 2026).
**4.7 shipped in June 2026 and is the real gap** — it is the version this project is
pinned to, and the model has not seen it.

Treat any 4.7-specific API as unverified until checked against `breaking-changes.md`
or the official docs. The older 4.4/4.5/4.6 material in this directory is retained as
a cross-check, but those versions are now inside the training window rather than
beyond it.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | Mid 2025 | LOW (in training data) | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | Late 2025 | LOW (in training data) | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | MEDIUM (edge of training data) | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | Jun 2026 | **HIGH — POST-CUTOFF** | HDR output, AreaLight3D, Control offset transforms, inline shader previews, Android XR |

## What 4.7 Added

- **HDR output** on Windows, macOS, iOS, visionOS, and Linux (Wayland)
- **`AreaLight3D`** — rectangular light sources with softer shadows and more realistic reflections
- **Clearcoat** reworked to match the Disney PBR standard
- **`Control` offset transforms** — animate a Control without disturbing container layout
- **Inline text shader previews** — live visualization while editing shader code
- **`DrawableTexture2D`**, **`VirtualJoystick`** node, conic gradients in `GradientTexture2D`
- **3D vertex snapping**, `PopupMenu` search filtering, `Tree` drag-and-drop position indicators
- **Android XR and Steam Frame** production-ready; Android picture-in-picture; standalone
  Android export/publishing via GABE; initial Wayland touch support on Linux
- **New Asset Store**

## Freshness of This Directory

Refreshed on 2026-08-18 against the official 4.6→4.7 migration guide:
`VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`.

**`modules/*.md` were NOT re-verified** — they still carry `Last verified: 2026-02-12 |
Engine: Godot 4.6` headers and describe 4.6 behavior. Check `breaking-changes.md` for
4.7 deltas before trusting a module doc on rendering, physics, input, or animation.

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.7/
