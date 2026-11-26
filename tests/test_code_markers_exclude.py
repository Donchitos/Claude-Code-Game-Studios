"""Exercise exclusions through the actual Bash helper in owned directories."""
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / '.claude/scripts/code-markers.sh'


class CodeMarkersExcludeTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='code-markers-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name).resolve()
        self.root = self.base / 'project [1].+ with spaces'
        self.root.mkdir()
        self.game = self.write(self.root / 'Assets/game.cs', '// TODO game\n')
        self.vendor = self.write(self.root / 'Assets/Plugins/vendor.cs', '// FIXME vendor\n')

    def write(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def scan(self, operand, exclude=None):
        args = ['/bin/bash', str(HELPER), '--root', str(self.root)]
        if exclude is not None:
            args += ['--exclude', exclude]
        args += [str(operand)]
        result = subprocess.run(args, capture_output=True, text=True, timeout=15,
                                env={'PATH': '/usr/bin:/bin', 'HOME': str(self.base), 'LC_ALL': 'C'})
        self.assertEqual(result.returncode, 0, result.stderr)
        rows = [line.split('\t') for line in result.stdout.splitlines()]
        counts = {row[0]: int(row[1]) for row in rows if row[0] in ('scanned_files', 'todo', 'fixme')}
        return counts, [row for row in rows if row[0] == 'MARK']

    def test_relative_operand(self):
        counts, _ = self.scan('Assets', 'Assets/Plugins/*')
        self.assertEqual(counts, dict(scanned_files=1, todo=1, fixme=0))

    def test_absolute_operand_matches_relative_exclusion(self):
        counts, marks = self.scan(self.root / 'Assets', 'Assets/Plugins/*')
        self.assertEqual(counts, dict(scanned_files=1, todo=1, fixme=0))
        self.assertEqual(marks, [['MARK', 'TODO', str(self.game), '1']])

    def test_direct_absolute_file(self):
        counts, marks = self.scan(self.vendor, 'Assets/Plugins/*')
        self.assertEqual(counts, dict(scanned_files=0, todo=0, fixme=0))
        self.assertEqual(marks, [])

    def test_no_exclusions_preserves_absolute_output(self):
        counts, marks = self.scan(self.root / 'Assets')
        self.assertEqual(counts, dict(scanned_files=2, todo=1, fixme=1))
        self.assertEqual({row[2] for row in marks}, {str(self.game), str(self.vendor)})

    def test_outside_root_is_not_treated_as_root_relative(self):
        outside = self.write(self.base / 'outside/Assets/Plugins/vendor.cs', '// FIXME outside\n')
        counts, marks = self.scan(outside, 'Assets/Plugins/*')
        self.assertEqual(counts, dict(scanned_files=1, todo=0, fixme=1))
        self.assertEqual(marks[0][2], str(outside))

    def test_root_prefix_sibling_is_not_stripped(self):
        sibling = self.write(Path(str(self.root) + '-sibling') / 'vendor.cs', '// FIXME sibling\n')
        counts, _ = self.scan(sibling, '-sibling/*')
        self.assertEqual(counts, dict(scanned_files=1, todo=0, fixme=1))

    def test_existing_absolute_exclusion_outside_root(self):
        outside = self.write(self.base / 'outside/vendor.cs', '// FIXME outside\n')
        counts, _ = self.scan(outside, str(self.base / 'outside') + '/*')
        self.assertEqual(counts, dict(scanned_files=0, todo=0, fixme=0))


if __name__ == '__main__':
    unittest.main(verbosity=2)
