#!/bin/bash
# Hook helper: yaml-helper.sh
# Purpose: Shared YAML reading helper for CCGS hooks and skill orchestrators.
# Cross-platform: Windows Git Bash compatible.
#
# Provides:
#   get_yaml_key <file> <dotted.path>
#     Prints the scalar value at <dotted.path> in <file>, or empty string if:
#       - the file does not exist or is unreadable
#       - the path does not exist in the YAML
#       - the path resolves to a sub-map or array (caller wanted a scalar)
#       - no Python interpreter is available
#     Always exits 0 — callers can safely use it under `set -e`.
#
#   get_yaml_array <file> <dotted.path>
#     Prints array values one per line. Handles both inline [a, b, c]
#     and block-dash forms (- a / - b on subsequent indented lines).
#     Empty output if not an array, not found, or file missing.
#
#   get_effective_yaml_key <dotted.path>
#   get_effective_yaml_array <dotted.path>
#     Convenience wrappers that read project.local.yaml first, then
#     fall back to project.yaml. Per-leaf override (local wins) —
#     sibling keys are read independently from their own files, so the
#     effective config has deep-merge semantics across leaves.
#
#   validate_yaml_enum <file>
#     Validates known enum-typed keys in <file> against their allowed
#     value sets (12 enums hardcoded below). Prints one error line per
#     invalid value to stderr. Returns 1 if any invalid value found,
#     0 otherwise. Unknown-key (typo) detection is a future sub-phase —
#     enum errors are the critical-path block per the spec.
#
#   validate_local_yaml_base
#     Hard-error guard per spec: project.local.yaml requires a project.yaml
#     base. Returns 1 with error on stderr if local exists without base.
#     Uses CWD-relative paths.
#
#   is_locally_overridable <dotted.path>
#     Whitelist check for the /settings --local flag. Returns 0 if the
#     setting is on the personal-experience whitelist (12 settings per
#     effects-map.md), 1 otherwise. Locked settings cannot be locally
#     overridden because they affect on-disk artifacts.
#
#   validate_enum_value <dotted.path> <value>
#     Single-key version of validate_yaml_enum — for /settings to check
#     a pending write before committing it to disk. Returns 0 if the
#     key has no enum constraint OR the value is in the enum set.
#     Returns 1 (with error on stderr) if the key is enum-typed and the
#     value is out of range. Skills call this before any Write/Edit.
#
#   is_always_ask_category <category>
#     Membership check on modes.automation_always_ask. Returns 0 if the
#     category is in the configured list (or in the default list when
#     unset), 1 otherwise. Skills use this in autonomous mode to know
#     when to prompt anyway. Default list: scope_changes, file_deletions,
#     schema_changes.
#
#   log_decision <skill> <point> <options> <chosen> <reason> <category>
#     Append a decision-log entry to production/session-logs/decision-log.md.
#     Creates the file and directory if absent. Used by skills in
#     autonomous mode to record decisions that would otherwise have
#     been AskUserQuestion prompts.
#
# Python fallback chain: python -> python3 -> py
# Parses a YAML subset: nested maps + scalar leaves + arrays + comments
# + quoted strings. PyYAML is NOT required.
#
# Usage:
#   source .claude/hooks/yaml-helper.sh
#   review_mode=$(get_yaml_key "$_YH_ROOT/project.yaml" modes.review_mode)
#   if [ -z "$review_mode" ]; then
#     # fall back to legacy .txt
#     review_mode=$(cat production/review-mode.txt 2>/dev/null || echo lean)
#   fi

# Resolve a working Python interpreter once per shell, cache the result.
_yaml_helper_python=""
_yaml_helper_resolve_python() {
  if [ -n "$_yaml_helper_python" ]; then return 0; fi
  for candidate in python python3 py; do
    if command -v "$candidate" >/dev/null 2>&1; then
      # Require Python 3 — the parser uses py3-only open(encoding=) kwargs.
      if "$candidate" -c "import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1; then
        _yaml_helper_python="$candidate"
        return 0
      fi
    fi
  done
  return 1
}

