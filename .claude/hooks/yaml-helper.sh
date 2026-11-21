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
#     invalid value to stderr. Also reports tab indentation and repeated
#     keys (which the parsers merge). Returns 1 if any were found,
#     0 otherwise. Unknown-key (typo) detection is a future sub-phase —
#     enum errors are the critical-path block per the spec.
#
#   validate_local_yaml_base
#     Hard-error guard per spec: project.local.yaml requires a project.yaml
#     base. Returns 1 with error on stderr if local exists without base.
#     Uses CWD-relative paths.
#
#   is_locally_overridable <dotted.path>
#     Whitelist check for the /project-settings --local flag. Returns 0 if the
#     setting is on the personal-experience whitelist (13 settings per
#     effects-map.md), 1 otherwise. Locked settings cannot be locally
#     overridden because they affect on-disk artifacts.
#
#   validate_enum_value <dotted.path> <value>
#     Single-key version of validate_yaml_enum — for /project-settings to check
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

# THE TEXT OF A BLOCK SCALAR IS TEXT, NEVER KEYS.
#
# A value of `|` or `>`, with any chomping or indentation indicator (`|-`,
# `>+`, `|2`) and an optional comment, opens a block scalar: every following
# line indented deeper than its key, and every blank line among them, is the
# scalar's text. Read as keys, a note such as
#   notes: |
#     review_mode: full
# set modes.review_mode beside a real `review_mode: lean`, overwrote it, or
# raised an enum error at session start for a value nobody set. The value kept
# is still the indicator itself, as before; only the text stops being keys.
# block_indent gives the indent the text must exceed when a line opens one
# (the key's own column, or the dash's for a `- |` list item), else None.
# validate_yaml_enum's duplicate-key walk skips block scalars by the same rule.
def block_indent(stripped, indent):
    rest = stripped
    if rest == '-' or rest.startswith('- '):
        rest = rest[1:].lstrip(' ')
        if re.match(r'[|>][-+0-9]*\s*(#.*)?$', rest):
            return indent
        indent += len(stripped) - len(rest)
    m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', rest)
    if m and re.match(r'[|>][-+0-9]*\s*(#.*)?$', m.group(2).strip()):
        return indent
    return None

def parse(lines):
    root = {}
    stack = [(-1, root)]  # (indent, mapping)
    block = None          # indent a block scalar's text must exceed
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        if block is not None:
            if indent > block:
                continue
            block = None
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        block = block_indent(stripped, indent)
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
            # A REPEATED KEY MERGES INTO THE MAP ALREADY THERE.
            #
            # `parent[key] = {}` replaced it: a second `modes:` block further
            # down the file wiped the first, so `rigor` and `automation` set in
            # the first block fell back to their defaults and nothing said so.
            # Two blocks is a realistic file, not a contrived one -- a user or a
            # skill adding a setting appends a new block rather than finding
            # the old one. Merging keeps both; a key set in both still takes
            # the last value, as a scalar always has.
            #
            # Merging is not silence: validate_yaml_enum reports every repeated
            # key, because YAML allows a key once and other YAML tools keep only
            # the last block. Every parser in this file merges the same way.
            new_map = parent[key] if isinstance(parent.get(key), dict) else {}
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
# The text of a block scalar is text, never keys or items (see get_yaml_key).
def block_indent(stripped, indent):
    rest = stripped
    if rest == '-' or rest.startswith('- '):
        rest = rest[1:].lstrip(' ')
        if re.match(r'[|>][-+0-9]*\s*(#.*)?$', rest):
            return indent
        indent += len(stripped) - len(rest)
    m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', rest)
    if m and re.match(r'[|>][-+0-9]*\s*(#.*)?$', m.group(2).strip()):
        return indent
    return None

def parse(lines):
    root = {}
    stack = [(-1, root)]
    block = None
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            i += 1
            continue
        indent = len(line) - len(stripped)
        if block is not None:
            if indent > block:
                i += 1
                continue
            block = None
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        block = block_indent(stripped, indent)
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
            pblock = None   # an item's block scalar: its text is skipped
            while j < len(lines):
                pl = lines[j].rstrip('\n').rstrip('\r')
                pstripped = pl.lstrip(' ')
                if not pstripped.strip() or pstripped.lstrip().startswith('#'):
                    j += 1
                    continue
                pindent = len(pl) - len(pstripped)
                if pblock is not None:
                    if pindent > pblock:
                        j += 1
                        continue
                    pblock = None
                if pindent <= indent:
                    break
                if pstripped.startswith('- '):
                    pblock = block_indent(pstripped, pindent)
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
                # A repeated key merges (see get_yaml_key). A list is not
                # merged: the last one is used, and validate_yaml_enum says so.
                new_map = parent[key] if isinstance(parent.get(key), dict) else {}
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
engine.name::Godot|Unity|Unreal|Web
project.stage::Concept|Systems Design|Technical Setup|Pre-Production|Production|Polish|Release
project.goal::jam|learn|hobby|portfolio|sell|early_access|publisher|mobile|other
testing.strict.logic::true|false
testing.strict.integration::true|false
testing.strict.visual::true|false
testing.strict.ui::true|false
testing.strict.config::true|false
features.session_state::on|off
features.read_guard::on|off|true|false
platform.online::true|false
workflow_overrides.edge_cases::true|false
workflow_overrides.tuning_knobs::true|false
workflow_overrides.art_bible_strict::true|false
updates.check::true|false"
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
#     means ENABLED, which is why validating it matters. `features.read_guard`
#     is not that case: read-guard.sh reads `true` and `false` as `on` and
#     `off`, so all four are listed for it.
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
features.token_budget_warn_at
features.read_guard
features.read_guard_kb
updates.check"

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
#   /project-settings --local already refuses these; only the hand-edited file is
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
  local file="${1:-}"
  # Default to the PROJECT ROOT's local file, not the working directory's: run
  # from src/, a bare `project.local.yaml` names a file that is not there, and
  # the check passes because it found nothing to check.
  if [ -z "$file" ]; then _yaml_helper_set_root; file="$_YH_ROOT/project.local.yaml"; fi
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

# The text of a block scalar is text, never keys (see get_yaml_key).
def block_indent(stripped, indent):
    rest = stripped
    if rest == '-' or rest.startswith('- '):
        rest = rest[1:].lstrip(' ')
        if re.match(r'[|>][-+0-9]*\s*(#.*)?$', rest):
            return indent
        indent += len(stripped) - len(rest)
    m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', rest)
    if m and re.match(r'[|>][-+0-9]*\s*(#.*)?$', m.group(2).strip()):
        return indent
    return None

