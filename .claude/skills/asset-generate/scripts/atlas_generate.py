#!/usr/bin/env python3
"""Generate one image with Atlas Cloud and save it inside the current project."""

from __future__ import annotations

import argparse
import json
import os
import re
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Callable


API_ROOT = "https://api.atlascloud.ai"
CATALOG_URL = f"{API_ROOT}/api/v1/models"
DEFAULT_MODEL = "google/nano-banana-pro/text-to-image-developer"
TERMINAL_STATUSES = {"completed", "failed", "canceled", "cancelled"}


class AtlasError(RuntimeError):
    """Raised when Atlas Cloud cannot complete a generation."""


def _json_request(
    url: str,
    *,
    method: str = "GET",
    api_key: str | None = None,
    payload: dict[str, Any] | None = None,
    timeout: float = 30,
) -> dict[str, Any]:
    headers = {"Accept": "application/json", "User-Agent": "ccgs-asset-generate/1.0"}
    body = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(payload).encode("utf-8")
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            decoded = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:500]
        raise AtlasError(f"Atlas Cloud returned HTTP {exc.code}: {detail}") from exc
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise AtlasError(f"Atlas Cloud request failed: {exc}") from exc

    if not isinstance(decoded, dict):
        raise AtlasError("Atlas Cloud returned an unexpected response shape")
    return decoded


def _data(response: dict[str, Any]) -> dict[str, Any]:
    value = response.get("data", response)
    if not isinstance(value, dict):
        raise AtlasError("Atlas Cloud response is missing an object data field")
    return value


def resolve_model(
    model: str,
    fetch_json: Callable[..., dict[str, Any]] = _json_request,
) -> dict[str, Any]:
    catalog = fetch_json(CATALOG_URL)
    models = catalog.get("data")
    if not isinstance(models, list):
        raise AtlasError("Atlas Cloud model catalog is unavailable")

    match = next(
        (item for item in models if isinstance(item, dict) and item.get("model") == model),
        None,
    )
    if not match or not match.get("display_console"):
        raise AtlasError(f"Model is unavailable in the live Atlas Cloud catalog: {model}")

    schema_url = match.get("schema")
    if not isinstance(schema_url, str) or not schema_url.startswith("https://"):
        raise AtlasError(f"Model has no usable schema URL: {model}")
    schema = fetch_json(schema_url)
    if "/api/v1/model/generateImage" not in schema.get("paths", {}):
        raise AtlasError(f"Model schema does not expose the image generation endpoint: {model}")
    properties = (
        schema.get("components", {})
        .get("schemas", {})
        .get("Input", {})
        .get("properties", {})
    )
    if "prompt" not in properties or "model" not in properties:
        raise AtlasError(f"Model schema does not support prompt generation: {model}")
    return properties


def validate_options(properties: dict[str, Any], aspect_ratio: str, resolution: str) -> None:
    for field, value in (("aspect_ratio", aspect_ratio), ("resolution", resolution)):
        allowed = properties.get(field, {}).get("enum", [])
        if allowed and value not in allowed:
            raise AtlasError(f"Unsupported {field} '{value}'. Allowed: {', '.join(allowed)}")


def poll_prediction(
    request_id: str,
    api_key: str,
    *,
    attempts: int,
    interval: float,
    fetch_json: Callable[..., dict[str, Any]] = _json_request,
    sleep: Callable[[float], None] = time.sleep,
) -> dict[str, Any]:
    url = f"{API_ROOT}/api/v1/model/prediction/{request_id}"
    for attempt in range(attempts):
        prediction = _data(fetch_json(url, api_key=api_key))
        status = str(prediction.get("status", "")).lower()
        if status in TERMINAL_STATUSES:
            return prediction
        if attempt + 1 < attempts:
            sleep(interval)
    raise AtlasError(f"Prediction {request_id} did not finish after {attempts} checks")


def safe_output_path(raw_path: str, cwd: Path | None = None) -> Path:
    root = (cwd or Path.cwd()).resolve()
    requested = Path(raw_path)
    if requested.is_absolute():
        raise AtlasError("Output path must be relative to the project root")
    output = (root / requested).resolve()
    if root != output and root not in output.parents:
        raise AtlasError("Output path must stay inside the project root")
    return output


