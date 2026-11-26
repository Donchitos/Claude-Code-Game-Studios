"""Guardrails for the @gamer external-scout agent and its skill integration.

Run: python3 -m unittest discover -s tests -p test_gamer_agent.py -v
"""
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
AGENT = ROOT / '.claude/agents/gamer.md'
SPEC = ROOT / 'studio-tests/agents/specialists/gamer.md'
SKILLS = ('brainstorm', 'prototype', 'start', 'next-step')


class GamerAgentTests(unittest.TestCase):
    def test_agent_is_registered(self):
        self.assertTrue(AGENT.is_file(), 'gamer agent definition missing')
        self.assertTrue(SPEC.is_file(), 'gamer test spec missing')
        catalog = (ROOT / 'studio-tests/catalog.yaml').read_text(encoding='utf-8')
        self.assertIn('name: gamer', catalog)
        self.assertIn('spec: studio-tests/agents/specialists/gamer.md', catalog)

    def test_agent_is_read_only_and_web_enabled(self):
        text = AGENT.read_text(encoding='utf-8')
        frontmatter = text.split('---', 2)[1]
        self.assertIn('WebSearch', frontmatter)
        self.assertIn('WebFetch', frontmatter)
        self.assertIn('model: inherit', frontmatter)
        self.assertNotIn('Write', frontmatter)
        self.assertNotIn('Edit', frontmatter)
        self.assertNotIn('AskUserQuestion', frontmatter)
        # An agent has no question tool: the orchestrator asks for it.
        self.assertIn('orchestrator', text)
        self.assertIn('no question tool', text)
        self.assertIn('websearch', text)
        self.assertIn('webfetch', text)

    def test_suggestion_types_and_output_contract(self):
        text = AGENT.read_text(encoding='utf-8')
        for kind in ('IMPROVEMENT', 'IMPLEMENTATION', 'FIX'):
            self.assertIn(kind, text)
        for confidence in ('High', 'Medium', 'Low'):
            self.assertIn(confidence, text)
        self.assertIn('Research brief', text)
        self.assertIn('Local comparison', text)
        self.assertIn('Suggestions', text)
        self.assertIn('Question for the orchestrator', text)

    def test_four_skills_trigger_gamer(self):
        for name in SKILLS:
            text = (ROOT / '.claude/skills' / name / 'SKILL.md').read_text(encoding='utf-8')
            self.assertIn('gamer', text, f'{name} does not mention gamer')
            self.assertIn('Write no files', text, f'{name} lacks the read-only return contract')
        # start and next-step had no Agent tool before this integration.
        for name in ('start', 'next-step'):
            text = (ROOT / '.claude/skills' / name / 'SKILL.md').read_text(encoding='utf-8')
            self.assertIn('Agent', text.split('allowed-tools:', 1)[1].split('\n', 1)[0])

    def test_agent_count_is_consistent(self):
        count = len(list((ROOT / '.claude/agents').glob('*.md')))
        self.assertEqual(count, 51, 'agent count drifted from the docs')
        claude = (ROOT / 'CLAUDE.md').read_text(encoding='utf-8')
        self.assertIn('51 coordinated Claude Code subagents', claude)


class AgentCheckNotesTests(unittest.TestCase):
    def notes(self, agent):
        result = subprocess.run(
            ['bash', str(ROOT / '.claude/scripts/agent-check.sh'), '--agent', agent],
            cwd=ROOT, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return [line for line in result.stdout.splitlines() if 'asks-user' in line]

    def test_tool_mentions_are_not_reported_as_asks_user(self):
        for agent in ('gamer', 'question-widget-specialist'):
            self.assertEqual(self.notes(agent), [], f'{agent} has asks-user noise')

    def test_real_ask_instructions_are_still_reported(self):
        self.assertTrue(self.notes('accessibility-specialist'),
                        'agent-check lost real asks-user detection')
