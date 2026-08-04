"""
Convert a regular image to pixel art using PixelLab v2 API.

Usage:
    python pixellab_image_to_pixelart.py -i photo.png -o pixelart.png -W 64 -H 64
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixellab_client import api_post, image_to_base64, save_base64_image


def main():
    parser = argparse.ArgumentParser(description="Convert image to pixel art")
    parser.add_argument("--input", "-i", required=True, help="Input image path")
    parser.add_argument("--output", "-o", required=True, help="Output PNG path")
    parser.add_argument("--width", "-W", type=int, default=64)
    parser.add_argument("--height", "-H", type=int, default=64)
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    print(f"Converting to pixel art ({args.width}x{args.height})...")

    b64_input = image_to_base64(args.input)
    data = {
        "image": b64_input,
        "image_size": {"width": args.width, "height": args.height},
        "seed": args.seed,
    }

    result = api_post("image-to-pixelart", data, version="v2")

    if result.get("success") and result.get("data"):
        b64 = result["data"].get("image", result["data"].get("base64", ""))
        if b64:
            save_base64_image(b64, args.output)
        else:
            print(f"Response keys: {list(result['data'].keys())}")
    else:
        print(f"Error: {result.get('error', result)}")


if __name__ == "__main__":
    main()
