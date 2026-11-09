# Web — Breaking Changes

Last verified: 2026-10-29 | Toolchain: Vite 8.3, TypeScript 7.0, Vitest 5.0, Playwright 1.64

What changed in the web toolchain after the model's training (about Vite 6,
TypeScript 5.8, Vitest 3.1, Playwright 1.52). Libraries have their own pages:
`threejs.md`, `phaser.md`, `pixijs.md`.

**Grades:** **[S]** sourced — read in the named primary source on the date
above; **[M]** measured on a real machine; **[J]** judgment, not stated by a
source.

## Vite 6 → 7 (2025-06-24)

- Node 20.19+ or 22.12+; Node 18 dropped. **[S]** (1)
- Default `build.target` is `'baseline-widely-available'` (was `'modules'`),
  raised on every major. **[S]** (1)
- Sass legacy API support and `splitVendorChunkPlugin` removed. **[S]** (1)

## Vite 7 → 8 (2026-03-12 — HIGH RISK)

Vite 8 bundles with **Rolldown** and transforms and minifies with **Oxc**,
instead of Rollup and esbuild. Same Node range as Vite 7. **[S]** (2, 3)

| Area | Old | Vite 8 | |
|------|-----|--------|---|
| Build options | `build.rollupOptions`, `worker.rollupOptions` | `build.rolldownOptions`, `worker.rolldownOptions` | **[S]** |
| JS transform | `esbuild: {…}` | `oxc: {…}` (`esbuild` deprecated, converted automatically; `esbuild.supported` has no Oxc equivalent) | **[S]** |
| Dep optimizer | `optimizeDeps.esbuildOptions` | `optimizeDeps.rolldownOptions` (old one deprecated, converted) | **[S]** |
| JS minify | esbuild | Oxc; `build.minify: 'esbuild'` is deprecated and needs `esbuild` installed. `esbuild.drop` → `build.rolldownOptions.output.minify.compress.drop*`; property mangling unsupported | **[S]** |
| CSS minify | esbuild | Lightning CSS; `build.cssMinify: 'esbuild'` to go back | **[S]** |
| Chunks | `output.manualChunks` | Object form removed; function form deprecated; use Rolldown `codeSplitting` | **[S]** |
| CJS `default` import | inconsistent | Consistent rule; `legacy.inconsistentCjsInterop: true` restores the old one for now | **[S]** |
| `import.meta.url` in UMD/IIFE | polyfilled | `undefined` | **[S]** |
| Output formats | `system`, `amd` | not supported by Rolldown | **[S]** |
| Plugins | `transformWithEsbuild` | `transformWithOxc` (esbuild is now an optional dependency) | **[S]** |
| Errors | — | `build()` throws `BundleError`; read its `.errors` | **[S]** |
| Native decorators | lowered by esbuild | Oxc does not lower them yet | **[S]** |

- Default browser target raised: Chrome and Edge 107 → 111, Firefox 104 → 114,
  Safari 16.0 → 16.4. **[S]** (3)
- `rolldown-vite` was the preview of Vite 7 on Rolldown; a project on it goes
  straight to `vite@^8`. **[S]** (3)
- Vite 8.1–8.3 list no breaking changes in the changelog. 8.1 moved the
  WebSocket options of `server.hmr` (`protocol`, `host`, `port`, `path`,
  `clientPort`, `timeout`, `server`) to `server.ws`; the old ones are
  deprecated and still synced. `server.hmr` keeps `overlay`. **[S]** (4, 11)
- `vite-plugin-singlefile` 2.3 supports Vite 8 (peer `^8.0.0`; its `rollup`
  peer is optional). **[S]** (npm)

## TypeScript 5.x → 6.0 (2026-03-23) and 7.0 (2026-07-08 — HIGH RISK)

**7.0 is the native compiler** (a port to Go): the `typescript` package now
ships per-platform binaries and a `tsc` bin, and **no `tsserver` and no
JavaScript API**. Code that compiles cleanly on 6.0 (without
`ignoreDeprecations`) compiles the same on 7.0; what 6.0 deprecated, 7.0
rejects as hard errors. **[S]** (5, npm)

New defaults (6.0, kept by 7.0): **[S]** (5, 6)

- `strict: true`; `module: esnext`; `target` = the latest stable ES version.
- `types: []` — global `@types` packages are no longer picked up. List them:
  `"types": ["node"]`, or `["*"]` for the old behaviour. Vite's client types
  need `"types": ["vite/client"]`. **[S]** for the default, **[J]** for the
  Vite line.
