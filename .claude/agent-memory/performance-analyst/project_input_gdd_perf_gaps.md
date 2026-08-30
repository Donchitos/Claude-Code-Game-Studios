---
name: project-input-gdd-perf-gaps
description: Performance gaps found in design/gdd/input.md AC 22 (latency gate) and missing Input budget category, from 2026-08-19 review
metadata:
  type: project
---

Reviewed `design/gdd/input.md` (Sistema de Input, "pendiente de review" as of 2026-08-19) for performance issues. Key open gaps as of that review:

- **AC 22** ("≤1 frame / ≤16.6ms latency, 0 eventos caídos, medido en 60s") has no stated instrumentation strategy for detecting *dropped* events — you can't measure the absence of a signal without an independent record of physical OS events (timestamp diffing or synthetic input injection). No test harness for this is described anywhere in the doc, and Dependencies explicitly says Input has zero upstream deps. This makes AC 22 currently unfalsifiable as a BLOQUEANTE gate.
- The GDD doesn't specify whether intent-signal emission happens synchronously inside `_input`/`_unhandled_input` or via a deferred call — this determines whether "same frame" is guaranteed by construction or just asserted.
- The project's standard Frame Time Budget report table (Gameplay Logic / Rendering / Physics / AI / Audio) has **no Input row**, despite Input carrying a hard latency AC. Escalated as a gap for `technical-director` to decide: fold into Gameplay Logic, or add a dedicated category.
- `technical-preferences.md` calls for an explicitly-designed gamepad cursor/selection system for console (not a straight remap), but `input.md` doesn't design it at all — so its render/update cost per frame is currently unknown and unbudgeted. Worth checking whether a later revision of input.md (or a new GDD) addresses this before implementation.

**Why**: input.md is Foundation-tier and gates Pilar 1 (Sacrificio con Peso) — a hero must never die from a dropped/laggy input. These gaps block a clean performance sign-off.

**How to apply**: If input.md comes back for review/implementation sign-off, check whether the AC 22 instrumentation approach and the Input budget-category question were resolved before treating the BLOQUEANTE gate as satisfied. Check for a gamepad-cursor design (this doc or a new one) before console input work starts.
