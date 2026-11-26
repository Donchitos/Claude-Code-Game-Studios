#!/usr/bin/env bash
# agent-check.sh — observations about the agents and about every place a skill
# hands work to one.
#
# /skill-test reads agents and skills as text and judges them. Some of what it
# needs is mechanical and easy to miss by eye across 50 agent files: frontmatter
# that does not parse, two descriptions close enough that the wrong agent gets
# picked, an agent body that tells it to ask the user (an agent has no question
# tool), a setting the tool ignores. This script finds those and prints them, so
# every later change to an agent or a delegating skill is read the same way.
#
# OBSERVATIONS, NEVER VERDICTS (CLAUDE.md, "Helpers emit observations"). It
# prints what it found, with denominators first, and always exits 0 once it has
# run. Whether a tool list is beyond the job, whether two agents really overlap,
# whether a brief is good enough: the reader decides. The delegation markers are
# word counts, not grades.
#
# Usage: bash .claude/scripts/agent-check.sh [--agent <name>] [--skill <name>] [project-root]
#   --agent <name>  one agent: its block, the overlap pairs it is in, and the
#                   delegation blocks that name it
#   --skill <name>  one skill: its delegation blocks only
#   project-root    defaults to the repo root (the test suite passes fixtures)
#
# Output:
#   ROOT: <path>
#   AGENTS: <n>  SKILLS: <n>  SKILL_FILES: <n>  DELEGATION_BLOCKS: <n>
#   AGENT: <name> frontmatter=<ok|missing|unclosed> model=<v|unset> effort=<v|unset> maxTurns=<v|unset>
#     description: <text>
#     tools: <list | unset (inherits all)>   disallowed: <list>   skills: <list>
#     NOTE: <kind> <detail>                  one line per observation
#   OVERLAP: <a> <b> jaccard=<x> shared=<words>   (threshold printed first)
#   DELEGATION: <skill> <file>:<line> "<heading>" agents=<names> lines=<n>
#     markers: objective=<n> output=<n> sources=<n> boundaries=<n> recheck=<n>
#
# NOTE kinds:
#   frontmatter       a line that is not `key: value`, a list item or a continuation;
#                     a duplicate key; name missing or not the file name; no description
#   agent-type-list   `tools` lists Agent(...) types. In an agent file the type list
#                     is ignored; only the Agent tool itself counts
#   preload-off       `skills:` preloads a skill that sets disable-model-invocation:
#                     true, or one that does not exist
#   disallowed-specifier  a `disallowedTools` entry with a specifier, e.g.
#                     Bash(git push *): it removes the whole tool, not only those calls
#   memory-grants     `memory:` is set, which turns on Read, Write and Edit even when
#                     `tools` leaves them out
#   asks-user         a body line that tells the agent to ask the user or wait for
#                     approval; an agent's questions must come back in its report
#   no-delegations    printed under DELEGATION when no block was found, so "none
#                     found" is never silent

set -u

AGENT_FILTER=""
SKILL_FILTER=""
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --agent|--skill)
      [ $# -ge 2 ] || { echo "agent-check: $1 needs a value" >&2; exit 2; }
      if [ "$1" = "--agent" ]; then AGENT_FILTER="$2"; else SKILL_FILTER="$2"; fi
      shift 2 ;;
    --agent=*) AGENT_FILTER="${1#--agent=}"; shift ;;
    --skill=*) SKILL_FILTER="${1#--skill=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0"; exit 0 ;;
    *) ROOT_ARG="$1"; shift ;;
  esac
done

if [ -n "$ROOT_ARG" ]; then
  ROOT="$ROOT_ARG"
else
  cd "$(dirname "$0")/../.." || { echo "agent-check: cannot reach repo root" >&2; exit 1; }
  # `pwd -W` (Git Bash) gives C:/... so the Windows Python below can open it.
  ROOT="$(pwd -W 2>/dev/null || pwd)"
fi

if [ ! -d "$ROOT/.claude/agents" ]; then
  echo "agent-check: no .claude/agents folder under $ROOT" >&2
  exit 1
fi

# Python fallback chain: python -> python3 -> py (matches yaml-helper.sh).
PYBIN=""
for candidate in python python3 py; do
  if command -v "$candidate" >/dev/null 2>&1; then
    if "$candidate" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
      PYBIN="$candidate"; break
    fi
  fi
