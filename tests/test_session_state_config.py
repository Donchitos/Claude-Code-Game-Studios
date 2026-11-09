"""Session-state opt-out reads a feature setting, never nested prose."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / ".claude/hooks/yaml-helper.sh"


class SessionStateConfigTest(unittest.TestCase):
    def enabled(self, base, local=None):
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / "project.yaml").write_text(base)
            if local is not None:
                (Path(tmp) / "project.local.yaml").write_text(local)
            r = subprocess.run(["bash", "-c", 'source "$1"; session_state_enabled', "test", str(HELPER)],
                               cwd=tmp, env={**os.environ, "CLAUDE_PROJECT_DIR": tmp}, capture_output=True)
            return r.returncode == 0

    def test_comment_on_features_does_not_ignore_explicit_opt_out(self):
        self.assertFalse(self.enabled("features: # personal preferences\n  session_state: off\n"))

    def test_bom_does_not_ignore_explicit_opt_out(self):
        self.assertFalse(self.enabled("\ufefffeatures:\n  session_state: off\n"))

    def test_block_scalar_example_cannot_disable_recovery(self):
        self.assertTrue(self.enabled("features:\n  notes: |\n    session_state: off\n  session_state: on\n"))

    def test_nested_mapping_cannot_disable_recovery(self):
        self.assertTrue(self.enabled("features:\n  example:\n    session_state: off\n  session_state: on\n"))

    def test_last_direct_setting_matches_other_readers(self):
        self.assertTrue(self.enabled("features:\n  session_state: off\n  session_state: on\n"))

    def test_local_flag_keeps_precedence_and_unset_keeps_default(self):
        self.assertTrue(self.enabled("features:\n  session_state: off\n", "features:\n  session_state: on\n"))
        self.assertFalse(self.enabled("features:\n  session_state: on\n", "features:\n  session_state: off\n"))
        self.assertTrue(self.enabled("project:\n  name: example\n"))


if __name__ == "__main__":
    unittest.main()