def parse(lines):
    root = {}
    stack = [(-1, root)]
    block = None
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        if block is not None:
            if indent > block:
                continue
            block = None
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        block = block_indent(stripped, indent)
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
            # A repeated key merges (see get_yaml_key).
            new_map = parent[key] if isinstance(parent.get(key), dict) else {}
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
            # Bytes, not print(): on Windows print() writes CRLF, bash keeps
            # the CR, and every key but the last reached the notes line with
            # a carriage return on it. The other parsers here write this way.
            sys.stdout.buffer.write((dotted + '\n').encode('utf-8'))

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
#   project. Users who want the checkpoint preview's tokens back (at most ~750
#   per session start) opt out explicitly.
#
#   Deliberately awk, not get_effective_yaml_key: this runs in log-agent.sh on
#   EVERY subagent spawn, and get_effective_yaml_key shells out to Python twice.
#   Spending 200ms of interpreter startup per spawn to check a token-saving flag
#   would be self-defeating.
session_state_enabled() {
  local f v
  # The root, not the working directory (builtins only -- no added spawn).
  _yaml_helper_set_root
  for f in "$_YH_ROOT/project.local.yaml" "$_YH_ROOT/project.yaml"; do
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

# The text of a block scalar is text, never keys (see get_yaml_key).
def block_indent(stripped, indent):
    rest = stripped
    if rest == '-' or rest.startswith('- '):
        rest = rest[1:].lstrip(' ')
        if re.match(r'[|>][-+0-9]*\s*(#.*)?$', rest):
            return indent
        indent += len(stripped) - len(rest)
    m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', rest)
    if m and re.match(r'[|>][-+0-9]*\s*(#.*)?$', m.group(2).strip()):
        return indent
    return None

def parse(lines):
    root = {}
    stack = [(-1, root)]  # (indent, mapping)
    block = None          # indent a block scalar's text must exceed
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        if block is not None:
            if indent > block:
                continue
            block = None
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        block = block_indent(stripped, indent)
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
            # A repeated key merges (see get_yaml_key); reported below.
            new_map = parent[key] if isinstance(parent.get(key), dict) else {}
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
# Without this check, the same file with tabs instead of spaces reports no
# errors while `modes.review_mode: BOGUS_VALUE` sits in it unread.
#
# This is the validator's own version of the rule the skills are held to --
# absence of evidence is not evidence of absence. It cannot report "no invalid
# values" when the real answer is "no values".
#
# YAML forbids tabs for indentation, so reporting rather than repairing is
# correct; doing neither was the defect. Comment lines are exempt: a tab in
# front of a `#` hides nothing. So is a block scalar's text (parse() skips it
# by the same rule): a tab after its indentation spaces is part of the text.
tab_lines = []
_block = None
for _n, _raw in enumerate(raw_lines, 1):
    _line = _raw.rstrip('\n').rstrip('\r')
    if not _line.strip() or _line.lstrip(' \t').startswith('#'):
        continue
    _stripped = _line.lstrip(' ')
    _indent = len(_line) - len(_stripped)
    if _block is not None:
        if _indent > _block:
            continue
        _block = None
    _lead = _line[:len(_line) - len(_line.lstrip(' \t'))]
    if '\t' in _lead:
        tab_lines.append(_n)
    _block = block_indent(_stripped, _indent)

# A REPEATED KEY IS REPORTED, though every parser here now reads through it.
#
# Before the parsers merged, a second `modes:` block replaced the first and
# this validator passed the file: the dropped `rigor: standard` was never read,
# so it could not be invalid. Merging fixed what the framework reads, but YAML
# allows a key once and other YAML tools keep only the last block, so the file
# still means different things to different readers until it is tidied. Same
# rule as the tab check: say what the parser had to work around.
#
# Its own walk, not parse(): the report needs line numbers, and whether an
# empty-valued key opens a list (the last one is used) or a map (merged).
# Each `- ` item of a list is a map of its own, named `list[n]`, so the keys of
# a list of maps (two `- name:` items under specialists) are not repeats of
# each other; a key twice inside one item still is. An item that is a quoted
# scalar is not a key, even holding a colon. The text of a block scalar (a
# value of `|` or `>`, with any indicators) is text: a `Note:` line in it is not
# a key.
def repeated_keys(lines):
    rows = []
    for n, raw in enumerate(lines, 1):
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        rows.append((n, len(line) - len(stripped), stripped))
    seen = {}
    stack = [(-1, '', 'map')]   # (indent, dotted path, map | list | item)
    items = {}                  # list path -> items seen so far
    block = None                # indent a block scalar's text must exceed
    key_re = r'([^:#\s][^:]*?)\s*:\s*(.*)$'
    for i, (n, indent, stripped) in enumerate(rows):
        if block is not None:
            if indent > block:
                continue
            block = None
        if stripped == '-' or stripped.startswith('- '):
            # A dash at a list key's own indent (a compact list) belongs to it,
            # so only deeper entries, and the item before this one, close here.
            while stack[-1][0] > indent or (stack[-1][0] == indent and stack[-1][2] == 'item'):
                stack.pop()
            owner = stack[-1][1]
            items[owner] = items.get(owner, 0) + 1
            item = '%s[%d]' % (owner, items[owner])
            stack.append((indent, item, 'item'))
            rest = stripped[1:].lstrip(' ')
            key_indent = indent + len(stripped) - len(rest)
            if not rest or rest[0] in '"\'' or rest.startswith('#'):
                continue
            if re.match(r'[|>][-+0-9]*\s*(#.*)?$', rest):
                block = indent
                continue
            m = re.match(key_re, rest)
            if not m:
                continue
            key, value = m.group(1).strip(), m.group(2).strip()
            indent = key_indent
            path = item + '.' + key
        else:
            while stack[-1][0] >= indent:
                stack.pop()
            m = re.match(key_re, stripped)
            if not m:
                continue
            key, value = m.group(1).strip(), m.group(2).strip()
            path = stack[-1][1] + '.' + key if stack[-1][1] else key
        kind = 'value'
        if value == '' or value.startswith('#'):
            nxt = rows[i + 1] if i + 1 < len(rows) else None
            if nxt and nxt[1] >= indent and (nxt[2] == '-' or nxt[2].startswith('- ')):
                kind = 'list'
            else:
                kind = 'map'
            stack.append((indent, path, kind))
        elif re.match(r'[|>][-+0-9]*\s*(#.*)?$', value):
            block = indent
        seen.setdefault(path, []).append((n, kind))
    return [(p, occ) for p, occ in seen.items() if len(occ) > 1]

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
for _path, _occ in repeated_keys(raw_lines):
    _at = ', '.join(str(n) for n, _ in _occ)
    if all(k == 'map' for _, k in _occ):
        out.append("duplicate key `%s` (lines %s): read here as one merged block, "
                   "but other YAML tools keep only the last. Combine them into "
                   "one." % (_path, _at))
    else:
        out.append("duplicate key `%s` (lines %s): only the last one is used. "
                   "Delete the others." % (_path, _at))
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

# Validate a single pending value for /project-settings writes. Looks up
# the key in _yaml_helper_enums; if found, checks value membership. If
# the key has no enum constraint, returns 0 (no validation applies).
# Returns 1 with stderr error on invalid value.
validate_enum_value() {
  local key="$1"
  local value="$2"
  [ -z "$key" ] && return 0
  # testing.strict is left out of the enum table on purpose (its shape is a map
  # of five types; see the note below the table). Written as ONE value it is the
  # back-compat boolean, so it is checked like each type is: anything else was
  # written and then read as unset, waiving a gate the user believed was on.
  if [ "$key" = "testing.strict" ]; then
    case "$value" in true|false) return 0 ;; esac
    echo "Invalid value '$value' for '$key'. Allowed: true|false" >&2
    return 1
  fi
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
#   Every skill that reads a setting needs the same deterministic fallback chain
#   ("1. If --review passed -> use that; 2. Else read modes.review_mode from
#   project.yaml; 3. Else production/review-mode.txt; 4. Else lean"). Written out
#   in each SKILL.md, a model would re-interpret that prose on every invocation.
#   resolve_config computes the same answer once, deterministically -- and
#   testably, which prose never was.
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
# review_mode to `solo` (skipping the director and specialist gates),
# `standard` yields `lean` and `full` yields `full`. team.size is fronted the
# same way: `full` yields `studio` (the whole roster) while
# `minimal`/`standard` yield `individual`. Both stay locally overridable (they
# are personal-experience knobs, not on-disk artifacts): that source sits ABOVE
# the expansion, so a local value wins over the rigor level.
#
# --- WHY modes.rigor DEFAULTS TO `minimal` -----------------------------------
#
# The heavier tier costs more to reach working code without producing a better
# result, and gives nothing back when a new contributor picks the project up. A
# default that costs more and does not repay is the wrong default, and it is
# what every user who never opens /project-settings would receive.
#
# Raising rigor is one question in /start and one `/project-settings` call, and
# settings-guidance.md's upward triggers ("system-GDD count crosses ~9",
# "gate-check PASS into Production while rigor is minimal") are written to fire
# from exactly this starting state. The cost of under-running is one prompt.
#
# ORDER MATTERS: this default is only safe while /gate-check keeps its floors.
# `rigor: minimal` expands to `workflow: minimal` + `qa.level: minimal`, which
# together would leave the Production->Polish gate with ZERO required artifacts
# -- a vacuous PASS -- without the smoke-report floor and the "nothing required
# -> NOT ASSESSED, never PASS" rule. Do not change this default without
# re-checking that each /gate-check gate still requires something.
_yaml_helper_defaults="\
modes.automation::collaborative
modes.rigor::minimal
performance.enforce::warn"

# Rigor expansion — one asked-at-/start knob that supplies four.
#
# WHY: /start does not ask about workflow, docs.density, qa.level or
# story_granularity, so in practice a project runs all four at their defaults.
# The latter three each drive one behaviour (prose verbosity, whether evidence
# is required, story size) that many skills read. `rigor` makes the common case
# reachable in one question while each knob stays individually settable.
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

# The rigor level currently in effect (for source labels and /project-settings).
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
# This list MUST equal the `/project-settings --local` write whitelist. If resolution
# consults project.local.yaml for a narrower set than /project-settings will write to
# it, `/project-settings --local modes.review_mode=solo` writes a value that /project-settings
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
  _yaml_helper_set_root
  file="$_YH_ROOT/$file"
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
    # Checked under the root; labelled with the short path the user knows.
    if [ -n "$legacy" ] && [ -f "$_YH_ROOT/$legacy" ]; then
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

# The folders a code root of `.` (the project root itself: a flat web game) never
# scans -- the framework's own, throwaway work, and build output. The same line
# is in project-state.sh and code-markers.sh; keep the three the same.
CODE_ROOT_SKIP=".claude .git production design docs tests studio-tests prototypes tools node_modules dist"
# The folders engine.code_root may not name: the framework's own or throwaway.
CODE_ROOT_DENY=".claude .git production design docs tests studio-tests prototypes"

# The engine table, .claude/engines/engines.tsv: each engine's code, test and
# asset roots and its default commands (web-folder-design.md section 3). Found
# beside this file, not under the project root, so a helper sourced from another
# checkout reads its own table. No spawn here: this file is sourced by every hook.
_yh_self="${BASH_SOURCE[0]:-}"
case "$_yh_self" in */*) _YH_DIR="${_yh_self%/*}" ;; *) _YH_DIR="." ;; esac
case "$_YH_DIR" in /*|[A-Za-z]:*) ;; *) _YH_DIR="$PWD/$_YH_DIR" ;; esac
_YH_ENGINES="$_YH_DIR/../engines/engines.tsv"
_YH_ENGINE_ROW="$_YH_DIR/../scripts/engine-row.awk"

# _yh_engine_cell NAME COLUMN -- one cell of NAME's row: empty for a `-` cell, an
# engine the table does not name, or a missing table (read as an unknown engine).
_yh_engine_cell() {
  [ -n "$1" ] && [ -f "$_YH_ENGINES" ] && [ -f "$_YH_ENGINE_ROW" ] || return 0
  awk -F'\t' -v engine="$1" -v col="$2" -f "$_YH_ENGINE_ROW" "$_YH_ENGINES" 2>/dev/null
}

# _yh_code_root_check ROOT VALUE [KEY [DENY]] -- checks an engine.code_root value
# (or engine.test_root's, named by KEY, with DENY in place of CODE_ROOT_DENY) against
# the tree at ROOT. Prints the folder when it can be used, a TAB then the reason
# when it cannot, and nothing when the value is not set (empty, a [...]
# placeholder, or YAML's own null: ~, null, Null, NULL). Spelling is checked
# against each parent's listing, because on Windows and default macOS
# `[ -d scripts ]` is also true for Scripts/, which a Linux CI run would then
# not find. The same function is in project-state.sh.
_yh_code_root_check() {
  local base="$1" v="$2" key="${3:-engine.code_root}" deny="${4-$CODE_ROOT_DENY}" rest seg parent out first lo d actual
  v=$(printf '%s' "$v" | tr -d '\r')
  case "$v" in ""|"["*|"~"|null|Null|NULL) return 0 ;; esac
  case "$v" in *\\*) printf "\t$key: use / not \\\\ in '%s'" "$v"; return 0 ;; esac
  case "$v" in /*|"~"*|[A-Za-z]:*) printf "\t$key: absolute path '%s'" "$v"; return 0 ;; esac
  while :; do case "$v" in */) v="${v%/}" ;; ./*) v="${v#./}" ;; *) break ;; esac; done
  [ -z "$v" ] && v="."
  [ "$v" = "." ] && { printf '.'; return 0; }
  case "/$v/" in */../*) printf "\t$key: '..' not allowed in '%s'" "$v"; return 0 ;; esac
  case "/$v/" in */./*|*//*) printf "\t$key: '%s' is not a plain folder path" "$v"; return 0 ;; esac
  first="${v%%/*}"; lo=$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')
  for d in $deny; do
    [ "$lo" = "$d" ] && { printf "\t$key: framework folder '%s'" "$first"; return 0; }
  done
  parent="$base"; rest="$v"; out=""
  while [ -n "$rest" ]; do
    seg="${rest%%/*}"
    if [ "$seg" = "$rest" ]; then rest=""; else rest="${rest#*/}"; fi
    if [ ! -d "$parent/$seg" ]; then
      # A case-sensitive disk (Linux, some macOS) has no "$seg" spelled with other capitals:
      # name the spelling on disk, as a case-insensitive disk does below.
      actual=$(ls -1A "$parent" 2>/dev/null | LC_ALL=C grep -Fxi -- "$seg" | head -1)
      if [ -n "$actual" ] && [ -d "$parent/$actual" ]; then
        printf "\t$key: spelled '%s' on disk, not '%s'" "${out:+$out/}$actual" "${out:+$out/}$seg"; return 0
      fi
      printf "\t$key: no folder '%s'" "${out:+$out/}$seg"; return 0
    fi
    if ! ls -1A "$parent" 2>/dev/null | LC_ALL=C grep -Fxq -- "$seg"; then
      actual=$(ls -1A "$parent" 2>/dev/null | LC_ALL=C grep -Fxi -- "$seg" | head -1)
      printf "\t$key: spelled '%s' on disk, not '%s'" "${out:+$out/}$actual" "${out:+$out/}$seg"; return 0
    fi
    out="${out:+$out/}$seg"; parent="$parent/$seg"
  done
  printf '%s' "$out"
}