done
if [ -z "$PYBIN" ]; then
  echo "agent-check: no python 3 interpreter found (tried python, python3, py)" >&2
  exit 1
fi

"$PYBIN" - "$ROOT" "$AGENT_FILTER" "$SKILL_FILTER" <<'PYEOF'
import os
import re
import sys
from itertools import combinations

root, agent_filter, skill_filter = sys.argv[1:4]

# Descriptions carry em-dashes; a cp1252 console would raise mid-report.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except (AttributeError, ValueError):
    pass

# Jaccard over distinctive description words. Descriptions are one line, so
# scores run low: the pairs known to be confused (game-designer and
# systems-designer, qa-lead and qa-tester) score 0.12-0.13.
OVERLAP_THRESHOLD = 0.12
COMMON_SHARE = 0.25       # a word in more than this share of descriptions is not distinctive
STOPWORDS = set("""
about after also among and any are been before being between both but can could each
for from has have how into its like more most must not off one only other over own same
should such than that the their them then there these they this those through under use
used uses using via what when where which while who will with within without your
""".split())

ASKS_USER = re.compile(
    r"AskUserQuestion"
    r"|\bask(?:ing)? (?:the )?user\b"
    r"|\bask(?:ing)? (?:the user |them )?(?:clarifying |architecture |design |follow-up )?questions?\b"
    r"|\bMay I (?:write|create|edit|save|update|proceed|delete)\b"
    r"|\bwait(?:ing)? for (?:the user|approval|confirmation|their)\b"
    r"|\b(?:get|seek|obtain|request) (?:user |explicit )?(?:approval|sign-off|confirmation)\b"
    r"|\bconfirm with the user\b",
    re.IGNORECASE)

NO_TOOL = re.compile(r"AskUserQuestion`? is not\b|\bno (?:question tool|`?AskUserQuestion`?)\b|\bwithout (?:a question tool|`?AskUserQuestion`?)", re.I)

CUE = re.compile(
    r"\bspawn|\bsub-?agents?\b|`Agent`|\bAgent tool\b|\bsubagent_type\b"
    r"|\bdelegat|\bhand (?:it|this|them|each|the [\w-]+) (?:\w+ )?to\b|\bbrief\b",
    re.IGNORECASE)

