"""Stdlib-only routing regression tests; fixtures do not modify the real checkout."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import startup


def fixture():
    def task(tid, owner, path):
        return dict(id=tid, owner=owner, title=tid, priority=1, status='planned', depends_on=[],
                    branch=f'feat/{owner}/{tid.lower()}', write_scopes=[path], acceptance=['test'],
                    evidence=[], issue_url=None, roles=['qa-tester'], open_questions=[])
    return dict(schema_version=1, revision=1, developers=['alicomert', 'okanipk'],
                integration_owner='alicomert', shared_paths=['project.godot'],
                tasks=[task('P1-A01', 'alicomert', 'src/player'), task('P1-O01', 'okanipk', 'src/interaction')])


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.data = fixture()

    def route(self, dev='alicomert', branch=None, dirty=None, leases=None):
        branch = branch if branch is not None else 'feat/alicomert/p1-a01'
        return startup.resolve(self.data, dev, branch, dirty or [], leases or [])

    def test_two_owners_have_distinct_ready_tasks(self):
        for dev, tid in [('alicomert', 'P1-A01'), ('okanipk', 'P1-O01')]:
            result = self.route(dev, f'feat/{dev}/{tid.lower()}')
            self.assertTrue(result['can_write'])
            self.assertEqual(result['candidate_task']['id'], tid)
            self.assertEqual(result['source_freshness'], 'unknown')
            self.assertEqual(result['coordination'], 'local-only')

    def test_phase2_task_routes_and_phase1_dependency_is_preserved(self):
        task = self.data['tasks'][0]
        task.update(id='P2-A01', branch='feat/alicomert/p2-ui-concepts',
                    write_scopes=['production/ui-concepts'], depends_on=['P1-O01'])
        self.assertFalse(self.route(branch=task['branch'])['can_write'])
        self.data['tasks'][1].update(status='done', evidence=['qa/evidence.md'])
        self.assertTrue(self.route(branch=task['branch'],
                                   dirty=['production/ui-concepts/index.html'])['can_write'])
        self.assertFalse(self.route(branch=task['branch'], dirty=['project.godot'])['can_write'])

    def test_phase2_shared_files_still_require_integration_owner_and_role(self):
        task = self.data['tasks'][0]
        task.update(id='P2-A01', write_scopes=['project.godot'])
        with self.assertRaises(ValueError):
            startup.validate_manifest(self.data)
        task['id'] = 'P2-I01'
        startup.validate_manifest(self.data)
        task['owner'] = 'okanipk'
        task['branch'] = 'feat/okanipk/p2-i01'
        with self.assertRaises(ValueError):
            startup.validate_manifest(self.data)

    def test_unsupported_phase_ids_remain_rejected(self):
        for tid in ('P0-A01', 'P3-A01', 'P2-X01', 'P2-A1', 'P2-A001'):
            with self.subTest(tid=tid), self.assertRaises(ValueError):
                data = fixture()
                data['tasks'][0]['id'] = tid
                startup.validate_manifest(data)

    def test_explicit_integration_handoff_is_narrow_and_completed_only(self):
        target, source = self.data['tasks']
        target.update(id='P2-I01', branch='feat/alicomert/p2-integration',
                      depends_on=['P1-O01'], write_scopes=['src/interaction'])
        source.update(status='done', evidence=['qa/proof.md'])
        handoff = dict(from_task='P1-O01', to_task='P2-I01',
                       scopes=['src/interaction'], reason='Owner approved integration')
        self.data['integration_handoffs'] = [handoff]
        startup.validate_manifest(self.data)
        for change in ('active_source', 'missing_dependency', 'narrow_scope', 'wrong_target', 'missing_reason'):
            bad = copy.deepcopy(self.data)
            if change == 'active_source':
                bad['tasks'][1]['status'] = 'in_progress'
            elif change == 'missing_dependency':
                bad['tasks'][0]['depends_on'] = []
            elif change == 'narrow_scope':
                bad['integration_handoffs'][0]['scopes'] = ['src/interaction/one.gd']
            elif change == 'wrong_target':
                bad['tasks'][0]['id'] = 'P2-A01'
                bad['integration_handoffs'][0]['to_task'] = 'P2-A01'
            else:
                bad['integration_handoffs'][0]['reason'] = ''
            with self.subTest(change=change), self.assertRaises(ValueError):
                startup.validate_manifest(bad)

    def test_display_name_is_not_identity(self):
        self.assertFalse(self.route('Ali Comert')['can_write'])

    def test_dirty_main_is_blocked_not_modified(self):
        result = self.route(branch='main', dirty=['CLAUDE.md', 'src/player/a.gd'])
        self.assertFalse(result['can_write'])
        self.assertIn('CLAUDE.md', result['dirty_paths'])

    def test_correct_task_dirty_is_resumable(self):
        self.assertTrue(self.route(dirty=['src/player/a.gd'])['can_write'])
        self.assertFalse(self.route(dirty=['src/player2/a.gd'])['can_write'])

    def test_wrong_branch_and_detached(self):
        for branch in ['', 'feat/okanipk/p1-o01', 'master']:
            with self.subTest(branch=branch):
                self.assertFalse(self.route(branch=branch)['can_write'])

    def test_same_owner_foreign_session_blocks(self):
        result = self.route(leases=[dict(developer='alicomert', session_id='other', write_scopes=['src/player'])])
        self.assertFalse(result['can_write'])

    def test_component_boundary_and_case_policy(self):
        self.assertFalse(startup.overlap(startup.scope('src/player'), startup.scope('src/player2')))
        self.assertTrue(startup.overlap(startup.scope('SRC/PLAYER'), startup.scope('src/player/a.gd')))

    def test_invalid_paths_fail_closed(self):
        for path in ['../escape', 'src/../escape', '/root', 'C:\\root', '\\\\host\\share', 'src//player', '.', 'src/*', 'src/Player.']:
            with self.subTest(path=path), self.assertRaises(ValueError):
                startup.scope(path)

    def test_cycle_missing_dependency_duplicate_and_owner(self):
        cases = []
        bad = fixture(); bad['tasks'][0]['depends_on'] = ['missing']; cases.append(bad)
        bad = fixture(); bad['tasks'][0]['depends_on'] = ['P1-O01']; bad['tasks'][1]['depends_on'] = ['P1-A01']; cases.append(bad)
        bad = fixture(); bad['tasks'].append(copy.deepcopy(bad['tasks'][0])); cases.append(bad)
        bad = fixture(); bad['tasks'][0]['owner'] = 'unknown'; cases.append(bad)
        for bad in cases:
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                startup.validate_manifest(bad)

    def test_cross_owner_overlap_rejected(self):
        self.data['tasks'][1]['write_scopes'] = ['src/player/a.gd']
        with self.assertRaises(ValueError):
            startup.validate_manifest(self.data)

    def test_shared_files_only_integration_task(self):
        self.data['tasks'][0]['write_scopes'] = ['project.godot']
        with self.assertRaises(ValueError):
            startup.validate_manifest(self.data)
        self.data['tasks'][0]['id'] = 'P1-I01'
        startup.validate_manifest(self.data)

    def test_dependency_and_open_decisions_block(self):
        task = self.data['tasks'][0]
        task['depends_on'] = ['P1-O01']
        self.assertFalse(self.route()['can_write'])
        other = self.data['tasks'][1]
        other['status'] = 'done'; other['evidence'] = ['qa/test.md']
        self.assertTrue(self.route()['can_write'])
        task['open_questions'] = ['drag or remote recall?']
        self.assertFalse(self.route()['can_write'])

    def test_done_requires_evidence(self):
        self.data['tasks'][0]['status'] = 'done'
        with self.assertRaises(ValueError):
            startup.validate_manifest(self.data)

    def test_multiple_active_tasks_need_resolution(self):
        second = copy.deepcopy(self.data['tasks'][0])
        second.update(id='P1-A02', branch='feat/alicomert/p1-a02', status='in_progress')
        self.data['tasks'][0]['status'] = 'in_progress'
        self.data['tasks'].append(second)
        self.assertFalse(self.route()['can_write'])

    def test_waiting_is_not_success(self):
        self.data['tasks'][0]['status'] = 'blocked'
        result = self.route(branch='feat/alicomert/unrelated')
        self.assertFalse(result['can_write'])
        self.assertIsNone(result['candidate_task'])

    def test_repository_manifest_and_roles(self):
        data = json.loads((startup.ROOT_DIR / startup.MANIFEST).read_text(encoding='utf-8'))
        startup.validate_manifest(data, startup.ROOT_DIR)
        for task in data['tasks']:
            for role in task['roles']:
                self.assertTrue((startup.ROOT_DIR / '.claude/agents' / (role + '.md')).is_file(), role)


class InspectionTests(unittest.TestCase):
    def test_identity_disagreement_fails_before_task_selection(self):
        with patch('startup.git', return_value='okanipk'), patch.dict(os.environ, {'SDLC_DEVELOPER': ''}):
            result = startup.inspect(developer='alicomert')
        self.assertFalse(result['can_write'])
        self.assertIn('IDENTITY_DISAGREEMENT', result['blocked_reasons'][0])

    def test_temporary_repository_routing_and_rename_dirty(self):
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'SDLC_DEVELOPER': ''}):
            root = Path(folder)
            def git(*args):
                subprocess.run(['git', *args], cwd=root, check=True, capture_output=True, timeout=5)
            git('init', '--quiet')
            git('config', '--local', 'sdlc.developer', 'alicomert')
            git('symbolic-ref', 'HEAD', 'refs/heads/feat/alicomert/p1-a01')
            (root / '.sdlc').mkdir()
            (root / startup.MANIFEST).write_text(json.dumps(fixture()), encoding='utf-8')
            (root / '.sdlc/locks.json').write_text('{"version":1,"locks":[]}', encoding='utf-8')
            (root / '.gitignore').write_text('.sdlc/\n.gitignore\n', encoding='utf-8')
            before = {str(p): p.read_bytes() for p in root.rglob('*') if p.is_file()}
            result = startup.inspect(root)
            self.assertTrue(result['can_write'], result)
            after = {str(p): p.read_bytes() for p in root.rglob('*') if p.is_file()}
            # Git status may update its own optional index metadata; routing never changes work files.
            self.assertEqual({k:v for k,v in before.items() if '/.git/' not in k.replace('\\','/')},
                             {k:v for k,v in after.items() if '/.git/' not in k.replace('\\','/')})
            (root / 'foreign file.txt').write_text('preserve', encoding='utf-8')
            result = startup.inspect(root)
            self.assertFalse(result['can_write'])
            self.assertEqual((root / 'foreign file.txt').read_text(), 'preserve')
            (root / '.sdlc/locks.json').write_text('{ broken', encoding='utf-8')
            self.assertFalse(startup.inspect(root)['can_write'])


if __name__ == '__main__':
    unittest.main()
