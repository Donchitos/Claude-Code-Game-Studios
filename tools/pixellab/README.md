# PixelLab — Pixel Art Generation Tools

CLI wrappers around [PixelLab](https://pixellab.ai/)'s official API + Python
SDK. Generate pixel art sprites, UI elements, backgrounds, or convert
existing images to pixel art.

## Get a key

1. Sign up at https://pixellab.ai/
2. Dashboard → API Keys → **Create**

## Configure

```bash
# Option A — env var
export PIXELLAB_SECRET=your_key_here

# Option B — local config file (gitignored)
echo '{"api_key": "your_key_here"}' > tools/pixellab/config.json
```

## Install

```bash
pip install pixellab requests
```

(Or use the top-level `tools/requirements.txt`.)

## Tools

| Script | Purpose |
|---|---|
| `pixellab_client.py` | Shared base — auth, SDK client, v1/v2 HTTP helpers. Not called directly. |
| `pixellab_balance.py` | Check your PixelLab credit balance |
| `pixellab_generate_image.py` | Text → pixel sprite (Pixflux model, v1) — characters, items, icons |
| `pixellab_generate_ui.py` | Text → pixel UI element (v2) — health bars, buttons, panels, menus |
| `pixellab_generate_background.py` | Text → pixel background (up to 400×400) with presets: `topdown`, `sidescroller`, `parallax` (3 layers), `menu`, `battle`, `isometric` |
| `pixellab_image_to_pixelart.py` | Any image → pixel art conversion (v2) — photos, concept art, 3D renders |
| `pixellab_edit_image.py` | Inpaint / edit existing sprites with a mask |

## Examples

```bash
# Check balance
python tools/pixellab/pixellab_balance.py

# 64x64 hero sprite, transparent background
python tools/pixellab/pixellab_generate_image.py \
    -d "knight holding a sword, side view" \
    -W 64 -H 64 --no-background -o hero.png

# Inventory item icon
python tools/pixellab/pixellab_generate_image.py \
    -d "red health potion, glass flask with cork" \
    -W 32 -H 32 --no-background -o potion.png

# UI button
python tools/pixellab/pixellab_generate_ui.py \
    -d "green play button with icon" \
    -W 64 -H 32 -o play_btn.png

# Full top-down background
python tools/pixellab/pixellab_generate_background.py \
    -d "medieval village square at sunset" \
    --preset topdown -o village.png

# Convert a 3D render to pixel art
python tools/pixellab/pixellab_image_to_pixelart.py \
    -i render.png -o pixel.png -W 64 -H 64
```

## Tips

- **`--no-background`** is your default for characters and items. Transparent
  PNG alpha is what sprite atlases need.
- **Resolution matters.** PixelLab charges per-call based on output size. Start
  small (32×32 or 64×64) and only go big when a single icon becomes a hero
  image.
- **Background presets** in `pixellab_generate_background.py` are PixelLab's
  curated styles — `topdown`, `sidescroller`, `parallax` (returns 3 layers!),
  `menu`, `battle`, `isometric`. Use the preset closest to your game's
  perspective; it dramatically improves output quality.
