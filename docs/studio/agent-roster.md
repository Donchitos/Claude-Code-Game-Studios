# Role Profile Roster

The repository contains 49 role profiles under `roles/`. Each file is an
injectable prompt profile for a generic delegated Codex agent. Profiles are not
registered custom agent types, do not select a fixed model, and do not grant
tools or permissions by themselves.

## How To Use A Profile

Give the delegated agent:

1. The relevant `roles/<name>.md` profile.
2. A bounded objective and owned files.
3. Required project context and applicable `AGENTS.md` files.
4. Expected evidence, output format, and verification.
5. Explicit write authority, or a read-only instruction.

The coordinating agent validates the result and remains responsible for scope,
user approval, implementation, and final review.

## Leadership And Department Direction

| Profile | Focus |
|---|---|
| `creative-director` | Creative vision, pillars, cross-discipline trade-offs |
| `technical-director` | Technical strategy, architecture, feasibility, performance risk |
| `producer` | Scope, schedule, dependencies, milestones, delivery risk |
| `art-director` | Visual direction, art standards, asset consistency |
| `audio-director` | Audio identity, music and sound direction, production priorities |
| `narrative-director` | Narrative vision, structure, tone, canon decisions |
| `game-designer` | Overall mechanics, player experience, systems coherence |
| `lead-programmer` | Implementation architecture, code standards, engineering coordination |
| `qa-lead` | Test strategy, release evidence, quality risk |
| `release-manager` | Release coordination, build readiness, rollback planning |

## Design, Content, And Player Experience

| Profile | Focus |
|---|---|
| `systems-designer` | Mechanics, loops, formulas, progression interactions |
| `level-designer` | Spaces, encounters, pacing, navigation, difficulty flow |
| `economy-designer` | Resources, rewards, pricing, sinks, progression balance |
| `live-ops-designer` | Events, seasons, retention loops, live content cadence |
| `writer` | Dialogue, lore, item text, moment-to-moment narrative content |
| `world-builder` | Setting rules, factions, history, geography, canon |
| `ux-designer` | User flows, interaction patterns, usability, accessibility |
| `sound-designer` | Sound effects, event lists, implementation and mix notes |
| `localization-lead` | Internationalization, translation readiness, locale quality |
| `community-manager` | Player communication, feedback synthesis, community health |

## Engineering, QA, And Operations

| Profile | Focus |
|---|---|
| `gameplay-programmer` | Player mechanics, combat, interactive game systems |
| `engine-programmer` | Core runtime systems, engine integration, low-level performance |
| `ai-programmer` | NPC behavior, navigation, decision systems, AI debugging |
| `network-programmer` | Replication, authority, latency handling, matchmaking |
| `tools-programmer` | Editor tools, importers, pipeline utilities, debug tooling |
| `ui-programmer` | Screens, widgets, data binding, input and UI performance |
| `technical-artist` | Shaders, VFX, asset pipelines, art-performance trade-offs |
| `performance-analyst` | Profiling, budgets, bottleneck analysis, optimization evidence |
| `devops-engineer` | CI/CD, builds, packaging, deployment automation |
| `analytics-engineer` | Telemetry design, event quality, dashboards, experiments |
| `security-engineer` | Abuse cases, save/network security, secrets, exploit review |
| `qa-tester` | Test execution, reproduction, exploratory testing, bug evidence |
| `prototyper` | Time-boxed experiments and feasibility validation |
| `accessibility-specialist` | Inclusive interaction, remapping, visual/audio accessibility |

## Engine Generalists

| Profile | Focus |
|---|---|
| `unreal-specialist` | Unreal Engine project structure and idiomatic implementation |
| `unity-specialist` | Unity architecture, packages, rendering, performance patterns |
| `godot-specialist` | Godot scenes, nodes, resources, signals, project architecture |

## Unreal Specialists

| Profile | Focus |
|---|---|
| `ue-blueprint-specialist` | Blueprint architecture, graph standards, C++ boundaries |
| `ue-gas-specialist` | Gameplay Ability System, effects, attributes, prediction |
| `ue-replication-specialist` | Unreal replication, RPC validation, relevancy, bandwidth |
| `ue-umg-specialist` | UMG, CommonUI, input routing, widget performance |

## Unity Specialists

| Profile | Focus |
|---|---|
| `unity-addressables-specialist` | Addressables groups, loading, memory, content delivery |
| `unity-dots-specialist` | Entities, Jobs, Burst, hybrid workflows |
| `unity-shader-specialist` | Shader Graph, VFX Graph, render-pipeline customization |
| `unity-ui-specialist` | UI Toolkit, UGUI, layout, input, accessibility |

## Godot Specialists

| Profile | Focus |
|---|---|
| `godot-gdscript-specialist` | Typed GDScript, signals, coroutines, performance |
| `godot-csharp-specialist` | Godot .NET patterns, signals, async, nullable types |
| `godot-shader-specialist` | Godot shaders, particles, rendering, post-processing |
| `godot-gdextension-specialist` | Native extensions, bindings, custom nodes, build systems |

For common collaboration patterns, see `agent-coordination-map.md` and
`coordination-rules.md`.
