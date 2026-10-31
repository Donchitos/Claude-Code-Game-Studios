#!/usr/bin/env python3
"""Validate the generated OpenCode adapter.

Checks structure, frontmatter, command generation, policy constraints, and the
absence of Claude-only model pins. Run from the repository root:

    python3 tools/validate-opencode.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLAUDE_AGENTS = ROOT / ".claude" / "agents"
CLAUDE_SKILLS = ROOT / ".claude" / "skills"
OPENCODE = ROOT / ".opencode"
AGENTS = OPENCODE / "agents"
SKILLS = OPENCODE / "skills"
COMMANDS = OPENCODE / "commands"
DOCS = OPENCODE / "docs"

FORBIDDEN_MODEL_PINS = re.compile(r"\bmodel:\s*(sonnet|opus|haiku|inherit)\b")
FORBIDDEN_AGENT_FIELDS = {
    "name",
    "tools",
    "model",
    "maxTurns",
    "disallowedTools",
    "memory",
    "skills",
    "isolation",
}
FORBIDDEN_SKILL_FIELDS = {
    "model",
    "allowed-tools",
    "argument-hint",
    "user-invocable",
    "disable-model-invocation",
}
REQUIRED_DOCS = [
    "agents-reference.md",
    "skills-reference.md",
    "coordination-rules.md",
    "coding-standards.md",
    "directory-structure.md",
    "hooks-reference.md",
    "rules-reference.md",
    "permissions.md",
    "model-selection.md",
    "opencode-setup.md",
    "sync-and-maintenance.md",
    "troubleshooting.md",
    "context-management.md",
    "agent-teams.md",
]

problems: list[str] = []


def problem(message: str) -> None:
    problems.append(message)


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text
    fields: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if not line or line.lstrip().startswith("#") or ":" not in line:
            continue
        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip()
    return fields, text[end + 5 :]


def strip_jsonc(text: str) -> str:
    out: list[str] = []
    index = 0
    in_string = False
    escaped = False
    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""
        if in_string:
            out.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue
        if char == '"':
            in_string = True
            out.append(char)
            index += 1
            continue
        if char == "/" and nxt == "/":
            while index < len(text) and text[index] != "\n":
                index += 1
            continue
        if char == "/" and nxt == "*":
            index += 2
            while index + 1 < len(text) and not (text[index] == "*" and text[index + 1] == "/"):
                index += 1
            index += 2
            continue
        out.append(char)
        index += 1
    # Remove trailing commas left by commented-out entries.
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))


def check_config() -> None:
    path = ROOT / "opencode.jsonc"
    if not path.is_file():
        problem("missing opencode.jsonc")
        return
    try:
        config = json.loads(strip_jsonc(path.read_text(encoding="utf-8")))
    except Exception as error:  # noqa: BLE001 - report the parser message
        problem(f"opencode.jsonc is not valid JSONC: {error}")
        return

    if config.get("$schema") != "https://opencode.ai/config.json":
        problem("opencode.jsonc must keep the OpenCode $schema")
    if config.get("default_agent") != "studio":
        problem("opencode.jsonc default_agent should be studio")
    if "model" in config:
        problem("opencode.jsonc must not pin a root model")
    instructions = config.get("instructions")
    if not isinstance(instructions, list) or not instructions:
        problem("opencode.jsonc must list instruction files")
    else:
        for entry in instructions:
            if not isinstance(entry, str):
                problem(f"instruction entry is not a string: {entry!r}")
                continue
            if not (ROOT / entry).is_file():
                problem(f"instruction file does not exist: {entry}")
    experimental = config.get("experimental", {})
    if experimental.get("subagent_depth") != 3:
        problem("opencode.jsonc experimental.subagent_depth should be 3")
    if experimental.get("todo") is not True:
        problem("opencode.jsonc experimental.todo should be true")
    permissions = config.get("permissions")
    if not isinstance(permissions, list) or not permissions:
        problem("opencode.jsonc must define permissions")


def check_counts() -> None:
    canonical_agents = {p.stem for p in CLAUDE_AGENTS.glob("*.md")}
    canonical_skills = {p.name for p in CLAUDE_SKILLS.iterdir() if (p / "SKILL.md").is_file()}
    generated_agents = {p.stem for p in AGENTS.glob("*.md")}
    generated_skills = {p.name for p in SKILLS.iterdir() if (p / "SKILL.md").is_file()}
    generated_commands = {p.stem for p in COMMANDS.glob("*.md")}

    expected_agents = canonical_agents | {"studio"}
    if generated_agents != expected_agents:
        missing = expected_agents - generated_agents
        extra = generated_agents - expected_agents
        if missing:
            problem(f"missing generated agents: {', '.join(sorted(missing))}")
        if extra:
            problem(f"unexpected generated agents: {', '.join(sorted(extra))}")
    if generated_skills != canonical_skills:
        missing = canonical_skills - generated_skills
        extra = generated_skills - canonical_skills
        if missing:
            problem(f"missing generated skills: {', '.join(sorted(missing))}")
        if extra:
            problem(f"unexpected generated skills: {', '.join(sorted(extra))}")
    if generated_commands != canonical_skills:
        missing = canonical_skills - generated_commands
        extra = generated_commands - canonical_skills
        if missing:
            problem(f"missing commands: {', '.join(sorted(missing))}")
        if extra:
            problem(f"unexpected commands: {', '.join(sorted(extra))}")


def check_agents() -> None:
    for path in sorted(AGENTS.glob("*.md")):
        fields, body = split_frontmatter(path.read_text(encoding="utf-8"))
        name = path.stem
        for field in sorted(FORBIDDEN_AGENT_FIELDS & fields.keys()):
            problem(f"{path.relative_to(ROOT)} still has Claude field: {field}")
        if "description" not in fields:
            problem(f"{path.relative_to(ROOT)} has no description")
        if name == "studio":
            if fields.get("mode") != "primary":
                problem("studio.md must be mode: primary")
        else:
            if fields.get("mode") != "subagent":
                problem(f"{path.relative_to(ROOT)} must be mode: subagent")
            if "permissions" not in fields:
                problem(f"{path.relative_to(ROOT)} must define permissions")
        if not fields.get("steps", "").isdigit():
            problem(f"{path.relative_to(ROOT)} must have numeric steps")
        if "AskUserQuestion" in body and name not in {"skill-test", "skill-improve"}:
            problem(f"{path.relative_to(ROOT)} still mentions AskUserQuestion")


def check_skills() -> None:
    autoinvoke_off = {"day-one-patch", "dev-story", "hotfix", "launch-checklist", "story-done"}
    for path in sorted(SKILLS.glob("*/SKILL.md")):
        fields, body = split_frontmatter(path.read_text(encoding="utf-8"))
        name = path.parent.name
        for field in sorted(FORBIDDEN_SKILL_FIELDS & fields.keys()):
            problem(f"{path.relative_to(ROOT)} still has Claude field: {field}")
        if "description" not in fields:
            problem(f"{path.relative_to(ROOT)} has no description")
        if name in autoinvoke_off and "opencode/autoinvoke: false" not in path.read_text(encoding="utf-8"):
            problem(f"{path.relative_to(ROOT)} should set opencode/autoinvoke: false")
        if name not in {"skill-test", "skill-improve", "setup-engine"}:
            if "CLAUDE.md" in body:
                problem(f"{path.relative_to(ROOT)} still references CLAUDE.md")
            if "AskUserQuestion" in body:
                problem(f"{path.relative_to(ROOT)} still references AskUserQuestion")


def check_commands() -> None:
    for path in sorted(COMMANDS.glob("*.md")):
        fields, body = split_frontmatter(path.read_text(encoding="utf-8"))
        if "description" not in fields:
            problem(f"{path.relative_to(ROOT)} has no description")
        if "$ARGUMENTS" not in body:
            problem(f"{path.relative_to(ROOT)} does not pass $ARGUMENTS")
        command_name = path.stem
        if f"`{command_name}` skill" not in body:
            problem(f"{path.relative_to(ROOT)} does not name its skill")


def check_forbidden_text() -> None:
    scan = [AGENTS, SKILLS, COMMANDS]
    for directory in scan:
        for path in directory.rglob("*"):
            if not path.is_file() or path.suffix not in {".md", ".ts", ".json"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            # skill-test/skill-improve inspect the canonical Claude layer, where
            # `model: inherit` is a legitimate example. They are exempt.
            if not any(part in {"skill-test", "skill-improve"} for part in path.parts):
                match = FORBIDDEN_MODEL_PINS.search(text)
                if match:
                    problem(f"{path.relative_to(ROOT)} pins a Claude model: {match.group(0)}")
            if "AskUserQuestion" in text:
                problem(f"{path.relative_to(ROOT)} still mentions AskUserQuestion")
            if "the model Code" in text:
                problem(f"{path.relative_to(ROOT)} has a broken 'Claude Code' rewrite")
            if "CLAUDE_SKILL_DIR" in text:
                problem(f"{path.relative_to(ROOT)} still uses CLAUDE_SKILL_DIR")


def check_docs_and_plugin() -> None:
    for name in REQUIRED_DOCS:
        if not (DOCS / name).is_file():
            problem(f"missing OpenCode doc: .opencode/docs/{name}")
    plugin = OPENCODE / "plugins" / "ccgs" / "index.ts"
    if not plugin.is_file():
        problem("missing .opencode/plugins/ccgs/index.ts")
    package = OPENCODE / "plugins" / "ccgs" / "package.json"
    if not package.is_file():
        problem("missing .opencode/plugins/ccgs/package.json")


def main() -> int:
    if not CLAUDE_AGENTS.is_dir() or not CLAUDE_SKILLS.is_dir():
        print("validate-opencode: canonical .claude agents/skills not found", file=sys.stderr)
        return 2

    check_config()
    check_counts()
    check_agents()
    check_skills()
    check_commands()
    check_forbidden_text()
    check_docs_and_plugin()

    if problems:
        print(f"OpenCode validation failed with {len(problems)} problem(s):", file=sys.stderr)
        for entry in problems:
            print(f"  - {entry}", file=sys.stderr)
        return 1

    print(
        "OpenCode validation passed: "
        f"{len(list(AGENTS.glob('*.md')))} agents, "
        f"{len(list(SKILLS.glob('*/SKILL.md')))} skills, "
        f"{len(list(COMMANDS.glob('*.md')))} commands."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
