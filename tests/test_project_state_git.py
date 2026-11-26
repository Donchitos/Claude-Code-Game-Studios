"""Run the observation helper in isolated, local-only Git fixtures."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ORIGIN = 'https://example.invalid/fixture.git'
ROWS = {'root', 'engine', 'code_root', 'source_files', 'concept', 'systems_index',
        'gdd_files', 'adr', 'story', 'prototype', 'sprint', 'milestone',
        'origin_url', 'stage_yaml', 'stage_txt', 'stage', 'phase', 'phase_inferred'}


class ProjectStateGitTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='project-state-git-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name).resolve()
        for name in ('home', 'xdg', 'hooks', 'templates'):
            (self.base / name).mkdir()
        for name in ('global', 'system'):
            (self.base / name).write_text('')
        self.env = {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin',
                    'HOME': str(self.base / 'home'), 'XDG_CONFIG_HOME': str(self.base / 'xdg'),
                    'LANG': 'C', 'LC_ALL': 'C', 'GIT_CONFIG_NOSYSTEM': '1',
                    'GIT_CONFIG_GLOBAL': str(self.base / 'global'),
                    'GIT_CONFIG_SYSTEM': str(self.base / 'system'),
                    'GIT_TERMINAL_PROMPT': '0', 'GIT_ALLOW_PROTOCOL': ''}
        self.git_binary = shutil.which('git', path=self.env['PATH'])
        if not self.git_binary:
            self.skipTest('Git is required to construct local fixtures')

    def run_command(self, args, cwd=None, env=None):
        result = subprocess.run(args, cwd=cwd or self.base, env=env or self.env,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def git(self, directory, *args):
        return self.run_command([self.git_binary, '-c', 'core.hooksPath=' + str(self.base / 'hooks'),
                                 '-c', 'init.templateDir=' + str(self.base / 'templates'),
                                 '-c', 'user.name=Project state fixture',
                                 '-c', 'user.email=fixture@example.invalid',
                                 '-c', 'commit.gpgsign=false', '-C', str(directory)] + list(args))

    def project(self, name, git=True, origin=True):
        directory = self.base / name
        scripts = directory / '.claude/scripts'
        scripts.mkdir(parents=True)
        for filename in ('project-state.sh', 'yaml-get.awk'):
            shutil.copyfile(ROOT / '.claude/scripts' / filename, scripts / filename)
        if git:
            self.git(directory, 'init', '-q')
            if origin:
                self.git(directory, 'config', 'remote.origin.url', ORIGIN)
            self.git(directory, 'add', '.claude/scripts')
            self.git(directory, 'commit', '-q', '-m', 'Owned fixture')
        return directory

    def linked(self):
        primary = self.project('primary with spaces')
        linked = self.base / 'linked with spaces'
        self.git(primary, 'worktree', 'add', '-q', '--detach', str(linked), 'HEAD')
        return primary, linked

    def observe(self, directory, env=None, cwd=None):
        output = self.run_command(['/bin/bash', '--noprofile', '--norc',
                                   str(directory / '.claude/scripts/project-state.sh'),
                                   '--root', str(directory)], cwd=cwd, env=env)
        rows = {fields[0]: fields[1:] for fields in (line.split('\t') for line in output.splitlines())}
        self.assertEqual(set(rows), ROWS)
        return rows['origin_url']

    def test_primary(self):
        primary = self.project('primary')
        self.assertEqual(self.observe(primary), [ORIGIN, '.git/config'])

    def test_linked_worktree_with_spaces(self):
        primary, linked = self.linked()
        self.assertEqual(self.observe(primary), [ORIGIN, '.git/config'])
        config = self.git(linked, 'rev-parse', '--git-path', 'config')
        self.assertEqual(self.observe(linked), [self.git(linked, 'config', '--local', '--get', 'remote.origin.url'), config])

    def test_no_origin(self):
        self.assertEqual(self.observe(self.project('no origin', origin=False)), ['-', '.git/config'])

    def test_non_git(self):
        self.assertEqual(self.observe(self.project('plain', git=False)), ['-', 'absent'])

    def test_primary_without_git_on_path(self):
        primary = self.project('primary')
        tools = self.base / 'tools'
        tools.mkdir()
        for name in ('awk', 'dirname', 'find', 'wc', 'tr', 'grep', 'head', 'sed'):
            target = shutil.which(name, path=self.env['PATH'])
            self.assertIsNotNone(target)
            (tools / name).symlink_to(target)
        env = dict(self.env, PATH=str(tools))
        self.assertEqual(self.observe(primary, env=env), [ORIGIN, '.git/config'])

    def test_explicit_root_ignores_foreign_discovery_environment(self):
        _, linked = self.linked()
        foreign = self.project('foreign')
        self.git(foreign, 'config', 'remote.origin.url', 'https://example.invalid/foreign.git')
        env = dict(self.env, GIT_DIR=str(foreign / '.git'), GIT_WORK_TREE=str(foreign),
                   GIT_COMMON_DIR=str(foreign / '.git'), GIT_INDEX_FILE=str(foreign / '.git/index'),
                   GIT_OBJECT_DIRECTORY=str(foreign / '.git/objects'),
                   GIT_ALTERNATE_OBJECT_DIRECTORIES=str(foreign / '.git/objects'),
                   GIT_CEILING_DIRECTORIES=str(self.base), GIT_DISCOVERY_ACROSS_FILESYSTEM='0')
        config = self.git(linked, 'rev-parse', '--git-path', 'config')
        self.assertEqual(self.observe(linked, env=env, cwd=foreign), [ORIGIN, config])


if __name__ == '__main__':
    unittest.main(verbosity=2)
