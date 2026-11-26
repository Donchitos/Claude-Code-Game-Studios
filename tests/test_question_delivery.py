"""Guardrails for the question-delivery protocol (widget first, no raw reasoning).

Run: python3 -m unittest discover -s tests -p test_question_delivery.py -v
"""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

# Instructions that made an agent print a question as raw text next to, or
# instead of, the rendered question widget.
LEAK_PHRASES = (
    'plain text, not a widget',
    'plain text, never with',
    'ask in plain text:',
    'ask (plain text)',
    'In plain text: "',
    'Then, in plain text:',
)


class QuestionDeliveryTests(unittest.TestCase):
    def test_central_rule_is_present(self):
        claude = (ROOT / 'CLAUDE.md').read_text(encoding='utf-8')
        modes = (ROOT / '.claude/docs/automation-modes.md').read_text(encoding='utf-8')
        self.assertIn("Questions go through the runtime's question widget", claude)
        self.assertIn('Question delivery — widget first, no raw reasoning', modes)
        self.assertIn('Do not emit reasoning, a draft', modes)
        # The shared "ask again in plain text" fallback line stays covered.
        self.assertIn('"ask again in plain text"', modes)
        # The root protocol must not contradict the widget-first rule.
        self.assertNotIn('re-ask in\n  plain text and wait', claude)

    def test_no_skill_instructs_a_raw_text_question(self):
        offenders = []
        for path in sorted((ROOT / '.claude/skills').rglob('*.md')):
            text = path.read_text(encoding='utf-8')
            for phrase in LEAK_PHRASES:
                if phrase in text:
                    offenders.append(f'{path.relative_to(ROOT)}: {phrase}')
        self.assertEqual(offenders, [], '\n'.join(offenders))


class QuestionWidgetAgentTests(unittest.TestCase):
    def test_agent_is_registered(self):
        agent = ROOT / '.claude/agents/question-widget-specialist.md'
        spec = ROOT / 'studio-tests/agents/specialists/question-widget-specialist.md'
        self.assertTrue(agent.is_file(), 'agent definition missing')
        self.assertTrue(spec.is_file(), 'agent test spec missing')
        catalog = (ROOT / 'studio-tests/catalog.yaml').read_text(encoding='utf-8')
        self.assertIn('name: question-widget-specialist', catalog)
        self.assertIn('spec: studio-tests/agents/specialists/question-widget-specialist.md', catalog)

    def test_agent_is_read_only_and_count_is_consistent(self):
        text = (ROOT / '.claude/agents/question-widget-specialist.md').read_text(encoding='utf-8')
        self.assertIn('tools: Read, Glob, Grep', text)
        self.assertNotIn('Write', text.split('\n## ')[0])
        count = len(list((ROOT / '.claude/agents').glob('*.md')))
        self.assertEqual(count, 51, 'agent count drifted from the docs')
        claude = (ROOT / 'CLAUDE.md').read_text(encoding='utf-8')
        self.assertIn('51 coordinated Claude Code subagents', claude)
