# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 53 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Flutter + Flame 1.37.0 (Flutter SDK 3.44.4 / Dart 3.12.2)
- **Language**: Dart
- **Version Control**: Git with trunk-based development
- **Build System**: Flutter build system (flutter build apk/ios/web/linux/windows/macos)
- **Asset Pipeline**: Flutter asset pipeline (pubspec.yaml assets section)

> **Note**: Engine-specialist agents exist for Godot, Unity, Unreal, and Flutter+Flame with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/flutter-flame/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
