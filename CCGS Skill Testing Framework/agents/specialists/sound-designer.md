# Agent Test Spec: sound-designer

## Agent Summary
Domain: SFX specs, audio events, mixing parameters, and sound category definitions.
Does NOT own: music composition direction (audio-director), code implementation of audio systems.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references SFX / audio events / mixing)
- [ ] `tools:` list includes Read, Write, Edit, Glob, Grep — does NOT include engine code execution tools
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over music direction or audio code implementation, and names `audio-director` as the owner of music direction and composition

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create an SFX spec for a sword swing attack."
**Expected behavior:**
- Produces a complete SFX spec sheet including:
  - Description, reference sounds, frequency character, and duration
  - Volume range and spatial properties
  - Variation plan: number of variants, pitch randomization range (e.g., ±8%), and round-robin behavior
  - Audio event entry: what triggers it, priority, concurrency limit, and cooldown
  - Bus assignment for mixing (e.g., the combat SFX bus)
- Event name follows the project audio naming convention if one is established (e.g., `sfx_combat_sword_swing`)
- Does NOT create the audio files or write engine code; asks before writing the spec to a file

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Compose a looping ambient music track for the forest level."
**Expected behavior:**
- Does NOT produce music composition direction or a music brief, and does not create the audio itself
- Explicitly states that music direction belongs to `audio-director`
- Redirects the request to `audio-director`
- Anything it offers in place of the track is from its own domain — e.g., an ambience layer spec for the forest (base layer, detail sounds such as wind and wildlife, one-shots, transitions) to complement the music once its direction is set — never a music brief

### Case 3: Dynamic parameter — falloff curve spec
**Input:** "The sword swing SFX needs distance falloff so it sounds different across the arena."
**Expected behavior:**
- Documents the event's spatial properties for distance:
  - Parameter name (e.g., `distance` or `listener_distance`)
  - Falloff curve type (e.g., logarithmic, linear, custom)
  - Near/far distance thresholds with corresponding volume and high-frequency attenuation values
- Asks about behavior the request leaves unspecified (e.g., occlusion by arena geometry) rather than assuming it
- Does NOT write the audio engine integration code or change the audio middleware configuration

### Case 4: Naming convention conflict
**Input:** "Add a new SFX event called `SWORD_HIT_1` for the melee system." [Context includes the audio-director's naming convention: `[category]_[context]_[name]_[variant]`, e.g., `sfx_combat_sword_swing_01`.]
**Expected behavior:**
- Identifies that `SWORD_HIT_1` deviates from the naming convention in context
- Does NOT silently register the non-conforming name
- Flags the deviation explicitly with a compliant alternative (e.g., `sfx_combat_sword_hit_01`), naming `audio-director` as the owner of the convention
- Adds the event only once the user confirms the corrected name (or an explicit exception)

### Case 5: Context pass — uses audio style guide
**Input:** Audio style guide provided in context specifying: "gritty, grounded, no reverb tails over 1.5s, reference: The Witcher 3 combat audio." Request: "Create SFX specs for the full melee combat suite."
**Expected behavior:**
- References the "gritty, grounded" tone descriptor in the spec rationale
- Caps all reverb tail specifications at 1.5 seconds as stated
- Notes the reference material (The Witcher 3) as a benchmark for mix levels and transient design
- Does NOT produce specs that contradict the style guide (e.g., no ethereal or heavily reverb-processed specs); where a sound seems to need something the guide rules out, flags it for audio-director instead of deciding the sonic palette itself

---

## Protocol Compliance

- [ ] Stays within declared domain (SFX specs, event definitions, mixing parameters)
- [ ] Redirects music direction requests to audio-director
- [ ] Returns structured SFX specs (description, volume range, spatial properties, variants and pitch range, trigger/priority/concurrency, bus)
- [ ] Does not produce code for audio system implementation
- [ ] Flags deviations from an established naming convention or design doc explicitly rather than silently accepting non-conforming names
- [ ] References provided style guides and constraints in all spec output

---

## Coverage Notes
- SFX spec format (Case 1) should match whatever event schema the audio middleware (Wwise/FMOD/built-in) requires
- Falloff curve (Case 3) verifies the agent produces implementation-ready parameter specs
- Style guide compliance (Case 5) confirms the agent reads provided context and constrains output accordingly
