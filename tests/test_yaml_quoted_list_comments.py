"""Inline comments on quoted YAML categories must not remove approval gates."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / ".claude/hooks/yaml-helper.sh"


class QuotedListCommentsTest(unittest.TestCase):
    def query(self, items, function="get_effective_yaml_array modes.automation_always_ask"):
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / "project.yaml").write_text("modes:\n  automation_always_ask:\n" + items)
            return subprocess.run(["bash", "-c", 'source "$1"; ' + function, "test", str(HELPER)],
                                  cwd=tmp, env={**os.environ, "CLAUDE_PROJECT_DIR": tmp},
                                  text=True, capture_output=True)

    def test_double_quoted_category_with_comment_remains_configured(self):
        result = self.query('    - "file_deletions" # confirm first\n', "is_always_ask_category file_deletions")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_single_quoted_category_with_comment_remains_configured(self):
        result = self.query("    - 'schema_changes' # review\n", "is_always_ask_category schema_changes")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_hash_inside_quotes_remains_part_of_the_value(self):
        result = self.query('    - "label # one" # outside\n')
        self.assertEqual(result.stdout, "label # one")

    def test_plain_and_quoted_uncommented_entries_keep_their_values(self):
        result = self.query('    - scope_changes # scope\n    - "file_deletions"\n')
        self.assertEqual(result.stdout.splitlines(), ["scope_changes", "file_deletions"])


if __name__ == "__main__":
    unittest.main()