get_yaml_key() {
  local file="$1"
  local path="$2"
  if [ -z "$file" ] || [ -z "$path" ]; then return 0; fi
  if [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  "$_yaml_helper_python" - "$file" "$path" <<'PYEOF'
import sys, re

path_file, dotted = sys.argv[1], sys.argv[2]
keys = dotted.split('.')

def parse(lines):
    root = {}
    stack = [(-1, root)]  # (indent, mapping)
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        # Resolve the scalar: handle comment-only, quoted, and inline-comment forms.
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            if end >= 0:
                value = value[1:end]   # quoted content; any trailing comment ignored
            else:
                value = value[1:]      # unterminated quote — take the remainder
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

cur = data
for k in keys:
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.exit(0)

if isinstance(cur, dict):
    sys.exit(0)

# Write raw UTF-8 bytes — bypasses the platform stdout encoding (cp1252 on
# Windows) so unicode values round-trip intact.
sys.stdout.buffer.write(str(cur).encode('utf-8'))
PYEOF
}

# -----------------------------------------------------------------------------
# Array reads, effective (deep-merged) reads, enum validation
# -----------------------------------------------------------------------------

get_yaml_array() {
  local file="$1"
  local path="$2"
  if [ -z "$file" ] || [ -z "$path" ]; then return 0; fi
  if [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  "$_yaml_helper_python" - "$file" "$path" <<'PYEOF'
import sys, re

path_file, dotted = sys.argv[1], sys.argv[2]
keys = dotted.split('.')

# Parser extended to recognize two YAML array forms:
#   key: [a, b, c]                     (inline)
#   key:                               (block-dash)
#     - a
#     - b
# Block-dash detection peeks ahead at indented child lines after a key
# whose own value is empty; if those children start with "- ", they form
# an array, otherwise they form a sub-map (existing behavior).
def parse(lines):
    root = {}
    stack = [(-1, root)]
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            i += 1
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            i += 1
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] == '[':
            # Inline array, scanned with QUOTE AWARENESS.
            #
            # A comma or a closing bracket inside a quoted element is DATA, not
            # a delimiter. Splitting on every comma turns one quoted entry that
            # contains commas into several bogus ones -- and because each shard
            # is a plausible-looking string, nothing downstream can tell that it
            # happened. Values written from hand-authored prose hit this
            # routinely.
            parts = []
            buf = ''
            quote = None
            idx = 1
            while idx < len(value):
                ch = value[idx]
                if quote is not None:
                    if ch == quote:
                        quote = None
                    else:
                        buf += ch
                elif ch in ('"', "'"):
                    quote = ch
                elif ch == ']':
                    break
                elif ch == ',':
                    parts.append(buf.strip())
                    buf = ''
                else:
                    buf += ch
                idx += 1
            if buf.strip():
                parts.append(buf.strip())
            parent[key] = [p for p in parts if p != '']
            i += 1
            continue
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            if end >= 0:
                value = value[1:end]
            else:
                value = value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            # Peek: block-dash list or sub-map?
            j = i + 1
            items = []
            while j < len(lines):
                pl = lines[j].rstrip('\n').rstrip('\r')
                pstripped = pl.lstrip(' ')
                if not pstripped.strip() or pstripped.lstrip().startswith('#'):
                    j += 1
                    continue
                pindent = len(pl) - len(pstripped)
                if pindent <= indent:
                    break
                if pstripped.startswith('- '):
                    # INDENT IS NOT ENFORCED between items, deliberately.
                    #
                    # Requiring every item to sit at the first item's indent
                    # made ONE misindented entry end the list there and return
                    # the prefix, silently: three configured always-ask
                    # categories came back as one. `is_always_ask_category`
                    # compares exactly, so the dropped entries lost their
                    # prompt with nothing written anywhere -- and a partial
                    # list is non-empty, so the caller's "fall back to the
                    # defaults when unset" branch does not fire either. It
                    # failed toward LESS confirmation, which is the wrong
                    # direction for the setting that decides when to ask.
                    #
                    # Safe because this schema holds only flat scalar lists:
                    # any deeper `- ` line under the key is an item of it. A
                    # non-dash line still ends the list via the break below,
                    # so a sub-map after a list is unaffected.
                    item = pstripped[2:].strip()
                    if item[:1] in ('"', "'") and item[-1:] == item[:1] and len(item) >= 2:
                        item = item[1:-1]
                    else:
                        # Unquoted items take the same trailing-comment rule
                        # scalars take. Without it `- scope_changes  # ask`
                        # parsed as the literal string INCLUDING the comment
                        # and matched no category -- the same silent loss as
                        # above, reached a different way. Quoted items are
                        # left alone: a `#` inside quotes is data.
                        hash_pos = item.find(' #')
                        if hash_pos >= 0:
                            item = item[:hash_pos].strip()
                    items.append(item)
                    j += 1
                    continue
                break
            if items:
                parent[key] = items
                i = j
                continue
            else:
                new_map = {}
                parent[key] = new_map
                stack.append((indent, new_map))
        else:
            parent[key] = value
        i += 1
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

cur = data
for k in keys:
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.exit(0)

if not isinstance(cur, list):
    sys.exit(0)

for item in cur:
    sys.stdout.buffer.write((str(item) + '\n').encode('utf-8'))
PYEOF
}

# Guard: project.local.yaml requires a project.yaml base.
# Per spec (effects-map.md "Creation and error handling"), the local file
# has no meaning without a base — it only overrides values from project.yaml.
# Prints a hard-error message to stderr and returns 1 if the orphan case
# is detected. Returns 0 otherwise (including when neither file exists).
# Uses CWD-relative paths — callers cd into the project root first.
# --- project root resolution -------------------------------------------------
#
# Config paths must NOT be resolved against the bare current working directory.
# Run a skill or hook from a subdirectory that way and project.yaml is
# unfindable, so EVERY setting resolves to empty -- silently, because the guard
# that reports a missing base cannot find its files either. From the repo root
# `modes.rigor` returns `full`; from `src/` it would return nothing.
#
# Being loadable from anywhere is only half the problem: the helper must also be
# able to do its job from anywhere. Fixing one without the other leaves it
# sourceable everywhere and functional only at the root.
#
# PRECEDENCE IS LOAD-BEARING, in this order:
#   1. cwd holds project.yaml         -> cwd
#   2. cwd holds project.local.yaml   -> cwd
#   3. CLAUDE_PROJECT_DIR has a base  -> that directory
#   4. nothing found                  -> cwd (unchanged behaviour)
#
# AN UPWARD WALK WAS IMPLEMENTED AND REMOVED, and the reason is worth keeping.
# The intent was a fallback needing no environment variable: climb until an
# ancestor has project.yaml. It resolves the wrong tree. A project that has a
# legacy production/review-mode.txt and no project.yaml, sitting anywhere below
# another project, reads the OUTER project's project.local.yaml one directory
# up instead of its own legacy file -- the wrong answer, returned silently.
#
# That is not a test-harness artifact. Any real project nested inside another
# repo that happens to carry a project.yaml would silently inherit the outer
# project's settings, which is the same silent-wrong-answer class this whole fix
# exists to remove. A fallback that guesses is worse than one that is absent:
# rule 4 leaves an unconfigured directory reading its own legacy files, which is
# exactly what a project without project.yaml should do.
#
# CLAUDE_PROJECT_DIR is populated in both the hook environment and the
# skill-bootstrap environment, so rule 3 covers every way this framework
# actually invokes the helper.
#
# 1 and 2 come FIRST deliberately. A project nested inside another one must read
# ITSELF, and an ambient CLAUDE_PROJECT_DIR would otherwise point it at the
# outer tree. Rule 2 covers the case that is easiest to lose: a directory with a
# project.local.yaml and deliberately NO base must still raise the hard error
# for a missing base. Without it, an upward walk finds an ancestor's
# project.yaml and that error silently stops firing.
#
# Sets a variable rather than echoing a path: a $( ) per lookup would add a
# subshell to every one of validate_yaml_enum's 23 calls, and per-lookup cost of
# that kind is what pushes a hook past its 10s timeout.
_yaml_helper_set_root() {
  _YH_ROOT="."
  [ -f "$_YH_ROOT/project.yaml" ] && return 0
  [ -f "$_YH_ROOT/project.local.yaml" ] && return 0
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/project.yaml" ]; then
    _YH_ROOT="$CLAUDE_PROJECT_DIR"; return 0
  fi
  return 0
}

validate_local_yaml_base() {
  _yaml_helper_set_root
  if [ -f "$_YH_ROOT/project.local.yaml" ] && [ ! -f "$_YH_ROOT/project.yaml" ]; then
    echo "project.local.yaml exists but project.yaml is missing — run /start to create one. Local overrides require a base." >&2
    return 1
  fi
  return 0
}

# Per-leaf deep-merge: read project.local.yaml first (if present),
# fall back to project.yaml. Each leaf is resolved independently from
# its own file, so sibling keys at the same nesting level naturally
# come through from project.yaml when project.local.yaml only overrides
# specific leaves.
get_effective_yaml_key() {
  _yaml_helper_set_root
  local path="$1"
  if [ -z "$path" ]; then return 0; fi
  local val=""
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    val=$(get_yaml_key "$_YH_ROOT/project.local.yaml" "$path")
  fi
  if [ -z "$val" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    val=$(get_yaml_key "$_YH_ROOT/project.yaml" "$path")
  fi
  printf '%s' "$val"
}

get_effective_yaml_array() {
  _yaml_helper_set_root
  local path="$1"
  if [ -z "$path" ]; then return 0; fi
  local val=""
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    val=$(get_yaml_array "$_YH_ROOT/project.local.yaml" "$path")
  fi
  if [ -z "$val" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    val=$(get_yaml_array "$_YH_ROOT/project.yaml" "$path")
  fi
  printf '%s' "$val"
}

# Enum constants — the 12 settings whose values are constrained to a
# fixed set per effects-map.md. Format: dotted.path::value1|value2|...
# Validation: walk this list; for each key present in the file, verify
# value is in the allowed set. Out-of-set values are hard errors per
# spec (effects-map.md line 145-153).
_yaml_helper_enums="\
modes.review_mode::full|lean|solo
modes.rigor::minimal|standard|full
modes.workflow::minimal|standard|full
modes.automation::collaborative|guided|autonomous
modes.story_granularity::coarse|balanced|fine
docs.density::terse|balanced|thorough
qa.level::minimal|standard|full
team.size::individual|small|studio
performance.enforce::warn|block|off
platform.cert_tier::none|itch|steam|console
accessibility.target::none|standard|aaa
engine.name::Godot|Unity|Unreal
project.stage::Concept|Systems Design|Technical Setup|Pre-Production|Production|Polish|Release
testing.strict.logic::true|false
testing.strict.integration::true|false
testing.strict.visual::true|false
testing.strict.ui::true|false
testing.strict.config::true|false
features.session_state::on|off
platform.online::true|false
workflow_overrides.edge_cases::true|false
workflow_overrides.tuning_knobs::true|false
workflow_overrides.art_bible_strict::true|false"
# The boolean keys above are enumerated for the same reason the string keys are:
# `resolve_setting` validates every hop and DROPS a value that fails, so a key
# absent from this table accepts anything. Before they were listed,
# `testing.strict.logic: maybe` in project.local.yaml passed validation and won
# over an explicit `true` in project.yaml -- and `/story-done` treats the gate as
# BLOCKING only when the value is `true`, so a typo silently downgraded a
# blocking test gate to advisory with no error. `performance.enforce` was
# already enumerated and correctly rejected garbage, which is exactly the
# asymmetry that hides this. Any NEW boolean setting must be added here too.
#
# Two keys deliberately NOT listed as `true|false`, both of which the config
# test suite catches if they are -- add nothing here without checking it:
#   - `features.session_state` is an ON/OFF enum, not a boolean. It is listed
#     above as `on|off` because `session_state_enabled()` disables only on the
#     literal `off`, and effects-map documents `on`/`off`. Writing `false` there
#     means ENABLED, which is why validating it matters.
#   - `testing.strict` (the parent) is absent because its primary shape is a MAP
#     of the five type keys; the bare scalar is only a back-compat form. Its
#     effects-map `**Values:**` line documents the map, so enumerating the parent
#     as a scalar would force that line to misdescribe the real shape. The five
#     leaves below carry the validation, which is where /story-done reads.
#
#   validate_local_scope [<file>]
#     The location check the value checks above cannot do: names keys in
#     project.local.yaml that are NOT locally overridable, which resolution
#     silently ignores. One line per key on stderr; returns 1 if any found.
#     Warns, never reconciles. Defined below is_locally_overridable.

# Whitelist of locally-overridable settings (per effects-map.md
# "Whitelist — which settings can be locally overridden"). Personal-experience
# settings only — divergence between developers is safe because they don't
# affect what artifacts exist on disk.
_yaml_helper_locally_overridable="\
modes.review_mode
modes.automation
modes.automation_always_ask
team.size
testing.strict.logic
testing.strict.integration
testing.strict.visual
testing.strict.ui
testing.strict.config
performance.enforce
features.session_state
features.token_budget_warn_at"

is_locally_overridable() {
  local path="$1"
  [ -z "$path" ] && return 1
  local whitelisted
  while IFS= read -r whitelisted; do
    [ -z "$whitelisted" ] && continue
    if [ "$path" = "$whitelisted" ]; then return 0; fi
  done <<EOF
$_yaml_helper_locally_overridable
EOF
  return 1
}

# validate_local_scope [<file>]
#   Names the keys in project.local.yaml that resolution will NEVER read,
#   because they are not on the whitelist above. One line per key on stderr;
#   returns 1 if any were found, 0 otherwise.
#
#   Why this needs its own check, separate from validate_yaml_enum: that
#   function validates VALUES, and a locked key hand-written into the local
#   file has a perfectly legal one. `modes.rigor: strict` there passes every
#   validation in the chain — correct key, correct value — and then
#   resolve_setting never consults the local file for that path, so the
#   setting is discarded in total silence and the user sees the default they
#   were trying to override. Nothing else checks the key's LOCATION.
#   /settings --local already refuses these; only the hand-edited file is
#   unguarded, and hand-editing is what the file is for.
#
#   WARNS, NEVER RECONCILES — the same shape as the stage-mirror check.
#   It does not edit project.local.yaml, does not begin honouring
#   the key, and does not alter resolution. A locked setting is locked
#   because it changes which artifacts exist on disk, so a helper that
#   "helpfully" applied one would let two developers' checkouts diverge —
#   precisely what the whitelist exists to prevent. The fix belongs to the
#   user: move the key to project.yaml, or delete it.
#
#   The parser below is a third copy of the one in get_yaml_key and
#   validate_yaml_enum. That duplication is deliberate and matches the
#   established shape of this file: these helpers are sourced individually
#   and must agree on YAML edge cases exactly, and a shared copy that drifted
#   would make two functions disagree about what a file says.
validate_local_scope() {
  local file="${1:-project.local.yaml}"
  [ -f "$file" ] || return 0
  if ! _yaml_helper_resolve_python; then return 0; fi
  local found key rc=0
  found=$("$_yaml_helper_python" - "$file" "$_yaml_helper_locally_overridable" <<'PYEOF'
import sys, re

path_file, allowed_table = sys.argv[1], sys.argv[2]
allowed = set(l.strip() for l in allowed_table.splitlines() if l.strip())

# File metadata, not settings -- effects-map.md lists `schema_version` and
# `framework.*` under "Locked to project.yaml" with the reason "File metadata,
# not preferences". They are not preferences, so "you cannot override this
# preference locally" is the wrong complaint about them: nothing was dropped
# and nothing needs moving. This repo's own project.local.yaml carries
# `schema_version: 1`, which is how the false positive was caught -- the check
# was written against a hand-made fixture and only run against the real file
# afterwards, where it immediately flagged a correct file.
EXEMPT_EXACT = {'schema_version'}
EXEMPT_PREFIX = ('framework.',)

def parse(lines):
    root = {}
    stack = [(-1, root)]
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            value = value[1:end] if end >= 0 else value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

# An EMPTY map counts as a leaf. Array-valued keys parse that way -- the
# `- item` lines carry no colon and are skipped -- so treating an empty map as
# a branch would silently exempt every list-valued setting from this check.
def walk(node, prefix):
    for k, v in node.items():
        dotted = prefix + k if not prefix else prefix + '.' + k
        if isinstance(v, dict) and v:
            walk(v, dotted)
        elif dotted in allowed or dotted in EXEMPT_EXACT:
            continue
        elif dotted.startswith(EXEMPT_PREFIX):
            continue
        else:
            print(dotted)

walk(data, '')
PYEOF
)
  [ -n "$found" ] || return 0
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    echo "$file: \`$key\` is not locally overridable — ignored, not applied. Move it to project.yaml (or delete it); see the whitelist in yaml-helper.sh." >&2
    rc=1
  done <<EOF
$found
EOF
  return "$rc"
}

# session_state_enabled
#   Returns 0 when the session-state pipeline should run, 1 when the user has
#   turned it off with `features.session_state: off`. Honours the local
#   override (the key is on the whitelist above), local winning over base.
#
#   DEFAULT IS `on`. A default of `off` would contradict practice: every project
#   runs with the pipeline active --
#   and `production/session-state/active.md` is the documented recovery
#   checkpoint that `.claude/docs/context-management.md` tells users to rely on.
#   Shipping `off` as the default would have silently removed crash recovery,
#   the session archive and the subagent spawn tally from every existing
#   project. Users who want the ~2-5k tokens per session opt out explicitly.
#
#   Deliberately awk, not get_effective_yaml_key: this runs in log-agent.sh on
#   EVERY subagent spawn, and get_effective_yaml_key shells out to Python twice.
#   Spending 200ms of interpreter startup per spawn to check a token-saving flag
#   would be self-defeating.
session_state_enabled() {
  local f v
  for f in project.local.yaml project.yaml; do
    [ -f "$f" ] || continue
    v=$(awk '
      /^features:[[:space:]]*$/ { inf=1; next }
      /^[^[:space:]#]/          { inf=0 }
      inf && /^[[:space:]]+session_state:/ {
        sub(/^[[:space:]]*session_state:[[:space:]]*/, "")
        sub(/[[:space:]]*#.*$/, "")
        gsub(/["'"'"']/, "")
        print; exit
      }
    ' "$f" 2>/dev/null | tr -d '\r' | tr -d ' ')
    if [ -n "$v" ]; then
      [ "$v" = "off" ] && return 1
      return 0
    fi
  done
  return 0   # unset anywhere => on
}

validate_yaml_enum() {
  local file="$1"
  if [ -z "$file" ] || [ ! -f "$file" ]; then return 0; fi
  if ! _yaml_helper_resolve_python; then
    echo "yaml-helper: no python interpreter found (tried python, python3, py)" >&2
    return 0
  fi
  # ONE interpreter spawn for the whole enum table.
  #
  # Calling `get_yaml_key` once per enum -- 23 calls -- spawns a Python
  # interpreter each time (see get_yaml_key). At ~214ms of process startup on
  # Windows that is ~4.9s per config file, and with project.yaml plus
  # project.local.yaml it puts session-start.sh over its 10s hook timeout,
  # killing it mid-write so the recovery checkpoint never reaches context.
  #
  # A bash pre-filter that skips lookups for keys ABSENT from the file is
  # correct but insufficient, and the distinction is the lesson: it only removes
  # spawns for keys you do not have. A sparse config skips nearly all of them
  # and looks like a 35x win. A fully configured project sets all of them, every
  # lookup survives the filter, and the cost returns in full -- ~4683ms filtered
  # versus ~4576ms unfiltered, i.e. no improvement on the population that
  # matters.
  # The count of spawns was never the invariant worth fixing; the cost of one
  # was. Parsing the document once and answering every enum from that parse is
  # constant in the number of keys, so a denser config no longer costs more.
  #
  # Behaviour is unchanged by construction: the parser below is the same one
  # get_yaml_key uses, the enum table is walked in the same order, absent keys
  # are skipped exactly as `[ -z "$actual" ] && continue` did, and the error
  # text is byte-identical.
  "$_yaml_helper_python" - "$file" "$_yaml_helper_enums" <<'PYEOF'
import sys, re

path_file, enum_table = sys.argv[1], sys.argv[2]

def parse(lines):
    root = {}
    stack = [(-1, root)]  # (indent, mapping)
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key = m.group(1).strip()
        value = m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            quote = value[0]
            end = value.find(quote, 1)
            if end >= 0:
                value = value[1:end]
            else:
                value = value[1:]
        else:
            hash_pos = value.find(' #')
            if hash_pos >= 0:
                value = value[:hash_pos].strip()
        if value == '':
            new_map = {}
            parent[key] = new_map
            stack.append((indent, new_map))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        raw_lines = f.readlines()
except OSError:
    sys.exit(0)

data = parse(raw_lines)

# A TAB IN THE INDENTATION IS AN ERROR, not something to normalise away.
#
# The parser stripped leading SPACES only, so a tab-indented line never matched
# the key regex and vanished -- the setting then silently resolved to its
# default. Every enum check below passed on such a file, because a key that
# cannot be read cannot hold an invalid value. That is rc=0 on a config that
# configures nothing, byte-identical in outcome to a genuinely clean file.
# Measured before this check: the same file with tabs instead of spaces
# reported no errors while `modes.review_mode: BOGUS_VALUE` sat in it unread.
#
# This is the validator's own version of the rule the skills are held to --
# absence of evidence is not evidence of absence. It cannot report "no invalid
# values" when the real answer is "no values".
#
# YAML forbids tabs for indentation, so reporting rather than repairing is
# correct; doing neither was the defect. Comment lines are exempt: a tab in
# front of a `#` hides nothing.
tab_lines = []
for _n, _raw in enumerate(raw_lines, 1):
    _line = _raw.rstrip('\n').rstrip('\r')
    if not _line.strip() or _line.lstrip(' \t').startswith('#'):
        continue
    _lead = _line[:len(_line) - len(_line.lstrip(' \t'))]
    if '\t' in _lead:
        tab_lines.append(_n)

def lookup(dotted):
    cur = data
    for k in dotted.split('.'):
        if isinstance(cur, dict) and k in cur:
            cur = cur[k]
        else:
            return ''
    if isinstance(cur, dict):
        return ''
    return str(cur)

errors = 0
out = []
if tab_lines:
    _shown = ', '.join(str(n) for n in tab_lines[:5])
    if len(tab_lines) > 5:
        _shown += ' (and %d more)' % (len(tab_lines) - 5)
    out.append("line %s: indented with a TAB. YAML forbids tabs for indentation, "
               "so these lines are invisible to the config parser and their "
               "settings silently fall back to defaults. Replace leading tabs "
               "with spaces." % _shown)
    errors += 1
for line in enum_table.splitlines():
    line = line.strip()
    if not line or '::' not in line:
        continue
    enum_path, _, enum_values = line.partition('::')
    actual = lookup(enum_path)
    if actual == '':
        continue
    if actual not in enum_values.split('|'):
        out.append("%s: '%s' is not a valid value (expected: %s)"
                   % (enum_path, actual, enum_values))
        errors += 1

if out:
    sys.stderr.buffer.write(('\n'.join(out) + '\n').encode('utf-8'))
sys.exit(1 if errors else 0)
PYEOF
}

# Validate a single pending value for /settings writes. Looks up
# the key in _yaml_helper_enums; if found, checks value membership. If
# the key has no enum constraint, returns 0 (no validation applies).
# Returns 1 with stderr error on invalid value.
validate_enum_value() {
  local key="$1"
  local value="$2"
  [ -z "$key" ] && return 0
  local line enum_path enum_values v
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    enum_path="${line%::*}"
    enum_values="${line##*::}"
    if [ "$key" = "$enum_path" ]; then
      local oldIFS="$IFS"
      IFS='|'
      for v in $enum_values; do
        if [ "$value" = "$v" ]; then IFS="$oldIFS"; return 0; fi
      done
      IFS="$oldIFS"
      echo "Invalid value '$value' for '$key'. Allowed: $enum_values" >&2
      return 1
    fi
  done <<EOF
$_yaml_helper_enums
EOF
  # Key has no enum constraint — caller decides what to do.
  return 0
}

# automation_always_ask category check.
# Returns 0 if the named category is in modes.automation_always_ask (or in
# the default list when unset), 1 otherwise. Used by skills in autonomous
# mode to know which decisions still warrant a prompt.
# Default list (when modes.automation_always_ask absent from both files):
#   scope_changes, file_deletions, schema_changes
_yaml_helper_always_ask_default="scope_changes
file_deletions
schema_changes"

is_always_ask_category() {
  local category="$1"
  [ -z "$category" ] && return 1
  local configured
  configured=$(get_effective_yaml_array modes.automation_always_ask)
  if [ -z "$configured" ]; then
    configured="$_yaml_helper_always_ask_default"
  fi
  local item
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    if [ "$item" = "$category" ]; then return 0; fi
  done <<EOF
$configured
EOF
  return 1
}

# Append a decision-log entry. Format per effects-map.md
# "Decision log format (autonomous mode)". Creates the file and parent
# directory if absent. Uses ISO 8601 UTC timestamps.
log_decision() {
  _yaml_helper_set_root
  local skill="$1"
  local point="$2"
  local options="$3"
  local chosen="$4"
  local reason="$5"
  local category="$6"
  local logfile="$_YH_ROOT/production/session-logs/decision-log.md"
  mkdir -p "$(dirname "$logfile")"
  if [ ! -f "$logfile" ]; then
    printf '# Decision Log\n\nAppend-only audit trail of decisions made in autonomous mode.\n' > "$logfile"
  fi
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u)
  cat >> "$logfile" <<EOF

## $timestamp — $skill

**Decision point:** $point
**Options considered:** $options
**Chosen:** $chosen
**Reason:** $reason
**Category:** $category
EOF
}

# =============================================================================
# Whole-config resolution.
#
# WHY THIS EXISTS
#   ~51 SKILL.md files each carried an English description of a deterministic
#   fallback chain ("1. If --review passed -> use that; 2. Else read
#   modes.review_mode from project.yaml; 3. Else production/review-mode.txt;
#   4. Else lean"), re-interpreted by a model on every invocation at roughly
#   +1,360 tokens per skill. resolve_config computes the same answer once, in
#   ~150 tokens, deterministically -- and testably, which prose never was.
#
# CONTRACT BOUNDARY
#   This layer resolves SOURCES. It does not own per-skill policy. Anything
#   whose default legitimately differs between skills (testing.strict.*) is
#   reported as configured-or-unset and left to the skill to default.
# =============================================================================

# Terminal defaults. ONLY knobs whose default is uniform across every consumer.
#
# testing.strict.* is deliberately ABSENT: /smoke-check defaults it to blocking
# (build-health gate) while /story-done and /dev-story default per story type.
# Emitting one value here would silently pick a winner between them.
#
# The six knobs `rigor` fronts (modes.workflow, docs.density, qa.level,
# modes.story_granularity, modes.review_mode, team.size) are ALSO absent: their
# value comes from the rigor expansion below, which sits between the legacy step
# and this table. Leaving a terminal default here as well would shadow the
# expansion and make `rigor` a no-op for anyone who had not also set the sub-knob.
# modes.review_mode is fronted by rigor so `rigor: minimal` resolves
# review_mode to `solo` (skipping the ~44k-token director/specialist gates),
# `standard` yields `lean` and `full` yields `full`. team.size joined the fronted
# set the same way: `full` yields `studio` (the whole roster) while
# `minimal`/`standard` yield `individual`. Both stay locally overridable (they
# are personal-experience knobs, not on-disk artifacts): that source sits ABOVE
# the expansion, so only the terminal fallback moved.
#
# --- WHY modes.rigor DEFAULTS TO `minimal` -----------------------------------
#
# It defaulted to `standard`. Building the same project both ways showed the
# heavier tier costing several times as much to reach working code without
# producing a better result, and giving nothing back when a fresh developer
# picked the project up. A default that costs more and does not repay is the
# wrong default, and it was what every user who never opened /settings received.
#
# Raising rigor stays one question in /start and one `/settings` call, and
# settings-guidance.md's upward triggers ("system-GDD count crosses ~9",
# "gate-check PASS into Production while rigor is minimal") are written to fire
# from exactly this starting state. The cost of under-running is one prompt.
#
# ORDER MATTERS: this default is only safe while /gate-check keeps its floors.
# `rigor: minimal` expands to `workflow: minimal` + `qa.level: minimal`, which
# together once left the Production->Polish gate with ZERO required artifacts --
# a vacuous PASS. That is fixed (the smoke-report floor and the "nothing
# required -> NOT ASSESSED, never PASS" rule). Do not move this default again
# without re-checking that the gates below it still require something.
_yaml_helper_defaults="\
modes.automation::collaborative
modes.rigor::minimal
performance.enforce::warn"

# Rigor expansion — one asked-at-/start knob that supplies four.
#
# WHY: /start has never asked about workflow, docs.density, qa.level or
# story_granularity, so in practice every project ran all four at their defaults.
# Between them the latter three drive ONE behaviour each (prose verbosity, is-
# evidence-required, story size) restated across 19 skills with 17 "we are
# orthogonal" disclaimers. `rigor` makes the common case reachable in one
# question while each knob stays individually settable.
#
# modes.workflow is fronted, NOT replaced: it drives ~5 distinct behaviours and
# owns the only per-system override mechanism (workflow_overrides.system_
# overrides), which continues to win over the rigor-derived value.
_yaml_helper_rigor_expansion="\
minimal::modes.workflow=minimal,docs.density=terse,qa.level=minimal,modes.story_granularity=coarse,modes.review_mode=solo,team.size=individual
standard::modes.workflow=standard,docs.density=balanced,qa.level=standard,modes.story_granularity=balanced,modes.review_mode=lean,team.size=individual
full::modes.workflow=full,docs.density=thorough,qa.level=full,modes.story_granularity=fine,modes.review_mode=full,team.size=studio"

# Value for <path> implied by the project's rigor level, or '' if rigor does not
# front that key. Never consulted for modes.rigor itself — that would recurse.
_yaml_helper_rigor_value() {
  _yaml_helper_set_root
  local path="$1" level="" line pair
  [ -z "$path" ] && return 0
  [ "$path" = "modes.rigor" ] && return 0

  # Resolve rigor WITHOUT resolve_setting, to keep the recursion impossible.
  [ -f "$_YH_ROOT/project.yaml" ] && level=$(get_yaml_key "$_YH_ROOT/project.yaml" modes.rigor)
  if [ -n "$level" ] && ! validate_enum_value modes.rigor "$level" 2>/dev/null; then level=""; fi
  [ -z "$level" ] && level=$(get_yaml_default modes.rigor)
  [ -z "$level" ] && return 0

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [ "${line%%::*}" = "$level" ] || continue
    local oldIFS="$IFS"; IFS=','
    for pair in ${line##*::}; do
      if [ "${pair%%=*}" = "$path" ]; then IFS="$oldIFS"; printf '%s' "${pair#*=}"; return 0; fi
    done
    IFS="$oldIFS"
  done <<EOF
$_yaml_helper_rigor_expansion
EOF
  return 0
}

# The rigor level currently in effect (for source labels and /settings).
_yaml_helper_rigor_level() {
  _yaml_helper_set_root
  local level=""
  [ -f "$_YH_ROOT/project.yaml" ] && level=$(get_yaml_key "$_YH_ROOT/project.yaml" modes.rigor)
  if [ -n "$level" ] && ! validate_enum_value modes.rigor "$level" 2>/dev/null; then level=""; fi
  [ -z "$level" ] && level=$(get_yaml_default modes.rigor)
  printf '%s' "$level"
}

# Plain-text legacy mirrors — the read side of the dual-write contract.
_yaml_helper_legacy_files="\
modes.review_mode::production/review-mode.txt
project.stage::production/stage.txt"

# Which keys consult project.local.yaml DURING RESOLUTION.
#
# This list MUST equal the `/settings --local` write whitelist. If resolution
# consults project.local.yaml for a narrower set than /settings will write to
# it, `/settings --local modes.review_mode=solo` writes a value that /settings
# accepts and displays, and that every skill then ignores. A write
# list and a read list that disagree is not a design; it is a bug with a
# plausible-looking symptom.
#
# Kept as its own variable rather than inlining the whitelist: "may be written
# locally" and "is read during resolution" are distinct concepts that merely
# coincide today. A future setting could legitimately be one and not the other.
_yaml_helper_local_read_scope="$_yaml_helper_locally_overridable"

_yaml_helper_in_local_read_scope() {
  local path="$1" entry
  [ -z "$path" ] && return 1
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    [ "$path" = "$entry" ] && return 0
  done <<EOF
$_yaml_helper_local_read_scope
EOF
  return 1
}

_yaml_helper_legacy_file_for() {
  local path="$1" line
  [ -z "$path" ] && return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "${line%%::*}" = "$path" ]; then printf '%s' "${line##*::}"; return 0; fi
  done <<EOF
$_yaml_helper_legacy_files
EOF
  return 0
}

# Documented terminal default for a key, or '' when it has none.
get_yaml_default() {
  local path="$1" line
  [ -z "$path" ] && return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ "${line%%::*}" = "$path" ]; then printf '%s' "${line##*::}"; return 0; fi
  done <<EOF
$_yaml_helper_defaults
EOF
  return 0
}

# Read a legacy plain-text mirror. Strips CR and surrounding whitespace but
# PRESERVES INTERNAL SPACES — "Systems Design" is a legal project.stage value,
# and a `tr -d '[:space:]'` reader collapsed it to "SystemsDesign", which
# matched none of the phase keys downstream. Skips leading blank lines.
get_legacy_key() {
  local path="$1" file
  [ -z "$path" ] && return 0
  file=$(_yaml_helper_legacy_file_for "$path")
  [ -z "$file" ] && return 0
  [ -f "$file" ] || return 0
  awk 'BEGIN{FS="\n"} { gsub(/\r/,""); sub(/^[ \t]+/,""); sub(/[ \t]+$/,"");
        if (length($0) > 0) { print; exit } }' "$file"
}

# Resolve one setting through the full chain.
#   prints: "<value>\t<source>"
#   source: project.local.yaml | project.yaml | <legacy path> | default | unset
#   exit:   always 0
#
# Enum-invalid values FALL THROUGH rather than winning — a typo degrades to the
# next source and ultimately the documented default, instead of propagating a
# nonsense mode into every skill. resolve_config surfaces what was rejected.
resolve_setting() {
  _yaml_helper_set_root
  local path="$1"
  if [ -z "$path" ]; then printf '\tunset'; return 0; fi
  local val="" src="" legacy=""

  if _yaml_helper_in_local_read_scope "$path" && [ -f "$_YH_ROOT/project.local.yaml" ]; then
    val=$(get_yaml_key "$_YH_ROOT/project.local.yaml" "$path")
    if [ -n "$val" ] && ! validate_enum_value "$path" "$val" 2>/dev/null; then val=""; fi
    [ -n "$val" ] && src="project.local.yaml"
  fi

  if [ -z "$val" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    val=$(get_yaml_key "$_YH_ROOT/project.yaml" "$path")
    if [ -n "$val" ] && ! validate_enum_value "$path" "$val" 2>/dev/null; then val=""; fi
    [ -n "$val" ] && src="project.yaml"
  fi

  if [ -z "$val" ]; then
    legacy=$(_yaml_helper_legacy_file_for "$path")
    if [ -n "$legacy" ] && [ -f "$legacy" ]; then
      val=$(get_legacy_key "$path")
      if [ -n "$val" ] && ! validate_enum_value "$path" "$val" 2>/dev/null; then val=""; fi
      [ -n "$val" ] && src="$legacy"
    fi
  fi

  # Rigor expansion sits BELOW every explicit source and ABOVE the terminal
  # default. That ordering is the back-compat guarantee: a project.yaml that
  # already sets docs.density resolves exactly as it did before rigor existed.
  if [ -z "$val" ]; then
    val=$(_yaml_helper_rigor_value "$path")
    [ -n "$val" ] && src="rigor:$(_yaml_helper_rigor_level)"
  fi

  if [ -z "$val" ]; then
    val=$(get_yaml_default "$path")
    [ -n "$val" ] && src="default"
  fi

  [ -z "$src" ] && src="unset"
  printf '%s\t%s' "$val" "$src"
}

# Resolve the ENGINE-SPECIFIC code root.
#   prints: "<dir>\t<source>"
#   source: engine.name | <legacy path> | detected | unset
#   exit:   always 0
#
# WHY THIS EXISTS. `.claude/docs/directory-structure.md` is explicit that the
# code root is not a style preference but a hard toolchain constraint: Unity
# compiles only `Assets/` and `Packages/`, and UnrealBuildTool discovers modules
# under `Source/`. `src/` is that table's GODOT row, not a universal path.
#
# Every hook that filtered staged or on-disk files with a literal `^src/`
# therefore matched NOTHING on a Unity or Unreal project — and matching nothing
# is indistinguishable from scanning cleanly. That is the exact row
# `.claude/rules/skill-authoring.md` records for `/security-audit`
# ("Godot-only greps returned zero hits on Unity/Unreal, and zero hits read as
# clean"), reproduced in four more places.
#
# UNSET DOES NOT DEFAULT TO `src`. Obligation 2 of skill-authoring.md: an absent
# value may not default to the permissive one. Defaulting here would re-create
# the Godot bias this function exists to remove, and would do it invisibly. An
# unresolvable root returns empty, and the CALLER must announce that its check
# did not run — see the `_no_code_root` reporting in validate-commit.sh.
#
# Step 3 (detect) is derivation, not enumeration (obligation 5): it believes the
# tree over the absence of config, but only when the tree is UNAMBIGUOUS. Two
# roots present means a genuinely undecidable project, and guessing there would
# scan half of it and report a pass.
resolve_code_root() {
  _yaml_helper_set_root
  local ename="" src="" root="" legacy="" found="" d n=0

  # 1. The configured engine, through the normal chain.
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    ename=$(get_yaml_key "$_YH_ROOT/project.local.yaml" engine.name 2>/dev/null)
    [ -n "$ename" ] && src="project.local.yaml"
  fi
  if [ -z "$ename" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    ename=$(get_yaml_key "$_YH_ROOT/project.yaml" engine.name 2>/dev/null)
    [ -n "$ename" ] && src="engine.name"
  fi

  # 2. The legacy mirror. `/setup-engine` wrote an `Engine:` line here before
  #    project.yaml existed, and workflow-catalog's `engine-setup` step still
  #    accepts it as an `any_of` alternative — so a v1.0 project that never
  #    migrated resolves rather than falling through to "unset".
  legacy="$_YH_ROOT/.claude/docs/technical-preferences.md"
  if [ -z "$ename" ] && [ -f "$legacy" ]; then
    ename=$(grep -iE '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Engine\*{0,2}[[:space:]]*:' "$legacy" 2>/dev/null \
            | head -1 | sed 's/.*://' | tr -d '\r' \
            | sed 's/^[[:space:]]*//; s/[[:space:]].*$//; s/\*//g')
    case "$ename" in
      *"[TO BE CONFIGURED]"*|"["*) ename="" ;;
    esac
    [ -n "$ename" ] && src=".claude/docs/technical-preferences.md"
  fi

  case "$(printf '%s' "$ename" | tr '[:upper:]' '[:lower:]')" in
    godot)   root="src" ;;
    unity)   root="Assets" ;;
    unreal*) root="Source" ;;
    *)       root="" ;;
  esac

  # 3. No usable engine value — believe the tree, but only if it is unambiguous.
  if [ -z "$root" ]; then
    for d in src Assets Source; do
      if [ -d "$_YH_ROOT/$d" ]; then found="$d"; n=$((n + 1)); fi
    done
    if [ "$n" = 1 ]; then root="$found"; src="detected"; else root=""; src=""; fi
  fi

  [ -z "$src" ] && src="unset"
  printf '%s\t%s' "$root" "$src"
}

