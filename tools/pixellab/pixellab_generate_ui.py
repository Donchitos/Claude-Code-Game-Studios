"""
Generate UI elements using PixelLab v2 API (not in SDK).

Usage:
    python pixellab_generate_ui.py -d "medieval stone button with gold trim" -W 64 -H 32 -o button.png
    python pixellab_generate_ui.py -d "health bar red and green" -W 128 -H 16 -o healthbar.png
    python pixellab_generate_ui.py -d "inventory slot dark wood frame" -W 32 -H 32 --no-background -o slot.png
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixellab_client import api_post, save_base64_image


def main():
    parser = argparse.ArgumentParser(description="Generate UI elements with PixelLab")
    parser.add_argument("--description", "-d", required=True)
    parser.add_argument("--width", "-W", type=int, default=64)
    parser.add_argument("--height", "-H", type=int, default=64)
    parser.add_argument("--output", "-o", required=True)
    parser.add_argument("--no-background", action="store_true")
    parser.add_argument("--palette", default=None, help="Color palette description")
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    print(f"Generating UI: {args.description} ({args.width}x{args.height})...")

    data = {
        "description": args.description,
        "image_size": {"width": args.width, "height": args.height},
        "no_background": args.no_background,
        "seed": args.seed,
    }
    if args.palette:
        data["color_palette"] = args.palette

    result = api_post("generate-ui-v2", data, version="v2")

    if result.get("success") and result.get("data"):
        b64 = result["data"].get("image", result["data"].get("base64", ""))
        if b64:
            save_base64_image(b64, args.output)
        else:
            print(f"Response: {list(result['data'].keys())}")
    else:
        print(f"Error: {result.get('error', result)}")


if __name__ == "__main__":
    main()