- `rootDir: ./` (the tsconfig's folder) — a project with code in `src/` sets
  `"rootDir": "./src"` if it emits.
- `noUncheckedSideEffectImports: true` — a bare `import './style.css'` must
  resolve. `libReplacement: false`. `stableTypeOrdering` always on.

Errors in 7.0 (deprecated in 6.0): **[S]** (5)

- `target: es5`; `downlevelIteration`; `moduleResolution: node`/`node10`/`classic`
  (use `bundler` or `nodenext`); `module: amd`/`umd`/`system`/`none` (use
  `esnext` or `preserve`); `outFile`; `baseUrl` (make `paths` relative to the
  project root); `esModuleInterop` or `allowSyntheticDefaultImports` set to
  `false`; `alwaysStrict: false`.
- `module Foo {}` for namespaces; `import … asserts {…}` (use `with`).
- `tsc file.ts` in a folder that has a `tsconfig.json`, unless `--ignoreConfig`.
- In `.js` files checked with JSDoc: `@enum`, `@class` constructors, Closure
  function types (`function(string): void`), postfix `!` and a bare `?` type
  are no longer understood.

When a tool needs the JavaScript API (typescript-eslint, Vue/Svelte/Astro/MDX
tooling, Angular templates): stay on 6.0, or install both — **[S]** (5)

```json
"devDependencies": {
  "@typescript/native": "npm:typescript@^7.0.2",
  "typescript": "npm:@typescript/typescript6@^6.0.2"
}
```

`npx tsc` then runs 7.0 and other tools import 6.0 (`tsc6` is its CLI).
Vite itself never type-checks: it strips types, so `tsc --noEmit` is the type
check. **[J]** TypeScript 7.0.2's `tsc --noEmit`, with the web template's
`tsconfig.json` (`moduleResolution: bundler`, `types: ["vite/client"]`), exits 0
on clean code and 1 on a type error or a syntax error, naming the file and line
(`error TS2322`, `error TS1109`). **[M]** (Windows, 2026-10-29)

## Vitest 3 → 4 (2025-10-22) and 4 → 5 (2026-09-03 — HIGH RISK)

Vitest 5 needs **Node 22.12+** and Vite 6.4+. **[S]** (7)

Vitest 4: **[S]** (8)

- `workspace` → `projects`, written in `vitest.config.ts` (no separate file).
- Browser mode is stable. The provider is a separate package and an object:
  `provider: playwright({…})` from `@vitest/browser-playwright` (was the
  string `'playwright'`); `@vitest/browser` is no longer installed directly.
- `coverage.all` and `coverage.extensions` removed: only files the tests load
  are reported; set `coverage.include` to report the rest.
- Default `exclude` is only `node_modules` and `.git` (no longer `dist/`), so
  set `include` or `test.dir`.
- `maxThreads`/`maxForks` → `maxWorkers`; `poolOptions` removed (options are
  top level); `singleThread` → `maxWorkers: 1, isolate: false`.
- Test options as the third argument removed: `test(name, { retry: 2 }, fn)`.
- `poolMatchGlobs`, `environmentMatchGlobs` → `projects`; `deps.inline` and
  friends → `server.deps.*`; `basic` reporter removed.

Vitest 5: **[S]** (7, 9)

- `clearMocks` defaults to `true`: mock call history is cleared before every test.
- An un-awaited `expect(p).resolves` / `.rejects` fails the test.
- `expect.poll` fails when it times out.
- `vi.mock`, `vi.unmock`, `vi.hoisted` inside a function or `describe` throw;
  put them at the top level.
- No config lookup in parent folders; pass `--config`.
- Reports and attachments go to one `.vitest/` folder at the project root
  (gitignore it); the JSON and JUnit reporters write files there instead of
  stdout, and the HTML reporter takes `outputDir`.
- `test.sequential`, `describe.sequential` removed; `bench` is a test-context
  fixture, not an import.
- `vite` is a peer dependency: Yarn users add it themselves.
- Removed entry points: `vitest/coverage`, `vitest/reporters` (→ `vitest/node`),
  `vitest/environments`, `vitest/snapshot` (→ `vitest/runtime`),
  `vitest/runners`, `vitest/suite`.
- Browser locators are strict by default; `browser.api` → top-level `api`.

## Playwright 1.53 → 1.64

Mostly additive. What a test author trips on: **[S]** (10)

- **1.53:** URL globs in `page.route()` and similar no longer support `?` and
  `[]` (use a RegExp); `route.continue()` ignores a `Cookie` header.
- **1.54:** Node 16 removed, Node 18 deprecated; `-gv` CLI option removed
  (`--grep-invert`).
- **1.57:** bundled browsers are Chrome for Testing builds: headed uses
  `chrome`, headless uses `chrome-headless-shell`. `page.accessibility`
  removed (use Axe).
- **1.58:** `_react` and `_vue` selectors, the `:light` suffix and the
  `devtools` launch option removed (`args: ['--auto-open-devtools-for-tabs']`).
- **1.60:** `videosPath`/`videoSize` removed (use `recordVideo`);
  `Locator.ariaRef()` removed.
- **1.62:** clipboard isolated from the OS in headless; Debian 11 dropped.
- **1.63:** Ubuntu 20.04 dropped.
- **1.64:** device descriptors set `screen` (media queries see the emulated
  screen; set `screen: undefined` to opt out); elements in hidden iframes count
  as hidden; `updateSnapshots`'s unset mode is now called `'default'`.
- WebKit dropped macOS 13 (1.58) and macOS 14 (1.59).

## Sources

1. https://vite.dev/blog/announcing-vite7 (source: github.com/vitejs/vite `docs/blog/announcing-vite7.md`)
2. https://vite.dev/blog/announcing-vite8
3. https://vite.dev/guide/migration (Migration from v7)
4. https://github.com/vitejs/vite/blob/main/packages/vite/CHANGELOG.md
5. https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
6. https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/
7. https://vitest.dev/guide/migration (Migrating to Vitest 5.0)
8. https://v4.vitest.dev/guide/migration (Migrating to Vitest 4.0)
9. https://vitest.dev/blog/vitest-5
10. https://playwright.dev/docs/release-notes (source: github.com/microsoft/playwright `docs/src/release-notes-js.md`)
11. https://vite.dev/config/server-options (`server.hmr`, `server.ws`)

npm: `registry.npmjs.org/<package>` (versions, dates, `bin`, `engines`, peers).
