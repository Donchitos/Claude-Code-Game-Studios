#!/usr/bin/env bash
# artifact-check.sh — evaluate every workflow-catalog step's artifact spec
# against what is actually on disk.
#
# Replaces the "Use Glob and Read to verify files exist and have meaningful
# content" loop in /gate-check (and the equivalent hand-scans in /help and
# /project-stage-detect). workflow-catalog.yaml already encodes `glob`,
# `pattern`, `min_count` and `any_of` per step; nothing consumed it
# deterministically, so the model re-derived the same answers by opening files.
#
# EMITS OBSERVATIONS, NOT A VERDICT (per .claude/docs/context-management.md
# rule 2). It reports what is on disk; the CALLER applies the workflow tier,
# the required/optional distinction, and any per-system override. In
# particular this script never says PASS or FAIL, and never decides that an
# ABSENT artifact is a blocker — at `minimal` most of them are not.
#
# Usage: bash .claude/scripts/artifact-check.sh [--phase <id> | --path <id>] [project-root]
#   --phase <id>  restrict output to one phase (concept, systems-design, ...)
#   --path <id>   report one tier path instead of the phase ladder (`minimal`).
#                 Paths live under the catalog's top-level `paths:` key with the
#                 same step schema. Without --path they are never reported, so
#                 the ladder's consumers see exactly what they saw before paths.
#   project-root  defaults to the repo root; an explicit path is taken as-is
#                 (used by the test suite against fixtures).
#
# Output:
#   CATALOG: <path>            the catalog actually read
#   ROOT: <path>               the tree evaluated against
#   PHASES: <n> / STEPS: <n>   denominators — see below (PATHS: with --path)
#   PHASE: <id>                (PATH: <id> with --path)
#     STEP: <id> required=<bool> repeatable=<bool> check=<kind> status=<status> ...
#
# status values (observations):
#   PRESENT       glob matched, count >= min_count, pattern found if specified
#   ABSENT        no file matched the glob
#   SHORT         files matched but fewer than min_count
#   PATTERN_MISS  files matched but none contained the required pattern
#   NO_CHECK      the step declares no artifact — completion is not detectable
#                 from disk. NOT the same as ABSENT. A `note=` field carries the
#                 catalog's human-readable fallback where one exists.
#
# DENOMINATOR DISCIPLINE (mirrors create-control-manifest / adr-dep-graph.sh):
# STEPS is printed before any per-step line so a caller can tell "0 steps
# reported because the catalog failed to parse" from "0 steps are incomplete".
# A NO_CHECK count is printed too — a phase that is all NO_CHECK has been
# *scanned*, not *satisfied*, and reporting it as clean would be a false pass.
#
# Patterns are POSIX ERE and are matched with `grep -E`, never Python `re`
# (the catalog uses classes like [[:space:]]) and never `grep -P` (unavailable
# on Windows Git Bash — see .claude/docs/coding-standards notes).

set -u

PHASE_FILTER=""
PATH_FILTER=""
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    # A trailing flag with no value used to loop forever: `shift 2` with one
    # argument left fails without shifting anything.
    --phase|--path)
      [ $# -ge 2 ] || { echo "artifact-check: $1 needs a value" >&2; exit 2; }
      if [ "$1" = "--phase" ]; then PHASE_FILTER="$2"; else PATH_FILTER="$2"; fi
      shift 2 ;;
    --phase=*) PHASE_FILTER="${1#--phase=}"; shift ;;
    --path=*) PATH_FILTER="${1#--path=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0"; exit 0 ;;
    *) ROOT_ARG="$1"; shift ;;
  esac
done
if [ -n "$PHASE_FILTER" ] && [ -n "$PATH_FILTER" ]; then
  echo "artifact-check: --phase and --path are exclusive (a path is a tier's whole route, not a phase)" >&2
  exit 2
fi

if [ -n "$ROOT_ARG" ]; then
  ROOT="$ROOT_ARG"
else
  cd "$(dirname "$0")/../.." || { echo "artifact-check: cannot reach repo root" >&2; exit 1; }
  # `pwd -W` (Git Bash) gives C:/... . A /c/... path reaches the Windows Python
  # below only through MSYS path conversion, which MSYS_NO_PATHCONV=1 turns off.
  ROOT="$(pwd -W 2>/dev/null || pwd)"
fi

CATALOG="$ROOT/.claude/docs/workflow-catalog.yaml"
if [ ! -f "$CATALOG" ]; then
  echo "artifact-check: catalog not found at $CATALOG" >&2
  exit 1
