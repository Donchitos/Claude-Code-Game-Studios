"""ADR graph node IDs must come from filenames, not parent directories.

Run from the repository root:
    python3 -m unittest discover -s tests -p test_adr_graph_file_identity.py -v
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".claude/scripts/adr-dep-graph.sh"


class AdrGraphFileIdentityTests(unittest.TestCase):
    def write_adr(self, directory, number, dependency, suffix="decision"):
        path = directory / f"adr-{number:04d}-{suffix}.md"
        path.write_text(
            f"# ADR-{number:04d}\n\n## ADR Dependencies\n\n"
            "| Relationship | ADR |\n|---|---|\n"
            f"| **Depends On** | {dependency} |\n"
        )
        return path

    def run_graph(self, directory, cwd=None):
        argument = directory.relative_to(cwd) if cwd else directory
        result = subprocess.run(
            ["bash", str(SCRIPT), str(argument)],
            cwd=cwd,
            env={**os.environ, "LC_ALL": "C"},
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_parent_adr_ids_cannot_hide_a_two_node_cycle(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            ordinary = root / "ordinary"
            ordinary.mkdir()
            self.write_adr(ordinary, 1, "ADR-0002")
            self.write_adr(ordinary, 2, "ADR-0001")
            expected = self.run_graph(ordinary)
            self.assertIn("CYCLE: adr-0001 -> adr-0002\n", expected)
            self.assertIn("CYCLE: adr-0002 -> adr-0001\n", expected)
            self.assertIn("ORDER: (none)\n", expected)
            for folder in [
                "adr-9999-archive",
                "game adr-0001 archive/docs with spaces",
            ]:
                directory = root / folder
                directory.mkdir(parents=True)
                self.write_adr(directory, 1, "ADR-0002")
                self.write_adr(directory, 2, "ADR-0001")
                for cwd in [None, root]:
                    with self.subTest(folder=folder, relative=cwd is not None):
                        self.assertEqual(self.run_graph(directory, cwd), expected)

    def test_acyclic_order_uses_filename_ids_and_ignores_non_adr_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary) / "adr-9999 archive"
            directory.mkdir()
            self.write_adr(directory, 1, "ADR-0002", suffix="compare-adr-7777")
            self.write_adr(directory, 2, "None", suffix="decision with spaces")
            (directory / "notes.md").write_text(
                "# ADR-9998\n## ADR Dependencies\n| **Depends On** | ADR-0001 |\n"
            )
            output = self.run_graph(directory)
            self.assertIn("ADRS: 2\n", output)
            self.assertIn("  adr-0001 -> adr-0002\n", output)
            self.assertIn("ORDER: adr-0002, adr-0001\n", output)
            self.assertNotIn("CYCLE:", output)
            self.assertNotIn("adr-9999", output)
            self.assertNotIn("adr-7777", output)
            self.assertNotIn("adr-9998", output)

    def test_missing_and_unfilled_dependency_sections_name_the_actual_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary) / "adr-9999 archive"
            directory.mkdir()
            (directory / "adr-0001-decision.md").write_text("# ADR-0001\n")
            self.write_adr(directory, 2, "[List prerequisites]")
            output = self.run_graph(directory)
            self.assertIn("NO_DEPS_SECTION: adr-0001\n", output)
            self.assertIn("UNFILLED_DEPS: adr-0002\n", output)
            self.assertNotIn("adr-9999", output)

    def test_existing_self_reference_policy_is_unchanged(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            self.write_adr(directory, 1, "ADR-0001")
            output = self.run_graph(directory)
            self.assertIn("ADRS: 1\n", output)
            self.assertIn("ORDER: adr-0001\n", output)
            self.assertNotIn("CYCLE:", output)


if __name__ == "__main__":
    unittest.main()
