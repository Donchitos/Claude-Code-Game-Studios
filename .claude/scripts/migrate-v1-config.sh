#!/usr/bin/env bash
#
# migrate-v1-config.sh — convert a v1.0 CCGS project to v1.1 `project.yaml`.
#
# WHY THIS IS A SCRIPT AND NOT SKILL PROSE
#
# "Migration on a real v1.0 project loses data" is the highest-severity risk in
# this whole area. Skill files are prose executed by a model and cannot be
# unit-tested, so a prose migration could not be proven correct before being
# pointed at someone's project. Every
# failure mode the spec names — malformed file, enum mismatch, split-brain,
# custom sections — is a testable branch here instead.
#
# Spec: `.claude/docs/effects-map.md` -> "Migration from v1.0 -> v1.1".
# That section is the authority. If this script and that section disagree, the
# section wins and this script is the bug.
#
# MODES
#   (default)   migrate: write project.yaml + production/migration-report.md
#   --dry-run   report what would happen; write nothing
#   --finalize  delete legacy files, but ONLY after proving their content is
#               preserved in project.yaml
#
# NON-DESTRUCTIVE BY DEFAULT. Migration leaves every legacy file in place, so
# the whole operation is reversible with `git checkout` until --finalize is run
# deliberately. That is why --finalize is a separate invocation and not a flag
# on the same run.

set -u
export LC_ALL=C

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO" || exit 1

MODE="migrate"
case "${1:-}" in
  --dry-run)  MODE="dry-run" ;;
  --finalize) MODE="finalize" ;;
  "")         MODE="migrate" ;;
  *) echo "usage: $0 [--dry-run|--finalize]" >&2; exit 2 ;;
esac

PY="project.yaml"
STAGE_TXT="production/stage.txt"
REVIEW_TXT="production/review-mode.txt"
TP=".claude/docs/technical-preferences.md"
REPORT="production/migration-report.md"

WARN=""
MANUAL=""
warn()   { WARN="${WARN}- $1"$'\n'; }
manual() { MANUAL="${MANUAL}- $1"$'\n'; }

# --- legacy detection -------------------------------------------------------

legacy_present() {
  [ -f "$STAGE_TXT" ] || [ -f "$REVIEW_TXT" ] || { [ -f "$TP" ] && tp_configured; }
}

# A technical-preferences.md full of [TO BE CONFIGURED] is the template default,
# not a v1.0 project's data. Treating it as legacy content would make every
# fresh clone look like it needs migrating.
# Only the keys this script actually MIGRATES count as legacy data.
#
# `\*\*[^*]+\*\*` matched ANY bullet, and the shipped template carries one line
# that is a prose default rather than a placeholder:
#   - **Required Tests**: Balance formulas, gameplay systems, networking
# so a FRESH v1.1 clone satisfied this and legacy_present() returned true for it.
# With project.yaml also present that is the split-brain branch, so `--dry-run`
# on an ordinary v1.1 project answered "REFUSED: both project.yaml and legacy
# files exist. Resolve which is authoritative before migrating." -- naming a
# conflict that does not exist and blocking the preview. That is precisely the
# case the note above says this function exists to prevent.
#
# Keys, not shape. A value under a key nothing reads is not data this migration
# would carry over, so it cannot be evidence that a migration is needed.
# `Required Tests` is guidance for a human and is never passed to tp_get.
#
# This list is every key handed to tp_get below -- keep the two in step. A key
# missing from here fails safe (the file reads as unconfigured) rather than
# resurrecting the false positive.
_TP_KEYS='Engine|Language|Rendering|Physics|Target Platforms|Primary Input|Gamepad Support|Touch Support|Classes|Variables|Constants|Signals(/Events)?|Files|Scenes(/Prefabs)?|Target Framerate|Frame Budget|Draw Calls|Memory Ceiling|Framework|Minimum Coverage|Additional Specialists|Language/Code Specialist|Shader Specialist|UI Specialist'
tp_configured() {
  [ -f "$TP" ] || return 1
  grep -qE "^[[:space:]]*-[[:space:]]+\*\*($_TP_KEYS)\*\*:[[:space:]]*[^[:space:]\[]" "$TP" 2>/dev/null
}

# --- technical-preferences.md parsing ---------------------------------------

