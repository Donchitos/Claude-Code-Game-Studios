"""
Shared PixelLab client — pixel art / sprite generation.

Supports both SDK (v1) and direct API calls (v1 + v2).

Usage:
    from pixellab_client import get_client, get_api_key, api_post, api_post_v2

API key lookup order:
    1. PIXELLAB_SECRET environment variable
    2. tools/pixellab/config.json (gitignored) with { "api_key": "..." }

Get a key from https://pixellab.ai/dashboard (API keys section).
"""
import json
import os
import requests
from pathlib import Path
from pixellab.client import PixelLabClient

_SCRIPT_DIR = Path(__file__).parent.resolve()
CONFIG_FILE = _SCRIPT_DIR / "config.json"
API_V1 = "https://api.pixellab.ai/v1"
API_V2 = "https://api.pixellab.ai/v2"


def get_api_key() -> str:
    """Load PixelLab API key from env var or local config file."""
    key = os.environ.get("PIXELLAB_SECRET", "").strip()
    if key:
        return key
    if CONFIG_FILE.is_file():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            key = (data.get("api_key") or "").strip()
            if key:
                return key
        except Exception:
            pass
    raise RuntimeError(
        "No PixelLab API key found. Set PIXELLAB_SECRET env var, or create "
        f"{CONFIG_FILE} with {{\"api_key\": \"...\"}}. "
        "Get a key from https://pixellab.ai/dashboard"
    )


def get_client() -> PixelLabClient:
    """Get a ready-to-use PixelLab SDK client (v1 endpoints)."""
    return PixelLabClient(secret=get_api_key())


def _headers() -> dict:
    return {"Authorization": f"Bearer {get_api_key()}"}


def api_post(endpoint: str, data: dict, version: str = "v1") -> dict:
    """POST to PixelLab API. version='v1' or 'v2'."""
    base = API_V2 if version == "v2" else API_V1
    resp = requests.post(
        f"{base}/{endpoint.lstrip('/')}",
        headers=_headers(),
        json=data,
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()


def api_get(endpoint: str, version: str = "v1") -> dict:
    """GET from PixelLab API."""
    base = API_V2 if version == "v2" else API_V1
    resp = requests.get(
        f"{base}/{endpoint.lstrip('/')}",
        headers=_headers(),
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()


def get_balance() -> dict:
    """Check account balance."""
    return api_get("/balance")


def image_to_base64(image_path: str) -> str:
    """Convert image file to base64 string for API requests."""
    import base64
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def save_base64_image(b64_data: str, output_path: str):
    """Save base64-encoded image data to file."""
    import base64
    data = base64.b64decode(b64_data)
    with open(output_path, "wb") as f:
        f.write(data)
    print(f"Saved: {output_path}")
