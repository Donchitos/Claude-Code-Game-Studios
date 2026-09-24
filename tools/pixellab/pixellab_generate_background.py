"""
Generate pixel art game backgrounds using PixelLab Pixflux.
Supports top-down maps, sidescroller scenes, parallax layers, and menu screens.

Usage:
    # Top-down map background
    python pixellab_generate_background.py -d "forest clearing with river" --preset topdown -o forest.png

    # Sidescroller scene
    python pixellab_generate_background.py -d "underground cave with crystals" --preset sidescroller -o cave.png

    # Parallax layers (generates 3 layers: far, mid, near)
    python pixellab_generate_background.py -d "mountain sunset landscape" --preset parallax -o mountains.png

    # Menu/title screen
    python pixellab_generate_background.py -d "dark castle entrance with torches" --preset menu -o title_bg.png

    # Custom size
    python pixellab_generate_background.py -d "ocean with islands" -W 400 -H 300 --view "high top-down" -o ocean.png

    # Batch: generate multiple variations
    python pixellab_generate_background.py -d "enchanted forest" --preset topdown --variations 3 -o enchanted.png
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixellab_client import get_client

PRESETS = {
    "topdown": {
        "description": "Game backgrounds: top-down view",
        "width": 400, "height": 400,
        "view": "high top-down",
        "suffix": " top-down game map, pixel art, seamless",
    },
    "sidescroller": {
        "description": "Sidescroller scene backgrounds",
        "width": 400, "height": 225,
        "view": "side",
        "suffix": " side-view game background, pixel art, atmospheric",
    },
    "parallax": {
        "description": "Parallax layers (generates far/mid/near)",
        "width": 400, "height": 225,
        "view": "side",
        "layers": [
            {"name": "far", "suffix": " distant background layer, simple silhouettes, hazy, pixel art"},
            {"name": "mid", "suffix": " middle ground layer, moderate detail, pixel art"},
            {"name": "near", "suffix": " foreground elements, detailed, pixel art"},
        ],
    },
    "menu": {
        "description": "Menu/title screen backgrounds",
        "width": 360, "height": 400,
        "view": "side",
        "suffix": " game title screen background, atmospheric, detailed pixel art",
    },
    "battle": {
        "description": "Battle/arena backgrounds",
        "width": 400, "height": 300,
        "view": "side",
        "suffix": " battle arena background, pixel art, dramatic lighting",
    },
    "isometric": {
        "description": "Isometric map backgrounds",
        "width": 400, "height": 400,
        "view": "low top-down",
        "suffix": " isometric game map, pixel art",
        "isometric": True,
    },
}


def generate_one(client, description, width, height, view, output, isometric=False, no_bg=False, seed=0, guidance=8.0, shading=None, detail=None, outline=None):
    result = client.generate_image_pixflux(
        description=description,
        image_size={"width": width, "height": height},
        view=view,
        isometric=isometric,
        no_background=no_bg,
        seed=seed,
        text_guidance_scale=guidance,
        shading=shading,
        detail=detail,
        outline=outline,
    )
    result.image.pil_image().save(output)
    print(f"  Saved: {output}")


def main():
    parser = argparse.ArgumentParser(description="Generate pixel art game backgrounds")
    parser.add_argument("--description", "-d", required=True, help="Scene description")
    parser.add_argument("--preset", "-p", choices=list(PRESETS.keys()), default=None, help="Preset type")
    parser.add_argument("--width", "-W", type=int, default=None)
    parser.add_argument("--height", "-H", type=int, default=None)
    parser.add_argument("--output", "-o", required=True, help="Output path (for parallax, suffix _far/_mid/_near added)")
    parser.add_argument("--view", choices=["side", "low top-down", "high top-down"], default=None)
    parser.add_argument("--isometric", action="store_true")
    parser.add_argument("--no-background", action="store_true", help="Transparent background")
    parser.add_argument("--variations", type=int, default=1, help="Generate N variations (different seeds)")
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--guidance", type=float, default=8.0)
    parser.add_argument("--shading", default=None)
    parser.add_argument("--detail", default=None)
    parser.add_argument("--outline", default=None)
    args = parser.parse_args()

    client = get_client()
    preset = PRESETS.get(args.preset, {})

    width = args.width or preset.get("width", 400)
    height = args.height or preset.get("height", 400)
    view = args.view or preset.get("view", "high top-down")
    isometric = args.isometric or preset.get("isometric", False)

    base, ext = os.path.splitext(args.output)
    ext = ext or ".png"

    # Parallax: generate 3 layers
    if args.preset == "parallax":
        layers = preset["layers"]
        print(f"Generating {len(layers)} parallax layers: {args.description} ({width}x{height})")
        for layer in layers:
            desc = args.description + layer["suffix"]
            out = f"{base}_{layer['name']}{ext}"
            print(f"  Layer [{layer['name']}]: {desc}")
            generate_one(client, desc, width, height, view, out,
                         no_bg=True, seed=args.seed, guidance=args.guidance,
                         shading=args.shading, detail=args.detail, outline=args.outline)
        print("All parallax layers done.")
        return

    # Standard or preset generation
    suffix = preset.get("suffix", "")

    for i in range(args.variations):
        desc = args.description + suffix
        seed = args.seed + i if args.variations > 1 else args.seed

        if args.variations > 1:
            out = f"{base}_{i+1}{ext}"
        else:
            out = f"{base}{ext}"

        print(f"Generating ({i+1}/{args.variations}): {desc} ({width}x{height}, seed={seed})")
        generate_one(client, desc, width, height, view, out,
                     isometric=isometric, no_bg=args.no_background, seed=seed,
                     guidance=args.guidance, shading=args.shading, detail=args.detail,
                     outline=args.outline)

    print("Done.")


if __name__ == "__main__":
    main()
