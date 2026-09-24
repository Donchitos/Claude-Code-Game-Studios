"""
Generate pixel art image using PixelLab Pixflux (SDK).

Usage:
    python pixellab_generate_image.py -d "cute wizard with blue robes" -W 64 -H 64 -o wizard.png
    python pixellab_generate_image.py -d "wooden barrel" -W 32 -H 32 --no-background -o barrel.png
    python pixellab_generate_image.py -d "knight in armor" -W 48 -H 48 --view side --direction south -o knight.png
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixellab_client import get_client


def main():
    parser = argparse.ArgumentParser(description="Generate pixel art with PixelLab Pixflux")
    parser.add_argument("--description", "-d", required=True)
    parser.add_argument("--width", "-W", type=int, default=64)
    parser.add_argument("--height", "-H", type=int, default=64)
    parser.add_argument("--output", "-o", required=True)
    parser.add_argument("--no-background", action="store_true")
    parser.add_argument("--view", choices=["side", "low top-down", "high top-down"], default=None)
    parser.add_argument("--direction", default=None)
    parser.add_argument("--outline", default=None)
    parser.add_argument("--shading", default=None)
    parser.add_argument("--detail", default=None)
    parser.add_argument("--isometric", action="store_true")
    parser.add_argument("--guidance", type=float, default=8.0)
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    client = get_client()
    print(f"Generating: {args.description} ({args.width}x{args.height})...")

    result = client.generate_image_pixflux(
        description=args.description,
        image_size={"width": args.width, "height": args.height},
        no_background=args.no_background,
        view=args.view,
        direction=args.direction,
        outline=args.outline,
        shading=args.shading,
        detail=args.detail,
        isometric=args.isometric,
        text_guidance_scale=args.guidance,
        seed=args.seed,
    )

    result.image.pil_image().save(args.output)
    print(f"Saved: {args.output}")


if __name__ == "__main__":
    main()