# code_root_filter ROOT -- repo-relative paths on stdin, those under ROOT on
# stdout (a leading ./ removed). For ROOT `.`, every path outside the
# CODE_ROOT_SKIP folders. Callers use it in place of `grep "^$ROOT/"`, which
# for `.` would read as the regex `^./` and match the wrong files.
code_root_filter() {
  awk -v root="${1%/}" -v skip="$CODE_ROOT_SKIP" '
    BEGIN { n = split(skip, s, " ") }
    { p = $0; sub(/\r$/, "", p); sub(/^\.\//, "", p); if (p == "") next }
    root != "." { if (index(p, root "/") == 1) print p; next }
    { top = p; sub(/\/.*/, "", top)
      if (top != p) for (i = 1; i <= n; i++) if (top == s[i]) next
      print p }'
}

# code_root_find ROOT FIND-TESTS... -- `find ROOT FIND-TESTS... -print`, except
# that for ROOT `.` the CODE_ROOT_SKIP folders at the top are not entered.
code_root_find() {
  local root="${1%/}" d; shift
  if [ "$root" != "." ]; then find "$root" "$@" 2>/dev/null; return 0; fi
  set -- \) -prune -o \( "$@" \) -print
  for d in $CODE_ROOT_SKIP; do set -- -o -path "./$d" "$@"; done
  shift   # the first -o
  find . \( "$@" 2>/dev/null
}

# _yh_engine_name -- the engine name the code and test roots are read for, into
# _YH_ENAME, and where it came from into _YH_ESRC (engine.name, project.local.yaml
# or the legacy file; empty when unset). Variables, not output: no subshell.
_yh_engine_name() {
  local legacy
  _YH_ENAME=""; _YH_ESRC=""
  # 1. The configured engine, through the normal chain.
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    _YH_ENAME=$(get_yaml_key "$_YH_ROOT/project.local.yaml" engine.name 2>/dev/null)
    [ -n "$_YH_ENAME" ] && _YH_ESRC="project.local.yaml"
  fi
  if [ -z "$_YH_ENAME" ] && [ -f "$_YH_ROOT/project.yaml" ]; then
    _YH_ENAME=$(get_yaml_key "$_YH_ROOT/project.yaml" engine.name 2>/dev/null)
    [ -n "$_YH_ENAME" ] && _YH_ESRC="engine.name"
  fi

  # 2. The legacy mirror. `/setup-engine` wrote an `Engine:` line here before
  #    project.yaml existed, and workflow-catalog's `engine-setup` step still
  #    accepts it as an `any_of` alternative — so a v1.0 project that never
  #    migrated resolves rather than falling through to "unset".
  legacy="$_YH_ROOT/.claude/docs/technical-preferences.md"
  if [ -z "$_YH_ENAME" ] && [ -f "$legacy" ]; then
    _YH_ENAME=$(grep -iE '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Engine\*{0,2}[[:space:]]*:' "$legacy" 2>/dev/null \
            | head -1 | sed 's/.*://' | tr -d '\r' \
            | sed 's/^[[:space:]]*//; s/[[:space:]].*$//; s/\*//g')
    case "$_YH_ENAME" in
      *"[TO BE CONFIGURED]"*|"["*) _YH_ENAME="" ;;
    esac
    [ -n "$_YH_ENAME" ] && _YH_ESRC=".claude/docs/technical-preferences.md"
  fi

  return 0
}

# Resolve the ENGINE-SPECIFIC code root.
#   prints: "<dir>\t<source>", or "\tinvalid\t<reason>" for a bad engine.code_root
#   source: engine.code_root | engine.name | <legacy path> | detected | unset | invalid
#   exit:   always 0
#
# A bad engine.code_root never falls back to the engine's folder: a typo for
# scripts/ that quietly read src/ would scan nothing and look clean, which is
# the bug the override exists to fix.
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
  local ename="" src="" root="" found="" d n=0 ov="" chk="" line tab
  tab=$(printf '\t')

  # 0. The project's own override, engine.code_root. project.yaml only:
  #    engine.* is shared by the whole team (effects-map.md), so a value in
  #    project.local.yaml is not read, and validate_local_scope reports it.
  #    The read loop is bash only: a project that never sets the key starts no
  #    interpreter here, and this runs in three hooks.
  if [ -f "$_YH_ROOT/project.yaml" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in *code_root*:*) ov=1; break ;; esac
    done < "$_YH_ROOT/project.yaml"
    if [ -n "$ov" ]; then
      ov=$(get_yaml_key "$_YH_ROOT/project.yaml" engine.code_root 2>/dev/null)
      chk=$(_yh_code_root_check "$_YH_ROOT" "$ov")
      case "$chk" in
        "") ;;
        "$tab"*) printf '\tinvalid\t%s' "${chk#"$tab"}"; return 0 ;;
        *) printf '%s\tengine.code_root' "$chk"; return 0 ;;
      esac
    fi
  fi

  # 1-2. The configured engine, then the legacy mirror; its folder from the
  #      engine table (Godot src, Unity Assets, Unreal Source, Web src).
  _yh_engine_name; ename="$_YH_ENAME"; src="$_YH_ESRC"
  root=$(_yh_engine_cell "$ename" code_root)

  # 3. No usable engine value — believe the tree, but only if it is unambiguous.
  #    Names are compared exactly, against the directory listing: `[ -d Assets ]`
  #    is also true for Godot's own `assets/` on a case-insensitive filesystem
  #    (Windows, default macOS), which made src/ + assets/ "ambiguous" and a lone
  #    assets/ a Unity project.
  if [ -z "$root" ]; then
    for d in "$_YH_ROOT"/*/; do
      d="${d%/}"; d="${d##*/}"
      case "$d" in src|Assets|Source) found="$d"; n=$((n + 1)) ;; esac
    done
    if [ "$n" = 1 ]; then root="$found"; src="detected"; else root=""; src=""; fi
  fi

  [ -z "$src" ] && src="unset"
  printf '%s\t%s' "$root" "$src"
}

