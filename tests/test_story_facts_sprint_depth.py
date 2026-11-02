"""Install: python3 -m pip install -r tests/requirements.txt
Run: python3 -m unittest discover -s tests -p test_story_facts_sprint_depth.py -v
"""
import pathlib
import subprocess
import tempfile
import unittest

import yaml

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / '.claude/scripts/story-facts.sh'
FILES = ['production/epics/example/story-001.md',
         'production/epics/example/story-002.md']
DECOY = 'production/epics/example/story-999.md'


def item(number, blocker, layout='inline', indent=2, padding=1):
    lead = ' ' * indent + '-' + ' ' * padding
    field = ' ' * (indent + padding + 1)
    parts = [('file', '"' + FILES[number] + '"'),
             ('status', 'done' if number == 0 else 'blocked'), ('blocker', blocker)]
    if layout in ('quoted', 'inline-anchor'):
        parts = [parts[2], *parts[:2]]
        if layout == 'quoted':
            parts[0] = ('"blocker"', blocker)
    lines = []
    for key, value in parts:
        lines.extend((key + ': ' + value).splitlines())
    if layout in ('comment', 'empty', 'anchor', 'tag', 'quoted'):
        metadata = {'comment': '# story', 'empty': '', 'anchor': '&story' + str(number),
                    'tag': '!!map', 'quoted': ''}[layout]
        field = ' ' * (indent + 2)
        return lead + metadata + '\n' + '\n'.join(field + line for line in lines) + '\n'
    prefix = '&story' + str(number) + ' ' if layout == 'inline-anchor' else ''
    return lead + prefix + lines[0] + '\n' + '\n'.join(field + line for line in lines[1:]) + '\n'


class SprintSelectionTests(unittest.TestCase):
    def run_fixture(self, text, missing=False, newline='\n'):
        parsed = yaml.safe_load(text)
        self.assertEqual([story['file'] for story in parsed['stories']], FILES)
        self.assertIsInstance(parsed['stories'][1]['blocker'], str)
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            for name, status in [(FILES[0], 'Complete'), (FILES[1], 'Blocked'), (DECOY, 'Complete')]:
                if missing and name == FILES[1]:
                    continue
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('# Story\n> **Status**: ' + status + '\n> **Type**: Logic\n')
            path = root / 'production/sprint-status.yaml'
            before = text.replace('\n', newline).encode()
            path.write_bytes(before)
            result = subprocess.run(['/bin/bash', str(SCRIPT), '--root', directory, '--sprint'],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 3 if missing else 0, result.stderr)
            self.assertEqual(path.read_bytes(), before)
        rows = [line.split('\t') for line in result.stdout.splitlines()]
        stories = [row for row in rows if row[0] == 'STORY']
        self.assertEqual([row[1] for row in stories], FILES[:1] if missing else FILES)
        self.assertEqual([row[-1] for row in stories], ['done'] if missing else ['done', 'blocked'])
        counts = {row[0]: row[1] for row in rows if row[0] in ('stories', 'complete', 'blocked')}
        self.assertEqual(counts, {'stories': '1' if missing else '2',
                                  'complete': '1', 'blocked': '0' if missing else '1'})
        self.assertEqual([row[1] for row in rows if row[0] == 'NOT_FOUND'],
                         FILES[1:] if missing else [])

    def fixture(self, blocker, **kwargs):
        return 'sprint: 1\nstories:\n' + item(0, '""', **kwargs) + item(1, blocker, **kwargs)

    def test_blocker_file_and_status_do_not_select_a_different_story(self):
        for style in ('|', '>-'):
            for indent in (0, 2, 4):
                with self.subTest(style=style, indent=indent):
                    self.run_fixture(self.fixture(style + '\n  file: ' + DECOY + '\n  status: done',
                                                  indent=indent))

    def test_blocker_bullets_do_not_flush_the_actual_story(self):
        self.run_fixture(self.fixture('|\n  - Waiting for art\n  status: done'))

    def test_empty_comment_and_metadata_items_infer_mapping_depth(self):
        for layout in ('empty', 'comment', 'anchor', 'tag', 'quoted'):
            with self.subTest(layout=layout):
                self.run_fixture(self.fixture('|\n  file: ' + DECOY + '\n  status: done',
                                              layout=layout, padding=4))

    def test_inline_anchor_and_wide_first_file_preserve_selection(self):
        self.run_fixture(self.fixture('|\n  file: ' + DECOY + '\n  status: done',
                                      layout='inline-anchor'))
        self.run_fixture(self.fixture('"Waiting"', padding=4))

    def test_missing_actual_story_is_reported_instead_of_reading_decoy(self):
        self.run_fixture(self.fixture('|\n  file: ' + DECOY + '\n  status: done'), missing=True)

    def test_plain_comments_crlf_and_outside_sprint_file_preserve_selection(self):
        for newline in ('\n', '\r\n'):
            with self.subTest(newline=repr(newline)):
                self.run_fixture(self.fixture('"Waiting" # file: ' + DECOY), newline=newline)


if __name__ == '__main__':
    unittest.main()