# tp_get <section> <key> -> value, or empty when absent/unconfigured.
#
# JOINS WRAPPED CONTINUATION LINES. Reading only the first physical line
# truncated values mid-sentence -- a framerate budget migrated as
# "...Pro-tier target.** *(Changed", cut exactly where the author had wrapped.
# A continuation is indented and is not itself a new `- **Key**:` bullet.
tp_get() {
  [ -f "$TP" ] || return 0
  awk -v sec="$1" -v key="$2" '
    index($0, "## " sec) == 1 { ins = 1; next }
    ins && index($0, "## ") == 1 { ins = 0 }
    ins && grab {
      if ($0 ~ /^[[:space:]]+[^[:space:]]/ && $0 !~ /^[[:space:]]*-[[:space:]]+\*\*/) {
        cont = $0
        sub(/^[[:space:]]+/, "", cont)
        gsub(/[[:space:]]+$/, "", cont)
        val = val " " cont
        next
      }
      print val; grab = 0; exit
    }
    ins {
      pat = "^- \\*\\*" key "\\*\\*:[[:space:]]*"
      if ($0 ~ pat) {
        val = $0
        sub(pat, "", val)
        gsub(/[[:space:]]+$/, "", val)
        grab = 1
        next
      }
    }
    END { if (grab) print val }
  ' "$TP" | sed 's/^\[TO BE CONFIGURED.*$//'
}

# Strip a trailing unit so "16.67ms" and "1024MB" become numbers. Non-numeric
# input is returned untouched, which is what surfaces a forked file's prose.
num() { printf '%s' "$1" | sed -E 's/[[:space:]]*(ms|MB|mb|fps|FPS|%)[[:space:]]*$//'; }

is_num() { printf '%s' "$1" | grep -qE '^[0-9]+(\.[0-9]+)?$'; }

# Escapes before quoting. These values are hand-written markdown prose, so a
# double quote inside one is ordinary -- and wrapping it unescaped emitted
# `key: "He said "hi""`, which is not valid YAML and takes the whole file down
# with it. Backslashes first, or the quote's escape gets re-escaped.
# Escapes before quoting. These values are hand-written markdown prose, so a
# double quote inside one is ordinary -- and wrapping it unescaped emitted
# `key: "He said "hi""`, which is not valid YAML and takes the whole file down
# with it. Backslashes first, or the quote's escape gets re-escaped.
yaml_str() {
  [ -z "$1" ] && { printf 'null'; return; }
  _ys=$1
  _ys=${_ys//\\/\\\\}
  _ys=${_ys//\"/\\\"}
  printf '"%s"' "$_ys"
}
yaml_num() { { [ -z "$1" ] || ! is_num "$1"; } && printf 'null' || printf '%s' "$1"; }

# --- shared legacy-file reader ----------------------------------------------

# Trim CR and leading/trailing whitespace from the first line, but NEVER interior
# spaces: two valid v1.1 stages contain one (`Systems Design`, `Technical Setup`).
# A `tr -d ' \r\n'` here silently produced `SystemsDesign`, which fails the enum
# and made the migrate-step warning misdiagnose a valid stage as a forked one.
#
# BOTH the migrate step and the finalize verifier below must use this. They read
# the same legacy files and compare the results, so any divergence in trimming
# desynchronises them: while both mangled `Systems Design` identically the
# comparison still matched, but fixing only the writer would make finalize search
# project.yaml for a value migrate never wrote and refuse to delete anything.
# Quote regex metacharacters before a value is spliced into a grep -E pattern.
# The finalize verifier builds its pattern from legacy file content, so a forked
# value like `Alpha (draft)` would be read as a regex group and never match, so
# the script would refuse to delete a file whose content HAD been preserved. That
# fails closed, which is the right direction, but it fails on correct input.
re_quote() { printf '%s' "$1" | sed 's/[][\\.*^$(){}?+|/]/\\&/g'; }

trim_line() {
  sed -e 's/\r//g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" | head -1
}

# --- preflight --------------------------------------------------------------

# A legacy file whose value project.yaml ALREADY carries is a MIRROR, not a
# rival source of truth.
#
# `/start` writes production/stage.txt on every NEW v1.1 project, deliberately,
# as a mirror for hooks that have not migrated -- its own header says so.
# legacy_present() cannot tell that from a v1.0 leftover, so every project
# onboarded by /start answered:
#
#   REFUSED: both project.yaml and legacy files exist.
#   Resolve which is authoritative before migrating.
#
# with nothing whatever to resolve, because the two agreed. And the same message
# points the user at --finalize, which verifies the value is preserved and then
# DELETES the mirror /start had just created on purpose.
#
# The test is the one --finalize already applies, inverted: a legacy value
# project.yaml does not carry is a genuine second source; one it does carry is a
# mirror and needs no resolution. Only reachable when project.yaml exists, so a
# real v1.0 project -- which has none -- takes exactly the path it did before.
#
# These helpers must be defined ABOVE this point. A preflight placed before them
# can only ever call legacy_present().
legacy_conflict() {
  _lc=""
  if [ -f "$STAGE_TXT" ]; then
    _lc=$(trim_line "$STAGE_TXT")
    [ -z "$_lc" ] || grep -qE "^[[:space:]]*stage:[[:space:]]*\"?$(re_quote "$_lc")\"?" "$PY" || return 0
  fi
  if [ -f "$REVIEW_TXT" ]; then
    _lc=$(trim_line "$REVIEW_TXT")
    # The same v1.0 `none` -> v1.1 `solo` rename the migrate step applies, or a
    # v1.0 project that chose "no reviews" would read as a disagreement.
    [ "$_lc" = "none" ] && _lc="solo"
    [ -z "$_lc" ] || grep -qE "^[[:space:]]*review_mode:[[:space:]]*\"?$(re_quote "$_lc")\"?" "$PY" || return 0
  fi
  if [ -f "$TP" ] && tp_configured; then
    _lc=$(tp_get "Engine & Language" "Engine" | awk '{print $1}')
    [ -z "$_lc" ] || grep -qE "^[[:space:]]*name:[[:space:]]*\"?$(re_quote "$_lc")\"?" "$PY" || return 0
  fi
  return 1
}

if [ "$MODE" != "finalize" ]; then
  if [ -f "$PY" ] && legacy_present; then
    # THREE states share this shape and only two are problems. Collapsing them
    # is what made a brand-new project look like a split brain.
    if legacy_conflict; then
      # Values differ: a real second source of truth, and no way to know which
      # the user edited last.
      echo "REFUSED: both $PY and legacy files exist, and their values DISAGREE."
      echo "  Resolve which is authoritative before migrating."
      echo "  If you already migrated, the next step is: $0 --finalize"
      exit 3
    elif [ -f "$REPORT" ]; then
      # Values agree AND a migration ran here -- the report is written by this
      # script and by nothing else. The legacy files are post-migration
      # leftovers, so --finalize is the next step and a second `migrate` is not.
      # Refusing is what keeps the user off that path.
      echo "REFUSED: both $PY and legacy files exist."
      echo "  Resolve which is authoritative before migrating."
      echo "  If you already migrated, the next step is: $0 --finalize"
      exit 3
    else
      # Values agree and no migration ever ran here. These are v1.1 mirrors --
      # /start writes production/stage.txt on every new project by design.
      # Nothing to resolve, and --finalize would DELETE a file /start meant to
      # create.
      echo "Nothing to do: $PY exists and the legacy files mirror it (values agree)."
      exit 0
    fi
  fi
  if [ -f "$PY" ]; then
    echo "Nothing to do: $PY exists and no legacy config was found."
    exit 0
  fi
  if ! legacy_present; then
    echo "Nothing to do: no legacy config files found (not a v1.0 project)."
    exit 0
  fi
fi

# --- finalize ---------------------------------------------------------------

if [ "$MODE" = "finalize" ]; then
  [ -f "$PY" ] || { echo "REFUSED: $PY does not exist. Run migration first."; exit 3; }
  FAILED=""
  # Verify preservation before deleting anything. A legacy file is only removed
  # once its value is demonstrably present in project.yaml.
  if [ -f "$STAGE_TXT" ]; then
    want=$(trim_line "$STAGE_TXT")
    grep -qE "^[[:space:]]*stage:[[:space:]]*\"?$(re_quote "$want")\"?" "$PY" || FAILED="$FAILED $STAGE_TXT"
  fi
  if [ -f "$REVIEW_TXT" ]; then
    want=$(trim_line "$REVIEW_TXT")
    # Mirror the migrate step's v1.0 `none` -> v1.1 `solo` rename, or this check
    # would look for `review_mode: none` (never written) and refuse to finalize.
    [ "$want" = "none" ] && want="solo"
    grep -qE "^[[:space:]]*review_mode:[[:space:]]*\"?$(re_quote "$want")\"?" "$PY" || FAILED="$FAILED $REVIEW_TXT"
  fi
  if [ -f "$TP" ] && tp_configured; then
    want=$(tp_get "Engine & Language" "Engine" | awk '{print $1}')
    [ -z "$want" ] || grep -qE "^[[:space:]]*name:[[:space:]]*\"?$(re_quote "$want")\"?" "$PY" || FAILED="$FAILED $TP"
  fi
  if [ -n "$FAILED" ]; then
    echo "REFUSED: content not preserved in $PY for:$FAILED"
    echo "  Nothing was deleted. Re-run migration or fix $PY by hand."
    exit 4
  fi
  for f in "$STAGE_TXT" "$REVIEW_TXT"; do
    [ -f "$f" ] && rm -f "$f" && echo "deleted $f"
  done
  echo "NOTE: $TP is NOT deleted — it still holds Forbidden Patterns and"
  echo "      Allowed Libraries, which have no project.yaml equivalent."
  echo "finalize complete."
  exit 0
fi

# --- parse ------------------------------------------------------------------

STAGE=""; REVIEW=""
if [ -f "$STAGE_TXT" ]; then
  STAGE=$(trim_line "$STAGE_TXT")
  [ -z "$STAGE" ] && warn "$STAGE_TXT is empty — project.stage left unset"
fi
if [ -f "$REVIEW_TXT" ]; then
  REVIEW=$(trim_line "$REVIEW_TXT")
  [ -z "$REVIEW" ] && warn "$REVIEW_TXT is empty — modes.review_mode left unset, so modes.rigor supplies it"
  # The consequential direction, which went unreported until it was measured.
  # An explicit modes.review_mode OUTRANKS the modes.rigor expansion -- that is
  # deliberate, so a genuine v1.0 choice survives migration. But it means rigor
  # can never move review depth on this project again, and the user is told
  # elsewhere that rigor "drives six settings". On a migrated project it drives
  # five. Reporting only the empty case explained the harmless half.
  [ -n "$REVIEW" ] && warn "$REVIEW_TXT is '$REVIEW' — modes.review_mode is now set EXPLICITLY, which outranks the modes.rigor expansion. Setting modes.rigor later will NOT change review depth on this project. To let rigor drive it, delete the modes.review_mode line from project.yaml after migrating."
fi

# Enum checks. A fork may hold values v1.1 does not know; the spec says preserve
# them raw and flag, never silently coerce.
case "$STAGE" in
  ""|Concept|"Systems Design"|"Technical Setup"|Pre-Production|Production|Polish|Release) ;;
  *) warn "project.stage \`$STAGE\` is not a v1.1 stage — preserved raw, resolve by hand"; manual "Confirm \`project.stage: $STAGE\` is intended" ;;
esac
# v1.0 used `none` for "no director reviews"; v1.1 renamed that tier to `solo`.
# Map it transparently (the rename is reported below via warn()) rather than
# writing `none`, which v1.1's enum rejects — that would silently resolve to
# `lean`, the OPPOSITE of the user's intent. This is a documented rename, not a
# forked value, so it is coerced-and-flagged, not preserved-raw. See
# effects-map.md "Migration from v1.0 -> v1.1".
if [ "$REVIEW" = "none" ]; then
  REVIEW="solo"
  warn "modes.review_mode \`none\` (v1.0 \"no reviews\") migrated to v1.1 \`solo\` — the renamed \"no reviews\" tier"
fi
case "$REVIEW" in
  ""|full|lean|solo) ;;
  *) warn "modes.review_mode \`$REVIEW\` is not a v1.1 value — preserved raw, resolve by hand"; manual "Confirm \`modes.review_mode: $REVIEW\` is intended" ;;