fi

# Python fallback chain: python -> python3 -> py (matches yaml-helper.sh:65).
PYBIN=""
for candidate in python python3 py; do
  if command -v "$candidate" >/dev/null 2>&1; then
    if "$candidate" -c 'import sys; sys.exit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
      PYBIN="$candidate"; break
    fi
  fi
done
if [ -z "$PYBIN" ]; then
  echo "artifact-check: no python 3 interpreter found (tried python, python3, py)" >&2
  exit 1
fi

"$PYBIN" - "$CATALOG" "$ROOT" "$PHASE_FILTER" "$PATH_FILTER" <<'PYEOF'
import glob as globmod
import os
import subprocess
import sys
import tempfile

catalog_path, root, phase_filter, path_filter = sys.argv[1:5]

# A gate's own output path is part of the gate: the catalog's `note:` fields
# contain em-dashes, and on a cp1252 console an unreconfigured stdout raises
# UnicodeEncodeError mid-report — dying after some rows have printed, which
# reads as a short but successful run. Force UTF-8 and never crash on a glyph.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except (AttributeError, ValueError):
    pass


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def strip_val(v):
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        v = v[1:-1]
    return v


# --- parse ---------------------------------------------------------------
# Hand-rolled on purpose: PyYAML is not a guaranteed dependency (yaml-helper.sh
# promises "no external deps beyond a Python 3 interpreter"). The catalog's
# shape is fixed and regular, so an indentation walk is sufficient and cannot
# drag in an import that fails on a user's machine.
with open(catalog_path, encoding="utf-8", errors="replace") as fh:
    lines = [ln.rstrip("\n").rstrip("\r") for ln in fh]

phases = []            # [(phase_id, [step, ...])]
paths = []             # [(path_id, [step, ...])] — same shape, top-level `paths:`
cur_phase = None
cur_step = None
ctx = None             # None | "artifact" | "any_of"
section = None         # the list the current top-level key feeds, or None

for raw in lines:
    if not raw.strip() or raw.lstrip().startswith("#"):
        continue
    ind = indent_of(raw)
    s = raw.strip()

    if ind == 0:
        section = {"phases:": phases, "paths:": paths}.get(s)
        cur_phase = cur_step = ctx = None
        continue
    if section is None:
        continue

    if ind == 2 and s.endswith(":"):
        cur_phase = (s[:-1].strip(), [])
        section.append(cur_phase)
        cur_step = None
        ctx = None
        continue
    if cur_phase is None:
        continue

    if ind == 6 and s.startswith("- id:"):
        cur_step = {"id": strip_val(s[len("- id:"):]), "required": False,
                    "repeatable": False, "artifact": None, "note": None}
        cur_phase[1].append(cur_step)
        ctx = None
        continue
    if cur_step is None:
        continue

    if ind == 8:
        ctx = None
        if s == "artifact:":
            cur_step["artifact"] = {"glob": None, "pattern": None,
                                    "min_count": 1, "any_of": [], "note": None}
            ctx = "artifact"
        elif s.startswith("required:"):
            cur_step["required"] = strip_val(s[len("required:"):]).lower() == "true"
        elif s.startswith("repeatable:"):
            cur_step["repeatable"] = strip_val(s[len("repeatable:"):]).lower() == "true"
        continue

    art = cur_step["artifact"]
    if art is None:
        continue

    if ind == 10:
        if s == "any_of:":
            ctx = "any_of"
        elif s.startswith("glob:"):
            art["glob"] = strip_val(s[len("glob:"):]); ctx = "artifact"
        elif s.startswith("pattern:"):
            art["pattern"] = strip_val(s[len("pattern:"):]); ctx = "artifact"
        elif s.startswith("min_count:"):
            try:
                art["min_count"] = int(strip_val(s[len("min_count:"):]))
            except ValueError:
                pass
            ctx = "artifact"
        elif s.startswith("note:"):
            art["note"] = strip_val(s[len("note:"):]); ctx = "artifact"
        continue

    if ind >= 12 and ctx == "any_of":
        if s.startswith("- glob:"):
            art["any_of"].append({"glob": strip_val(s[len("- glob:"):]), "pattern": None})
        elif s.startswith("pattern:") and art["any_of"]:
            art["any_of"][-1]["pattern"] = strip_val(s[len("pattern:"):])

# --- evaluate ------------------------------------------------------------
def match_files(pat):
    if not pat:
        return []
    full = os.path.join(root, pat.replace("/", os.sep))
    return sorted(p for p in globmod.glob(full, recursive=True) if os.path.isfile(p))