# Resolve the engine's TEST root (web-folder-design.md section 3).
#   prints: "<dir>\t<source>", or "\tinvalid\t<reason>" for a bad engine.test_root
#   source: engine.test_root | engine.name | <legacy path> | unset | invalid
# engine.test_root in project.yaml beats the engine's row, with engine.code_root's
# checks, except that it may name tests/. Unset, the engine's row decides; an
# unknown or unset engine has none (never a guessed tests/).
CODE_ROOT_DENY_TESTS=".claude .git production design docs studio-tests prototypes"
resolve_test_root() {
  _yaml_helper_set_root
  local ov="" chk="" line root tab
  tab=$(printf '\t')
  if [ -f "$_YH_ROOT/project.yaml" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in *test_root*:*) ov=1; break ;; esac
    done < "$_YH_ROOT/project.yaml"
    if [ -n "$ov" ]; then
      ov=$(get_yaml_key "$_YH_ROOT/project.yaml" engine.test_root 2>/dev/null)
      chk=$(_yh_code_root_check "$_YH_ROOT" "$ov" engine.test_root "$CODE_ROOT_DENY_TESTS")
      case "$chk" in
        "") ;;
        "$tab"*) printf '\tinvalid\t%s' "${chk#"$tab"}"; return 0 ;;
        *) printf '%s\tengine.test_root' "$chk"; return 0 ;;
      esac
    fi
  fi
  _yh_engine_name
  root=$(_yh_engine_cell "$_YH_ENAME" test_root)
  if [ -n "$root" ]; then printf '%s\t%s' "$root" "$_YH_ESRC"; else printf '\tunset'; fi
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