esac
# NO DEFAULT HERE. `production/review-mode.txt` was OPTIONAL in v1.0, so it is
# absent for a large share of upgraders. Defaulting to `lean` wrote an explicit
# value the user never chose, and an explicit `modes.review_mode` sits ABOVE the
# rigor expansion in the resolution chain — so it pinned the knob permanently.
# A project that later set `rigor: full` got workflow/qa/team.size at full and
# `review_mode: lean`, with no error: the exact defect this release exists to
# fix, reintroduced through the upgrade path. Leaving it unset lets
# `modes.rigor` supply it, which is the v1.1 design. If the user genuinely
# chose a review mode in v1.0, the file exists and its value is preserved above.

ENGINE_RAW=$(tp_get "Engine & Language" "Engine")
ENGINE_NAME=$(printf '%s' "$ENGINE_RAW" | awk '{print $1}')
ENGINE_VER=$(printf '%s' "$ENGINE_RAW" | awk '{if (NF>1 && $NF ~ /^[0-9]+(\.[0-9]+)*[A-Za-z0-9]*$/) print $NF}')
LANG=$(tp_get "Engine & Language" "Language")
RENDER=$(tp_get "Engine & Language" "Rendering")
PHYSICS=$(tp_get "Engine & Language" "Physics")

TARGETS=$(tp_get "Input & Platform" "Target Platforms")
PRIMARY_INPUT=$(tp_get "Input & Platform" "Primary Input")
GAMEPAD=$(tp_get "Input & Platform" "Gamepad Support")
TOUCH=$(tp_get "Input & Platform" "Touch Support")

