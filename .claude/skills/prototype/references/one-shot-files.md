# /prototype — The one-shot's files

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

**In this file:** The folder · config.js · Built to be checked · 3D · Origin lines and
placeholders · The person's references · Never

## The folder

```text
prototypes/<name>/
  index.html     the game, from the lean starter
  config.js      window.CONFIG: every tuning value
  tune.js        the tweak panel, added when the person asks to tune: sliders for config.js
  brief.md       this game's brief: a copy of design/game-brief.md while that is this game's
  feel-log.md    a line per value tuned in the panel, written by one-shot-tune.sh
  assets/        images and sounds, and provenance.yaml (where each came from)
  vendor/        libraries, kept in the folder (three.js for 3D)
  evidence/      screenshots and logs from the runs
  dist/          the shared build, made by one-shot-share.sh: no tweak panel; never committed
```

It plays offline, from a double-click on `index.html`. Plain JavaScript, no build step: Canvas
2D, three.js only when the look's `renderer:` is `webgl`, HTML and CSS when it is `dom`, and
Web Audio for sound. Each file that can hold a comment keeps the starter's three header lines
(PROTOTYPE - NOT FOR PRODUCTION, the Question, the Date) at the top.

**One brief per game.** `design/game-brief.md` is the game being worked on; each game keeps its
own brief in `prototypes/<name>/brief.md`. The two are written together while they are the same
game's. A change to another game writes only its folder's brief and leaves `design/game-brief.md`
as it is.

## config.js

Every number a designer would tune lives here, each with `value`, `min`, `max` and `step`:

```js
window.CONFIG = {
  seed: 1,
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },
  jump_height: { value: 3, min: 1, max: 8, step: 0.25 }, // tiles
};
```

- **The game reads values through `tune.<name>`** each time it needs one, never a copy, so a
  value changed while the game runs takes effect at once.
- **The tweak panel** (`tune.js`) opens on the backquote key, or `?tune` in the address, with a
  slider for each value that has `value`, `min`, `max` and `step`, in this file's order: put the
  values that matter most first. It is not in the first build: the change loop adds it when the
  person asks to tune, with its `<script src="tune.js"></script>` line right after config.js's.
  Where the game reads a value only once (a level's size), it listens for the panel's `tune`
  event and reads it again. The backquote key is not one of the game's controls:
  leave it off the game's screens and the brief's Controls, since a shared build has no panel;
  the change loop tells the person when it adds the panel.
- **A value worked out from others** (gravity from jump height and time to apex) is computed in
  the game, not stored.
- **`seed`** is a plain number. Every gameplay random call goes through `rng()`; `Math.random`
  never appears in game code. `?seed=` in the address overrides it.

## Built to be checked

Keep the starter's parts the checks read, whatever else changes:

- the fixed step (`STEP`): motion is per second, never per frame;
- the clock, which a check may replace (`window.GAME_CLOCK`);
- the `figures` scene: every enemy kind and unit side by side, each named;
- `window.game` (`scene`, `state`, `press`, `hold`, `step`) and the address options `scene=`,
  `seed=` and `manual=1`;

Keep the game's own state in `state`, so `window.game.state` reports it: score, lives, level,
whether the goal is reached.

- **The scene name the checks look for:** `play` for the game itself.
- **Game logic runs on the step,** never on a timer (`setTimeout`, `setInterval`) or the real
  clock, so a replay of the same inputs repeats the game exactly.

## 3D

Run `bash .claude/scripts/vendor-three.sh prototypes/<name> [add-on ...]`, naming each add-on the
game uses as its path under three.js's examples (`controls/OrbitControls`,
`loaders/GLTFLoader`). Give the call a 10-minute timeout and wait for it: on a slow connection
the fetch takes minutes. Then, by its `mode` row:

- **`bundled`:** add `<script src="vendor/three.js"></script>` above the `config.js` line. The
  game uses the global `THREE` and `THREE.<add-on>`, and still plays from a double-click.
- **`served`:** load three.js as a module through an import map
  (`"three": "./vendor/three.module.js"`), with the game in a `type="module"` script. The page
  must be served: the handover gives the `serve` row's command. Add-ons marked `missing` are
  not there; write what the game needs itself.
- **`not_done`:** say why, and ask: build it in 2D in the brief's look, or stop.

The script fetches three.js 0.186.1, which differs from older versions you may know:

- `PCFSoftShadowMap` is removed and falls back to `PCFShadowMap`; use `PCFShadowMap` or
  `VSMShadowMap`.
- `THREE.Clock` is deprecated in favour of `THREE.Timer`; game logic runs on the step anyway.
- `FogExp2` fades as 1 - exp(-(density × distance)²): density 0.02 is about 30% fog at 30 m.

**The cheap render.** Every screenshot and check asks for it (`render=cheap` in the address, the
starter's `CHEAP`), because headless Chrome draws WebGL in software, where each frame costs
seconds and the cost grows with pixels and shadows. Under `CHEAP`:
`new THREE.WebGLRenderer({ antialias: !CHEAP })`, `renderer.setPixelRatio(CHEAP ? 0.5 :
devicePixelRatio)`, `renderer.shadowMap.enabled = !CHEAP`, and no post effects (render the scene
straight, not through an `EffectComposer`). The HUD stays at full size.
A slow shot or check is the sandbox, not the game: never tune shadows, resolution or effects for
it. A shot that judges the look itself takes `--full`.

The HUD goes on a 2D canvas or in HTML over the WebGL canvas, in the brief's look.

## Origin lines and placeholders

Every file in `assets/` and `vendor/` has an entry in `assets/provenance.yaml`; the field names
are in the file's opening comment. `origin: ai` for a file a generative model made (with `tool`
and `model`), `code` for one made by code or written as code, such as an SVG or a sprite a script
baked (with `tool`, and `model` when an AI wrote the code), `cc0` or `licensed` for a download
(with `source` and `licence`), `you` for the person's own file. A placeholder carries
`placeholder: true` on its entry and `_ph` before its extension (`hero_ph.png`) until it is
replaced. Art and sound the code makes while the game runs have no file and need no entry.

## The person's references

The project's `references/` folder sits at the project's root, beside `prototypes/`. It is the
person's: every game reads it and none owns it. The card file says how to read it.

```text
references/
  notes.md       optional: a line per file or clip link
  cave-ui.png    what they dropped in: images, screenshots, UI, sounds
  pasted-1.png   an image pasted in the chat, saved by references-save.sh
```

A `notes.md` line names a file or a link, then what to take, what to avoid, or `use`:

```text
- cave-ui.png: take: the HUD in the corners, the dark blue · avoid: the pixel font
- https://www.youtube.com/watch?v=<id>: take: how the dash snaps
- my-hero.png: use
```

- **A reference guides the build; it is never copied into the game.** Only a file marked `use`
  is copied into `assets/` with `origin: you`.
- **Before any change after the handover,** read `notes.md` again and look at any file added
  since the build, as the card did.

## Never

- A request to the network while the game runs: no web fonts, no libraries from a CDN, no
  remote images. Fonts are a system stack or a file in `assets/`.
- A server, or play between tabs, windows or machines (a `server.js`, WebSocket, WebRTC,
  BroadcastChannel): online play is the card's stand-in, and LAN play only when the person asks
  for it by name.
- A write outside `prototypes/<name>/`, except `design/game-brief.md`, in `references/` the
  pasted images and their `notes.md` lines, and growing (`one-shot-5-grow.md`), which copies the
  game to the project root.
- An import from the project's code root, or the code root importing from `prototypes/`.
- `tune.js` in anything shared: share `dist/`, which `one-shot-share.sh` makes without it.
