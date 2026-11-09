# Godot — Current Best Practices

Last verified: 2026-10-17 (4.7 sections); 2026-02-12 (rest) | Engine: Godot 4.7

Practices that are **new or changed** since the model's training data (~4.3).
This supplements (not replaces) the agent's built-in knowledge.

## GDScript (4.5+)

- **Variadic arguments**: Functions can accept arbitrary parameter counts. The
  rest parameter is written `...name`, comes last, and is typed `Array` or left
  untyped — `values: Variant...` and `...values: Array[int]` do not parse
  ```gdscript
  func log_values(prefix: String, ...values: Array) -> void:
      for v in values:
          print(prefix, ": ", v)
  ```

- **Lambdas capture local variables by value** (every Godot 4 version): a local
  is captured once, when the lambda is created, and a lambda cannot reassign an
  outer local — `var hit := false` / `func(): hit = true` leaves the caller's
  `hit` false. Share state through a reference type (a Dictionary, an Array or
  an object) and mutate its contents. A rest parameter works in a lambda too, so
  `func(...args)` connects to a signal with any number of arguments (observed on
  4.6.1; a one-argument lambda on a zero-argument signal errors "Method expected
  1 argument(s), but called with 0")
  ```gdscript
  var state := {"emitted": false}
  some_signal.connect(func(...args): state.emitted = true)
  ```

- **Abstract classes and methods**: Use `@abstract` to enforce inheritance
  ```gdscript
  @abstract
  class_name BaseEnemy extends CharacterBody3D

  # No body: "a newline or a semicolon is expected after the function header".
  # Subclasses MUST override it.
  @abstract func get_attack_pattern() -> Array[Attack]
  ```

- **Script backtracing**: Detailed call stacks available even in Release builds

## GDScript (4.7)

- **An override of a typed method inherits its return type**, so it needs an
  explicit `return` statement; the migration guide's fix is `return null`
- **Writing one element of a packed array no longer calls the property's
  setter.** A setter on a `PackedInt32Array` (etc.) property no longer runs on
  `arr[i] = v`; assign the whole array where the setter has to run

## Physics (4.7)

- **Jolt `WorldBoundaryShape3D`**: the sign of `plane.d` now matches Godot
  Physics, flipped from 4.6. Negate it in scenes authored on 4.6
- **Jolt `SoftBody3D`**: mass is 1 kg for the whole body (was 1 kg per point)
  and `linear_stiffness` is applied differently; re-tune `linear_stiffness`
  and `damping_coefficient`. `Area3D` now reports `SoftBody3D` overlaps
- **Audio areas**: `area_mask` on `AudioStreamPlayer2D`/`3D` defaults to `0`
  (was layer `1`); set it to layer `1` where `audio_bus_override` areas are used

## Physics (4.6)

- **Jolt Physics is the default 3D engine** for new projects
  - Better determinism and stability than GodotPhysics3D
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics
  - Switch: Project Settings → Physics → 3D → Physics Engine
  - 2D physics unchanged (still Godot Physics 2D)

## Rendering (4.7)

- **`AreaLight3D`**: real-time rectangular area lights, instead of an emissive
  material plus global illumination
- **HDR output** on Windows, macOS, iOS, visionOS and Linux (Wayland)
- **`DrawableTexture2D`**: a simpler API for drawing onto textures
- **`CanvasItem` lines are drawn without an antialiasing feather**, so they look
  thinner than in 4.6; widen lines that relied on the old look
- The `LinearToSRGB` visual shader node no longer clamps to `[0.0, 1.0]` under
  Forward+ and Mobile

## Rendering (4.6)

- **Vulkan is still the Windows default driver**; D3D12 is opt-in through `rendering/rendering_device/driver.windows` (Godot source, main/main.cpp at 4.6, 4.7 and 4.7.2)
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

## Animation (4.7)

- **`Tween.tween_await()`** pauses a tween until a signal is emitted
- **`LookAtModifier3D.relative`** defaults to `false` (was `true`)

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

## UI and Input (4.7)

- **`Control.offset_transform_*`** (`offset_transform_enabled`,
  `offset_transform_position`, `offset_transform_rotation`,
  `offset_transform_scale`, …): a visual transform that containers do not
  reset, for hover and press animations inside containers
- **`RichTextLabel` images can size relative to the font**
  (`[img height=1em]…[/img]`); `add_image()` / `update_image()` take
  `width_unit` / `height_unit` (`RichTextLabel.ImageUnit`) in place of the
  `*_in_percent` booleans
- **`VirtualJoystick` node** for touch controls, with Fixed, Dynamic and
  Following modes
- **Mouse and keyboard events report `InputEvent.DEVICE_ID_MOUSE` /
  `DEVICE_ID_KEYBOARD`**, not device `0`; check the event type rather than
  `device == 0`
- **New projects stretch by default**: `display/window/stretch/mode` is
  `canvas_items` and `aspect` is `expand`. Projects created before 4.7 keep
  their settings

## Editor Workflow (4.7)

- **The Asset Store replaces the Asset Library**: the editor workspace is
  "Asset Store" (it was "AssetLib"), and addons such as gdUnit4 are installed
  from there
- Method, signal and property names show in a monospace font by default
  ("Use Monospace Font for Editor Symbols" turns it off)

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

## Command Line — Tests and Parse Check

Flags, from Godot's command-line tutorial: `--headless` (headless display and a
dummy audio driver, "useful for servers and with `--script`"), `--path <dir>`
(a directory holding `project.godot`), `-s`/`--script <script>`, `-d`/`--debug`
(the local stdout debugger), `--remote-debug <protocol>://<host>[:<port>]`,
`--import` (starts the editor, waits for the import, and quits),
`--quit-after <n>` (iterations), `--export-debug <preset>` (implies `--import`)
and `--check-only` (parse for errors and quit, with `--script`). The editor is
not on `PATH` by default: on Windows and Linux run the binary by its relative or
absolute path; on macOS run `Godot.app/Contents/MacOS/Godot` inside the bundle.

