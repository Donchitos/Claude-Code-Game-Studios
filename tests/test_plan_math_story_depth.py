"""Run: python3 -m pip install -r tests/requirements.txt
python3 -m unittest discover -s tests -p test_plan_math_story_depth.py -v
"""
import pathlib
import subprocess
import tempfile
import unittest

import yaml

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / '.claude/scripts/plan-math.sh'


class StoryDepthTests(unittest.TestCase):
    def progress(self, payload, indent=2, newline='\n', second_priority='must-have',
                 padding=1, item_prefix=None, status_first=False):
        space = ' ' * indent
        item = space + '-' + ' ' * padding
        field = space + ' ' * (padding + 1)
        text = ('sprint: 1\nstart: "2026-11-01"\nend: "2026-11-03"\n'
                'stories:\n' + item + 'id: "1-1"\n' + field + 'priority: must-have\n'
                + field + 'status: done\n' + item + 'id: "1-2"\n'
                + field + 'priority: ' + second_priority + '\n' + field + 'status: blocked\n'
                + field + payload.replace('\n', '\n' + field) + '\n')
        if status_first:
            text = text.replace(item + 'id: "1-1"\n' + field + 'priority: must-have\n'
                                + field + 'status: done\n',
                                item + 'status: done\n' + field + 'id: "1-1"\n'
                                + field + 'priority: must-have\n')
        if item_prefix:
            content = {'empty': '', 'comment': '# story', 'anchor': '&story',
                       'tag': '!!map'}[item_prefix]
            text = text.replace(item + 'id:', item + content + '\n' + field + 'id:')
            text = text.replace('\n' + field, '\n' + space + '  ')
            if item_prefix == 'anchor':
                text = text.replace('&story\n', '&first\n', 1)
        self.check_progress(text, newline, second_priority)

    def check_progress(self, text, newline='\n', second_priority='must-have'):
        parsed = yaml.safe_load(text)
        self.assertEqual(len(parsed['stories']), 2)
        self.assertIsInstance(parsed['stories'][1]['blocker'], str)
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            path = root / 'production/sprint-status.yaml'
            path.parent.mkdir()
            before = text.replace('\n', newline).encode()
            path.write_bytes(before)
            result = subprocess.run(['/bin/bash', str(SCRIPT), 'progress', '--root', directory,
                                     '--today', '2026-11-02'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(path.read_bytes(), before)
        rows = [line.split('\t') for line in result.stdout.splitlines()]
        values = {row[0]: row[1] for row in rows if row[0] != 'status'}
        self.assertEqual(values['stories'], '2')
        self.assertEqual(values['done'], '1')
        self.assertEqual(values['done_pct'], '50')
        self.assertEqual(values['gap'], '0')
        self.assertEqual(values['band'], 'On Track')
        self.assertEqual(values['must_have'], '2' if second_priority == 'must-have' else '1')
        self.assertEqual(values['must_have_done'], '1')
        statuses = {row[1]: row[2] for row in rows if row[0] == 'status'}
        self.assertEqual(statuses['blocked'], '1')
        self.assertEqual(statuses['other'], '0')

    def test_blocker_bullets_are_not_story_items(self):
        for style in ('|', '>-'):
            for indent in (0, 2, 4):
                with self.subTest(style=style, indent=indent):
                    self.progress('blocker: ' + style + '\n  - Waiting for art\n  - Waiting for audio', indent)

    def test_blocker_text_is_not_story_status_or_priority(self):
        for style in ('|', '>-'):
            with self.subTest(style=style):
                self.progress('blocker: ' + style + '\n  status: done\n  priority: must-have',
                              second_priority='nice-to-have')

    def test_wide_item_prefix_preserves_field_alignment(self):
        self.progress('blocker: |\n  - Waiting for art', padding=4)

    def test_wide_item_can_start_with_status(self):
        self.progress('blocker: "Waiting for art"', padding=4, status_first=True)

    def test_item_comment_precedes_story_fields(self):
        for padding in (1, 4):
            with self.subTest(padding=padding):
                self.progress('blocker: "Waiting for art"', item_prefix='comment', padding=padding)

    def test_empty_item_content_precedes_story_fields(self):
        for padding in (1, 4):
            with self.subTest(padding=padding):
                self.progress('blocker: "Waiting for art"', item_prefix='empty', padding=padding)

    def test_quoted_first_key_determines_actual_mapping_depth(self):
        self.check_progress('''sprint: 1
start: "2026-11-01"
end: "2026-11-03"
stories:
  - status: done
    priority: must-have
    blocker: ""
  - EMPTY
    "blocker": |
      status: done
    id: "1-2"
    status: blocked
    priority: must-have
'''.replace('  - EMPTY', '  -    '))

    def test_item_metadata_does_not_determine_mapping_indent(self):
        for prefix in ('anchor', 'tag'):
            with self.subTest(prefix=prefix):
                self.progress('blocker: "Waiting for art"', item_prefix=prefix, padding=4)

    def test_inline_anchor_keeps_mapping_depth(self):
        self.check_progress('''sprint: 1
start: "2026-11-01"
end: "2026-11-03"
stories:
  - status: done
    priority: must-have
    blocker: ""
  - &story blocker: |
      status: done
    status: blocked
    priority: must-have
''')

    def test_plain_blocker_comments_and_crlf_preserve_metrics(self):
        for newline in ('\n', '\r\n'):
            with self.subTest(newline=repr(newline)):
                self.progress('blocker: "Waiting for art" # - not another story', newline=newline)


if __name__ == '__main__':
    unittest.main()
