# Codex Game Studios

Indie game development is organized through 49 specialist role profiles. Each
role owns a focused studio domain so work stays coordinated, reviewable, and
consistent.

## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

Use the engine specialist and sub-specialist profiles that match the configured
engine. Verify engine APIs against `docs/engine-reference/` before using them.

## Studio References

- Project layout: `docs/studio/directory-structure.md`
- Technical preferences: `docs/studio/technical-preferences.md`
- Coordination rules: `docs/studio/coordination-rules.md`
- Coding standards: `docs/studio/coding-standards.md`
- Context management: `docs/studio/context-management.md`
- Engine version: `docs/engine-reference/godot/VERSION.md`

## Role Delegation

Custom specialist role profiles live in `roles/<name>.md`. They are prompt
profiles, not registered custom Codex agent types.

When a workflow needs a specialist, spawn a generic sub-agent and provide the
relevant role profile together with the task context, file paths, constraints,
and expected output. The coordinating agent remains responsible for validating
the specialist's findings and final work.

## Collaboration Protocol

Work is user-driven, not autonomous. Use this sequence:
**Question -> Options -> Decision -> Draft -> Approval**.

- Ask before writing or editing files unless the user already approved the SPEC
  or explicitly asked to proceed without confirmation.
- Show the proposed scope or draft before requesting approval.
- Obtain approval for the complete changeset before multi-file work.
- Do not commit unless the user explicitly requests it.

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for the full protocol. For a new
project with no engine or concept configured, use `$start`.

## Coding And Verification

- Inspect the relevant design, architecture, engine reference, and local
  `AGENTS.md` files before implementation.
- Make the smallest correct change and preserve behavior outside the approved
  scope.
- Keep gameplay values data-driven and document public APIs.
- Add or update focused tests for changed behavior and edge cases.
- Verify with the relevant tests, build, lint, type checks, or targeted manual
  checks; use screenshots for UI changes.
- Report assumptions, skipped checks, risks, and remaining issues.
