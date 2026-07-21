## Summary

Describe the problem and the smallest change that solves it.

## Type Of Change

- [ ] Skill
- [ ] Role profile
- [ ] Hook or `.codex/hooks.json`
- [ ] `AGENTS.md` instruction rule
- [ ] Bug fix
- [ ] Documentation or template
- [ ] Package metadata
- [ ] Other:

## Changes

-

## Verification

List the commands, Codex skill invocations, hook events, and manual checks run.

## Checklist

- [ ] I tested the change in a project opened with Codex.
- [ ] Skill examples use `$skill-name` and skill files use `skills/<name>/SKILL.md`.
- [ ] Skill metadata in `agents/openai.yaml` is updated when needed.
- [ ] Role files are documented as injectable profiles, not registered agents.
- [ ] Hook changes are reflected in `.codex/hooks.json` and use portable Bash.
- [ ] I reviewed project-trust, shell-injection, secret-leakage, and path risks.
- [ ] Relevant studio reference docs and examples are updated.
- [ ] Referenced local paths and Markdown links were checked.
- [ ] `git diff --check` passes and skipped validation is explained.