N_CLASSES=$(tp_get "Naming Conventions" "Classes")
N_VARS=$(tp_get "Naming Conventions" "Variables")
N_CONST=$(tp_get "Naming Conventions" "Constants")
# The v1.0 template spells these two keys `Signals/Events` and `Scenes/Prefabs`;
# a hand-trimmed file may carry the short form. The key is a regex, so accept both.
N_SIG=$(tp_get "Naming Conventions" "Signals(/Events)?")
N_FILES=$(tp_get "Naming Conventions" "Files")
N_SCENES=$(tp_get "Naming Conventions" "Scenes(/Prefabs)?")

P_FPS=$(num "$(tp_get "Performance Budgets" "Target Framerate")")
P_BUDGET=$(num "$(tp_get "Performance Budgets" "Frame Budget")")
P_DRAW=$(num "$(tp_get "Performance Budgets" "Draw Calls")")
P_MEM=$(num "$(tp_get "Performance Budgets" "Memory Ceiling")")

# A BUDGET THAT IS PRESENT BUT NOT A BARE NUMBER MUST BE REPORTED, NOT DROPPED.
#
# These four are written with yaml_num, which emits `null` for anything that is
# not numeric -- while the report row tested only for non-empty. So a budget
# recorded as prose ("30 FPS on the console floor; 60 FPS as a PC target") wrote
# `null` to the file and printed as PRESERVED in the report, with Warnings: None.
# The report is the artifact the user is told to review before --finalize, so it
# is the one place a silent drop is least affordable.
#
# Real budgets routinely carry per-platform splits, ranges and rationale, none of
# which is a bare number. The converter cannot pick one, and MUST NOT guess which
# platform the user meant -- so it names what it found and hands the choice back.
for _pb in "target_framerate:$P_FPS" "frame_budget_ms:$P_BUDGET"            "draw_call_limit:$P_DRAW" "memory_ceiling_mb:$P_MEM"; do
  _pk="${_pb%%:*}"; _pv="${_pb#*:}"
  if [ -n "$_pv" ] && ! is_num "$_pv"; then
    warn "performance.$_pk not migrated: \"$_pv\" is not a single number"
    manual "Set \`performance.$_pk\` by hand — the legacy value was: $_pv"
  fi
done