MARKERS = {
    "objective": re.compile(r"\bask (?:them|it|each)\b|\bto (?:review|check|write|design|draft|produce|validate|assess|evaluate|audit|analy[sz]e|create|implement|identify|find)\b|\bgoal\b|\bobjective\b", re.I),
    "output": re.compile(r"\breturn\b|\boutput\b|\breport\b|\bformat\b|\bwrite (?:your|the|its) [\w ]{0,20}to\b", re.I),
    "sources": re.compile(r"`[\w.-]+/[\w./*-]+`|\bread\b|\bpass\b|\binputs?\b|\bsources?\b", re.I),
    "boundaries": re.compile(r"\bdo not\b|\bdon't\b|\bnever\b|\bonly\b|\bmust not\b", re.I),
    "recheck": re.compile(r"\bre-?check|\bre-?verify|\bdouble-check|\bsecond opinion\b|\bverify (?:your|the|its) own\b", re.I),
}


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def frontmatter(text):
    """Return (status, fields, notes, body_start_line). Hand-parsed: no PyYAML."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return "missing", {}, ["no frontmatter block"], 0
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        return "unclosed", {}, ["frontmatter never closes with ---"], 0
    fields, notes, key = {}, [], None
    for n, line in enumerate(lines[1:end], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z][\w-]*):(.*)$", line)
        if m:
            key = m.group(1)
            if key in fields:
                notes.append("duplicate key %s (line %d)" % (key, n))
            fields[key] = m.group(2).strip()
        elif key and re.match(r"^\s+(-\s+)?\S", line):
            item = re.sub(r"^\s+(-\s+)?", "", line).strip()
            fields[key] = (fields[key] + ", " + item).strip(", ")
        else:
            notes.append("line %d is not key: value: %s" % (n, line.strip()[:80]))
    return "ok", fields, notes, end + 1


def unquote(v):
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        v = v[1:-1]
    return v


def split_list(v):
    """Split a tools/skills value on commas outside parentheses; accepts [a, b]."""
    v = unquote(v)
    if v.startswith("[") and v.endswith("]"):
        v = v[1:-1]
    out, depth, cur = [], 0, ""
    for ch in v:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(unquote(cur))
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(unquote(cur))
    return [x for x in (s.strip() for s in out) if x]


def words(text):
    return {w for w in re.findall(r"[a-z]{4,}", text.lower()) if w not in STOPWORDS}


# --- agents ---------------------------------------------------------------
agent_dir = os.path.join(root, ".claude", "agents")
skill_dir = os.path.join(root, ".claude", "skills")
agents = {}
for fn in sorted(os.listdir(agent_dir)):
    if fn.endswith(".md"):
        agents[fn[:-3]] = os.path.join(agent_dir, fn)

skills = {}
if os.path.isdir(skill_dir):
    for d in sorted(os.listdir(skill_dir)):
        p = os.path.join(skill_dir, d, "SKILL.md")
        if os.path.isfile(p):
            skills[d] = os.path.join(skill_dir, d)

skill_files = []
for name, d in skills.items():
    for dirpath, _, files in os.walk(d):
        for f in sorted(files):
            if f.endswith(".md"):
                skill_files.append((name, os.path.join(dirpath, f)))


def model_invocation_off(skill):
    d = skills.get(skill)
    if not d:
        return None
    _, fm, _, _ = frontmatter(read(os.path.join(d, "SKILL.md")))
    return unquote(fm.get("disable-model-invocation", "")).lower() == "true"


records = {}
for name, path in agents.items():
    text = read(path)
    status, fm, notes, body_start = frontmatter(text)
    rec = {"status": status, "fm": fm, "notes": ["frontmatter " + n for n in notes]}
    if status == "ok":
        if "name" not in fm:
            rec["notes"].append("frontmatter name missing")
        elif unquote(fm["name"]) != name:
            rec["notes"].append("frontmatter name %s is not the file name %s" % (unquote(fm["name"]), name))
        if not unquote(fm.get("description", "")):
            rec["notes"].append("frontmatter description missing or empty")
        tools = split_list(fm.get("tools", ""))
        typed = [t for t in tools if re.match(r"^Agent\s*\(", t)]
        if typed:
            rec["notes"].append("agent-type-list tools lists %s; in an agent file only the Agent tool counts, the type list is ignored" % typed[0])
        for t in split_list(fm.get("disallowedTools", "")):
            if "(" in t:
                rec["notes"].append("disallowed-specifier disallowedTools lists %s; a specifier still removes the whole tool, not only the matching calls" % t)
        if unquote(fm.get("memory", "")) and tools:
            missing = [t for t in ("Read", "Write", "Edit") if t not in tools]
            if missing:
                rec["notes"].append("memory-grants memory: is set, which turns on %s although tools does not list them" % ", ".join(missing))
        for sk in split_list(fm.get("skills", "")):
            off = model_invocation_off(sk)
            if off is None:
                rec["notes"].append("preload-off skills: lists %s, which is not a skill in .claude/skills/" % sk)
            elif off:
                rec["notes"].append("preload-off skills: lists %s, which sets disable-model-invocation: true" % sk)
    body = text.splitlines()[body_start:]
    for i, line in enumerate(body, start=body_start + 1):
        # A line that says the question tool is absent is the fix, not the problem.
        if ASKS_USER.search(line) and not NO_TOOL.search(line):
            rec["notes"].append("asks-user line %d: %s" % (i, line.strip()[:120]))
    records[name] = rec

# --- description overlap -------------------------------------------------
desc_words = {n: words(unquote(r["fm"].get("description", ""))) for n, r in records.items()}
df = {}
for ws in desc_words.values():
    for w in ws:
        df[w] = df.get(w, 0) + 1
limit = max(2, int(len(desc_words) * COMMON_SHARE))
common = {w for w, c in df.items() if c > limit}
distinct = {n: ws - common for n, ws in desc_words.items()}
pairs = []
for a, b in combinations(sorted(distinct), 2):
    union = distinct[a] | distinct[b]
    if not union:
        continue
    j = len(distinct[a] & distinct[b]) / len(union)
    if j >= OVERLAP_THRESHOLD:
        pairs.append((j, a, b, sorted(distinct[a] & distinct[b])))
pairs.sort(key=lambda p: (-p[0], p[1], p[2]))

# --- delegation blocks in skills ------------------------------------------
weak = {n for n in agents if "-" not in n}   # e.g. writer, producer: plain words too


def names_in(text):
    found = []
    for n in agents:
        if n in weak:
            pat = r"(?:`%s`|\*\*%s\*\*|subagent_type:\s*%s\b)" % ((re.escape(n),) * 3)
        else:
            pat = r"(?<![\w-])%s(?![\w-])" % re.escape(n)
        if re.search(pat, text):
            found.append(n)
    return found


blocks = []
for sname, path in skill_files:
    lines = read(path).splitlines()
    # Code fences hold templates and example output: a heading there does not
    # start a block, and an agent named there is an example, not a hand-off.
    # The markers still count fenced text, where a brief is often written out.
    fenced, inside = [], False
    for l in lines:
        if l.lstrip().startswith("```"):
            inside = not inside
            fenced.append(True)
        else:
            fenced.append(inside)
    starts = [i for i, l in enumerate(lines) if not fenced[i] and re.match(r"^#{1,6}\s", l)] or [0]
    if starts[0] != 0:
        starts.insert(0, 0)
    for k, s in enumerate(starts):
        e = starts[k + 1] if k + 1 < len(starts) else len(lines)
        chunk = "\n".join(lines[s:e])
        prose = "\n".join(l for i, l in enumerate(lines[s:e], start=s) if not fenced[i])
        if not CUE.search(prose):
            continue
        named = names_in(prose)
        if not named:
            continue
        heading = lines[s].lstrip("#").strip() if re.match(r"^#{1,6}\s", lines[s]) else "(top of file)"
        marks = {k2: len(rx.findall(chunk)) for k2, rx in MARKERS.items()}
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        blocks.append((sname, rel, s + 1, heading[:70], named, e - s, marks))

# --- report --------------------------------------------------------------
show_agents = sorted(agents) if not agent_filter else [agent_filter]
if skill_filter:
    show_agents = []
show_blocks = [b for b in blocks
               if (not skill_filter or b[0] == skill_filter)
               and (not agent_filter or agent_filter in b[4])]

print("ROOT: %s" % root)
print("AGENTS: %d  SKILLS: %d  SKILL_FILES: %d  DELEGATION_BLOCKS: %d"
      % (len(agents), len(skills), len(skill_files), len(blocks)))
if agent_filter and agent_filter not in agents:
    print("NOT FOUND: agent %s is not a file in .claude/agents/" % agent_filter)
    show_agents = []
if skill_filter and skill_filter not in skills:
    print("NOT FOUND: skill %s is not a folder in .claude/skills/" % skill_filter)

for name in show_agents:
    r = records[name]
    fm = r["fm"]
    print("AGENT: %s frontmatter=%s model=%s effort=%s maxTurns=%s" % (
        name, r["status"], unquote(fm.get("model", "")) or "unset",
        unquote(fm.get("effort", "")) or "unset", unquote(fm.get("maxTurns", "")) or "unset"))
    print("  description: %s" % (unquote(fm.get("description", "")) or "(none)"))
    tools = split_list(fm.get("tools", ""))
    print("  tools: %s   disallowed: %s   skills: %s" % (
        ", ".join(tools) if tools else "unset (inherits all)",
        ", ".join(split_list(fm.get("disallowedTools", ""))) or "none",
        ", ".join(split_list(fm.get("skills", ""))) or "none"))
    for note in r["notes"]:
        print("  NOTE: %s" % note)

if not skill_filter:
    print("OVERLAP_THRESHOLD: jaccard >= %.2f over description words in at most %d of %d descriptions"
          % (OVERLAP_THRESHOLD, limit, len(desc_words)))
    shown = [p for p in pairs if not agent_filter or agent_filter in (p[1], p[2])]
    for j, a, b, shared in shown:
        print("OVERLAP: %s %s jaccard=%.2f shared=%s" % (a, b, j, ",".join(shared)))
    if not shown:
        print("OVERLAP: none at or above the threshold")

for sname, rel, line, heading, named, n, marks in show_blocks:
    print('DELEGATION: %s %s:%d "%s" agents=%s lines=%d' % (sname, rel, line, heading, ",".join(named), n))
    print("  markers: " + " ".join("%s=%d" % kv for kv in marks.items()))
if not show_blocks and (skill_filter or not agent_filter or agent_filter in agents):
    print("DELEGATION: no-delegations found in the files read")
PYEOF
exit 0
