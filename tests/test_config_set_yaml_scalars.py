"""config-set must agree with YAML and both supported scalar readers.

Test-only setup and execution, from the repository root:
    python3 -m venv .venv-config-tests
    .venv-config-tests/bin/python -m pip install -r tests/requirements.txt
    .venv-config-tests/bin/python -m unittest discover -s tests -p test_config_set_yaml_scalars.py -v

The product script needs Bash and awk; PyYAML is only the independent test oracle.
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / ".claude/scripts/config-set.sh"


class ConfigSetYamlScalarTests(unittest.TestCase):
    def run_setter(self, root, value, *flags, key="project.name"):
        return subprocess.run(
            ["bash", str(SCRIPT), f"{key}={value}", "--root", str(root), *flags],
            capture_output=True,
            text=True,
            env={**os.environ, "LC_ALL": "C"},
        )

    def check_readers(self, config, key, expected):
        with config.open() as stream:
            parsed = yaml.safe_load(stream)
        for part in key.split("."):
            parsed = parsed[part]
        self.assertEqual(parsed, expected)
        for command in [
            ["awk", "-f", str(SCRIPT.parent / "yaml-get.awk"), str(config)],
            [
                "bash",
                str(ROOT / ".claude/hooks/yaml-helper.sh"),
                "get_yaml_key",
                str(config),
                key,
            ],
        ]:
            result = subprocess.run(
                command,
                env={**os.environ, "LC_ALL": "C", "YG_PATH": key},
                capture_output=True,
                text=True,
                check=True,
            )
            self.assertEqual(result.stdout.rstrip("\n"), str(expected))

    def test_structural_text_is_written_as_a_scalar(self):
        values = ["Foo: Bar", "Foo:\tBar", "Game:", "Bob's: Game", 'Say "Hi": Game']
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            for value in values:
                with self.subTest(value=value):
                    config.write_text("project:\n  name: Original\n")
                    result = self.run_setter(root, value)
                    self.assertEqual(
                        result.returncode, 0, result.stdout + result.stderr
                    )
                    self.check_readers(config, "project.name", value)

    def test_plain_and_existing_quoted_values_still_round_trip(self):
        cases = [
            ("Original", "Systems Design", "Systems Design"),
            ("Original", "https://example.com/game", "https://example.com/game"),
            ("Original", "Foo:Bar", "Foo:Bar"),
            ("Original", r"C:\Games\demo", r"C:\Games\demo"),
            ("Original", "-name", "-name"),
            ("Original", "?name", "?name"),
            ("Original", ":name", ":name"),
            ("12", "-12", -12),
            ('"Original"', "Foo: Bar", "Foo: Bar"),
            ("'Original'", "Foo: Bar", "Foo: Bar"),
            ('"Original"', r"C:\Games\demo", r"C:\Games\demo"),
            ("'Original'", "Bob's: Game", "Bob's: Game"),
            ('"Original"', 'Say "Hi": Game', 'Say "Hi": Game'),
            ("Original", 'Bob\'s "Game"', 'Bob\'s "Game"'),
        ]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            for original, value, expected in cases:
                with self.subTest(original=original, value=value):
                    config.write_text(f"project:\n  name: {original}\n")
                    result = self.run_setter(root, value)
                    self.assertEqual(
                        result.returncode, 0, result.stdout + result.stderr
                    )
                    self.check_readers(config, "project.name", expected)

    def test_unrepresentable_values_are_refused_before_write_or_dry_run(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            original = b"project:\n  name: Original\n"
            for value in ['Bob\'s "Game": now', "Bob's: C:\\Games"]:
                for flags in [(), ("--dry-run",)]:
                    with self.subTest(value=value, flags=flags):
                        config.write_bytes(original)
                        result = self.run_setter(root, value, *flags)
                        self.assertEqual(
                            result.returncode, 2, result.stdout + result.stderr
                        )
                        self.assertEqual(config.read_bytes(), original)

    def test_insertion_and_added_block_use_the_same_scalar_rendering(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            for original in ["project:\n  version: 1\n", "engine:\n  name: Godot\n"]:
                with self.subTest(original=original):
                    config.write_text(original)
                    result = self.run_setter(root, "Foo: Bar")
                    self.assertEqual(
                        result.returncode, 0, result.stdout + result.stderr
                    )
                    self.check_readers(config, "project.name", "Foo: Bar")

    def test_intentional_flow_array_keeps_array_semantics(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            config.write_text("platform:\n  targets: [Old]\n")
            result = self.run_setter(root, "[North, South]", key="platform.targets")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(
                yaml.safe_load(config.read_text())["platform"]["targets"],
                ["North", "South"],
            )
            array = subprocess.run(
                [
                    "bash",
                    "-c",
                    'source "$1"; get_yaml_array "$2" "$3"',
                    "test",
                    str(ROOT / ".claude/hooks/yaml-helper.sh"),
                    str(config),
                    "platform.targets",
                ],
                capture_output=True,
                text=True,
                check=True,
            )
            self.assertEqual(array.stdout.splitlines(), ["North", "South"])

    def test_safe_unchanged_values_remain_byte_identical(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            for original, value in [
                (b'project:\r\n  name: "Foo: Bar"   # title\r\n', "Foo: Bar"),
                (b"project:\n  name: Systems Design   # title\n", "Systems Design"),
            ]:
                with self.subTest(original=original):
                    config.write_bytes(original)
                    result = self.run_setter(root, value)
                    self.assertEqual(
                        result.returncode, 0, result.stdout + result.stderr
                    )
                    self.assertEqual(config.read_bytes(), original)

    def test_new_local_file_preserves_intentional_flow_array(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "project.yaml").write_text("project:\n  name: Original\n")
            result = self.run_setter(
                root,
                "[schema_changes, destructive_ops]",
                "--local",
                key="modes.automation_always_ask",
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            parsed = yaml.safe_load((root / "project.local.yaml").read_text())
            self.assertEqual(
                parsed["modes"]["automation_always_ask"],
                ["schema_changes", "destructive_ops"],
            )

    def test_dry_run_and_repair_of_an_existing_plain_colon_value(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / "project.yaml"
            original = b"project:\n  name: Foo: Bar\n"
            config.write_bytes(original)
            result = self.run_setter(root, "Foo: Bar", "--dry-run")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(config.read_bytes(), original)
            result = self.run_setter(root, "Foo: Bar")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.check_readers(config, "project.name", "Foo: Bar")


if __name__ == "__main__":
    unittest.main()