TEST_FW=$(tp_get "Testing" "Framework")
# "Minimum Coverage" has a v1.1 home (`qa.coverage_minimum`, integer 0-100,
# enforced only at qa.level: full). Same rule as the budgets: a bare number
# migrates, prose is reported and handed back, nothing is dropped in silence.
TEST_COV=$(num "$(tp_get "Testing" "Minimum Coverage")")
if [ -n "$TEST_COV" ] && ! is_num "$TEST_COV"; then
  warn "qa.coverage_minimum not migrated: \"$TEST_COV\" is not a single number"
  manual "Set \`qa.coverage_minimum\` by hand — the legacy value was: $TEST_COV"
fi

# v1.0 /setup-engine wrote every specialist line as `agent-name (what it covers)`,
# and the Unreal code line as `a-specialist (Blueprint) or b-specialist (C++)`.
# Skills pass `specialists.*` straight to the Agent tool as a subagent_type, so
# anything but the bare agent name is an agent that does not exist. Keep the
# first agent name per entry; the prose goes to the report, not the yaml.
S_CODE_RAW=$(tp_get "Engine Specialists" "Language/Code Specialist")
S_SHADER_RAW=$(tp_get "Engine Specialists" "Shader Specialist")
S_UI_RAW=$(tp_get "Engine Specialists" "UI Specialist")
S_ADD_RAW=$(tp_get "Engine Specialists" "Additional Specialists")

# agent_name <prose> -> first token that looks like an agent name, else the
# trimmed input unchanged (a value this cannot parse is surfaced, not dropped).
agent_name() {
  _an=$(printf '%s' "$1" | grep -oE '[a-z][a-z0-9]*(-[a-z0-9]+)+' | head -1)
  [ -n "$_an" ] && printf '%s' "$_an" || printf '%s' "$1" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
}
# agent_names <prose list> -> comma-separated agent names, one per top-level
# comma-separated element (commas inside parentheses belong to the prose).
agent_names() {
  [ -z "$1" ] && return 0
  printf '%s' "$1" | awk '
    { d = 0; cur = ""
      for (i = 1; i <= length($0); i++) { c = substr($0, i, 1)
        if (c == "(") d++; else if (c == ")") { if (d > 0) d-- }
        if (c == "," && d == 0) { print cur; cur = "" } else cur = cur c }
      print cur }' | while IFS= read -r _el; do
        _n=$(agent_name "$_el"); [ -n "$_n" ] && printf '%s, ' "$_n"
      done | sed -E 's/, $//'
}
specialist_warn() {   # <dotted.key> <raw> <kept>
  [ -n "$2" ] && [ "$2" != "$3" ] || return 0
  warn "$1 trimmed to \`$3\` — the legacy line was: $2"
  case "$2" in
    *" or "*) manual "\`$1\` had two candidates in $TP (\"$2\"); kept the first — change it in project.yaml if the other is right" ;;
  esac
}
S_CODE=$(agent_name "$S_CODE_RAW")
S_SHADER=$(agent_name "$S_SHADER_RAW")
S_UI=$(agent_name "$S_UI_RAW")
S_ADD=$(agent_names "$S_ADD_RAW")
specialist_warn "specialists.code"       "$S_CODE_RAW"   "$S_CODE"
specialist_warn "specialists.shader"     "$S_SHADER_RAW" "$S_SHADER"
specialist_warn "specialists.ui"         "$S_UI_RAW"     "$S_UI"
specialist_warn "specialists.additional" "$S_ADD_RAW"    "$S_ADD"

# Sections a fork may have added. Not migrated — surfaced instead of dropped.
if [ -f "$TP" ]; then
  while IFS= read -r h; do
    case "$h" in
      "Engine & Language"|"Input & Platform"|"Naming Conventions"|"Performance Budgets"|"Testing"|"Forbidden Patterns"|"Allowed Libraries / Addons"|"Architecture Decisions Log"|"Engine Specialists") ;;
      "") ;;
      *) manual "Custom section \`## $h\` in $TP — not migrated, integrate by hand" ;;
    esac
  done < <(grep -E '^## ' "$TP" | sed 's/^## //; s/\r$//')
fi
[ -f "$TP" ] && manual "Forbidden Patterns and Allowed Libraries stay in $TP — they have no project.yaml equivalent"

# v1.0 had no `modes.rigor`; its fixed process level matches v1.1's `standard`.
# v1.1 defaults `rigor` to `minimal`, and this script writes nothing it did not
# read, so a migrated project lands on `minimal` — fewer required GDD sections,
# terser docs, lighter test evidence, no director panels. That is a behaviour
# change the upgrader never chose; say so in the one artifact they read first.
warn "modes.rigor is not written — v1.1 defaults it to \`minimal\`, which is lighter than v1.0 behaved (v1.0 matched \`standard\`). To keep v1.0's process level, add \`modes: { rigor: standard }\` to project.yaml or run \`/settings modes.rigor=standard\`"
manual "Decide \`modes.rigor\`: leave unset for the lighter v1.1 default, or pin \`standard\` to keep v1.0's process level"

