import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(os.environ.get('CCGS_MD_SECTION', Path(__file__).resolve().parents[1] / '.claude/scripts/md-section.sh'))


class CommentFenceTests(unittest.TestCase):
    def invoke(self, command, text, *args, replacement=None):
        with tempfile.TemporaryDirectory() as directory:
            document = Path(directory) / 'design.md'
            document.write_text(text)
            result = subprocess.run(['bash', str(SCRIPT), command, str(document), *args], input=replacement, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout, document.read_text()

    def test_commented_fences_do_not_hide_following_headings(self):
        for fence in ['```example', '~~~~example']:
            with self.subTest(fence=fence):
                output, _ = self.invoke('list', f'# First\n<!--\n{fence}\n-->\n# Second\nKeep me.\n')
                self.assertEqual(output, 'headings\t2\n1\t1\t4\tFirst\n1\t5\t6\tSecond\n')

    def test_extract_stops_before_the_next_real_section(self):
        output, _ = self.invoke('extract', '# First\n<!--\n```\n-->\n# Second\nKeep me.\n', 'First')
        self.assertEqual(output, '# First\n<!--\n```\n-->\n')

    def test_replace_preserves_the_following_section(self):
        _, updated = self.invoke('replace', '# First\n<!--\n```\n-->\n# Second\nKeep me.\n', 'First', replacement='New first section.\n')
        self.assertEqual(updated, '# First\n\nNew first section.\n\n# Second\nKeep me.\n')

    def test_comment_only_section_remains_empty(self):
        output, _ = self.invoke('status', '# First\n<!--\n```\n-->\n# Second\nKeep me.\n', 'First')
        self.assertIn('EMPTY\t1-4\tFirst\n', output)

    def test_real_fences_still_hide_headings_and_comment_markers(self):
        output, _ = self.invoke('list', '# First\n```\n<!--\n# Hidden\n```\n# Second\nKeep me.\n')
        self.assertEqual(output, 'headings\t2\n1\t1\t5\tFirst\n1\t6\t7\tSecond\n')


if __name__ == '__main__':
    unittest.main()