# The text of a block scalar is text, never keys (see get_yaml_key).
def block_indent(stripped, indent):
    rest = stripped
    if rest == '-' or rest.startswith('- '):
        rest = rest[1:].lstrip(' ')
        if re.match(r'[|>][-+0-9]*\s*(#.*)?$', rest):
            return indent
        indent += len(stripped) - len(rest)
    m = re.match(r'([^:#\s][^:]*?)\s*:\s*(.*)$', rest)
    if m and re.match(r'[|>][-+0-9]*\s*(#.*)?$', m.group(2).strip()):
        return indent
    return None

def parse(lines):
    root = {}
    stack = [(-1, root)]
    block = None
    for raw in lines:
        line = raw.rstrip('\n').rstrip('\r')
        stripped = line.lstrip(' ')
        if not stripped.strip() or stripped.lstrip().startswith('#'):
            continue
        indent = len(line) - len(stripped)
        if block is not None:
            if indent > block:
                continue
            block = None
        while stack and stack[-1][0] >= indent:
            stack.pop()
        if not stack:
            return root
        parent = stack[-1][1]
        block = block_indent(stripped, indent)
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
            # A repeated key merges (see get_yaml_key).
            nm = parent[key] if isinstance(parent.get(key), dict) else {}
            parent[key] = nm; stack.append((indent, nm))
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
# --keys restricts output to the named knobs. USE IT. A block of every knob
# costs more than the resolution prose it replaces in a skill that reads 2-3
# knobs; a block of just those knobs is the saving.
# Valid key names are the output labels: rigor, review_mode, automation, workflow,
# docs.density, story_granularity, qa.level, team.size, project.stage,
# automation_always_ask, engine, testing.strict, system_overrides; and, only when
# named, the derived lines gate_level, engine_values, specialists, review_gate,
# input_methods, perf_budgets, engine_row.
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
  # Every file below is named under $_YH_ROOT. A bare `project.yaml` is the
  # WORKING directory's, so run from src/ these checks found no file and
  # reported nothing, while the values above them resolved from the root.
  # A repeated key is not "ignored": its blocks were merged and read. Those
  # lines are split off so the suffix does not contradict them. Bash only, and
  # only when something was reported -- this runs in every skill bootstrap.
  local enum_err dup_lines="" bad_lines="" l
  enum_err=$(validate_yaml_enum "$_YH_ROOT/project.yaml" 2>&1 >/dev/null)
  if [ -n "$enum_err" ]; then
    while IFS= read -r l; do
      case "$l" in
        "duplicate key "*) dup_lines="${dup_lines:+$dup_lines;}$l" ;;
        ?*) bad_lines="${bad_lines:+$bad_lines;}$l" ;;
      esac
    done <<EOF