def prompt_from_spec(raw_path: str, asset_id: str | None, cwd: Path | None = None) -> str:
    root = (cwd or Path.cwd()).resolve()
    spec = safe_output_path(raw_path, root)
    specs_root = (root / "design" / "assets" / "specs").resolve()
    if specs_root not in spec.parents or spec.suffix.lower() != ".md":
        raise AtlasError("Spec path must be a Markdown file under design/assets/specs/")
    try:
        text = spec.read_text(encoding="utf-8")
    except OSError as exc:
        raise AtlasError(f"Could not read asset spec: {raw_path}") from exc

    section = text
    if asset_id:
        normalized = asset_id.upper()
        match = re.search(
            rf"^##\s+{re.escape(normalized)}\b.*?(?=^##\s+ASSET-[A-Z0-9_-]+\b|\Z)",
            text,
            flags=re.IGNORECASE | re.MULTILINE | re.DOTALL,
        )
        if not match:
            raise AtlasError(f"Asset id not found in spec: {asset_id}")
        section = match.group(0)

    match = re.search(
        r"\*\*Generation Prompt:\*\*\s*(.*?)(?=^\*\*[A-Za-z][^\n]*:\*\*|^##\s|\Z)",
        section,
        flags=re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise AtlasError("Selected asset has no Generation Prompt")
    prompt = match.group(1).strip()
    if prompt.startswith("```") and prompt.endswith("```"):
        prompt = re.sub(r"^```[^\n]*\n?|\n?```$", "", prompt).strip()
    if not prompt:
        raise AtlasError("Selected asset has an empty Generation Prompt")
    return prompt


def image_kind(content: bytes) -> str | None:
    if content.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if content.startswith(b"\xff\xd8\xff"):
        return "jpeg"
    if content.startswith((b"GIF87a", b"GIF89a")):
        return "gif"
    if content.startswith(b"RIFF") and content[8:12] == b"WEBP":
        return "webp"
    return None


def output_path_for_kind(output: Path, kind: str) -> Path:
    expected = {".jpg": "jpeg", ".jpeg": "jpeg"}.get(output.suffix.lower(), output.suffix.lower().lstrip("."))
    if not expected or expected == kind:
        return output
    suffix = ".jpg" if kind == "jpeg" else f".{kind}"
    return output.with_suffix(suffix)


def download_image(url: str, output: Path, *, overwrite: bool = False, timeout: float = 60) -> Path:
    if not url.startswith("https://"):
        raise AtlasError("Atlas Cloud returned a non-HTTPS output URL")
    request = urllib.request.Request(url, headers={"User-Agent": "ccgs-asset-generate/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            content_type = response.headers.get_content_type()
            content = response.read(25 * 1024 * 1024 + 1)
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as exc:
        raise AtlasError(f"Could not download generated image: {exc}") from exc
    kind = image_kind(content)
    if not content_type.startswith("image/") or kind is None:
        raise AtlasError(f"Generated output is not an image ({content_type})")
    if len(content) > 25 * 1024 * 1024:
        raise AtlasError("Generated image exceeds the 25 MB download limit")
    actual_output = output_path_for_kind(output, kind)
    if actual_output.exists() and not overwrite:
        raise AtlasError(f"Output already exists: {actual_output}")
    actual_output.parent.mkdir(parents=True, exist_ok=True)
    actual_output.write_bytes(content)
    return actual_output


def generate(args: argparse.Namespace) -> dict[str, Any]:
    api_key = os.getenv("ATLASCLOUD_API_KEY") or os.getenv("ATLAS_CLOUD_API_KEY")
    if not api_key:
        raise AtlasError("Set ATLASCLOUD_API_KEY before generating an asset")

    properties = resolve_model(args.model)
    validate_options(properties, args.aspect_ratio, args.resolution)
    output = safe_output_path(args.output)
    if output.exists() and not args.overwrite:
        raise AtlasError(f"Output already exists: {args.output} (use --overwrite to replace it)")

    prompt = args.prompt or prompt_from_spec(args.spec, args.asset_id)
    payload = {
        "model": args.model,
        "prompt": prompt,
        "aspect_ratio": args.aspect_ratio,
        "resolution": args.resolution,
        "enable_web_search": False,
        "enable_sync_mode": False,
        "enable_base64_output": False,
    }
    # Generation POST is deliberately issued exactly once and is never retried.
    created = _data(
        _json_request(
            f"{API_ROOT}/api/v1/model/generateImage",
            method="POST",
            api_key=api_key,
            payload=payload,
            timeout=args.request_timeout,
        )
    )
    request_id = created.get("id")
    if not request_id:
        raise AtlasError("Atlas Cloud did not return a prediction id; generation was not retried")

    try:
        prediction = poll_prediction(
            str(request_id),
            api_key,
            attempts=args.poll_attempts,
            interval=args.poll_interval,
        )
        if str(prediction.get("status", "")).lower() != "completed":
            raise AtlasError(f"ended with status: {prediction.get('status')}")
        outputs = prediction.get("outputs")
        if not isinstance(outputs, list) or not outputs:
            raise AtlasError("completed without an output URL")
        actual_output = download_image(str(outputs[0]), output, overwrite=args.overwrite)
    except AtlasError as exc:
        raise AtlasError(f"Prediction {request_id}: {exc}") from exc
    return {"id": request_id, "model": args.model, "output": str(actual_output)}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    prompt_source = parser.add_mutually_exclusive_group(required=True)
    prompt_source.add_argument("--prompt", help="Approved generation prompt")
    prompt_source.add_argument("--spec", help="Project-relative approved asset spec path")
    parser.add_argument("--asset-id", help="ASSET-NNN section to read from --spec")
    parser.add_argument("--output", required=True, help="Project-relative output image path")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--aspect-ratio", default="1:1")
    parser.add_argument("--resolution", default="1k")
    parser.add_argument("--poll-attempts", type=int, default=30)
    parser.add_argument("--poll-interval", type=float, default=2.0)
    parser.add_argument("--request-timeout", type=float, default=30.0)
    parser.add_argument("--overwrite", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.prompt and args.asset_id:
        raise SystemExit("--asset-id can only be used with --spec")
    if args.poll_attempts < 1 or args.poll_interval < 0:
        raise SystemExit("poll options must be non-negative and include at least one attempt")
    try:
        result = generate(args)
    except AtlasError as exc:
        print(f"ERROR: {exc}")
        return 1
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
