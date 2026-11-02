"""Exercise test-run's Unity wrapper with real commands and NUnit XML fixtures.

No Unity editor is used. Run from the repository root:
    python3 -m unittest discover -s tests -p test_unity_result_evidence.py -v
"""

import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET


SCRIPT = Path(__file__).resolve().parents[1] / ".claude/scripts/test-run.sh"
RUNNER = """
import argparse
from pathlib import Path
import xml.etree.ElementTree as ET
p = argparse.ArgumentParser()
p.add_argument('-testResults', default='test-results/editmode.xml')
p.add_argument('--total', default='1')
p.add_argument('--passed', default='1')
p.add_argument('--failed', default='0')
p.add_argument('--exit-code', type=int, default=0)
p.add_argument('--omit-report', action='store_true')
p.add_argument('--omit-total', action='store_true')
a = p.parse_args()
target = Path(a.testResults)
if target.exists():
    Path('stale-seen').write_text('The old results were not removed')
if not a.omit_report:
    target.parent.mkdir(parents=True, exist_ok=True)
    root = ET.Element('test-run', testcasecount=a.total, passed=a.passed, failed=a.failed)
    if a.omit_total:
        del root.attrib['testcasecount']
    if int(a.total):
        ET.SubElement(root, 'test-case', fullname='Fixture.Example',
                      result='Failed' if int(a.failed) else 'Passed')
    ET.ElementTree(root).write(target, encoding='unicode')
raise SystemExit(a.exit_code)
"""


class UnityResultEvidenceTests(unittest.TestCase):
    def run_wrapper(self, directory, target=None, quote=None, *runner_args):
        (directory / "Packages").mkdir(exist_ok=True)
        (directory / "Packages/manifest.json").write_text(
            json.dumps({"dependencies": {"com.unity.test-framework": "1.3.9"}})
        )
        runner = directory / "runner.py"
        runner.write_text(RUNNER)
        command = f"{shlex.quote(sys.executable)} {shlex.quote(str(runner))}"
        if target is not None:
            quoted = f"{quote}{target}{quote}" if quote else target
            command += f" -testResults {quoted}"
        command += "".join(" " + shlex.quote(value) for value in runner_args)
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "unity",
                "--root",
                str(directory),
                "--cmd",
                command,
                "--tool",
                "none",
                "--log",
                str(directory / "run.log"),
            ],
            env={**os.environ, "LC_ALL": "C"},
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ran\tyes\t-\n", result.stdout)
        return result.stdout

    def test_literal_result_paths_follow_bash_quoting_and_remove_stale_reports(self):
        cases = [
            (None, None),
            ("test-results/custom.xml", None),
            ("test-results/custom.xml", "'"),
            ("test-results/custom report.xml", "'"),
            ("test-results/custom report.xml", '"'),
            ("test-results/Bob's report.xml", '"'),
        ]
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for target, quote in cases:
                with self.subTest(target=target, quote=quote):
                    (directory / "stale-seen").unlink(missing_ok=True)
                    path = directory / (target or "test-results/editmode.xml")
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text(
                        '<test-run testcasecount="99" passed="99" failed="0"/>'
                    )
                    output = self.run_wrapper(directory, target, quote)
                    self.assertFalse((directory / "stale-seen").exists())
                    self.assertIn(
                        f"results_file\t{target or 'test-results/editmode.xml'}\tpresent\n",
                        output,
                    )
                    self.assertIn("tests\ttotal=1 passed=1 failed=0\n", output)
                    self.assertIn("rule\tunity:0\t", output)
                    ET.parse(path)

    def test_failed_report_is_not_described_as_all_passed_after_exit_zero(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            output = self.run_wrapper(
                directory, None, None, "--passed", "0", "--failed", "1"
            )
            ET.parse(directory / "test-results/editmode.xml")
            self.assertIn("exit\t0\n", output)
            self.assertIn("tests\ttotal=1 passed=0 failed=1\n", output)
            self.assertIn("rule\tunity:result-fail\t", output)
            self.assertNotIn("every test passed", output)

    def test_existing_command_exit_and_result_rules_remain_distinct(self):
        cases = [
            ([], "unity:0", "0"),
            (["--exit-code", "2", "--passed", "0", "--failed", "1"], "unity:2", "2"),
            (["--total", "0", "--passed", "0"], "unity:zero-tests", "0"),
            (["--omit-report"], "unity:no-results", "0"),
            (["--omit-total", "--passed", "0", "--failed", "1"], "unity:no-count", "0"),
        ]
        for args, rule, code in cases:
            with self.subTest(rule=rule), tempfile.TemporaryDirectory() as temporary:
                output = self.run_wrapper(Path(temporary), None, None, *args)
                self.assertIn(f"exit\t{code}\n", output)
                self.assertIn(f"rule\t{rule}\t", output)


if __name__ == "__main__":
    unittest.main()