$enum_err
EOF
    [ -n "$dup_lines" ] && notes="${notes:+$notes; }$dup_lines"
    [ -n "$bad_lines" ] && notes="${notes:+$notes; }$bad_lines — ignored, chain continued"
  fi
  if [ -f "$_YH_ROOT/project.local.yaml" ]; then
    enum_err=$(validate_yaml_enum "$_YH_ROOT/project.local.yaml" 2>&1 >/dev/null)
    [ -n "$enum_err" ] && notes="${notes:+$notes; }local: $(echo "$enum_err" | tr '\n' ';' | sed 's/;$//')"
    # Locked keys in the local file. Separate from the enum check
    # above because their VALUES are legal — it is the location that is not, so
    # every value-shaped validation passes them and resolution then drops them
    # in silence. Reported, never applied: see validate_local_scope.
    # Collapsed to one note listing the keys: validate_local_scope prints a
    # full remedy sentence per key for direct callers, and three copies of it
    # would cost more of this block than every resolved value put together.
    local scope_err scope_keys
    scope_err=$(validate_local_scope "$_YH_ROOT/project.local.yaml" 2>&1 >/dev/null)
    if [ -n "$scope_err" ]; then
      scope_keys=$(printf '%s\n' "$scope_err" | sed -n 's/.*`\([^`]*\)`.*/\1/p' | paste -sd, - | sed 's/,/, /g')
      notes="${notes:+$notes; }local: not locally overridable, ignored — $scope_keys (move to project.yaml or delete)"
    fi
  fi

  # For a skill reading 1-2 knobs the block's framing would cost more than the
  # inline chain it replaced, so bare lines are emitted instead -- "automation:
  # guided (project.local.yaml)" is self-describing without a banner.
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
  # Joined item by item. It used to join on commas and then turn every comma
  # into ", ", so one quoted item holding a comma printed as two items. An item
  # that holds a comma is now quoted, so one item stays one item.
  _rc_join() {
    printf '%s\n' "$1" | awk '/^[[:space:]]*$/ { next }
      { s = $0; if (index(s, ",")) s = "\"" s "\""; out = out (n++ ? ", " : "") s }
      END { print out }'
  }
  local aaa
  if _rc_want automation_always_ask; then
    aaa=$(get_effective_yaml_array modes.automation_always_ask 2>/dev/null)
    if [ -n "$aaa" ]; then
      echo "automation_always_ask: $(_rc_join "$aaa") (configured)"
    else
      echo "automation_always_ask: $(_rc_join "$_yaml_helper_always_ask_default") (default)"
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
  #
  # Each value is validated before it counts: get_effective_yaml_key printed an
  # invalid value (`logic: maybe`) as the value while the notes line said it was
  # ignored. Local first (the keys are locally overridable), then project.yaml,
  # then the scalar shorthand (`testing.strict: true`), each checked against
  # true|false. Not resolve_setting: that adds a rigor lookup per type, and
  # testing.strict is neither rigor-fronted nor defaulted -- five more
  # interpreter spawns for nothing. validate_enum_value is bash only.
  local ts_out="" k tv ts_all
  if _rc_want testing.strict; then
    ts_all=$(get_yaml_key "$_YH_ROOT/project.yaml" testing.strict 2>/dev/null)
    if [ -n "$ts_all" ] && ! validate_enum_value testing.strict.logic "$ts_all" 2>/dev/null; then ts_all=""; fi
    for k in logic integration visual ui config; do
      tv=""
      if [ -f "$_YH_ROOT/project.local.yaml" ]; then
        tv=$(get_yaml_key "$_YH_ROOT/project.local.yaml" "testing.strict.$k" 2>/dev/null)
        if [ -n "$tv" ] && ! validate_enum_value "testing.strict.$k" "$tv" 2>/dev/null; then tv=""; fi
      fi
      if [ -z "$tv" ]; then
        tv=$(get_yaml_key "$_YH_ROOT/project.yaml" "testing.strict.$k" 2>/dev/null)
        if [ -n "$tv" ] && ! validate_enum_value "testing.strict.$k" "$tv" 2>/dev/null; then tv=""; fi
      fi
      [ -z "$tv" ] && tv="$ts_all"
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
  #      `review_mode: nonsense` resolves to the rigor value, `solo (rigor:minimal)`
  #      by default.
  #   2. No provenance. Every other line names its source; this one printed a
  #      bare value with a `${pe:+}` suffix that expands to nothing -- a
  #      provenance tag someone started and never finished. The key is on the
  #      `/project-settings --local` whitelist and the docs stress that a teammate's
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
  #
  # Through resolve_setting, as performance.enforce above. get_effective_yaml_key
  # let a hand-edited project.local.yaml win although platform.* is locked, and
  # printed an invalid value (`banana`) as the value while the notes line said
  # it was ignored. Only project.yaml can set it, so any other source -- there is
  # no default to fall to -- leaves it unset and the skill asks.
  local ct cs
  if _rc_want cert_tier || _rc_want platform.cert_tier; then
    ct=$(resolve_setting platform.cert_tier)
    cs="${ct#*$(printf '\t')}"; ct="${ct%%$(printf '\t')*}"
    if [ -n "$ct" ] && [ "$cs" = "project.yaml" ]; then
      echo "platform.cert_tier: $ct ($cs)"
    else
      echo "platform.cert_tier: (unset -- ask which platforms are in scope)"
    fi
  fi

  # system_overrides: dump the whole map so the 10 per-system skills need no
  # second call. A named <system> is echoed explicitly for convenience.
  local so_keys so_out="" sk sv
  if _rc_want system_overrides; then
    so_keys=$(get_yaml_child_keys "$_YH_ROOT/project.yaml" workflow_overrides.system_overrides 2>/dev/null)
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

  # --- Derived lines: answers six steps that skills used to work out by hand ---
  # Each is printed ONLY when asked for by name (--keys gate_level,...): a block
  # without --keys, and every existing --keys call, prints exactly what it did
  # before and spawns no extra interpreter. Each value carries its source in
  # parentheses, like every other line. YAML `null` and `~` read back as those
  # strings, which are not empty, so they are mapped to unset here once rather
  # than in every skill (a skill once started an agent called "null").
  _rc_named() { [ -n "$want" ] && _rc_want "$1"; }
  _rc_tag() { if [ -n "$1" ]; then printf '%s(%s)' "$1" "$2"; else printf unset; fi; }
  _rc_yaml() {  # _rc_yaml <file> <key>: the value, with null/~ as empty
    local rv
    rv=$(get_yaml_key "$1" "$2" 2>/dev/null)
    case "$rv" in null|Null|NULL|"~") rv="" ;; esac
    printf '%s' "$rv"
  }
  # _rc_tp <label>: a `- **Label**: value` line of the legacy
  # technical-preferences.md; its `[TO BE CONFIGURED]` placeholder is unset.
  _rc_tp() {
    local f="$_YH_ROOT/.claude/docs/technical-preferences.md"
    [ -f "$f" ] || return 0
    awk -v lbl="**$1**:" '{ gsub(/\r/, "") }
      index($0, lbl) { v = substr($0, index($0, lbl) + length(lbl))
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        if (v !~ /TO BE CONFIGURED/) print v; exit }' "$f"
  }
  local tp_src=".claude/docs/technical-preferences.md"

  # gate_level: the gate level per story type, as coding-standards.md's table
  # defines it: testing.strict.<type> (project.local.yaml, then project.yaml),
  # then the legacy plain `testing.strict: true|false`, then the default
  # (blocking, except config/data: advisory). /smoke-check's own unset default
  # for config is blocking (a build-health gate), so it is named beside config
  # when config fell to the default. An invalid value is skipped, as in the
  # testing.strict line above, and that line's notes name it.
  local gl_all gl_out="" gk gv gsrc
  if _rc_named gate_level; then
    gl_all=$(get_yaml_key "$_YH_ROOT/project.yaml" testing.strict 2>/dev/null)
    if [ -n "$gl_all" ] && ! validate_enum_value testing.strict.logic "$gl_all" 2>/dev/null; then gl_all=""; fi
    for gk in logic integration visual ui config; do
      gv=""; gsrc=""
      if [ -f "$_YH_ROOT/project.local.yaml" ]; then
        gv=$(get_yaml_key "$_YH_ROOT/project.local.yaml" "testing.strict.$gk" 2>/dev/null)
        if [ -n "$gv" ] && ! validate_enum_value "testing.strict.$gk" "$gv" 2>/dev/null; then gv=""; fi
        [ -n "$gv" ] && gsrc="project.local.yaml"
      fi
      if [ -z "$gv" ]; then
        gv=$(get_yaml_key "$_YH_ROOT/project.yaml" "testing.strict.$gk" 2>/dev/null)
        if [ -n "$gv" ] && ! validate_enum_value "testing.strict.$gk" "$gv" 2>/dev/null; then gv=""; fi
        [ -n "$gv" ] && gsrc="project.yaml"
      fi
      if [ -z "$gv" ] && [ -n "$gl_all" ]; then gv="$gl_all"; gsrc="testing.strict"; fi
      case "$gv" in
        true)  gl_out="$gl_out $gk=blocking($gsrc)" ;;
        false) gl_out="$gl_out $gk=advisory($gsrc)" ;;
        *) if [ "$gk" = "config" ]; then
             gl_out="$gl_out config=advisory(default; /smoke-check: blocking)"
           else
             gl_out="$gl_out $gk=blocking(default)"
           fi ;;
      esac
    done
    echo "gate_level:$gl_out"
  fi

  # engine_values: engine.name, .version and .language from project.yaml, each
  # falling back to technical-preferences.md, the record a v1.0 project that
  # never migrated still has. Its Engine line holds name and version together
  # ("Godot 4.6", "Unreal Engine 5.4"): the last word is the version when it
  # starts with a digit. Locked keys, so project.local.yaml is not read.
  local ev_name ev_ver ev_lang ev_line ev_ns ev_vs ev_ls
  if _rc_named engine_values || _rc_named specialists; then
    ev_name=$(_rc_yaml "$_YH_ROOT/project.yaml" engine.name); ev_ns="project.yaml"
    ev_ver=$(_rc_yaml "$_YH_ROOT/project.yaml" engine.version); ev_vs="project.yaml"
    ev_lang=$(_rc_yaml "$_YH_ROOT/project.yaml" engine.language); ev_ls="project.yaml"
    if [ -z "$ev_name" ] || [ -z "$ev_ver" ]; then
      ev_line=$(_rc_tp Engine)
      if [ -n "$ev_line" ]; then
        case "${ev_line##* }" in
          [0-9]*) [ -z "$ev_ver" ] && { ev_ver="${ev_line##* }"; ev_vs="$tp_src"; }
                  [ -z "$ev_name" ] && { ev_name="${ev_line% *}"; ev_ns="$tp_src"; } ;;
          *)      [ -z "$ev_name" ] && { ev_name="$ev_line"; ev_ns="$tp_src"; } ;;
        esac
      fi
    fi
    if [ -z "$ev_lang" ]; then
      ev_lang=$(_rc_tp Language); ev_ls="$tp_src"
    fi
  fi
  if _rc_named engine_values; then
    echo "engine_values: name=$(_rc_tag "$ev_name" "$ev_ns") version=$(_rc_tag "$ev_ver" "$ev_vs") language=$(_rc_tag "$ev_lang" "$ev_ls")"
  fi

  # specialists: the agents a skill starts for engine work. primary is derived
  # from the engine (Godot -> godot-specialist), else the legacy Primary line.
  # code, shader, ui and additional come from project.yaml's specialists block;
  # a member set to null is UNSET, never an agent name. Only when the block is
  # absent do they fall back to technical-preferences.md (the v1.0 migration
  # writes the whole block, with null for each member it did not know).
  local sp_primary sp_psrc sp_src sp_code sp_shader sp_ui sp_add
  if _rc_named specialists; then
    case "$(printf '%s' "$ev_name" | tr '[:upper:]' '[:lower:]')" in
      godot)   sp_primary="godot-specialist" ;;
      unity)   sp_primary="unity-specialist" ;;
      unreal*) sp_primary="unreal-specialist" ;;
      # No web specialist: engine work on Web goes to lead-programmer,
      # against docs/engine-reference/web/.
      web)     sp_primary="lead-programmer" ;;
      *)       sp_primary="" ;;
    esac
    sp_psrc="engine.name"
    if [ -z "$sp_primary" ]; then sp_primary=$(_rc_tp Primary); sp_psrc="$tp_src"; fi
    if [ -n "$(get_yaml_child_keys "$_YH_ROOT/project.yaml" specialists 2>/dev/null)" ]; then
      sp_src="project.yaml"
      sp_code=$(_rc_yaml "$_YH_ROOT/project.yaml" specialists.code)
      sp_shader=$(_rc_yaml "$_YH_ROOT/project.yaml" specialists.shader)
      sp_ui=$(_rc_yaml "$_YH_ROOT/project.yaml" specialists.ui)
      sp_add=$(get_yaml_array "$_YH_ROOT/project.yaml" specialists.additional 2>/dev/null \
               | awk '$0 != "" && $0 != "null" && $0 != "~"' | paste -sd, - | sed 's/,/, /g')
    else
      sp_src="$tp_src"
      sp_code=$(_rc_tp "Language/Code Specialist")
      sp_shader=$(_rc_tp "Shader Specialist")
      sp_ui=$(_rc_tp "UI Specialist")
      sp_add=$(_rc_tp "Additional Specialists")
      [ -z "$sp_code$sp_shader$sp_ui$sp_add" ] && sp_src="no specialists block"
    fi
    echo "specialists: primary=$(_rc_tag "$sp_primary" "$sp_psrc") code=${sp_code:-unset} shader=${sp_shader:-unset} ui=${sp_ui:-unset} additional=${sp_add:-none} ($sp_src; unset = skip that specialist)"
  fi

  # engine_row: the engine's row of .claude/engines/engines.tsv, for a skill that
  # needs the engine's folders or default commands. code_root and test_root are
  # the resolved ones (engine.code_root and engine.test_root beat the row, and a
  # bad value is invalid with its reason); asset_root and the four commands are
  # the table's, `-` where it has none. The project's own commands.* still win
  # where a skill runs a command. Same engine-name chain as resolve_code_root.
  local er_row er_t er_cr er_tr er_e er_out f er_i
  if _rc_named engine_row; then
    er_t=$(printf '\t')
    _yh_engine_name
    er_row=""; [ -n "$_YH_ENAME" ] && er_row=$(_yh_engine_cell "$_YH_ENAME" "")
    case "$_YH_ESRC" in engine.name) er_e="project.yaml" ;; *) er_e="$_YH_ESRC" ;; esac
    if [ -z "$_YH_ENAME" ]; then er_e="unset"
    elif [ -z "$er_row" ]; then er_e="$_YH_ENAME($er_e; not in the table)"
    else er_e="$_YH_ENAME($er_e)"; fi
    _rc_root() {  # "<dir>\t<src>" or "\tinvalid\t<why>" or "\t<src>" -> dir(src) | invalid(why) | unset
      case "$1" in
        "$er_t"invalid"$er_t"*) printf 'invalid(%s)' "${1#"$er_t"invalid"$er_t"}" ;;
        "$er_t"*|"") printf unset ;;
        *) printf '%s(%s)' "${1%%"$er_t"*}" "${1#*"$er_t"}" ;;
      esac
    }
    er_cr=$(_rc_root "$(resolve_code_root)"); er_tr=$(_rc_root "$(resolve_test_root)")
    er_out=""
    if [ -n "$er_row" ]; then
      er_row="${er_row#*"$er_t"}${er_t}"   # drop the engine column; split on tabs (no cell is empty)
      for er_i in code_root test_root asset_root run build test smoke; do
        f="${er_row%%"$er_t"*}"; er_row="${er_row#*"$er_t"}"
        case "$er_i" in
          code_root|test_root) ;;
          asset_root) er_out="$er_out asset_root=$f" ;;
          *) if [ "$f" = "-" ]; then er_out="$er_out $er_i=-"; else er_out="$er_out $er_i=\"$f\""; fi ;;
        esac
      done
    else
      er_out=" asset_root=- run=- build=- test=- smoke=-"
    fi
    echo "engine_row: engine=$er_e code_root=$er_cr test_root=$er_tr$er_out (.claude/engines/engines.tsv; - = not in the table)"
  fi

  # review_gate: whether a skill's own director gate runs, and whether the
  # PHASE-GATEs run, at the resolved review_mode (director-gates.md): solo runs
  # none, lean only the PHASE-GATEs, full all. How many PHASE-GATEs run is
  # /gate-check's own rule (modes.workflow), not this line's.
  local rg rgs rg_skill rg_phase
  if _rc_named review_gate; then
    rg=$(resolve_setting modes.review_mode)
    rgs="${rg#*$(printf '\t')}"; rg="${rg%%$(printf '\t')*}"
    case "$rg" in
      full) rg_skill=run;  rg_phase=run ;;
      lean) rg_skill=skip; rg_phase=run ;;
      *)    rg_skill=skip; rg_phase=skip ;;
    esac
    echo "review_gate: skill-gates=$rg_skill phase-gates=$rg_phase (review_mode ${rg:-solo}, $rgs; a --review flag overrides)"
  fi

  # input_methods: the set of supported input methods, derived from project.yaml's
  # platform block: keyboard/mouse when PC or Web is a target, gamepad and touch
  # when their support is Full or Partial (Full | Partial | None, in any case:
  # `full` is how every other value in the file is written), plus the primary
  # input. Each method is listed once: a primary input spelt Keyboard, Mouse or
  # Keyboard & Mouse is keyboard/mouse, Controller or Joypad is gamepad,
  # Touchscreen is touch; any other primary input is added as written, in lower
  # case. Without a platform block, technical-preferences.md's explicit Input
  # Methods line. Locked keys, so project.local.yaml is not read.
  local im_set="" im_t im_g im_to im_p im_pl
  if _rc_named input_methods; then
    if [ -n "$(get_yaml_child_keys "$_YH_ROOT/project.yaml" platform 2>/dev/null)" ]; then
      im_t=$(get_yaml_array "$_YH_ROOT/project.yaml" platform.targets 2>/dev/null | tr '[:upper:]' '[:lower:]')
      im_g=$(_rc_yaml "$_YH_ROOT/project.yaml" platform.gamepad_support)
      im_to=$(_rc_yaml "$_YH_ROOT/project.yaml" platform.touch_support)
      im_p=$(_rc_yaml "$_YH_ROOT/project.yaml" platform.primary_input)
      printf '%s\n' "$im_t" | grep -qxE 'pc|web' && im_set="keyboard/mouse"
      case "$im_g" in [Ff][Uu][Ll][Ll]|[Pp][Aa][Rr][Tt][Ii][Aa][Ll]) im_set="${im_set:+$im_set, }gamepad" ;; esac
      case "$im_to" in [Ff][Uu][Ll][Ll]|[Pp][Aa][Rr][Tt][Ii][Aa][Ll]) im_set="${im_set:+$im_set, }touch" ;; esac
      im_pl=$(printf '%s' "$im_p" | tr '[:upper:]' '[:lower:]')
      case "$(printf '%s' "$im_pl" | tr -d ' ')" in
        keyboard|mouse|keyboard/mouse|mouse/keyboard|keyboard+mouse|mouse+keyboard|keyboard\&mouse|mouse\&keyboard|keyboardandmouse|mouseandkeyboard|keyboard-mouse|kbm|kb/m|kb+m|m+kb|mkb)
          im_pl="keyboard/mouse" ;;
        gamepad|controller|gamecontroller|joypad) im_pl="gamepad" ;;
        touch|touchscreen) im_pl="touch" ;;
      esac
      if [ -n "$im_pl" ]; then
        case ", $im_set," in *", $im_pl,"*) ;; *) im_set="${im_set:+$im_set, }$im_pl" ;; esac
      fi
      echo "input_methods: ${im_set:-none} (project.yaml platform; primary: ${im_p:-unset})"
    else
      im_set=$(_rc_tp "Input Methods"); im_p=$(_rc_tp "Primary Input")
      if [ -n "$im_set" ]; then
        echo "input_methods: $im_set ($tp_src; primary: ${im_p:-unset})"
      else
        echo "input_methods: unset (no platform block in project.yaml, no Input Methods line)"
      fi
    fi
  fi

  # perf_budgets: the four committed performance budgets, each spelled out in
  # full (the dead-settings audit matches whole dotted keys). Locked keys, so
  # project.yaml only: a budget in project.local.yaml is reported on notes as
  # not locally overridable and never applied, like every other locked key.
  local pb_out="" pb_v
  if _rc_named perf_budgets; then
    pb_v=$(_rc_yaml "$_YH_ROOT/project.yaml" performance.target_framerate)
    pb_out="$pb_out target_framerate=${pb_v:-unset}"
    pb_v=$(_rc_yaml "$_YH_ROOT/project.yaml" performance.frame_budget_ms)
    pb_out="$pb_out frame_budget_ms=${pb_v:-unset}"
    pb_v=$(_rc_yaml "$_YH_ROOT/project.yaml" performance.draw_call_limit)
    pb_out="$pb_out draw_call_limit=${pb_v:-unset}"
    pb_v=$(_rc_yaml "$_YH_ROOT/project.yaml" performance.memory_ceiling_mb)
    pb_out="$pb_out memory_ceiling_mb=${pb_v:-unset}"
    echo "perf_budgets:$pb_out (project.yaml)"
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

