# Web scaffold

What `/setup-engine web` copies into a new web project (`scaffold/`, through
`.claude/scripts/web-scaffold.sh`). Plain Canvas 2D and Web Audio, TypeScript,
Vite, Vitest and Playwright, at the versions `docs/engine-reference/web/VERSION.md`
pins. Every file goes to the same path in the project; none is copied over a file
that is there. The two test files are stored here with `.tmpl` after their names,
which the copy drops: a project that already has Jest or Vitest and adds Claude Code Game Studios would
otherwise run them as its own tests.

| File | What it is for |
|---|---|
| `index.html` | The page. `@TITLE@` becomes the game's name; the title screen shows it |
| `src/main.ts` | Screen, input, sound, scenes and the fixed-step loop |
| `src/game/rules.ts` | The rules: plain TypeScript with no browser in it, so Vitest runs them in Node |
| `src/hook.ts` | The game-state hook the checks drive: `window.game`, `GAME_CLOCK`, `GAME_AUDIO`, `?manual=1`, `?scene=`, `?seed=` (the one-shot's, so its scripted runs carry over) |
| `data/config.json` | Every tuning value, each with `value`, `min`, `max` and `step` |
| `assets/provenance.yaml` | Where each asset came from. Assets are imported in the code, so this file never enters a build |
| `tests/unit/rules.test.ts` | Vitest: the rules |
| `tests/integration/boot.spec.ts` | Playwright: the `@boot` test and a same-seed scripted run, on the single-file build opened from disk |
| `package.json` | The pinned versions and the scripts below; `engines` names the Node range |
| `package-lock.json` | The exact tree Claude Code Game Studios tested, for every platform; `npm ci` installs it |
| `vite.config.ts` | `base: './'`, no public folder, and `--mode single` for the single-file build |
| `tsconfig.json` | Strict TypeScript over `src/`, `allowJs`; `tsc --noEmit` is the type check |
| `playwright.config.ts` | `tests/integration/`, the browser `page-shot.sh --which` prints, software WebGL |
| `.gitignore` | Build output and test reports; a project that has a `.gitignore` keeps it: the missing lines are listed, and added on a yes (`--gitignore`) |

## Starters

`/setup-engine web` asks one question, the starter, with "nothing extra" first
and recommended. A starter is the same small game drawn with a library:
`web-scaffold.sh --starter <name>` copies its three files instead of the
scaffold's, and every other file is the scaffold's, the tests included.

| Starter | Library (pinned) | Its loop and time, and what `window.game.step()` drives |
|---|---|---|
| `none` | none: Canvas 2D and Web Audio | the scaffold's own fixed-step loop |
| `starters/three/` | `three` 0.186.1 (`@types/three` 0.186.0) | `renderer.setAnimationLoop()` and a `Timer` fed from `hook.ts`'s clock; with `?manual=1` the loop does not start |
| `starters/phaser/` | `phaser` 4.2.1 | Phaser's own loop; with `?manual=1` `game.loop.sleep()`, and each step is `game.step(time, delta)` with time moved on by one step |
| `starters/pixi/` | `pixi.js` 8.22.0 | PixiJS's ticker (`autoStart: false`); with `?manual=1` it stays stopped, and each step is `ticker.update(time)` with time moved on by one step |

Each starter folder holds `package.json` (the scaffold's, plus the library),
`package-lock.json` (the scaffold's tree plus the library's) and `src/main.ts`.
The three.js pin is the one `.claude/scripts/vendor-three.sh` bundles for a
one-shot, so a one-shot that grows keeps its version: change both together.
In each, two same-seed scripted runs match (the second Playwright test).

## The scripts

| Script | What it runs |
|---|---|
| `npm run dev` | The Vite dev server, to play while working (never exits; no check runs it) |
| `npm run build` | `tsc --noEmit`, then `dist/`: the build to ship |
| `npm run build:single` | `tsc --noEmit`, then `dist-single/index.html` with everything inlined, which opens from disk |
| `npm test` | `test:unit`, then `test:e2e` |
| `npm run test:unit` | Vitest over `tests/unit/` |
| `npm run test:e2e` | `build:single`, then Playwright over `tests/integration/` |
| `npm run smoke` | `build:single`, then the `@boot` test |

To ship on itch.io: `npm run build`, then `bash .claude/scripts/itch-zip.sh`,
which zips `dist/` with `index.html` at the top and checks the zip against
itch.io's limits. To let friends play it, on a hidden itch.io page or a web link:
`.claude/docs/share-link.md`.

## Growing a one-shot

`/prototype`'s grow step (`references/one-shot-5-grow.md`) turns a one-shot into a
web project through `.claude/scripts/one-shot-grow.sh`. It takes the scaffold's
tooling (`package.json`, the lockfile, the three configs, `src/hook.ts`) but not
its page, square game, values or tests, and two files from `grow/`:

| File | What it is for |
|---|---|
| `grow/config.js` | `src/config.js` while the grown game is still JavaScript: `window.CONFIG` from `data/config.json`, and the tweak panel on the dev server |
| `grow/tune.ts` | `src/dev/tune.ts`: the one-shot's tweak panel (`.claude/docs/templates/one-shot-lean/tune.js`, an add-on) in TypeScript, reading `data/config.json`, its block naming the project folder. A change to the starter's panel is made here too |