# List the child key names of a mapping node (one per line). get_yaml_key
# deliberately returns nothing for a mapping, so this is how the whole
# workflow_overrides.system_overrides map gets enumerated in one shot.
get_yaml_child_keys() {
  local file="$1" path="$2"
  if [ -z "$file" ] || [ -z "$path" ] || [ ! -f "$file" ]; then return 0; fi
  _yaml_helper_resolve_python || return 0
  "$_yaml_helper_python" - "$file" "$path" <<'PYEOF'
import sys, re
path_file, dotted = sys.argv[1], sys.argv[2]
keys = dotted.split('.')

def parse(lines):
    root = {}
    stack = [(-1, root)]
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', stripped)
        if not m:
            continue
        key, value = m.group(1).strip(), m.group(2).strip()
        if value.startswith('#'):
            value = ''
        elif value[:1] in ('"', "'"):
            q = value[0]; end = value.find(q, 1)
            value = value[1:end] if end >= 0 else value[1:]
        else:
            hp = value.find(' #')
            if hp >= 0:
                value = value[:hp].strip()
        if value == '':
            nm = {}; parent[key] = nm; stack.append((indent, nm))
        else:
            parent[key] = value
    return root

try:
    with open(path_file, 'r', encoding='utf-8-sig', errors='replace') as f:
        data = parse(f.readlines())
except OSError:
    sys.exit(0)

cur = data
for k in keys:
    if isinstance(cur, dict) and k in cur:
        cur = cur[k]
    else:
        sys.exit(0)
if not isinstance(cur, dict):
    sys.exit(0)
sys.stdout.buffer.write("\n".join(cur.keys()).encode('utf-8'))
PYEOF
}