# Report the STRING keys that land in the file as `null`, which the numeric
# family above already does and this half never did.
#
# `yaml_str` writes `null` for an empty value exactly as `yaml_num` does. A block
# is emitted when ANY of its members is set -- every guard in the writer below is
# `[ -n "$A$B$C" ]` -- so PARTIAL configuration is what produces these, and
# partial is the ordinary state of a v1.0 file: you configure what you use. A
# project that named its code specialist and left the rest at [TO BE CONFIGURED]
# got `shader: null` and `ui: null` written, "Warnings: None", and no report row
# for either.
#
# It matters because `get_yaml_key` returns the four-character STRING "null" for
# such a key. That is not empty, so a caller testing `[ -z ... ]` reads it as
# CONFIGURED, and nothing in the framework tests for the string -- /code-review
# reads `specialists.shader` to choose which agent to spawn.
#
# The value written is deliberately NOT changed here. `null` is the record that
# the key was seen and held nothing, and the config suite pins that. What was
# missing is telling the user, in the artifact they are told to read before
# --finalize deletes anything.
#
# performance.* is left to its own loop above on purpose: it distinguishes "held
# a value that would not convert" from "held nothing", and only reports the
# first. Blurring that here would overwrite a deliberate contract.
null_warn() {   # <block-guard> <dotted.key> <value>
  [ -n "$1" ] && [ -z "$3" ] || return 0
  warn "$2 written as \`null\` — $TP had no value for it"
  manual "Set \`$2\` in project.yaml, or delete the key so it resolves to its default"
}
_G_ENGINE="$ENGINE_NAME"
null_warn "$_G_ENGINE" "engine.version"    "$ENGINE_VER"
null_warn "$_G_ENGINE" "engine.language"   "$LANG"
null_warn "$_G_ENGINE" "engine.rendering"  "$RENDER"
null_warn "$_G_ENGINE" "engine.physics"    "$PHYSICS"
_G_SPEC="$S_CODE$S_SHADER$S_UI$S_ADD"
null_warn "$_G_SPEC" "specialists.code"    "$S_CODE"
null_warn "$_G_SPEC" "specialists.shader"  "$S_SHADER"
null_warn "$_G_SPEC" "specialists.ui"      "$S_UI"
_G_NAME="$N_CLASSES$N_VARS$N_CONST$N_SIG$N_FILES$N_SCENES"
null_warn "$_G_NAME" "naming.classes"      "$N_CLASSES"
null_warn "$_G_NAME" "naming.variables"    "$N_VARS"
null_warn "$_G_NAME" "naming.constants"    "$N_CONST"
null_warn "$_G_NAME" "naming.signals"      "$N_SIG"
null_warn "$_G_NAME" "naming.files"        "$N_FILES"
null_warn "$_G_NAME" "naming.scenes"       "$N_SCENES"
_G_PLAT="$TARGETS$PRIMARY_INPUT$GAMEPAD$TOUCH"
null_warn "$_G_PLAT" "platform.primary_input"  "$PRIMARY_INPUT"
null_warn "$_G_PLAT" "platform.gamepad_support" "$GAMEPAD"
null_warn "$_G_PLAT" "platform.touch_support"   "$TOUCH"

# --- helpers for list-ish values --------------------------------------------

yaml_list() {
  # "PC, Mac" -> ["PC", "Mac"]; empty -> []
  #
  # Splits on top-level commas ONLY -- a comma inside parentheses stays part of
  # its element. These values come from a hand-written document, so an entry is
  # routinely prose: `ue-gas-specialist (abilities, effects)` is ONE specialist,
  # not two, and splitting it produced entries like `attributes` that read as
  # real agent names. Every element is quoted for the same reason: prose carries
  # colons, dashes and brackets, all of which make a bare YAML scalar ambiguous
  # or invalid.
  [ -z "$1" ] && { printf '[]'; return; }
  printf '%s' "$1" | awk '
    function emit(s) {
      sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
      if (s == "") return
      gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s)
      out = out (n++ ? ", " : "") "\"" s "\""
    }
    { depth = 0; buf = ""; out = ""; n = 0
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (c == "(") depth++
        else if (c == ")") { if (depth > 0) depth-- }
        if (c == "," && depth == 0) { emit(buf); buf = "" } else buf = buf c
      }
      emit(buf)
      printf "[%s]", out
    }'
}

if [ "$MODE" = "dry-run" ]; then
  echo "DRY RUN — nothing written."
  echo "would create: $PY"
  echo "would create: $REPORT"
  echo
  echo "detected sources:"
  [ -f "$STAGE_TXT" ]  && echo "  $STAGE_TXT -> project.stage: ${STAGE:-<empty>}"
  [ -f "$REVIEW_TXT" ] && echo "  $REVIEW_TXT -> modes.review_mode: ${REVIEW:-<empty>}"
  # State the omission explicitly. Silence here is what let the invented `lean`
  # default ship unnoticed: the preview simply had no line for it, so the one
  # artifact a cautious user reads before migrating never mentioned the value.
  [ -z "$REVIEW" ] && echo "  (no $REVIEW_TXT — modes.review_mode left unset; modes.rigor will supply it)"
  # And the other direction, for the same reason: the preview is the one artifact
  # a cautious user reads before migrating, so the consequence belongs here too.
  [ -n "$REVIEW" ] && echo "  (modes.review_mode will be set EXPLICITLY to '$REVIEW' — this outranks modes.rigor, so rigor will not control review depth afterwards)"
  [ -f "$TP" ] && tp_configured && echo "  $TP -> engine/platform/naming/performance/testing/specialists"
  [ -n "$WARN" ] && { echo; echo "warnings:"; printf '%s' "$WARN"; }
  exit 0
