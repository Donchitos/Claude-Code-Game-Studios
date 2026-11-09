"""Committed design changes must not depend on Git's path quoting setting.

Run from the repository root:
    python3 -m unittest discover -s tests -p test_review_scope_git_paths.py -v
"""

from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".claude/scripts/review-scope.sh"


class ReviewScopeGitPathsTests(unittest.TestCase):
    def git(self, root, env, *args):
        return subprocess.run(
            ["git", *args],
            cwd=root,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=True,
            timeout=10,
        ).stdout

    @contextmanager
    def project(self, names, quote="true"):
        env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }
        env.update(
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_SYSTEM=os.devnull,
            GIT_CONFIG_NOSYSTEM="1",
            GIT_TERMINAL_PROMPT="0",
            LC_ALL="C",
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / ".claude/scripts").mkdir(parents=True)
            shutil.copyfile(SCRIPT, root / ".claude/scripts/review-scope.sh")
            gdds = root / "design/gdd"
            gdds.mkdir(parents=True)
            for name in names:
                (gdds / name).write_text(
                    "# System\n\nInitial design\n", encoding="utf-8"
                )
            (gdds / "gdd-cross-review-2026-10-30.md").write_text("# Review\n")
            self.git(root, env, "init", "-q")
            self.git(root, env, "config", "user.name", "Fixture")
            self.git(root, env, "config", "user.email", "fixture@example.invalid")
            if quote is not None:
                self.git(root, env, "config", "core.quotePath", quote)
            self.git(root, env, "add", ".")
            self.git(root, env, "commit", "-qm", "review baseline")
            yield root, env

    def run_scope(self, root, env):
        result = subprocess.run(
            ["bash", str(root / ".claude/scripts/review-scope.sh")],
            cwd=root,
            env=env,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_committed_unicode_changes_are_listed_with_either_quoting_setting(self):
        for quote in [None, "true", "false"]:
            for name in ["战斗系统.md", "Combat 系统.md"]:
                with (
                    self.subTest(quote=quote, name=name),
                    self.project([name], quote) as (root, env),
                ):
                    (root / "design/gdd" / name).write_text(
                        "# Changed design\n", encoding="utf-8"
                    )
                    self.git(root, env, "add", ".")
                    self.git(root, env, "commit", "-qm", "design changed after review")
                    self.assertIn(f"  design/gdd/{name}\n", self.run_scope(root, env))

    def test_staged_and_unstaged_unicode_changes_remain_listed(self):
        for quote in ["true", "false"]:
            for staged in [True, False]:
                with (
                    self.subTest(quote=quote, staged=staged),
                    self.project(["战斗.md"], quote) as (root, env),
                ):
                    (root / "design/gdd/战斗.md").write_text(
                        "# Changed design\n", encoding="utf-8"
                    )
                    if staged:
                        self.git(root, env, "add", ".")
                    self.assertIn("  design/gdd/战斗.md\n", self.run_scope(root, env))

    def test_spaces_dependencies_and_existing_exclusions_are_preserved(self):
        names = ["System Design.md", "combat.md", "deleted.md", "game-concept.md"]
        with self.project(names) as (root, env):
            (root / "design/gdd/System Design.md").write_text(
                "# System\n## Dependencies\n- combat.md\n"
            )
            (root / "design/gdd/game-concept.md").write_text("# Updated concept\n")
            (root / "design/gdd/deleted.md").unlink()
            self.git(root, env, "add", "-A")
            self.git(root, env, "commit", "-qm", "design changes and deletion")
            output = self.run_scope(root, env)
            self.assertIn("  design/gdd/System Design.md\n", output)
            self.assertIn("  System Design.md -> combat.md\n", output)
            self.assertNotIn("design/gdd/deleted.md", output)
            self.assertNotIn("design/gdd/game-concept.md", output)

    def test_committed_rename_keeps_the_existing_new_path(self):
        with self.project(["combat.md"]) as (root, env):
            self.git(root, env, "mv", "design/gdd/combat.md", "design/gdd/战斗.md")
            self.git(root, env, "commit", "-qm", "rename design")
            output = self.run_scope(root, env)
            self.assertIn("  design/gdd/战斗.md\n", output)
            self.assertNotIn("  design/gdd/combat.md\n", output)

    def test_unchanged_repo_and_untracked_unicode_file_remain_distinct(self):
        with self.project(["combat.md"]) as (root, env):
            self.assertIn(
                "(none — no GDDs modified since last review)", self.run_scope(root, env)
            )
            (root / "design/gdd/新系统.md").write_text(
                "# New design\n", encoding="utf-8"
            )
            self.assertIn("  design/gdd/新系统.md\n", self.run_scope(root, env))


if __name__ == "__main__":
    unittest.main()