gdUnit4's runner is `res://addons/gdUnit4/bin/GdUnitCmdTool.gd`; `-a <dir|suite>`
adds suites, reports go to `res://reports/` by default (`-rd` changes it), and
the documented exit codes are 0 (all passed), 100 (failures) and 101 (warnings).
The command the framework uses:
`godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`.

gdUnit4 6.2.x lists Godot 4.5 to 4.7.1 as compatible in its README
(https://github.com/godot-gdunit-labs/gdUnit4#compatibility-overview, checked
2026-10-17); 4.7.2 is not listed there yet, but gdUnit4 6.2.2 runs on it. On
Windows, 2026-10-17, Godot 4.7.2 and 4.7.1 gave the same exits on the command
above: 0 pass, 100 fail, 101 orphans, 105 parse error, 0 with `No test cases
found` over none, and 1 before the first import.

Observed on Godot 4.6.1 with gdUnit4 6.1.3, and the exits again on 4.7.2 with
6.2.2 — not in the docs:
- 101 is also the exit when every test passed but a test leaked orphan nodes;
  105 means a test script does not parse; 103 means gdUnit4 refused to run
  headless (`--ignoreHeadlessMode` missing). 104 is gdUnit4 refusing a Godot
  older than 4.3 — not reproducible on the pin.
- Over zero tests the runner prints `No test cases found` and exits 0.
- Without `--remote-debug tcp://127.0.0.1:0`, a script error opens the `-d`
  debugger and the run waits at a `debug>` prompt; with it, every run prints two
  `ERROR:` lines about the remote port, which are expected.
- A fresh clone has no `.godot/` class cache: run
  `godot --headless --path . --import` first, or `GdUnitCmdTool.gd` does not
  load and the run exits 1 having run nothing.
- On 4.7.1 and 4.7.2 (Windows, 2026-10-17), that first `--import` of a fresh
  project crashed on exit (139, segmentation fault) in 3 of 17 runs, after
  writing the same `.godot/` files as a clean run; running it again exited 0.
  4.6.1 did not crash in 4 runs.
- `--check-only` with `-s <file>` exits 1 on valid code that names an autoload
  (`Identifier not found`), and `--import` / `--quit-after` exit 0 on a parse
  error — neither is a parse check. The framework's parse check is
  `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<file>.gd …`
  (exit 1 when a script does not load).
- On Windows, a quoted full path to the editor (`"C:/Program Files/Godot/…exe"`)
  runs from Git Bash with its stdout and exit code intact.

Sources:
- Command line tutorial: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- gdUnit4 command line tool: https://godot-gdunit-labs.github.io/gdUnit4/latest/advanced_testing/cmd/
- gdUnit4 releases: https://github.com/godot-gdunit-labs/gdUnit4/releases
- Godot 4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- Godot 4.7 release notes: https://godotengine.org/releases/4.7/
- GDScript reference, lambda functions and rest parameters: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html

## Platform (4.5+)

- **visionOS export**: First new platform since open-sourcing (windowed app mode)
- **SDL3 gamepad driver**: Better cross-platform gamepad support
- **Android**: Edge-to-edge display, camera feed access, 16KB page support (Android 15+)
- **Linux**: Wayland subwindow support for multi-window capability
