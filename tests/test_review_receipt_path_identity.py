"""Receipt lookup must use the entire file path, including spaces.

Run from the repository root:
    python3 -m unittest discover -s tests -p test_review_receipt_path_identity.py -v
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".claude/scripts/review-receipts.sh"


class ReviewReceiptPathIdentityTests(unittest.TestCase):
    def run_receipts(self, directory, *args):
        env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        env.update(
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_SYSTEM=os.devnull,
            GIT_CONFIG_NOSYSTEM="1",
            LC_ALL="C",
        )
        result = subprocess.run(
            ["bash", str(SCRIPT), *args],
            cwd=directory,
            env=env,
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
        return result.stdout

    def test_similarly_named_file_cannot_hide_a_changed_review_input(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            a, b = directory / "design.md", directory / "design.md notes.md"
            a.write_text("Original reviewed content\n")
            b.write_text("Updated content\n")
            stamps = self.run_receipts(directory, "hash", a.name, b.name)
            (directory / "receipt.md").write_text(stamps)
            a.write_text(b.read_text())
            output = self.run_receipts(directory, "check", "receipt.md", a.name)
            self.assertIn("CHANGED: design.md\n", output)
            self.assertNotIn("UNCHANGED: design.md\n", output)
            self.assertIn("UNCHANGED: design.md notes.md\n", output)

    def test_unstamped_input_remains_new_when_another_name_has_its_prefix(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for name in ["design.md", "design.md notes.md"]:
                (directory / name).write_text("Same content\n")
            (directory / "receipt.md").write_text(
                self.run_receipts(directory, "hash", "design.md notes.md")
            )
            output = self.run_receipts(directory, "check", "receipt.md", "design.md")
            self.assertIn("NEW: design.md\n", output)
            self.assertIn("UNCHANGED: design.md notes.md\n", output)

    def test_exact_latest_stamp_wins_with_spaces_metacharacters_and_crlf(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            name = "design [draft].md"
            other = name + " notes.md"
            (directory / name).write_text("Old\n")
            (directory / other).write_text("Other\n")
            stamps = self.run_receipts(directory, "hash", name, other)
            (directory / name).write_text("New\n")
            stamps += self.run_receipts(directory, "hash", name)
            (directory / "receipt.md").write_bytes(
                stamps.replace("\n", "\r\n").encode()
            )
            output = self.run_receipts(directory, "check", "receipt.md", name)
            self.assertIn(f"UNCHANGED: {name}\n", output)
            self.assertIn(f"UNCHANGED: {other}\n", output)

    def test_incomplete_latest_stamp_does_not_revalidate_an_older_stamp(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "design.md").write_text("Reviewed\n")
            stamps = self.run_receipts(directory, "hash", "design.md")
            stamps += "Reviewed-Content-Hash: design.md \n"
            (directory / "receipt.md").write_text(stamps)
            output = self.run_receipts(directory, "check", "receipt.md", "design.md")
            self.assertNotIn("UNCHANGED: design.md\n", output)

    def test_deleted_stamped_file_is_still_reported_gone(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            name = "design.md"
            (directory / name).write_text("Reviewed\n")
            (directory / "receipt.md").write_text(
                self.run_receipts(directory, "hash", name)
            )
            (directory / name).unlink()
            self.assertIn(
                "GONE: design.md\n",
                self.run_receipts(directory, "check", "receipt.md", name),
            )


if __name__ == "__main__":
    unittest.main()
