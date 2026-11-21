# Share your game

How to let friends play a web game once its build runs: a hidden itch.io page, or a web link
from wherever you put the files. It covers a one-shot (`prototypes/<name>/`) and a grown web
project (one with `package.json` and `npm run build`). Read when the person asks to share,
send, upload or put the game online.

**Nothing here makes the game public.** The itch.io page stays Draft or Restricted. Making it
public, picking a price or entering a jam is the person's own step, outside this file.

## 1. Only a build that runs is shared

| Game | Make the build | It runs when |
|---|---|---|
| One-shot | `bash .claude/scripts/one-shot-share.sh prototypes/<name>` makes `prototypes/<name>/dist/` (no tweak panel, no working files) | its last check passed (the build's self-check, or the light check after a change) and no `found` row came back |
| Grown web project | `npm run build` makes `dist/` | `npm run smoke` passed after the last change |

If the check failed or was not run, say so and fix or run it first. Never share a build that has
not run, and never the game's own folder.

## 2. Pick the way

| Way | Good for | Who can play it |
|---|---|---|
| **A hidden itch.io page** | Friends and testers, with a page you can make public later | Only people you give the page's link to (section 3) |
| **A web link** | Anyone you send it to, with no itch.io account | Anyone who has the link. It is hidden, not private |

Ask which, in one plain question. With no answer, offer the itch.io page.

## 3. A hidden itch.io page

**Make the zip.** `bash .claude/scripts/itch-zip.sh --dist <the build folder> --out <name>-web.zip`
(the build folder is `prototypes/<name>/dist` or `dist`). It puts `index.html` at the top of
the zip and checks itch.io's limits: at most 1,000 files, 500 MB in all, 200 MB for one file.
An `over` row or `not_assessed` stops here: say what it found.

**The person does these by hand.** Claude Code Game Studios never makes an account, never logs in and never sees a
password or key.

1. Make an itch.io account at itch.io, if they don't have one.
2. Make a new project from their itch.io dashboard. Set its kind to **HTML** (not
   Downloadable) and leave its visibility on **Draft**, the default. Save it.
3. Upload the zip on that page, or install butler, itch.io's upload tool (from
   itchio.itch.io/butler, or the itch app), and run `butler login` themselves. It opens their
   browser and saves the login on their computer; `butler logout` removes it.
4. On the edit page, mark the upload as playable in the browser, set the game's size (the
   viewport), and fill in the AI disclosure section from the game's asset record
   (`assets/provenance.yaml`).
5. To let friends in, send them the page's **secret link**: a Draft page can be seen by its
   owners and by anyone with that link. (Restricted works too, with download keys or a
   password.) Never Public in this step.

**With butler, Claude Code Game Studios may upload, after the person says yes.** First show the dry run, which lists
the files it would send and sends nothing:
`butler push --dry-run <the build folder> <user>/<game>:html5`. Then ask: "Upload this build to
your itch.io page <user>/<game>? It stays a hidden draft." Only on a clear yes run
`butler push <the build folder> <user>/<game>:html5`. A new channel's upload shows on the page
at once, and only the page's visibility keeps it hidden, so ask the person to check the page
still says Draft. A failed push is reported as it came back; never retry with other names or
settings.

## 4. A web link

Any host that serves a folder of files works: put the build folder's contents there, with
`index.html` at the top. The game's paths are relative, so it runs from any address. Uploading is
the person's step, on their own account. Tell them plainly: anyone with the link can play it,
and a search engine may find it. For one friend, sending the zip from section 3 also works:
they unzip it and open `index.html`.

## 5. The handover

End with what is done and what is theirs, in plain words:

- the build folder and the zip, and that both ran;
- the itch.io steps from section 3 they still have to do, numbered;
- after an upload, the page address and "it is a hidden draft: only people with the secret link
  can see it".

If nothing was uploaded, say "not shared yet", never "shared".