# --- hook_warn: an advisory warning that someone actually sees ---------------
#
#   hook_warn <PreToolUse|PostToolUse> "<message>"
#
# A hook that writes a warning to stderr and exits 0 is writing to the debug
# log: Claude Code shows that text to neither the user nor Claude. Hook JSON on
# stdout reaches both -- systemMessage is shown to the user, additionalContext
# is given to Claude next to the tool result. It sets no permissionDecision:
# "allow" would skip the user's permission prompt. stdout must hold ONLY this
# object, so call it once, as the hook's last output, then exit 0.
#
# There is no jq to lean on, so the string is escaped here: backslash and quote
# by sed, tab and newline by awk. CR and other control characters are dropped.
hook_warn() {
  local m
  m=$(printf '%s' "$2" | tr -d '\000-\010\013-\037' \
      | sed 's/\\/\\\\/g; s/"/\\"/g' \
      | awk '{ gsub(/\t/, "\\t"); if (NR > 1) printf "\\n"; printf "%s", $0 }')
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' \
    "$m" "$1" "$m"
}

# --- Direct execution: the skill-bootstrap entry point -----------------------
#
#   bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys a,b
#
# Skills cannot `source` this file in their `` !`cmd` `` bootstrap line. Claude
# Code permission-checks every injected command before the skill renders, and
# outside auto mode anything short of "allow" ABORTS the whole invocation --
# see .claude/docs/config-resolution.md. A `${VAR:-x}` or
# `$( )` in the command fails that check as "Contains expansion" and no grant can
# approve it; a `source … && resolve_config` compound needs every part approved.
# `${CLAUDE_SKILL_DIR}` is substituted as text before the check, so one plain
# `bash <path> resolve_config …` call is approvable by the matching grant in the
# skill's own `allowed-tools`. That is also what lets a Bash-less agent preload
# the skill.
#
# resolve_config is what the bootstrap line runs. A short list of read-only
# lookups (the second branch below) is dispatchable too, for skills that call
# one through the Bash tool with a narrow grant. Every name added here widens
# what a skill grant can reach, so only read-only lookups belong in that list.
#
# ROOT. Run from a subdirectory, the skill shell's cwd has no project.yaml and
# $CLAUDE_PROJECT_DIR is the launch directory, not the repo root, so
# rules 1-3 of _yaml_helper_set_root all miss. This file's own location is the
# one anchor that cannot drift: hooks/ sits two levels below the root. It only
# fills CLAUDE_PROJECT_DIR when that has no project.yaml, so rules 1-2 (cwd
# first, for nested projects) keep their precedence.
#
# resolve_config, and a usage error, ALWAYS exit 0: a non-zero exit from an
# injected command aborts the skill. The lookups exit with their function's
# status (2 when the project root cannot be found), which is why none of them
# belongs in an injected line.
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
    resolve_setting|get_yaml_key|get_effective_yaml_key|validate_yaml_enum|validate_enum_value|is_locally_overridable)
      # Read-only lookups, run as `bash <path>/yaml-helper.sh <function> <args>`,
      # so a skill can pre-approve them with one narrow grant. A `(cd ... && source
      # ... && fn)` call matches no specific grant. Runs from the
      # project root, as that form did, so project.yaml arguments resolve from a
      # subfolder too; keeps the function's exit status (validate_enum_value and
      # is_locally_overridable answer with it). is_locally_overridable also
      # prints its 0 or 1: a caller that appends `; echo $?` to see it builds a
      # compound command that no grant approves.
      _yh_fn="$1"; shift
      _yh_self_root=$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)
      if [ -z "$_yh_self_root" ] || ! cd "$_yh_self_root"; then
        echo "yaml-helper.sh: cannot find the project root from $0" >&2
        exit 2
      fi
      "$_yh_fn" "$@"
      _yh_rc=$?
      [ "$_yh_fn" = is_locally_overridable ] && echo "$_yh_rc"
      exit "$_yh_rc"
      ;;
    *)
      echo "yaml-helper.sh: usage: bash yaml-helper.sh resolve_config [--keys k1,k2,...] [<system>]"
      echo "                       bash yaml-helper.sh resolve_setting|get_yaml_key|get_effective_yaml_key|validate_yaml_enum|validate_enum_value|is_locally_overridable <args>"
      ;;
  esac
  exit 0
fi
