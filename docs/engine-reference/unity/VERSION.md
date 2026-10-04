# Unity Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Unity 6.3 LTS |
| **Installed at pin time** | NOT DETERMINED — `/setup-engine` §3 probes the installed editor and records the result here. |
| **Release Date** | December 2025 |
| **Project Pinned** | 2026-02-13 |
| **Last Docs Verified** | 2026-02-13 |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Unity up to ~2022 LTS (2022.3). The entire
Unity 6 release series (formerly Unity 2023 Tech Stream) introduced significant
changes that the model does NOT know about. Always cross-reference this directory
before suggesting Unity API calls.

## Installed-Version Gap Warning

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
installed editor**, and an agent citing it correctly then emits APIs that do not
compile locally. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

## Post-Cutoff Version Timeline

<!-- timeline-unverified -->

> **⚠ THIS TABLE IS INTERNALLY INCONSISTENT AND MUST NOT BE TRUSTED FOR RISK
> JUDGEMENTS UNTIL RE-VERIFIED (flagged 2026-08-10).** It is titled
> *Post-Cutoff* and the stated cutoff above is **May 2025**, yet three of its four
> rows are dated **Oct, Nov and Dec 2024** — before that cutoff — followed by a
> twelve-month gap to 6.3 in Dec 2025. Both cannot be right. The sibling files
> `godot/VERSION.md` and `unreal/VERSION.md` list only genuinely post-cutoff
> versions, so this is a defect in this file, not in the format.
>
> **Why it matters more than a wrong date.** This table's entire job is to tell an
> agent what it does *not* already know. Rows that predate the cutoff invert that
> signal: take an installed `6000.1.0f1` (**Unity 6.1**) — this
> table dates it to Nov 2024 and labels it post-cutoff MEDIUM risk, while by its own
> cutoff a Nov 2024 release would be *inside* training data. An agent reading this
> either over-trusts the reference or mis-scopes what is new, and the `6.2+`
> boundaries cited elsewhere in this directory are anchored to these rows.
>
> **The dates are NOT corrected here, deliberately.** Real Unity release dates
> cannot be sourced from this repo — this directory *is* the source — and writing
> them from training data is the failure this whole directory exists to prevent
> (`/security-audit` makes the same call). Re-verify against Unity's
> published release notes and update the row dates, the `Release Date` field, and
> `Last Docs Verified` together. Until then, treat every version-qualified claim in
> `docs/engine-reference/unity/` as **unconfirmed**, and prefer APIs that are not
> version-boundary-dependent.

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 6.0 | Oct 2024 | HIGH | Unity 6 rebrand, new rendering features, Entities 1.3, DOTS improvements |
| 6.1 | Nov 2024 | MEDIUM | Bug fixes, stability improvements |
| 6.2 | Dec 2024 | MEDIUM | Performance optimizations, new input system improvements |
| 6.3 LTS | Dec 2025 | HIGH | First LTS since 6.0, production-ready DOTS, enhanced graphics features |

## Major Changes from 2022 LTS to Unity 6.3 LTS

### Breaking Changes
- **Entities/DOTS**: Major API overhaul in Entities 1.0+, complete redesign of ECS patterns
- **Input System**: Legacy Input Manager deprecated, new Input System is default
- **Rendering**: URP/HDRP significant upgrades, SRP Batcher improvements
- **Addressables**: Asset management workflow changes
- **Scripting**: C# 9 support, new API patterns

### New Features (Post-Cutoff)
- **DOTS**: Production-ready Entity Component System (Entities 1.3+)
- **Graphics**: Enhanced URP/HDRP pipelines, GPU Resident Drawer
- **Multiplayer**: Netcode for GameObjects improvements
- **UI Toolkit**: Production-ready for runtime UI (replaces UGUI for new projects)
- **Async Asset Loading**: Improved Addressables performance
- **Web**: WebGPU support

### Deprecated Systems
- **Legacy Input Manager**: Use new Input System package
- **Legacy Particle System**: Use Visual Effect Graph
- **UGUI**: Still supported, but UI Toolkit recommended for new projects
- **Old ECS (GameObjectEntity)**: Replaced by modern DOTS/Entities

## Verified Sources

- Official docs: https://docs.unity3d.com/6000.0/Documentation/Manual/index.html
- Unity 6 release: https://unity.com/releases/unity-6
- Unity 6.3 LTS announcement: https://unity.com/blog/unity-6-3-lts-is-now-available
- Migration guide: https://docs.unity3d.com/6000.0/Documentation/Manual/upgrade-guides.html
- Unity 6 support: https://unity.com/releases/unity-6/support
- C# API reference: https://docs.unity3d.com/6000.0/Documentation/ScriptReference/index.html
