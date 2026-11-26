"""Guardrails for the inventory counts published in README.md and quick-start.md.

The repository has several different totals that are easy to confuse: 75 current
skills plus 3 legacy aliases, 62 top-level templates plus 12 support files, and
15 hook commands across 8 event types. These tests pin the documented scope so
the numbers cannot drift silently again.

Run: python3 -m unittest discover -s tests -p test_catalog_integrity.py -v
"""
import json
import pathlib
import re
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]


class InventoryIntegrityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = yaml.safe_load((ROOT / 'studio-tests/catalog.yaml').read_text())
        cls.settings = json.loads((ROOT / '.claude/settings.json').read_text())
        cls.readme = (ROOT / 'README.md').read_text()
        cls.quick = (ROOT / '.claude/docs/quick-start.md').read_text()
        cls.skill_dirs = {
            path.parent.name
            for path in (ROOT / '.claude/skills').glob('*/SKILL.md')
        }
        cls.agent_files = {
            path.stem for path in (ROOT / '.claude/agents').glob('*.md')
        }
        template_root = ROOT / '.claude/docs/templates'
        all_templates = {p for p in template_root.rglob('*') if p.is_file()}
        cls.top_templates = {
            p for p in all_templates if p.parent == template_root and p.suffix == '.md'
        }
        cls.guidance = {p for p in all_templates if 'guidance' in p.relative_to(template_root).parts}
        cls.support = all_templates - cls.top_templates - cls.guidance
        cls.hook_events = cls.settings['hooks']
        cls.hook_commands = sum(
            len(entry.get('hooks', []))
            for entries in cls.hook_events.values() for entry in entries
        )

    def test_catalog_matches_the_files_on_disk(self):
        skills = {entry['name'] for entry in self.catalog['skills']}
        agents = {entry['name'] for entry in self.catalog['agents']}
        self.assertTrue(skills <= self.skill_dirs, 'catalog names missing a SKILL.md')
        self.assertEqual(agents, self.agent_files, 'agent registry drifted from agent files')
        for kind in ('skills', 'agents'):
            for entry in self.catalog[kind]:
                self.assertTrue(
                    (ROOT / entry['spec']).is_file(),
                    f'{kind} {entry["name"]} has no spec',
                )

    def test_legacy_aliases_are_the_only_extra_skills(self):
        skills = {entry['name'] for entry in self.catalog['skills']}
        self.assertEqual(
            self.skill_dirs - skills,
            {'changelog', 'help', 'settings'},
            'unexpected SKILL.md outside the catalog',
        )
        self.assertEqual(len(self.skill_dirs), len(skills) + 3)

    def test_readme_table_counts_match_the_files(self):
        table = {
            name: int(count)
            for name, count in re.findall(
                r'^\| \*\*(\w+)\*\* \| (\d+) \|', self.readme, re.MULTILINE
            )
        }
        expected = {
            'Agents': len(self.agent_files),
            'Skills': len(self.catalog['skills']),
            'Hooks': self.hook_commands,
            'Rules': len(list((ROOT / '.claude/rules').glob('*'))),
            'Templates': len(self.top_templates),
        }
        for name, count in expected.items():
            self.assertEqual(table.get(name), count, f'README {name} count drifted')

    def test_documentation_states_the_scope_of_each_count(self):
        events = len(self.hook_events)
        total_templates = len(self.top_templates) + len(self.guidance) + len(self.support)
        self.assertIn(
            f'{self.hook_commands} hook commands across {events} events', self.readme
        )
        self.assertIn(
            f'78 SKILL.md files: 75 current skills + 3 legacy aliases', self.readme
        )
        self.assertIn(
            f'{len(self.top_templates)} top-level document templates; '
            f'{total_templates} files in total', self.readme
        )
        self.assertIn(f'{self.hook_commands} hook commands across {events} events', self.quick)
        self.assertIn('75 slash commands + 3 legacy aliases', self.quick)
        self.assertIn(
            f'{len(self.top_templates)} top-level document templates '
            f'({total_templates} files: +{len(self.guidance)} guides, '
            f'+{len(self.support)} scaffold/config)', self.quick
        )

    def test_workflow_yaml_parses(self):
        workflows = list((ROOT / '.github/workflows').glob('*.yml'))
        self.assertTrue(workflows, 'CI workflow missing')
        for path in workflows:
            with self.subTest(path=path.name):
                data = yaml.safe_load(path.read_text())
                self.assertIn('jobs', data)


if __name__ == '__main__':
    unittest.main()
