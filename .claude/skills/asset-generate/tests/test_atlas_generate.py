import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "atlas_generate.py"
SPEC = importlib.util.spec_from_file_location("atlas_generate", SCRIPT)
atlas_generate = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(atlas_generate)


class AtlasGenerateTests(unittest.TestCase):
    def test_resolve_model_fetches_live_schema_shape(self):
        calls = []

        def fake_fetch(url, **_kwargs):
            calls.append(url)
            if url == atlas_generate.CATALOG_URL:
                return {
                    "data": [
                        {
                            "model": "example/model",
                            "display_console": True,
                            "schema": "https://example.test/schema.json",
                        }
                    ]
                }
            return {
                "components": {
                    "schemas": {
                        "Input": {
                            "properties": {
                                "model": {"type": "string"},
                                "prompt": {"type": "string"},
                                "aspect_ratio": {"enum": ["1:1"]},
                            }
                        }
                    }
                },
                "paths": {"/api/v1/model/generateImage": {"post": {}}},
            }

        properties = atlas_generate.resolve_model("example/model", fake_fetch)
        self.assertIn("prompt", properties)
        self.assertEqual(2, len(calls))

    def test_resolve_model_rejects_hidden_or_missing_model(self):
        def fake_fetch(_url, **_kwargs):
            return {"data": [{"model": "example/model", "display_console": False}]}

        with self.assertRaises(atlas_generate.AtlasError):
            atlas_generate.resolve_model("example/model", fake_fetch)

    def test_validate_options_uses_schema_enums(self):
        properties = {
            "aspect_ratio": {"enum": ["1:1", "16:9"]},
            "resolution": {"enum": ["1k", "2k"]},
        }
        atlas_generate.validate_options(properties, "16:9", "2k")
        with self.assertRaises(atlas_generate.AtlasError):
            atlas_generate.validate_options(properties, "4:5", "2k")

    def test_poll_prediction_only_retries_get(self):
        responses = iter(
            [
                {"data": {"id": "p-1", "status": "processing"}},
                {"data": {"id": "p-1", "status": "completed", "outputs": ["https://x"]}},
            ]
        )
        sleeps = []

        def fake_fetch(_url, **_kwargs):
            return next(responses)

        result = atlas_generate.poll_prediction(
            "p-1", "secret", attempts=3, interval=0.1, fetch_json=fake_fetch, sleep=sleeps.append
        )
        self.assertEqual("completed", result["status"])
        self.assertEqual([0.1], sleeps)

    def test_poll_prediction_is_bounded(self):
        def fake_fetch(_url, **_kwargs):
            return {"data": {"id": "p-1", "status": "processing"}}

        with self.assertRaises(atlas_generate.AtlasError):
            atlas_generate.poll_prediction(
                "p-1", "secret", attempts=2, interval=0, fetch_json=fake_fetch, sleep=lambda _n: None
            )

    def test_output_must_stay_inside_project(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            expected = (root / "assets" / "preview.png").resolve()
            self.assertEqual(expected, atlas_generate.safe_output_path("assets/preview.png", root))
            with self.assertRaises(atlas_generate.AtlasError):
                atlas_generate.safe_output_path("../preview.png", root)
            with self.assertRaises(atlas_generate.AtlasError):
                atlas_generate.safe_output_path("/tmp/preview.png", root)

    def test_image_kind_uses_file_signature(self):
        self.assertEqual("png", atlas_generate.image_kind(b"\x89PNG\r\n\x1a\n" + b"x" * 24))
        self.assertEqual("jpeg", atlas_generate.image_kind(b"\xff\xd8\xff" + b"x" * 29))
        self.assertIsNone(atlas_generate.image_kind(b"not an image"))

    def test_output_extension_tracks_generated_image_kind(self):
        output = Path("assets/preview.png")
        self.assertEqual(output, atlas_generate.output_path_for_kind(output, "png"))
        self.assertEqual(Path("assets/preview.jpg"), atlas_generate.output_path_for_kind(output, "jpeg"))

    def test_prompt_from_spec_selects_requested_asset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            spec = root / "design" / "assets" / "specs" / "enemies.md"
            spec.parent.mkdir(parents=True)
            spec.write_text(
                "## ASSET-001 — Slime\n\n**Generation Prompt:**\n```text\nBlue slime, no text\n```\n\n"
                "**Status:** Needed\n\n## ASSET-002 — Bat\n\n**Generation Prompt:**\nBlack bat\n",
                encoding="utf-8",
            )
            prompt = atlas_generate.prompt_from_spec(
                "design/assets/specs/enemies.md", "ASSET-001", root
            )
            self.assertEqual("Blue slime, no text", prompt)

    def test_prompt_from_spec_rejects_paths_outside_specs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with self.assertRaises(atlas_generate.AtlasError):
                atlas_generate.prompt_from_spec("README.md", None, root)


if __name__ == "__main__":
    unittest.main()
