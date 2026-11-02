"""Rotation preserves the active narrative when its archive cannot be written."""
import datetime
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / ".claude/scripts/rotate-session-state.sh"


class RotationArchiveFailureTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.script = self.root / ".claude/scripts/rotate-session-state.sh"
        self.script.parent.mkdir(parents=True)
        shutil.copyfile(SCRIPT, self.script)
        self.state = self.root / "production/session-state/active.md"
        self.state.parent.mkdir(parents=True)
        self.original = "<!-- CHECKPOINT -->\ncheckpoint\n<!-- /CHECKPOINT -->\n" + "narrative\n" * 12
        self.state.write_text(self.original)
        self.logs = self.root / "production/session-logs"
        self.archive = self.logs / ("session-state-" + datetime.date.today().isoformat() + ".md")

    def run_rotation(self):
        return subprocess.run(["bash", str(self.script)], text=True, capture_output=True)

    def test_archive_directory_cannot_destroy_the_only_narrative_copy(self):
        self.archive.mkdir(parents=True)
        result = self.run_rotation()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("UNCHANGED", result.stderr)
        self.assertEqual(self.state.read_text(), self.original)

    def test_uncreatable_log_directory_preserves_the_active_file(self):
        self.logs.write_text("not a directory")
        result = self.run_rotation()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.state.read_text(), self.original)

    def test_successful_rotation_preserves_narrative_in_the_archive(self):
        result = self.run_rotation()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("narrative\n" * 12, self.archive.read_text())
        self.assertNotIn("narrative\n", self.state.read_text())
        self.assertIn("checkpoint\n<!-- /CHECKPOINT -->", self.state.read_text())


if __name__ == "__main__":
    unittest.main()
