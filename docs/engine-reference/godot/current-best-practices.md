# Godot — Current Best Practices

Last verified: 2026-08-18 | Engine: Godot 4.7

Practices that are **new or changed** since the model's training data (~4.6).
This supplements (not replaces) the agent's built-in knowledge.

The 4.7 section below is the part the model has not seen. Sections tagged 4.5/4.6
are inside the training window and are kept as a consistency check.

## GDScript (4.7 — REQUIRED)

- **Every override declares its return type.** Untyped overrides of an inherited
  method no longer parse. This is the most common 4.7 upgrade failure.
  ```gdscript
  # ❌ Fails to parse in 4.7
  func _physics_process(delta):
      pass

  # ✅
  func _physics_process(delta: float) -> void:
      pass
  ```

- **Packed array element assignment does not invoke property setters.** If a setter
  needs to run, assign the whole array or call the setter explicitly.

## Input (4.7)

- **Never compare `event.device` to `0`.** Mouse and keyboard now report dedicated
  constants:
  ```gdscript
  if event.device == InputEvent.DEVICE_ID_MOUSE:
      ...
  elif event.device == InputEvent.DEVICE_ID_KEYBOARD:
      ...
  ```

## Rendering & Lighting (4.7)

- **`AreaLight3D`** for rectangular sources — softer shadows and more plausible
  reflections than faking it with a SpotLight3D and a large angle.
- **HDR output** is available on Windows, macOS, iOS, visionOS, and Linux (Wayland).
  Opt in per project; verify tonemapping on SDR displays before shipping.
- **Clearcoat** now follows the Disney PBR standard — existing clearcoat materials
  will look different and need re-tuning.
- `LinearToSRGB` in visual shaders no longer clamps to `[0.0, 1.0]`. Clamp explicitly
  if downstream nodes assume a normalized range.

## UI (4.7)

- **Animate `Control` offset transforms** instead of animating anchors or position
  when the node lives in a container — offsets no longer perturb container layout.
- `VirtualJoystick` is a built-in node now; drop custom touch-stick implementations.

## Audio (4.7)

- `AudioStreamPlayer.area_mask` defaults to **disabled**. Set it explicitly on any
  player that relies on `Area3D`-driven reverb or effect buses.

## GDScript (4.5+)

- **Variadic arguments**: Functions can accept arbitrary parameter counts
  ```gdscript
  func log_values(prefix: String, values: Variant...) -> void:
      for v in values:
          print(prefix, ": ", v)
  ```

- **Abstract classes and methods**: Use `@abstract` to enforce inheritance
  ```gdscript
  @abstract
  class_name BaseEnemy extends CharacterBody3D

  @abstract
  func get_attack_pattern() -> Array[Attack]:
      pass  # Subclasses MUST override
  ```

- **Script backtracing**: Detailed call stacks available even in Release builds

## Physics (4.6)

- **Jolt Physics is the default 3D engine** for new projects
  - Better determinism and stability than GodotPhysics3D
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics
  - Switch: Project Settings → Physics → 3D → Physics Engine
  - 2D physics unchanged (still Godot Physics 2D)

## Rendering (4.6)

- **D3D12 is the default backend on Windows** (was Vulkan) — for better driver compatibility
- **Glow now processes before tonemapping** with screen blending mode — existing glow setups may look different
- **SSR overhauled** — significant improvement in realism, stability, and performance
- **AgX tonemapper** — new white point and contrast controls

## Rendering (4.5)

- **Shader Baker**: Pre-compile shaders to eliminate startup hitching
- **SMAA 1x**: New AA option — sharper than FXAA, cheaper than TAA
- **Stencil buffer**: Available for advanced masking/portal effects
- **Bent normal maps**: Directional occlusion in normal map textures
- **Specular occlusion**: Ambient occlusion now affects reflections

## Accessibility (4.5+)

- **Screen reader support**: Control nodes integrate with accessibility tools via AccessKit
- **Live translation preview**: Test GUI layouts in different languages directly in-editor
- **FoldableContainer**: New accordion-style UI node for collapsible sections
- **Recursive Control disable**: Disable mouse/focus interactions for entire node hierarchies with a single property

## Animation (4.5+)

- **BoneConstraint3D**: Bind bones to other bones with modifiers
  - AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D

## Animation (4.6)

- **IK system fully restored**: Complete inverse kinematics reintroduced for 3D
  - Available modifiers: CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK
  - Applied via `SkeletonModifier3D` nodes

## Resources (4.5+)

- **`duplicate_deep()`**: Explicit deep duplication for nested resource trees
  - Old `duplicate()` behavior retained for backward compatibility
  - Use `duplicate_deep()` when you need per-instance copies of nested resources

## Navigation (4.5+)

- **Dedicated 2D navigation server**: No longer proxied through 3D NavigationServer
  - Reduces export binary size for 2D-only games

## UI (4.6)

- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
  - Visual feedback differs depending on input method
  - Consider this when designing custom focus behavior

## Editor Workflow (4.6)

- Flexible dock drag-and-drop with blue outline preview (including bottom panel)
- Most panels support floating windows (except Debugger)
- New keyboard shortcuts: Alt+O (Output), Alt+S (Shader)
- Export variable auto-generation: drag resource from FileSystem into script editor
- Live preview in Quick Open dialog when "Live Preview" enabled
- New "Select Mode" (v key) prevents accidental transforms; old mode renamed "Transform Mode" (q key)

## Tooling

- **ripgrep has no `gdscript` type**: `*.gd` is registered under `gap` (GAP programming language).
  `rg --type gdscript` is a hard error — the search never executes.
  Always use `rg --glob "*.gd"` (shell) or `glob: "*.gd"` (Grep tool) to filter GDScript files.

## Platform (4.5+)

- **visionOS export**: First new platform since open-sourcing (windowed app mode)
- **SDL3 gamepad driver**: Better cross-platform gamepad support
- **Android**: Edge-to-edge display, camera feed access, 16KB page support (Android 15+)
- **Linux**: Wayland subwindow support for multi-window capability