# Emit the resolved-config block a skill reads instead of re-deriving anything.
#
#   resolve_config [<system>]
#
# ALWAYS exits 0 and ALWAYS emits a complete block — a missing project.yaml,
# malformed YAML, an orphan project.local.yaml or a missing Python interpreter
# each degrade to defaults and surface on the notes: line rather than producing
# a truncated block a skill might half-read.
#   resolve_config [--keys k1,k2,...] [<system>]
#
# --keys restricts output to the named knobs. USE IT. Emitting all 12 lines costs
# ~188 tokens, while the resolution prose it replaces averages only ~101 tokens
# per skill -- so a full block is a NET LOSS for any skill that reads 2-3 knobs.
# A 3-knob block costs ~45 tokens, which is the actual win. Measured, not
# estimated.
# Valid key names are the output labels: rigor, review_mode, automation, workflow,
# docs.density, story_granularity, qa.level, team.size, project.stage,
# automation_always_ask, engine, testing.strict, system_overrides.
resolve_config() {
  _yaml_helper_set_root
  local want=""
  if [ "${1:-}" = "--keys" ]; then want=",${2},"; shift 2; fi
  local system="${1:-}"
  local notes="" v s pair
  # emit <label> — true when the label was requested (or nothing was restricted)
  _rc_want() { [ -z "$want" ] || case "$want" in *",$1,"*) return 0;; *) return 1;; esac; }

  if ! _yaml_helper_resolve_python; then
    notes="NO PYTHON INTERPRETER — YAML unreadable; legacy files and defaults only"
  fi
  if [ ! -f "$_YH_ROOT/project.yaml" ]; then
    notes="${notes:+$notes; }project.yaml absent — defaults in use"
  elif [ ! -s "$_YH_ROOT/project.yaml" ]; then
    # An EMPTY project.yaml resolves to defaults; unannounced it is
    # indistinguishable from a healthy fully-defaulted project. Absence is
    # announced one line above; emptiness is the more suspicious state of the two
    # (a truncated write, an interrupted /setup-engine) and was the silent one.
    notes="${notes:+$notes; }project.yaml is EMPTY — defaults in use; if you configured this project, the file did not survive"
  fi
  local orphan
  orphan=$(validate_local_yaml_base 2>&1) || notes="${notes:+$notes; }$orphan"

  # Collect enum complaints from both files so a typo is visible, not silent.
  local enum_err
  enum_err=$(validate_yaml_enum project.yaml 2>&1 >/dev/null)
  [ -n "$enum_err" ] && notes="${notes:+$notes; }$(echo "$enum_err" | tr '\n' ';' | sed 's/;$//') — ignored, chain continued"
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    enum_err=$(validate_yaml_enum project.local.yaml 2>&1 >/dev/null)
    [ -n "$enum_err" ] && notes="${notes:+$notes; }local: $(echo "$enum_err" | tr '\n' ';' | sed 's/;$//')"
    # Locked keys in the local file. Separate from the enum check
    # above because their VALUES are legal — it is the location that is not, so
    # every value-shaped validation passes them and resolution then drops them
    # in silence. Reported, never applied: see validate_local_scope.
    # Collapsed to one note listing the keys: validate_local_scope prints a
    # full remedy sentence per key for direct callers, and three copies of it
    # would cost more of this block than every resolved value put together.
    local scope_err scope_keys
    scope_err=$(validate_local_scope project.local.yaml 2>&1 >/dev/null)
    if [ -n "$scope_err" ]; then
      scope_keys=$(printf '%s\n' "$scope_err" | sed -n 's/.*`\([^`]*\)`.*/\1/p' | paste -sd, - | sed 's/,/, /g')
      notes="${notes:+$notes; }local: not locally overridable, ignored — $scope_keys (move to project.yaml or delete)"
    fi
  fi

  # Framing costs ~81 chars. For a skill reading 1-2 knobs that is more than the
  # inline chain it replaced, so bare lines are emitted instead -- "automation:
  # guided (project.local.yaml)" is self-describing without a banner. Measured:
  # single-knob skills were +226 chars WITH framing, negative without it.
  local nkeys=0
  if [ -n "$want" ]; then
    nkeys=$(printf '%s' "$want" | tr ',' '\n' | grep -c '[a-z]')
  fi
  local bare=0
  [ -n "$want" ] && [ "$nkeys" -le 2 ] && bare=1

  if [ "$bare" = "1" ]; then
    :
  elif [ -n "$want" ]; then
    echo "=== CCGS Config (resolved: local->yaml->legacy->default; use as-is) ==="
  else
    echo "=== CCGS Resolved Config ==="
  fi
  for pair in modes.rigor:rigor \
              modes.review_mode:review_mode \
              modes.automation:automation \
              modes.workflow:workflow \
              docs.density:docs.density \
              modes.story_granularity:story_granularity \
              qa.level:qa.level \
              team.size:team.size \
              project.stage:project.stage; do
    _rc_want "${pair##*:}" || continue
    v=$(resolve_setting "${pair%%:*}")
    s="${v#*$(printf '\t')}"; v="${v%%$(printf '\t')*}"
    echo "${pair##*:}: ${v:-not set} ($s)"
  done

  # automation_always_ask: array-valued, so it does not go through resolve_setting.
  local aaa
  if _rc_want automation_always_ask; then
    aaa=$(get_effective_yaml_array modes.automation_always_ask 2>/dev/null)
    if [ -n "$aaa" ]; then
      echo "automation_always_ask: $(echo "$aaa" | tr '\n' ',' | sed 's/,$//; s/,/, /g') (configured)"
    else
      echo "automation_always_ask: $(echo "$_yaml_helper_always_ask_default" | tr '\n' ',' | sed 's/,$//; s/,/, /g') (default)"
    fi
  fi

  # engine: project.yaml only. No markdown reader is built here — skills keep
  # their existing technical-preferences.md fallback prose, and forbidden
  # patterns / allowed libraries never migrate at all.
  local ename eversion
  if _rc_want engine; then
    ename=$(get_yaml_key "$_YH_ROOT/project.yaml" engine.name 2>/dev/null)
    eversion=$(get_yaml_key "$_YH_ROOT/project.yaml" engine.version 2>/dev/null)
    if [ -n "$ename" ]; then
      echo "engine: $ename${eversion:+ $eversion} (project.yaml)"
    else
      echo "engine: unset (fall back to .claude/docs/technical-preferences.md)"
    fi
  fi

  # testing.strict.*: reported as CONFIGURED STATE ONLY, never defaulted here.
  # Its unset default differs per skill by design.
  local ts_out="" k tv
  if _rc_want testing.strict; then
    for k in logic integration visual ui config; do
      tv=$(get_effective_yaml_key "testing.strict.$k" 2>/dev/null)
      [ -z "$tv" ] && tv=$(get_yaml_key "$_YH_ROOT/project.yaml" testing.strict 2>/dev/null)
      ts_out="$ts_out $k=${tv:-unset}"
    done
    echo "testing.strict:${ts_out} (unset = each skill applies its own default)"
  fi

  # performance.enforce: warn | block | off, default `warn`.
  # Unlike testing.strict.* this DOES get defaulted here -- effects-map gives it
  # a single terminal default (`warn`) rather than a per-skill one, so resolving
  # it in one place keeps /perf-profile and /gate-check from disagreeing. The
  # default lives in _yaml_helper_defaults, so resolve_setting supplies it and
  # labels it, exactly like the nine keys in the loop above.
  #
  # WAS `get_effective_yaml_key`, which reads the two YAML files and NOTHING
  # ELSE -- no enum validation and no source. That broke two invariants at the
  # one knob whose entire job is to decide whether a breach blocks a release:
  #
  #   1. An invalid value WON. `enforce: nonsense` resolved to `nonsense` and
  #      was handed to /perf-profile and /gate-check under a header that says
  #      "use as-is", while the notes line simultaneously claimed it had been
  #      "ignored, chain continued". resolve_setting falls invalid values
  #      through to the default, which is what every other knob already did --
  #      `review_mode: nonsense` resolves to `lean (rigor:standard)`.
  #   2. No provenance. Every other line names its source; this one printed a
  #      bare value with a `${pe:+}` suffix that expands to nothing -- a
  #      provenance tag someone started and never finished. The key is on the
  #      `/settings --local` whitelist and the docs stress that a teammate's
  #      stricter local setting "is meant to bite on their machine only", so
  #      "did this FAIL come from the project or from my own project.local.yaml"
  #      is exactly the question the line has to answer.
  local pe
  if _rc_want performance.enforce; then
    pe=$(resolve_setting performance.enforce)
    s="${pe#*$(printf '\t')}"; pe="${pe%%$(printf '\t')*}"
    echo "performance.enforce: ${pe:-warn} ($s)"
  fi

  # platform.cert_tier. /launch-checklist and /release-checklist both bootstrap
  # with `--keys rigor,stage,cert_tier` and are then told "Resolved above -- use
  # as-is", so without a handler here they receive nothing, always, for the
  # setting that decides which certification tracks they emit. A setting is not
  # "wired" because skills REFERENCE it; it is wired when the plumbing that
  # delivers it exists. Check the plumbing, not the references.
  #
  # NO DEFAULT SUBSTITUTED, deliberately. Unset must stay empty so the skills
  # can take their "ask which platforms are in scope" branch -- obligation 2 of
  # skill-authoring.md. Substituting `none` would make the question unaskable;
  # substituting anything else would emit every track, which is the ~150-item
  # checklist a single-platform jam project once received.
  local ct
  if _rc_want cert_tier || _rc_want platform.cert_tier; then
    ct=$(get_effective_yaml_key platform.cert_tier 2>/dev/null)
    if [ -n "$ct" ]; then
      echo "platform.cert_tier: $ct"
    else
      echo "platform.cert_tier: (unset -- ask which platforms are in scope)"
    fi
  fi

  # system_overrides: dump the whole map so the 10 per-system skills need no
  # second call. A named <system> is echoed explicitly for convenience.
  local so_keys so_out="" sk sv
  if _rc_want system_overrides; then
    so_keys=$(get_yaml_child_keys project.yaml workflow_overrides.system_overrides 2>/dev/null)
    if [ -n "$so_keys" ]; then
      while IFS= read -r sk; do
        [ -z "$sk" ] && continue
        sv=$(get_yaml_key "$_YH_ROOT/project.yaml" "workflow_overrides.system_overrides.$sk" 2>/dev/null)
        [ -n "$sv" ] && so_out="$so_out $sk=$sv"
      done <<EOF