fi

# --- write project.yaml -----------------------------------------------------

{
  echo "# CCGS project configuration — migrated from v1.0 legacy files."
  echo "# Generated by .claude/scripts/migrate-v1-config.sh"
  echo "# Review production/migration-report.md before running --finalize."
  echo ""
  echo "schema_version: 1"
  echo ""
  echo "framework:"
  echo "  version: 1.1.1"
  echo ""
  # Emit `project:` only when there is a stage to put in it -- same rule as the
  # `modes:` block below. Writing `stage: null` produced a file that FAILED THIS
  # PROJECT'S OWN SCHEMA VALIDATION: `null` is not in the stage enum, so every
  # migrated project without a legacy stage.txt greeted its user with a schema
  # error caused by the migration itself. An absent key resolves to unset, which
  # is what "no stage recorded yet" means.
  if [ -n "$STAGE" ]; then
    echo "project:"
    echo "  stage: \"$STAGE\""
    echo ""
  fi
  # Emit the `modes:` block only when there is something to put in it. An
  # unguarded `review_mode: $REVIEW` wrote a bare `review_mode:` (empty) once
  # the invented default was removed, which resolves no better than the default
  # did. No legacy review mode means no `modes:` block — rigor supplies it.
  if [ -n "$REVIEW" ]; then
    echo "modes:"
    echo "  review_mode: $REVIEW"
    echo ""
  fi
  if [ -n "$ENGINE_NAME" ]; then
    echo "engine:"
    echo "  name: $(yaml_str "$ENGINE_NAME")"
    echo "  version: $(yaml_str "$ENGINE_VER")"
    echo "  language: $(yaml_str "$LANG")"
    echo "  rendering: $(yaml_str "$RENDER")"
    echo "  physics: $(yaml_str "$PHYSICS")"
    echo ""
  fi
  if [ -n "$S_CODE$S_SHADER$S_UI$S_ADD" ]; then
    echo "specialists:"
    echo "  code: $(yaml_str "$S_CODE")"
    echo "  shader: $(yaml_str "$S_SHADER")"
    echo "  ui: $(yaml_str "$S_UI")"
    echo "  additional: $(yaml_list "$S_ADD")"
    echo ""
  fi
  if [ -n "$N_CLASSES$N_VARS$N_CONST$N_SIG$N_FILES$N_SCENES" ]; then
    echo "naming:"
    echo "  classes: $(yaml_str "$N_CLASSES")"
    echo "  variables: $(yaml_str "$N_VARS")"
    echo "  constants: $(yaml_str "$N_CONST")"
    echo "  signals: $(yaml_str "$N_SIG")"
    echo "  files: $(yaml_str "$N_FILES")"
    echo "  scenes: $(yaml_str "$N_SCENES")"
    echo ""
  fi
  if [ -n "$P_FPS$P_BUDGET$P_DRAW$P_MEM" ]; then
    echo "performance:"
    echo "  target_framerate: $(yaml_num "$P_FPS")"
    echo "  frame_budget_ms: $(yaml_num "$P_BUDGET")"
    echo "  draw_call_limit: $(yaml_num "$P_DRAW")"
    echo "  memory_ceiling_mb: $(yaml_num "$P_MEM")"
    echo ""
  fi
  if [ -n "$TARGETS$PRIMARY_INPUT$GAMEPAD$TOUCH" ]; then
    echo "platform:"
    echo "  targets: $(yaml_list "$TARGETS")"
    echo "  primary_input: $(yaml_str "$PRIMARY_INPUT")"
    echo "  gamepad_support: $(yaml_str "$GAMEPAD")"
    echo "  touch_support: $(yaml_str "$TOUCH")"
    echo ""
  fi
  if [ -n "$TEST_FW" ]; then
    echo "testing:"
    echo "  framework: $(yaml_str "$TEST_FW")"
    echo ""
  fi
  if is_num "$TEST_COV"; then
    echo "qa:"
    echo "  coverage_minimum: $TEST_COV"
    echo ""
  fi
} > "$PY"

# --- write the report -------------------------------------------------------

