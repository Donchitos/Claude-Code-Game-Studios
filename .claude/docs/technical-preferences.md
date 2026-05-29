# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: React Native (Expo SDK) + Node.js game server
- **Language**: TypeScript (client + server)
- **Rendering**: React Native renderer (Skia / Canvas TBD per graphics needs)
- **Physics**: Custom server-authoritative game logic (no engine physics)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: iOS + Android
- **Input Methods**: Touch
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: All UI must handle safe area insets (notch, home indicator). No hover-only interactions. Test on both iOS and Android physical devices before marking UI stories done.

## Naming Conventions

- **Classes/Components**: PascalCase (e.g., `PlayerCard`, `MatchScreen`)
- **Variables**: camelCase (e.g., `moveSpeed`, `currentHealth`)
- **Events/Callbacks**: camelCase with `on` prefix (e.g., `onMatchEnd`, `onPlayerJoin`)
- **Files**: PascalCase for React components (`MatchScreen.tsx`), camelCase for utilities (`matchUtils.ts`)
- **Scenes/Prefabs**: N/A — React Native screens use PascalCase component directories
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `TICK_RATE_MS`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms (JS thread; monitor with Flipper or React Native Perf Monitor)
- **Draw Calls**: N/A — React Native renderer; monitor JS thread frame time instead
- **Memory Ceiling**: 200MB (mid-range mobile device target)

## Testing

- **Framework**: Jest + React Native Testing Library
- **Minimum Coverage**: 70% for game logic (matchmaking, MMR, reward calculation); advisory for UI components
- **Required Tests**: Balance formulas, matchmaking logic, MMR calculation, reward distribution, game state transitions

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here when actively integrating, not speculatively -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for code-area-specific validation. -->

- **Primary**: lead-programmer
- **Game Logic Specialist**: gameplay-programmer (match mechanics, character abilities, game state)
- **Networking Specialist**: network-programmer (Socket.io real-time sync, matchmaking, lag compensation)
- **UI Specialist**: ui-programmer (React Native screens, HUD, menus, animations)
- **Security Specialist**: security-engineer (Supabase auth, RevenueCat IAP validation, anti-cheat)
- **Routing Notes**: This is a React Native / Node.js project — game engine specialists (Godot, Unity, Unreal) do not apply. Route by functional area using the table below.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game mechanics (.ts in game logic modules) | gameplay-programmer |
| React Native UI screens (.tsx) | ui-programmer |
| Real-time server code (.ts in server/) | network-programmer |
| Auth / IAP / security code | security-engineer |
| Native modules (.m, .java, .kt) | lead-programmer |
| General architecture review | lead-programmer |
