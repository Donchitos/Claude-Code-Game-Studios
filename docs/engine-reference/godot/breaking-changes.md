# Godot — Breaking Changes

Last verified: 2026-10-17 (4.6 → 4.7 and the section dates); 2026-02-12 (older sections)

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).

## 4.6 → 4.7 (Jun 2026 — POST-CUTOFF, HIGH RISK)

From the official migration guide
(https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html,
checked 2026-10-17). Rows marked **GDScript breaks** stop existing GDScript from
working; the rest add optional parameters, change C# compatibility only, or
change behaviour or defaults. The guide lists no deprecations.

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Overrides inherit a typed return | An override of a method with a typed return now inherits that type, so it needs an explicit `return` (add `return null` to fix the error). **GDScript breaks** |
| GDScript | Packed array element writes | Setting one element of a packed array no longer calls the setter of the whole packed-array property |
| GUI | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` renamed | Now `UPDATE_WIDTH_UNIT`. **GDScript breaks** |
| GUI | `RichTextLabel.add_image()` / `update_image()` | `width` / `height` are `float` (were `int`); `width_in_percent` / `height_in_percent` renamed `width_unit` / `height_unit`, typed `RichTextLabel.ImageUnit` (were `bool`, default `false` → `0`). C# source breaks |
| GUI | `Control.accessibility_live` type | `AccessibilityServer.AccessibilityLiveMode` (was `DisplayServer.AccessibilityLiveMode`). C# breaks |
| Core | `Object.is_class()` | Parameter is `StringName` (was `String`) |
| Core | `OptimizedTranslation.generate()` | Returns `bool` (was `void`). C# binary breaks |
| Input | Mouse and keyboard device IDs | Were `0`; now `InputEvent.DEVICE_ID_MOUSE` and `InputEvent.DEVICE_ID_KEYBOARD`, because some joypads use `0`. Identify events by type or compare `InputEvent.device` to those constants |
| Physics | Jolt: `WorldBoundaryShape3D` plane sign | The sign of `plane.d` is read the way Godot Physics reads it, so it is flipped compared to 4.6: negate it to keep 4.6 behaviour |
| Physics | Jolt: `SoftBody3D` mass and stiffness | Mass defaults to 1 kg for the whole body (was 1 kg per point); `linear_stiffness` is applied differently. Re-tune `linear_stiffness` and `damping_coefficient` on every `SoftBody3D` |
| Physics | Jolt: `Area3D` and `SoftBody3D` | `Area3D` now reports overlaps with `SoftBody3D`; use collision layers and masks to ignore them |
| Physics | `PhysicsServer2D.body_set_shape_as_one_way_collision()` | Optional `direction` added; `PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` requires it (extensions break) |
| Audio | `AudioStreamPlayer2D` / `AudioStreamPlayer3D` `area_mask` default | Changed from layer `1` to `0` (disabled). An `Area2D`/`Area3D` `audio_bus_override` that relied on the default mask stops working until the mask is set back to layer `1` |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` | Removed. **GDScript breaks** where it is used |
| Rendering | `CanvasItem` line drawing | No antialiasing feather is added, so lines look thinner; widen lines that relied on the old thickness |
| Rendering | `LinearToSRGB` visual shader node | No longer clamps to `[0.0, 1.0]` under Forward+ and Mobile |
| Rendering | `get_format()` moved | From `ImageTexture` / `PortableCompressedTexture2D` to base class `Texture2D` |
| Rendering | `RenderingServer.particles_request_process_time()` | `time` renamed `process_time`; optional `process_time_residual` added (also on `request_particles_process()` of the four particle nodes) |
| Rendering | Sky reflection roughness layers | `rendering/reflections/sky_reflections/roughness_layers` default `7` → `8` |
| Animation | `Animation.length` | Type metadata `double` (was `float`). C# breaks |
| Animation | `LookAtModifier3D.relative` | Default `false` (was `true`) |
| Animation | `AnimationNodeBlendSpace1D/2D.add_blend_point()` | Optional `name` added |
| Project | Stretch defaults for NEW projects | `display/window/stretch/mode` `canvas_items` (was `disabled`), `display/window/stretch/aspect` `expand` (was `keep`). Existing projects keep their settings |
| Text | `ResourceImporterDynamicFont.hinting` | Default `3` (was `1`) |
| Editor | `EditorSceneFormatImporter` import constants | Moved into the `ImportFlags` enum (`IMPORT_SCENE`, `IMPORT_ANIMATION`, …). C# source breaks |
| Editor | `EditorVCSInterface._commit()` | New `amend` parameter; VCS plugins break |
| Editor | Asset Library replaced by the Asset Store | The editor workspace is now "Asset Store" (release notes: https://godotengine.org/releases/4.7/) |
| XR | `OpenXRExtensionWrapper._on_register_metadata()` | New `interaction_profile_metadata` parameter; extensions break |

## 4.5 → 4.6 (Jan 2026 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics | Jolt is now the DEFAULT 3D physics engine | New projects use Jolt automatically. Existing projects keep their setting. Some HingeJoint3D properties (like `damp`) only work with GodotPhysics. |
| Rendering | Glow processes BEFORE tonemapping | Was after tonemapping. Scenes with glow will look different. Adjust intensity/blend in WorldEnvironment. |
| Rendering | AgX tonemapper new controls | White point and contrast parameters added. |
| Core | Quaternion initializes to identity | Was zero. Unlikely to affect most code but technically breaking. |
| UI | Dual-focus system | Mouse/touch focus now separate from keyboard/gamepad focus. Visual feedback differs by input method. |
| Animation | IK system fully restored | CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK via SkeletonModifier3D nodes. |
| Editor | New "Modern" theme default | Grayscale replaces blue-tint. Restore: Editor Settings → Interface → Theme → Style: Classic |
| Editor | "Select Mode" keybind changed | New "Select Mode" (v key) prevents accidental transforms. Old mode renamed "Transform Mode" (q key). |
| 2D | TileMapLayer scene tile rotation | Scene tiles can now be rotated like atlas tiles. |
| Localization | CSV plural form support | No longer requires Gettext for plurals. Context columns added. |
| C# | Automatic string extraction | Translation strings auto-extracted from C# code. |
| Plugins | New EditorDock class | Specialized container for plugin docks with layout control. |

## 4.4 → 4.5 (Sep 2025 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Variadic arguments added | Functions can accept `...` arbitrary params — new language feature |
| GDScript | `@abstract` decorator | Abstract classes and methods now enforceable |
| GDScript | Script backtracing | Detailed call stacks available even in Release builds |
| Rendering | Stencil buffer support | New capability for advanced visual effects |
| Rendering | SMAA 1x antialiasing | New post-processing AA option |
| Rendering | Shader Baker | Pre-compiles shaders — reportedly 20x faster startup on some demos |
| Rendering | Bent normal maps, specular occlusion | New material features |
| Accessibility | Screen reader support | Control nodes work with accessibility tools via AccessKit |
| Editor | Live translation preview | Test GUI layouts in different languages in-editor |
| Physics | 3D interpolation rearchitected | Moved from RenderingServer to SceneTree. API unchanged but internals differ. |
| Animation | BoneConstraint3D | New: AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D |
| Resources | `duplicate_deep()` added | New explicit method for deep duplication of nested resources |
| Navigation | Dedicated 2D navigation server | No longer a proxy to 3D navigation; smaller export for 2D games |
| UI | FoldableContainer node | New accordion-style container for collapsible UI sections |
| UI | Recursive Control behavior | Disable mouse/focus interactions across entire node hierarchies |
| Platform | visionOS export support | New platform target |
| Platform | SDL3 gamepad driver | Delegated gamepad handling to SDL library |
| Platform | Android 16KB page support | Required for Google Play targeting Android 15+ |

## 4.3 → 4.4 (Mar 2025 — BEFORE CUTOFF, VERIFY)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` | Parameter/return type changed from `Texture2D` to `Texture`; the shading language did not change |
| Particles | `.restart()` method | Added optional `keep_seed` parameter (CPU/GPU 2D/3D) |
| GUI | `RichTextLabel.push_meta` | Added optional `tooltip` parameter |
| GUI | `GraphEdit.connect_node` | Added optional `keep_alive` parameter |

## 4.2 → 4.3 (In Training Data — LOW RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Skeleton3D.add_bone` returns `int32` | Was `void` |
| Animation | `bone_pose_updated` signal | Replaced by `skeleton_updated` |
| TileMap | `TileMapLayer` replaces `TileMap` | One node per layer instead of multi-layer single node |
| Navigation | `NavigationRegion2D` | Removed `avoidance_layers`, `constrain_avoidance` properties |
| Editor | `EditorSceneFormatImporterFBX` | Renamed to `EditorSceneFormatImporterFBX2GLTF` |
| Animation | AnimationMixer base class | AnimationPlayer and AnimationTree now extend AnimationMixer |

## Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.7/ (4.6: https://godotengine.org/releases/4.6/)
- Releases and dates: https://github.com/godotengine/godot/releases