mkdir -p production 2>/dev/null
{
  echo "# Migration report — v1.0 to v1.1"
  echo ""
  echo "Generated by \`.claude/scripts/migrate-v1-config.sh\`."
  echo "Legacy files were **not** deleted. Read this report, then run"
  echo "\`bash .claude/scripts/migrate-v1-config.sh --finalize\` when satisfied."
  echo ""
  echo "## Source files detected"
  echo ""
  [ -f "$STAGE_TXT" ]  && echo "- \`$STAGE_TXT\`"
  [ -f "$REVIEW_TXT" ] && echo "- \`$REVIEW_TXT\`"
  { [ -f "$TP" ] && tp_configured; } && echo "- \`$TP\`"
  echo ""
  echo "## Values preserved"
  echo ""
  echo "| Setting | Value | From |"
  echo "|---|---|---|"
  [ -n "$STAGE" ]         && echo "| \`project.stage\` | $STAGE | $STAGE_TXT |"
  [ -n "$REVIEW" ]        && echo "| \`modes.review_mode\` | $REVIEW | ${REVIEW_TXT} |"
  [ -n "$ENGINE_NAME" ]   && echo "| \`engine.name\` | $ENGINE_NAME | $TP |"
  [ -n "$ENGINE_VER" ]    && echo "| \`engine.version\` | $ENGINE_VER | $TP |"
  [ -n "$LANG" ]          && echo "| \`engine.language\` | $LANG | $TP |"
  [ -n "$TEST_FW" ]       && echo "| \`testing.framework\` | $TEST_FW | $TP |"
  is_num "$TEST_COV"      && echo "| \`qa.coverage_minimum\` | $TEST_COV | $TP |"
  [ -n "$S_CODE" ]        && echo "| \`specialists.code\` | $S_CODE | $TP |"
  # Every migrated value gets a row. This table is titled "Values preserved" and
  # is what the user reviews before --finalize deletes anything -- listing 6 of
  # the 29 keys actually written meant someone checking "did my naming
  # conventions survive?" found nothing and could reasonably conclude they had
  # not. Understating what was preserved is the same defect as overstating it.
  [ -n "$RENDER" ]        && echo "| \`engine.rendering\` | $RENDER | $TP |"
  [ -n "$PHYSICS" ]       && echo "| \`engine.physics\` | $PHYSICS | $TP |"
  [ -n "$S_SHADER" ]      && echo "| \`specialists.shader\` | $S_SHADER | $TP |"
  [ -n "$S_UI" ]          && echo "| \`specialists.ui\` | $S_UI | $TP |"
  [ -n "$S_ADD" ]         && echo "| \`specialists.additional\` | $S_ADD | $TP |"
  [ -n "$N_CLASSES" ]     && echo "| \`naming.classes\` | $N_CLASSES | $TP |"
  [ -n "$N_VARS" ]        && echo "| \`naming.variables\` | $N_VARS | $TP |"
  [ -n "$N_CONST" ]       && echo "| \`naming.constants\` | $N_CONST | $TP |"
  [ -n "$N_SIG" ]         && echo "| \`naming.signals\` | $N_SIG | $TP |"
  [ -n "$N_FILES" ]       && echo "| \`naming.files\` | $N_FILES | $TP |"
  [ -n "$N_SCENES" ]      && echo "| \`naming.scenes\` | $N_SCENES | $TP |"
  [ -n "$TARGETS" ]  && echo "| \`platform.targets\` | $TARGETS | $TP |"
  [ -n "$PRIMARY_INPUT" ]    && echo "| \`platform.primary_input\` | $PRIMARY_INPUT | $TP |"
  [ -n "$GAMEPAD" ]      && echo "| \`platform.gamepad_support\` | $GAMEPAD | $TP |"
  [ -n "$TOUCH" ]    && echo "| \`platform.touch_support\` | $TOUCH | $TP |"
  # Report what was WRITTEN, not what was extracted. These rows sit under
  # "Values preserved", so testing merely for non-empty claimed preservation for
  # a value the file recorded as null. is_num is the same test yaml_num applies.
  is_num "$P_FPS"    && echo "| \`performance.target_framerate\` | $P_FPS | $TP |"
  is_num "$P_BUDGET" && echo "| \`performance.frame_budget_ms\` | $P_BUDGET | $TP |"
  is_num "$P_DRAW"   && echo "| \`performance.draw_call_limit\` | $P_DRAW | $TP |"
  is_num "$P_MEM"    && echo "| \`performance.memory_ceiling_mb\` | $P_MEM | $TP |"
  echo ""
  echo "## Defaults applied"
  echo ""
  echo "Settings new in v1.1 are absent from legacy files and are NOT written."
  echo "They resolve to their documented defaults at read time"
  echo "(\`.claude/docs/config-resolution.md\`): \`modes.rigor\`, \`modes.workflow\`,"
  echo "\`modes.automation\`, \`docs.density\`, \`qa.level\`, \`team.size\`,"
  echo "\`modes.story_granularity\`, \`testing.strict\`."
  echo ""
  echo "Run \`/settings\` to see the effective values, or \`/start\` to be asked."
  echo ""
  # `modes.review_mode` is NOT new in v1.1, so the paragraph above does not
  # cover it. Call the omission out by name: this table is the artifact the
  # user reads before `--finalize`, and listing an invented `lean` sourced to a
  # file that does not exist is worse than saying nothing.
  if [ -z "$REVIEW" ]; then
    echo "\`modes.review_mode\` is **deliberately not written**: no"
    echo "\`$REVIEW_TXT\` was found, so you never chose one. It is now supplied by"
    echo "\`modes.rigor\` — writing it here would pin it and shadow that expansion."
    echo ""
  fi
  echo "## Warnings"
  echo ""
  if [ -n "$WARN" ]; then printf '%s' "$WARN"; else echo "None."; fi
  echo ""
  echo "## Manual review"
  echo ""
  if [ -n "$MANUAL" ]; then printf '%s' "$MANUAL"; else echo "None."; fi
} > "$REPORT"

echo "wrote $PY"
echo "wrote $REPORT"
[ -n "$WARN" ] && { echo; echo "warnings:"; printf '%s' "$WARN"; }
echo
echo "Legacy files left in place. Review $REPORT, then:"
echo "  bash .claude/scripts/migrate-v1-config.sh --finalize"
exit 0
