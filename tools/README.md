# `tools/` — Asset Generator Backends

Python CLI wrappers for the paid asset-generation APIs that Claude Code Game
Studios skills reference. These are the **generator backends** that skills like
`/asset-spec` produce prompts *for* — so when a spec says "generate this
sprite," there's a ready-to-run script on disk that actually does it via a
`Bash` tool call, instead of Claude asking the user to run an image tool by
hand.

Everything in here uses **documented, sanctioned APIs** from each vendor's
official dashboard. No browser scraping, no reverse-engineered endpoints.

Vendors are being added one PR at a time (see issue #23 for the full roadmap:
Meshy AI, Tripo3D, frame extraction, and media utilities are queued next).

## Layout

```
tools/
├── pixellab/        PixelLab (pixel art generation)
│                    text-to-pixel-art, UI elements, backgrounds, image-to-pixel,
│                    edit/inpaint, balance check
└── requirements.txt Pinned Python deps for the toolkit
```

## Quick start

1. **Install Python deps**:

   ```bash
   pip install -r tools/requirements.txt
   ```

2. **Configure the vendor key** — every client resolves its key the same way:

   1. Environment variable (e.g. `PIXELLAB_SECRET`)
   2. `tools/{vendor}/config.json` (gitignored) with `{ "api_key": "..." }`

   See each vendor's README for where to get a key.

3. **Run a tool**:

   ```bash
   python tools/pixellab/pixellab_generate_image.py \
     --prompt "knight idle pose, side view" -W 128 -H 128 -o knight.png
   ```

## How it connects to the skills

1. `/art-bible` defines the visual identity anchor
2. `/asset-spec` writes a per-asset spec with a generation prompt
3. A sprint story says "generate the hero-idle asset from its spec"
4. Claude reads the spec and runs the matching `tools/` script

The scripts don't assume any skill exists — they're equally usable as
standalone CLI utilities from Bash, CI, or batch runs.