def pattern_hits(files, pattern):
    """POSIX ERE via grep -E. Python's re cannot parse [[:space:]], and grep -P
    is unavailable on Windows Git Bash.

    The pattern goes to grep via a pattern FILE (-f <path>), never as an
    argument and never on stdin: on Windows an argv element is re-quoted into
    a command line and re-split by MSYS grep, and a `"` in the pattern did not
    survive the round trip — the step read ABSENT against a file that matched
    (the quoted `name: "Godot"`). Stdin (-f -) was tried next, but BSD grep's
    reading of `-f -` is unconfirmed, and a build that does not read stdin
    there exits 2, which this function would have to treat as UNKNOWN anyway
    — so it writes the pattern to a real file instead, which every grep reads
    the same way."""
    if not pattern:
        return files
    hits = []
    try:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".grep", delete=False) as pf:
            pf.write(pattern + "\n")
            pattern_path = pf.name
    except OSError:
        return None               # no writable temp location — caller reports UNKNOWN
    try:
        for f in files:
            try:
                rc = subprocess.run(["grep", "-qE", "-f", pattern_path, f],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode
            except OSError:
                return None        # no grep — caller reports UNKNOWN rather than a false miss
            if rc == 0:
                hits.append(f)
    finally:
        try:
            os.unlink(pattern_path)
        except OSError:
            pass
    return hits


def evaluate(art):
    """-> (status, kind, detail dict). Observation only; no verdict."""
    if art is None:
        return "NO_CHECK", "none", {}

    if art["any_of"]:
        for i, alt in enumerate(art["any_of"]):
            files = match_files(alt["glob"])
            if not files:
                continue
            hits = pattern_hits(files, alt["pattern"])
            if hits is None:
                return "UNKNOWN", "any_of", {"why": "grep-unavailable"}
            if hits:
                return "PRESENT", "any_of", {"match": alt["glob"], "alt": str(i + 1)}
        return "ABSENT", "any_of", {"alts": str(len(art["any_of"]))}

    if not art["glob"]:
        return "NO_CHECK", "none", ({"note": art["note"]} if art["note"] else {})

    files = match_files(art["glob"])
    if not files:
        return "ABSENT", "glob", {"glob": art["glob"]}

    hits = pattern_hits(files, art["pattern"])
    if hits is None:
        return "UNKNOWN", "glob", {"why": "grep-unavailable"}
    if art["pattern"] and not hits:
        return "PATTERN_MISS", "glob", {"glob": art["glob"], "found": str(len(files))}

    counted = hits if art["pattern"] else files
    need = art["min_count"]
    if len(counted) < need:
        return "SHORT", "glob", {"glob": art["glob"], "count": str(len(counted)), "min": str(need)}
    d = {"count": str(len(counted))}
    if need > 1:
        d["min"] = str(need)
    return "PRESENT", "glob", d


if path_filter:
    label, pool, flt = "PATH", paths, path_filter
else:
    label, pool, flt = "PHASE", phases, phase_filter
sel = [(pid, steps) for pid, steps in pool if not flt or pid == flt]

if flt and not sel:
    known = ", ".join(pid for pid, _ in pool) or "(none parsed)"
    sys.stderr.write("artifact-check: unknown %s '%s' (known: %s)\n" % (label.lower(), flt, known))
    sys.exit(2)

total_steps = sum(len(s) for _, s in sel)
print("CATALOG: %s" % os.path.relpath(catalog_path, root).replace(os.sep, "/"))
print("ROOT: %s" % root.replace(os.sep, "/"))
print("%sS: %d" % (label, len(sel)))
print("STEPS: %d" % total_steps)

no_check = 0
rows = []
for pid, steps in sel:
    rows.append("%s: %s" % (label, pid))
    for st in steps:
        status, kind, det = evaluate(st["artifact"])
        if status == "NO_CHECK":
            no_check += 1
        extra = "".join(" %s=%s" % (k, v) for k, v in sorted(det.items()) if v is not None)
        rows.append("  STEP: %s required=%s repeatable=%s check=%s status=%s%s"
                    % (st["id"], str(st["required"]).lower(),
                       str(st["repeatable"]).lower(), kind, status, extra))

# Printed BEFORE the rows so a caller reading top-down knows how much of what
# follows is undetectable-from-disk before it reads any of it.
print("NO_CHECK: %d" % no_check)
for r in rows:
    print(r)
PYEOF
