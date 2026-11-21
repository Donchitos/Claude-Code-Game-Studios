# Web — Version Reference

`engine.name: Web` is not one engine but a toolchain plus whatever library the
game adds. This file pins the versions the web template uses; the library a
game actually uses is read from its `package.json`, never from a setting.

| Field | Value |
|-------|-------|
| **Engine** | Web (Vite + TypeScript; Canvas 2D and Web Audio by default) |
| **`engine.version`** | The bundler's version from `package.json` (Vite for a new project) |
| **Installed at pin time** | PER PROJECT — the project's lockfile decides; see the Installed-Version Gap Warning |
| **Project Pinned** | 2026-10-29 |
| **Last Docs Verified** | 2026-10-29 (every page in this folder) |
| **LLM Knowledge Cutoff** | May 2025 |

## Pinned versions

Exact versions, each published at least two weeks before the pin date. The
web template's `package.json` (`.claude/engines/web/scaffold/`) pins exactly
these, with its lockfile committed; when one changes here, it changes there.
The template has no library, so it pins the first five; the starters
(`.claude/engines/web/starters/`) pin their library from this table, each with
its own lockfile.

| Package | Pinned | Published | First release of this major | Node |
|---------|--------|-----------|-----------------------------|------|
| `vite` | 8.3.4 | 2026-10-08 | 8.0.0, 2026-03-12 | `^20.19 \|\| >=22.12` |
| `typescript` | 7.0.2 | 2026-07-08 | 7.0.2 (first stable), 2026-07-08 | `>=16.20` |
| `vitest` | 5.0.5 | 2026-10-15 | 5.0.0, 2026-09-03 | `^22.12 \|\| ^24 \|\| >=26` |
| `@playwright/test` | 1.64.1 | 2026-10-14 | 1.64.0, 2026-10-07 | `>=20` |
| `vite-plugin-singlefile` | 2.3.3 | 2026-04-17 | 2.0.0, 2024-02-11 | `>18` (peer: Vite `^5.4.21 \|\| ^6 \|\| ^7 \|\| ^8`) |
| `three` | 0.186.1 | 2026-09-24 | r186 (0.186.0), 2026-09-08 | — |
| `@types/three` | 0.186.0 | 2026-09-11 | — | — |
| `phaser` | 4.2.1 | 2026-07-09 | 4.0.0, 2026-04-10 | — |
| `pixi.js` | 8.22.0 | 2026-10-01 | 8.0.0, 2024-03-05 | — |

- **Node for the whole set:** `^22.12 || ^24 || >=26` — Vitest 5's range, which
  sits inside Vite 8's and Playwright's.
- **TypeScript fallback:** `typescript` 5.9.3 (2025-09-30), for a tool that needs
  the JavaScript compiler API that 7.0 does not ship (`breaking-changes.md`).
- **three.js types:** `three` ships no type declarations; `@types/three` does,
  versioned to match the three.js release.
- **The one-shot uses the same three.js.** `/prototype` without an engine
  bundles three.js 0.186.1 into one plain script (`.claude/scripts/vendor-three.sh`,
  `.claude/skills/prototype/references/one-shot-files.md`), so a one-shot that
  grows into a web project keeps its three.js version. Change both together.

Sources: the npm registry (`registry.npmjs.org/<package>`: `time`, `engines`,
`peerDependencies`, `types`), read 2026-10-29. **[S]** — sourced: read in the
primary source on that date. Risk levels below are judgment **[J]**.

## Knowledge Gap Warning

May 2025 is a floor for every model the studio runs on: a newer model may know more, but check this folder first.

A model whose training data ends in May 2025 saw npm's latest at about
Vite 6.3, TypeScript 5.8, Vitest 3.1, Playwright 1.52, three.js r176, Phaser
3.88 and PixiJS 8.9. Every
pinned version above is newer, and several are new majors with breaking
changes the model does NOT know about: Vite 7 and 8 (Rolldown replaces Rollup
and esbuild), TypeScript 6 and 7 (changed defaults; a native compiler with no
JavaScript API), Vitest 4 and 5, and Phaser 4 (a rewritten renderer). Read
`breaking-changes.md` and the library's page before writing config or library
calls.

## Installed-Version Gap Warning

This file is the template's pin, not the project's. A project made from the
template matches it until someone upgrades; an existing web project set up
with `/setup-engine web` keeps its own versions, which can be older (Vite 5, Phaser 3, PixiJS 7) or
newer than these. **Before trusting a version-qualified claim here, read the
version the project actually installs**: the package's entry in the lockfile,
or `node_modules/<package>/package.json`. A Phaser 3 project needs Phaser 3
code, whatever this page pins.

## Post-Cutoff Version Timeline

| Package | Release | Risk | Key change |
|---------|---------|------|------------|
| Vite 7 | 2025-06-24 | MEDIUM | Node 20.19+, browser target `baseline-widely-available` |
| Vite 8 | 2026-03-12 | HIGH | Rolldown and Oxc replace Rollup and esbuild; options renamed |
| TypeScript 6.0 | 2026-03-23 | HIGH | Changed defaults, deprecated options |
| TypeScript 7.0 | 2026-07-08 | HIGH | Native compiler; deprecated options removed; no JS API |
| Vitest 4 | 2025-10-22 | HIGH | Browser mode stable with provider packages; config changes |
| Vitest 5 | 2026-09-03 | MEDIUM | Node 22.12+; see `breaking-changes.md` |
| Playwright 1.53–1.64 | 2025-06 to 2026-10 | LOW | Additive; a few removals |
| three.js r177–r186 | 2025-05 to 2026-09 | MEDIUM | Removals and deprecations, see `threejs.md` |
| Phaser 4 | 2026-04-10 | HIGH | New renderer; filters replace FX and pipelines, see `phaser.md` |
| PixiJS 8.10–8.22 | 2025-06 to 2026-10 | LOW | Additive within 8, see `pixijs.md` |

Dates are each version's first publish on npm.
