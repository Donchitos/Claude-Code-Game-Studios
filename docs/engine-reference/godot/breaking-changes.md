# Godot — Breaking Changes

Last verified: 2026-08-18

Changes between Godot versions. With the current model cutoff (May 2026), the section
that matters most is **4.6 → 4.7** — everything below it is inside the training window
and is kept as a cross-check.

## 4.6 → 4.7 (Jun 2026 — POST-CUTOFF, HIGH RISK)

The model has not seen this release. Verify anything 4.7-specific.

### Signature & Type Changes

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `Object.is_class()` | Parameter type `String` → `StringName` |
| Core | `OptimizedTranslation.generate()` | Return type `void` → `bool` |
| Core | `ZIPPacker.start_file()` | Added optional `permissions` and `modified_time` parameters |
| GUI | `Control.accessibility_live` | Type `DisplayServer.AccessibilityLiveMode` → `AccessibilityServer.AccessibilityLiveMode` |
| GUI | `RichTextLabel.ImageUpdateMask` | Enum field `UPDATE_WIDTH_IN_PERCENT` renamed to `UPDATE_WIDTH_UNIT` |
| GUI | `RichTextLabel.add_image()` / `update_image()` | Width/height params `int` → `float`; `width_in_percent`/`height_in_percent` renamed to `width_unit`/`height_unit` and retyped to `RichTextLabel.ImageUnit` |
| Rendering | `ImageTexture.get_format()`, `PortableCompressedTexture2D.get_format()` | Moved up to the `Texture2D` base class |
| Rendering | `RenderingServer.particles_request_process_time()` | Param `time` renamed to `process_time`; added optional `process_time_residual` |
| Particles | `CPUParticles2D/3D`, `GPUParticles2D/3D` `request_particles_process()` | Added optional `process_time_residual` parameter |
| Animation | `Animation.length` | Property type metadata `float` → `double` |
| Animation | `AnimationNodeBlendSpace1D/2D.add_blend_point()` | Added optional `name` parameter |
| Physics | `PhysicsServer2D.body_set_shape_as_one_way_collision()` | Added optional `direction` parameter |
| Physics | `PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` | Added **mandatory** `direction` parameter — breaks custom physics extensions |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` | Property **removed entirely** |
| XR | `OpenXRExtensionWrapper._on_register_metadata()` | Added **mandatory** `interaction_profile_metadata` parameter |
| XR | `OpenXRSpatialAnchorCapability.create_new_anchor()` | Added optional `next` parameter |
| Editor | `EditorSceneFormatImporter` | Seven `IMPORT_*` constants moved into an `ImportFlags` enum |
| Editor | `EditorVCSInterface._commit()` | Added **mandatory** `amend` parameter |

### Behavior Changes (No Signature Change — Silent Breakage)

| Subsystem | Change | Impact |
|-----------|--------|--------|
| GDScript | Inherited method overrides must explicitly declare return types | Existing subclasses that omitted the return type now fail to parse. Most likely source of upgrade errors. |
| GDScript | Packed array element assignment no longer invokes property setters | Code relying on a setter firing on `packed_array[i] = x` silently stops working |
| Input | Mouse/keyboard device IDs changed from `0` to `InputEvent.DEVICE_ID_MOUSE` / `InputEvent.DEVICE_ID_KEYBOARD` | Any `event.device == 0` check is now wrong |
| Rendering | `LinearToSRGB` visual shader no longer clamps to `[0.0, 1.0]` (Mobile and Forward+) | Shader output can exceed the old range |
| Rendering | Line drawing feather removed | Line thickness appearance changes |
| Audio | `AudioStreamPlayer.area_mask` now defaults to disabled (was layer 1) | Area-based audio effects stop applying unless the mask is set explicitly |
| Physics (Jolt) | `WorldBoundaryShape3D` plane distance signs, `SoftBody3D` mass calculation, and stiffness application all changed | Jolt scenes need re-tuning |

### Changed Defaults

| Setting | Old | New |
|---------|-----|-----|
| Display stretch mode | `disabled` | `canvas_items` |
| Sky reflections roughness layers | 7 | 8 |
| Font hinting | 1 | 3 |

## 4.5 → 4.6 (Jan 2026 — EDGE OF TRAINING DATA, VERIFY)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics | Jolt is now the DEFAULT 3D physics engine | New projects use Jolt automatically. Existing projects keep their setting. Some HingeJoint3D properties (like `damp`) only work with GodotPhysics. |
| Rendering | Glow processes BEFORE tonemapping | Was after tonemapping. Scenes with glow will look different. Adjust intensity/blend in WorldEnvironment. |
| Rendering | D3D12 default on Windows | Was Vulkan. For better driver compatibility. |
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

## 4.4 → 4.5 (Late 2025 — IN TRAINING DATA, LOW RISK)

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

## 4.3 → 4.4 (Mid 2025 — IN TRAINING DATA, LOW RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | Shader texture types | Parameter/return types changed from `Texture2D` to `Texture` |
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
