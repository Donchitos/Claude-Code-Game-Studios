"""
Edit/inpaint pixel art using PixelLab v2 API.

Usage:
    python pixellab_edit_image.py -i sprite.png -m mask.png -d "add a red cape" -o edited.png

Mask: white = area to regenerate, black = keep as-is.
"""
import argparse
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixellab_client import api_post, image_to_base64, save_base64_image


def main():
    parser = argparse.ArgumentParser(description="Edit pixel art via inpainting")
    parser.add_argument("--input", "-i", required=True, help="Input image")
    parser.add_argument("--mask", "-m", required=True, help="Mask image (white=edit area)")
    parser.add_argument("--description", "-d", required=True, help="What to generate in the mask area")
    parser.add_argument("--output", "-o", required=True)
    parser.add_argument("--guidance", type=float, default=8.0)
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    print(f"Editing: {args.description}...")

    data = {
        "description": args.description,
        "image_size": {"width": 64, "height": 64},  # Will be overridden by image size
        "inpainting_image": image_to_base64(args.input),
        "mask_image": image_to_base64(args.mask),
        "text_guidance_scale": args.guidance,
        "seed": args.seed,
    }

    result = api_post("inpaint-v3", data, version="v2")

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