$so_keys
EOF
    fi
    echo "system_overrides:${so_out:- none}"
  fi
  if [ -n "$system" ]; then
    sv=$(get_yaml_key "$_YH_ROOT/project.yaml" "workflow_overrides.system_overrides.$system" 2>/dev/null)
    if [ -n "$sv" ]; then
      echo "workflow[$system]: $sv (system_overrides)"
    else
      v=$(resolve_setting modes.workflow); v="${v%%$(printf '\t')*}"
      echo "workflow[$system]: $v (no override — project value)"
    fi
  fi

  if [ "$bare" = "1" ]; then
    # Bare form: values only. notes still surface, because a rejected enum value
    # or a missing interpreter must never be silent.
    [ -n "$notes" ] && echo "notes: $notes"
  elif [ -n "$want" ]; then
    # Terse form: the header already states the chain, and notes only appear
    # when something actually went wrong. Every line here is paid on every
    # invocation of every migrated skill.
    [ -n "$notes" ] && echo "notes: $notes"
    echo "=== end ==="
  else
    echo "notes: ${notes:-none}"
    echo "Values above are fully resolved (local -> yaml -> legacy -> default). Use as-is."
    echo "An inline --review flag, if passed, overrides review_mode."
    echo "=== end CCGS config ==="
  fi
  return 0
}

