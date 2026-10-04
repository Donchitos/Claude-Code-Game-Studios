# Godot — Current Best Practices

Last verified: 2026-02-12 | Engine: Godot 4.6

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

Observed on Godot 4.6.1 with gdUnit4 6.1.3 — not in the docs:
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
- GDScript reference, lambda functions and rest parameters: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html

## Platform (4.5+)

- **visionOS export**: First new platform since open-sourcing (windowed app mode)
- **SDL3 gamepad driver**: Better cross-platform gamepad support
- **Android**: Edge-to-edge display, camera feed access, 16KB page support (Android 15+)
- **Linux**: Wayland subwindow support for multi-window capability
