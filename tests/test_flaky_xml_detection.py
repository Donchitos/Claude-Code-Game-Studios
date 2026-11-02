"""Auto detection must classify real XML elements, not their logged examples.

Run from the repository root:
    python3 -m unittest discover -s tests -p test_flaky_xml_detection.py -v
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


SCRIPT = Path(__file__).resolve().parents[1] / ".claude/scripts/flaky-stats.sh"


class FlakyXmlDetectionTests(unittest.TestCase):
    def run_stats(self, directory, mode, *files):
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "--root",
                str(directory),
                "--format",
                mode,
                "--runs",
                *files,
            ],
            env={**os.environ, "LC_ALL": "C"},
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_junit_examples_in_comments_or_cdata_do_not_erase_passing_runs(self):
        decoys = [
            '<!-- <test-case result="Passed" name="example"/> -->',
            '<!--\nExample NUnit report:\n<test-case result="Passed" name="example"/>\n-->',
            '<system-out><![CDATA[Example: <test-case result="Passed" name="example"/>]]></system-out>',
            '<system-out><![CDATA[\n<test-case result="Passed" name="example"/>\n]]></system-out>',
            '<system-out message="Example &lt;test-case result=&quot;Passed&quot;/&gt;"/>',
            "<system-out><![CDATA[\"<test-case result='Passed' name='example'/>\"]]></system-out>",
        ]
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            failed = directory / "failed.xml"
            failed.write_text(
                '<testsuite><testcase classname="Suite" name="Example"><failure>Failed</failure></testcase></testsuite>'
            )
            for decoy in decoys:
                with self.subTest(decoy=decoy):
                    passed = directory / "passed.xml"
                    passed.write_text(
                        f'<testsuite><testcase classname="Suite" name="Example">{decoy}</testcase></testsuite>'
                    )
                    ET.parse(passed)
                    ET.parse(failed)
                    automatic = self.run_stats(
                        directory, "auto", "passed.xml", "failed.xml"
                    )
                    explicit = self.run_stats(
                        directory, "junit", "passed.xml", "failed.xml"
                    )
                    self.assertEqual(automatic, explicit)
                    self.assertIn("runs\t2\t2\n", automatic)
                    self.assertIn("flaky\t1\t", automatic)
                    self.assertIn("\t50.0\tPF\tyes\tsuspected\t", automatic)

    def test_mixed_xml_formats_keep_their_own_parser_and_do_not_double_count(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "junit.xml").write_text(
                '<testsuite><testcase classname="Suite" name="Example"/></testsuite>'
            )
            (directory / "nunit.xml").write_text(
                '<test-run><test-case fullname="Suite.Example" result="Failed"/></test-run>'
            )
            ET.parse(directory / "junit.xml")
            ET.parse(directory / "nunit.xml")
            output = self.run_stats(directory, "auto", "junit.xml", "nunit.xml")
            self.assertIn("runs\t2\t2\n", output)
            self.assertIn("RUN\t1\tjunit.xml\tjunit\t1\t1\t0\t0\t0\n", output)
            self.assertIn("RUN\t2\tnunit.xml\tnunit\t1\t0\t1\t0\t0\n", output)
            self.assertIn("\t50.0\tPF\tyes\tsuspected\t", output)

    def test_nunit_tags_with_quoted_content_and_junit_examples_are_not_counted_twice(
        self,
    ):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "passed.xml").write_text(
                '<test-run><test-case\n fullname="Suite.Example" result="Passed" label="quoted > payload">'
                '<output><![CDATA[<testcase name="example"/>]]></output>'
                "</test-case></test-run>"
            )
            (directory / "failed.xml").write_text(
                '<test-run><test-case fullname="Suite.Example" result="Failed"/></test-run>'
            )
            # Windows NUnit exports can split start tags across CRLF lines.
            passed = directory / "passed.xml"
            passed.write_bytes(passed.read_bytes().replace(b"\n", b"\r\n"))
            for filename in ["passed.xml", "failed.xml"]:
                ET.parse(directory / filename)
            automatic = self.run_stats(directory, "auto", "passed.xml", "failed.xml")
            explicit = self.run_stats(directory, "nunit", "passed.xml", "failed.xml")
            self.assertEqual(automatic, explicit)
            self.assertIn("runs\t2\t2\n", automatic)
            self.assertIn("\t50.0\tPF\tyes\tsuspected\t", automatic)

    def test_non_xml_angle_brackets_do_not_change_text_results(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "text.log").write_text(
                "diagnostic < unfinished token\n" * 1000 + "Suite.Example FAILED\n"
            )
            self.assertEqual(
                self.run_stats(directory, "auto", "text.log"),
                self.run_stats(directory, "text", "text.log"),
            )

    def test_unreal_and_text_auto_detection_remain_available(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "unreal.log").write_text(
                "Test Completed. Result={Success} Name={Example} Path={Suite.Example}\n"
            )
            (directory / "text.log").write_text("Suite.Example FAILED\n")
            for filename, mode in [("unreal.log", "unreal"), ("text.log", "text")]:
                with self.subTest(mode=mode):
                    self.assertEqual(
                        self.run_stats(directory, "auto", filename),
                        self.run_stats(directory, mode, filename),
                    )


if __name__ == "__main__":
    unittest.main()