# --- Direct execution: the skill-bootstrap entry point -----------------------
#
#   bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys a,b
#
# Skills cannot `source` this file in their `` !`cmd` `` bootstrap line. Claude
# Code permission-checks every injected command before the skill renders, and
# outside auto mode anything short of "allow" ABORTS the whole invocation --
# measured on 2.1.281, see .claude/docs/config-resolution.md. A `${VAR:-x}` or
# `$( )` in the command fails that check as "Contains expansion" and no grant can
# approve it; a `source … && resolve_config` compound needs every part approved.
# `${CLAUDE_SKILL_DIR}` is substituted as text before the check, so one plain
# `bash <path> resolve_config …` call is approvable by the matching grant in the
# skill's own `allowed-tools`. That is also what lets a Bash-less agent preload
# the skill (GitHub issue #128).
#
# Only resolve_config is dispatchable: the bootstrap is the one caller, and
# every name added here widens what a skill grant can reach.
#
# ROOT. Run from a subdirectory, the skill shell's cwd has no project.yaml and
# $CLAUDE_PROJECT_DIR is the launch directory, not the repo root (measured), so
# rules 1-3 of _yaml_helper_set_root all miss. This file's own location is the
# one anchor that cannot drift: hooks/ sits two levels below the root. It only
# fills CLAUDE_PROJECT_DIR when that has no project.yaml, so rules 1-2 (cwd
# first, for nested projects) keep their precedence.
#
# ALWAYS exits 0: a non-zero exit from an injected command aborts the skill.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    resolve_config)
      shift
      if [ -z "${CLAUDE_PROJECT_DIR:-}" ] || [ ! -f "$CLAUDE_PROJECT_DIR/project.yaml" ]; then
        _yh_self_root=$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)
        [ -n "$_yh_self_root" ] && CLAUDE_PROJECT_DIR="$_yh_self_root"
      fi
      resolve_config "$@"
      ;;
    *)
      echo "yaml-helper.sh: usage: bash yaml-helper.sh resolve_config [--keys k1,k2,...] [<system>]"
      ;;
  esac
  exit 0
fi
