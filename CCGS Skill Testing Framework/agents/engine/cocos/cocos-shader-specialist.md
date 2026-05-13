# Agent Test Spec: cocos-shader-specialist

## Agent Summary
Domain: Cocos Creator Effect file (`.effect`) authoring, `CCEffect` / `CCProgram` blocks, material configuration, built-in uniforms (`cc_matViewProj`, `cc_cameraPos`, etc.), Custom Render Pipeline (CRP), and texture compression per platform.
Does NOT own: gameplay code, art style direction, UI component layout.
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Effect / CCEffect / CCProgram / material / Custom Render Pipeline)
- [ ] `allowed-tools:` list includes Read, Write, Edit, Glob, Grep
- [ ] Model tier is Sonnet (default for specialists)
- [ ] Agent definition does not claim authority over gameplay code, art direction, or UI layout

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create a basic unlit Effect file that samples a main texture and applies a tint color."
**Expected behavior:**
- Produces a complete `.effect` file with:
  - `CCEffect` block declaring one `opaque` technique with one pass
  - `vert` and `frag` stages referencing `vs:vert` / `fs:frag` CCProgram blocks
  - `properties` block declaring `mainTexture` (default `white`) and `mainColor` (default `[1,1,1,1]` with `linear: true`)
- `CCProgram vs` block:
  - Does NOT declare `uniform Mat4 cc_matViewProj;` or other built-in uniforms — these are injected by the engine; redeclaration causes black screen
  - Declares `in vec3 a_position;` and `in vec2 a_texCoord;`
  - Outputs `v_uv` to fragment stage
  - Returns `cc_matViewProj * vec4(a_position, 1.0)` — uses built-in uniform directly without declaration
- `CCProgram fs` block:
  - Declares `uniform sampler2D mainTexture;` and `uniform vec4 mainColor;`
  - Samples `texture(mainTexture, v_uv)` and multiplies by `mainColor`
- Does NOT redefine built-in uniforms (`cc_matViewProj`, `cc_matWorld`, `cc_cameraPos`, etc.)
- Does NOT use `gl_FragColor` (WebGL 1 name) — uses declared `out vec4 fragColor` or CCProgram output convention

### Case 2: Out-of-domain redirect
**Input:** "Implement the player's health bar UI with a fill animation."
**Expected behavior:**
- Does NOT produce UI implementation code (UITransform, Layout, Widget)
- Explicitly states that UI implementation belongs to `cocos-ui-specialist`
- Redirects the request appropriately
- May note that a shader-based fill effect (e.g., a dissolve / clip-based fill) is within its domain if the visual effect itself is shader-driven

### Case 3: Built-in uniform misuse
**Input:** "Write a shader that defines `uniform Mat4 cc_matViewProj;` and uses it for the vertex transform."
**Expected behavior:**
- Identifies this as a critical error — `cc_matViewProj` is a built-in uniform injected by the engine
- States that redefining built-in uniforms causes a black screen / compilation error
- Lists the built-in uniforms that must NOT be redefined: `cc_matViewProj`, `cc_matWorld`, `cc_matWorldIT`, `cc_cameraPos`, `cc_time`, `cc_screenSize`, `cc_screenScale`, `cc_exposure`, `cc_mainLitDir`, `cc_mainLitColor`, `cc_ambientLit`
- Shows the correct pattern: use the built-in uniform directly without declaring it
- Provides the corrected Effect file snippet

### Case 4: Custom Render Pipeline (CRP) configuration
**Input:** "We're on Cocos Creator 3.8.6 and want to add a custom depth prepass before the opaque pass."
**Expected behavior:**
- Identifies this as a Custom Render Pipeline (CRP) scenario (3.8+ feature)
- Produces a `CustomRenderPipelineBuilder` subclass:
  - `setupCameras(cameras: Camera[])` method
  - Sets custom stages via `cam.setCustomStages(['MyDepthPrepass', 'MyOpaque', 'MyTransparent'])`
- Notes that Effect files must declare the matching `stage: MyDepthPrepass` in the pass definition
- Does NOT produce CRP code for pre-3.8 versions (CRP was not stabilized before 3.8)
- Confirms the project is on 3.8+ before providing CRP code

### Case 5: Texture compression per platform
**Input:** "Configure texture compression for a character atlas targeting iOS, Android, and WeChat Mini Game."
**Expected behavior:**
- Produces a per-platform compression table:
  - iOS: ASTC 4x4 or 6x6 (`.astc`)
  - Android: ETC2 (or ASTC for modern devices) (`.ktx`)
  - WeChat Mini Game: ETC2 (`.ktx`) — PVRTC as fallback for older devices
- Notes that configuration is in **Asset Import Settings → Texture Compression → Platform Overrides**
- Warns against leaving defaults (uncompressed PNG → huge bundle sizes, especially for mini-game)
- Does NOT recommend PVRTC as the only option (deprecated for iOS; ASTC is modern standard)

---

## Protocol Compliance

- [ ] Stays within declared domain (Effect files, materials, CRP, texture compression, built-in uniforms)
- [ ] Redirects gameplay and UI code to appropriate agents
- [ ] Returns structured output (Effect file content, CRP builder classes, compression tables)
- [ ] Never redefines built-in engine uniforms in Effect files
- [ ] Distinguishes between pre-3.8 and 3.8+ CRP APIs — never produces CRP code without version confirmation
- [ ] Always includes `linear: true` for color properties in `CCEffect` blocks

---

## Coverage Notes
- Basic Effect (Case 1) verifies the agent produces correct CCEffect / CCProgram structure
- Built-in uniform misuse (Case 3) confirms the agent catches a critical shader authoring error
- CRP (Case 4) verifies the agent applies 3.8+ specific APIs correctly
- Texture compression (Case 5) confirms the agent understands per-platform constraints, not just generic shader knowledge
