#!/usr/bin/env bash
# write-guard.sh — the rules that must hold on every write, read as
# observations: the files skills never overwrite, the config guard, the
# prototype boundary, the localization freeze, the subagent write exception
# (and the artifact a return contract names), and the git and release actions
# that ask first. A skill states these rules in prose today; this script is
# the one place they are checked.
#
# The helper twin of three warn-only hooks: validate-write.sh (Write and Edit),
# validate-agent-artifact.sh (SubagentStop) and validate-push.sh (git and
# release actions). The hooks only call it. A skill that writes a guarded file
# runs it itself as its last step, because hooks do not run in every tool.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# Whether a row stops the work is the calling skill's call, or the user's.
#
# Usage: bash .claude/scripts/write-guard.sh [--root DIR] COMMAND [ARGS]
#   check PATH [NEW] [--tool Write|Edit] [--agent TYPE] [--existed yes|no]
#                    every rule below that applies to PATH. NEW is a file
#                    holding the content about to be written; without it the
#                    content of PATH itself is read (the check after writing)
#   overwrite PATH [--tool Write|Edit]
#                    PATH is a file skills never overwrite and it exists; an
#                    Edit changes a file in place, so only a Write (the
#                    default) is reported
#   config PATH [NEW]
#                    project.yaml or project.local.yaml: values outside a
#                    setting's allowed list, keys project.local.yaml cannot
#                    override, and modes.review_mode set; production/
#                    review-mode.txt: written at all. With NEW, a value the
#                    current file already holds is not reported again
#   prototype PATH [NEW]
#                    a file under prototypes/ without its PROTOTYPE or
#                    VERTICAL SLICE header, or reaching into the code root;
#                    a file under the code root reaching into prototypes/
#   freeze PATH      a string table under assets/data/strings/ while
#                    production/localization/freeze-status.md says ACTIVE
#   agent PATH --agent TYPE [--existed yes|no]
#                    a subagent's write outside the exception: only a new file
#                    under production/, docs/ or tests/
#   artifact PATH... each path a return contract named: there or missing
#   git              stdin: one shell command segment per line; each whose
#                    command (after VAR=value words and sudo-like wrappers) is
#                    git tag (not a listing), git merge (not --abort or
#                    --quit), gh release create/upload/edit/delete, butler push
#                    or steamcmd with +run_app_build
#   --root DIR       the project; defaults to the repo this script is in
#   -h, --help       this text
# PATH is project-relative (an absolute path inside the root is made relative;
# backslashes are read as slashes). NEW is read from where the caller stands.
#
# Output: TSV, `-` where a value is not there.
#   checked <path> <rules that applied, comma-separated | ->   (not for git)
#   OVERWRITE <path> <why it is never overwritten>
#   ENUM <path> <key> <value> <allowed> <line>
#   NOT_LOCAL <path> <key> <line>         a key resolution ignores locally
#   REVIEW_MODE <path> <value> <line>
#   PROTOTYPE_HEADER <path> <the header the first lines lack>
#   PROTOTYPE_IMPORT <path> <into-production | into-prototypes> <line> <text>
#   FREEZE <path> <freeze file> <called on | ->
#   AGENT_WRITE <path> <agent> <existing-file | outside>
#   ARTIFACT <path> <present | missing>
#   GIT_ACTION <action> <segment>         action: tag, merge, release, deploy-itch, deploy-steam
#   SKIPPED <rule> <why>                  a part of a rule that could not run
#
# Exit codes: 0 ran (what it finds is rows); 1 the root cannot be read;
# 2 usage error. Reads only; never writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk.
LC_ALL=C
export LC_ALL

usage() { echo "write-guard: $1 (try --help)" >&2; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"
abs_path() {
  case "$1" in
    /*|[A-Za-z]:[\\/]*) printf '%s' "$1" ;;
    *) printf '%s/%s' "$PWD" "${1#./}" ;;
  esac
}

ROOT_ARG=""; TOOL=Write; AGENT=""; EXISTED=""; POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --tool) [ $# -ge 2 ] || usage "--tool needs Write or Edit"; TOOL="$2"; shift 2 ;;
    --agent) [ $# -ge 2 ] || usage "--agent needs a type"; AGENT="$2"; shift 2 ;;
    --existed) [ $# -ge 2 ] || usage "--existed needs yes or no"; EXISTED="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'; exit 0 ;;
    *) POS[${#POS[@]}]="$1"; shift ;;
  esac
done
case "$TOOL" in Write|Edit) ;; *) usage "--tool takes Write or Edit, not $TOOL" ;; esac
case "$EXISTED" in ""|yes|no) ;; *) usage "--existed takes yes or no" ;; esac
[ ${#POS[@]} -gt 0 ] || usage "no command"
CMD="${POS[0]}"; NARG=$((${#POS[@]} - 1))
NEW=""
case "$CMD" in
  check|config|prototype)
    { [ $NARG -ge 1 ] && [ $NARG -le 2 ]; } || usage "$CMD takes a path and optionally the new content's file"
    [ $NARG -eq 2 ] && NEW=$(abs_path "${POS[2]}") ;;
  overwrite|freeze)
    [ $NARG -eq 1 ] || usage "$CMD takes one path" ;;
  agent)
    [ $NARG -eq 1 ] || usage "agent takes one path"
    [ -n "$AGENT" ] || usage "agent needs --agent TYPE" ;;
  artifact)
    [ $NARG -ge 1 ] || usage "artifact takes one or more paths" ;;
  git)
    [ $NARG -eq 0 ] || usage "git reads its segments on stdin and takes no arguments" ;;
  *) usage "unknown command: $CMD" ;;
esac
[ -z "$NEW" ] || [ -f "$NEW" ] || usage "no such file: ${POS[2]}"

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "write-guard: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "write-guard: cannot reach the repo root" >&2; exit 1; }
fi

# rel PATH — project-relative, slashes forward, ./ dropped; an absolute path
# outside the root is printed as it came. The root is tried in either
# spelling Git Bash gives it, then by physical path: its `pwd -P` against the
# path with its deepest existing directory resolved, so a root reached through
# a symlink (macOS /tmp is /private/tmp) and a path that comes resolved, or
# the other way round, still match.
ROOT_P=$(pwd); ROOT_W=$(pwd -W 2>/dev/null || printf '%s' "$ROOT_P"); ROOT_PP=$(pwd -P)
# phys PATH — PATH with its deepest existing directory resolved (symlinks
# followed, .. folded) and the rest as it came; empty when none can be entered.
phys() {
  _pd=$1; _pt=""
  while [ -n "$_pd" ] && [ ! -d "$_pd" ]; do
    _pt="/${_pd##*/}$_pt"; _pn=${_pd%/*}
    [ "$_pn" = "$_pd" ] && return 0
    _pd=$_pn
  done
  [ -n "$_pd" ] || _pd=/
  _pd=$(cd "$_pd" 2>/dev/null && pwd -P) || return 0
  printf '%s%s' "${_pd%/}" "$_pt"
}
rel() {
  _p=$(printf '%s' "$1" | sed 's|\\|/|g')
  shopt -s nocasematch
  case "$_p" in
    "$ROOT_P"/*) _p="${_p:${#ROOT_P}+1}" ;;
    "$ROOT_W"/*) _p="${_p:${#ROOT_W}+1}" ;;
    /*|[A-Za-z]:/*)
      _pf=$(phys "$_p")
      case "$_pf" in "$ROOT_PP"/*) _p="${_pf:${#ROOT_PP}+1}" ;; esac ;;
  esac
  shopt -u nocasematch
  printf '%s' "${_p#./}"
}
tsv() { printf '%s' "$1" | tr '\t\n' '  '; }

# The engine name project.yaml holds, and its code root from the engine table
# (directory-structure.md, "The code root is engine-specific").
engine_name() {
  [ -f project.yaml ] || return 0
  [ -f "$HERE/yaml-get.awk" ] || return 0
  YG_PATH=engine.name awk -f "$HERE/yaml-get.awk" project.yaml
}
ENGINE=$(engine_name | tr 'A-Z' 'a-z')
ROOTS=""
if [ -n "$ENGINE" ] && [ -f "$HERE/engine-row.awk" ] && [ -f "$HERE/../engines/engines.tsv" ]; then
  ROOTS=$(awk -F'\t' -v engine="$ENGINE" -v col=code_root -f "$HERE/engine-row.awk" "$HERE/../engines/engines.tsv")
fi
# Unset or unknown: the three roots, so no rule is skipped for want of one.
[ -n "$ROOTS" ] || ROOTS="src Assets Source"

APPLIED=""
applied() { APPLIED="${APPLIED:+$APPLIED,}$1"; }

# ------------------------------------------------------------------ overwrite
# Each never-overwrite rule and the skill that states it.
overwrite_why() {
  case "$1" in
    production/epics/*/EPIC.md) echo "/create-epics updates an existing EPIC.md in place and never rewrites it" ;;
    project.godot) echo "/setup-engine never replaces an existing Godot project file" ;;
    tests/helpers/*) echo "/test-helpers never overwrites existing helpers, which may hold hand-written code" ;;
    docs/tech-debt-register.md) echo "/tech-debt appends to the register and never rewrites it" ;;
    docs/engine-reference/*) echo "/setup-engine never overwrites an engine reference doc without asking" ;;
  esac
}
rule_overwrite() {
  applied overwrite
  [ "$TOOL" = Write ] || return 0
  [ -f "$1" ] || return 0
  _w=$(overwrite_why "$1")
  # Where /test-setup writes: the test roots of the four engines, CI, the QA
  # evidence folder and the web Playwright config. Other paths never ask test-scaffold.sh.
  case "$1" in tests/*|.github/*|production/qa/*|Assets/Tests/*|Source/*|playwright.config.ts) ;; *) _w="${_w:--}" ;; esac
  [ "$_w" = "-" ] && return 0
  if [ -z "$_w" ]; then
    # The files /test-setup creates, as test-scaffold.sh lists them per engine.
    if [ ! -f "$HERE/test-scaffold.sh" ]; then
      printf 'SKIPPED\toverwrite\ttest-scaffold.sh is missing, so the files /test-setup creates were not checked\n'
      return 0
    fi
    _engines="$ENGINE"
    case "$_engines" in godot|unity|unreal|web) ;; *) _engines="godot unity unreal web" ;; esac
    for _e in $_engines; do
      if bash "$HERE/test-scaffold.sh" --root . "$_e" --list 2>/dev/null | grep -qxF "$1"; then
        _w="/test-setup only creates the files that are missing"; break
      fi
    done
  fi
  [ -z "$_w" ] || printf 'OVERWRITE\t%s\t%s\n' "$(tsv "$1")" "$_w"
}

# --------------------------------------------------------------------- config
YH="$HERE/../hooks/yaml-helper.sh"
# yh_const NAME — the lines of the shell string NAME="\ ... " in yaml-helper.sh
# (config-set.sh reads the same constants the same way).
yh_const() {
  awk -v n="$1" '
    $0 == n "=\"\\" { on = 1; next }
    on { l = $0; end = (l ~ /"$/); if (end) sub(/"$/, "", l); print l; if (end) exit }
  ' "$YH"
}
# The scalar leaves of a YAML file, read by yaml-get.awk's rules: dotted path,
# value, line. List items are skipped; a key with no value opens a mapping; the
# text of a block scalar (a value of | or >, with any indicators) is never keys.
yaml_leaves() {
  awk '
    # opens(s, n): the indent the text of a block scalar opened by line s (at
    # indent n) must exceed, as in yaml-get.awk; else -1.
    function opens(s, n,    r, p, v) {
      r = s
      if (r == "-" || substr(r, 1, 2) == "- ") {
        r = substr(r, 2); sub(/^ +/, "", r)
        if (r ~ /^[|>][-+0-9]*[ \t]*(#.*)?$/) return n
        n = n + length(s) - length(r)
      }
      if (r == "" || r ~ /^[:# \t]/) return -1
      p = index(r, ":"); if (p == 0) return -1
      v = substr(r, p + 1); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      return (v ~ /^[|>][-+0-9]*[ \t]*(#.*)?$/) ? n : -1
    }
    BEGIN { BINMODE = 3; d = 0; blk = -1 }
    {
      l = $0; sub(/\r$/, "", l)
      if (NR == 1 && substr(l, 1, 3) == "\357\273\277") l = substr(l, 4)
      n = 0; while (substr(l, n + 1, 1) == " ") n++
      s = substr(l, n + 1); c = substr(s, 1, 1)
      t = s; sub(/^[ \t]+/, "", t)
      if (t == "" || substr(t, 1, 1) == "#") next
      if (blk >= 0) { if (n > blk) next; blk = -1 }
      blk = opens(s, n)
      if (c == "-" || c == "\t") next
      p = index(s, ":"); if (p <= 1) next
      k = substr(s, 1, p - 1); v = substr(s, p + 1); sub(/^[ \t]+/, "", v)
      while (d > 0 && ind[d] >= n) d--
      full = ""; for (i = 1; i <= d; i++) full = full keys[i] "."; full = full k
      if (v == "" || substr(v, 1, 1) == "#") { d++; ind[d] = n; keys[d] = k; next }
      q = substr(v, 1, 1)
      if (q == "\"" || q == "'"'"'") { v = substr(v, 2); e = index(v, q); if (e) v = substr(v, 1, e - 1) }
      else { e = index(v, " #"); if (e) v = substr(v, 1, e - 1); sub(/[ \t]+$/, "", v) }
      printf "%s\t%s\t%d\n", full, v, NR
    }' "$1"
}
rule_config() {
  _path="$1"; _new="${2:-$1}"
  case "$_path" in
    production/review-mode.txt)
      applied config
      [ -f "$_new" ] || return 0
      _v=$(awk 'BEGIN { BINMODE = 3 } { sub(/\r$/, ""); sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") } $0 != "" { print $0 "\t" NR; exit }' "$_new")
      printf 'REVIEW_MODE\t%s\t%s\t%s\n' "$_path" "${_v%%	*}" "${_v##*	}"
      [ -n "$_v" ] || printf 'REVIEW_MODE\t%s\t-\t-\n' "$_path"
      return 0 ;;
    project.yaml|project.local.yaml) applied config ;;
    *) return 0 ;;
  esac
  [ -f "$_new" ] || return 0
  if [ ! -f "$YH" ]; then
    printf 'SKIPPED\tconfig\tyaml-helper.sh is missing; the allowed values and the local whitelist live there\n'
    return 0
  fi
  _old=""
  [ "$_new" != "$_path" ] && [ -f "$_path" ] && _old=$(yaml_leaves "$_path")
  { printf 'E\t%s\n' "$(yh_const _yaml_helper_enums)" | sed '1!s/^/E	/'
    printf 'W\t%s\n' "$(yh_const _yaml_helper_locally_overridable)" | sed '1!s/^/W	/'
    printf '%s\n' "$_old" | sed '/^$/d; s/^/O	/'
    yaml_leaves "$_new" | sed 's/^/N	/'
  } | P="$_path" awk -F '\t' '
    $1 == "E" { i = index($2, "::"); if (i) AL[substr($2, 1, i - 1)] = substr($2, i + 2); next }
    $1 == "W" { if ($2 != "") WL[$2] = 1; next }
    $1 == "O" { OV[$2] = $3; HAD[$2] = 1; next }
    $1 == "N" {
      k = $2; v = $3; ln = $4; p = ENVIRON["P"]
      changed = !(k in HAD) || OV[k] != v
      # testing.strict as one scalar is the back-compat boolean (yaml-helper.sh).
      al = (k in AL) ? AL[k] : (k == "testing.strict" ? "true|false" : "")
      if (al != "" && changed && index("|" al "|", "|" v "|") == 0)
        printf "ENUM\t%s\t%s\t%s\t%s\t%d\n", p, k, v, al, ln
      # schema_version and framework.* are file metadata, not settings, so the
      # local file may carry them (validate_local_scope exempts the same two).
      if (p == "project.local.yaml" && !(k in WL) && k != "schema_version" && k !~ /^framework\./ && !(k in HAD))
        printf "NOT_LOCAL\t%s\t%s\t%d\n", p, k, ln
      if (k == "modes.review_mode" && changed)
        printf "REVIEW_MODE\t%s\t%s\t%d\n", p, v, ln
    }'
}

# ------------------------------------------------------------------ prototype
# The file types that can hold a comment line (/prototype, Phase 5: JSON,
# scene and project files are exempt).
COMMENTABLE=" gd py cs cpp cc cxx h hpp js mjs ts tsx lua html htm md gdshader shader hlsl glsl sh "
rule_prototype() {
  _path="$1"; _new="${2:-$1}"; _dir=""
  case "$_path" in
    prototypes/*) _dir=into-production ;;
    *) for _r in $ROOTS; do case "$_path" in "$_r"/*) _dir=into-prototypes ;; esac; done ;;
  esac
  [ -n "$_dir" ] || return 0
  applied prototype
  [ -f "$_new" ] || return 0
  if [ "$_dir" = into-production ]; then
    _ext="${_path##*.}"; [ "$_ext" = "$_path" ] && _ext=""
    _ext=$(printf '%s' "$_ext" | tr 'A-Z' 'a-z')
    case "$COMMENTABLE" in
      *" $_ext "*)
        # The header is the file's first lines; five leaves room for a shebang
        # or an engine's own first line above it.
        if ! awk 'BEGIN { BINMODE = 3 } NR > 5 { exit } /PROTOTYPE - NOT FOR PRODUCTION|VERTICAL SLICE - NOT FOR PRODUCTION/ { f = 1; exit } END { exit !f }' "$_new"; then
          case "$_path" in
            prototypes/*-vertical-slice/*) _h="VERTICAL SLICE - NOT FOR PRODUCTION" ;;
            *) _h="PROTOTYPE - NOT FOR PRODUCTION" ;;
          esac
          printf 'PROTOTYPE_HEADER\t%s\t%s\n' "$(tsv "$_path")" "$_h"
        fi ;;
    esac
  fi
  # A reference that climbs out of prototypes/ into a code root (../src/,
  # Godot's res://src/), or one from the code root into prototypes/.
  ROOTS="$ROOTS" D="$_dir" P="$(tsv "$_path")" awk '
    BEGIN {
      BINMODE = 3
      n = split(ENVIRON["ROOTS"], r, " "); alt = ""
      for (i = 1; i <= n; i++) alt = alt (alt == "" ? "" : "|") r[i]
      if (ENVIRON["D"] == "into-production") re = "(res://|\\.\\./)(\\.\\./)*(" alt ")/"
      else re = "(res://|\\.\\./|[\"'"'"'(<])(\\.\\./)*prototypes/"
    }
    { l = $0; sub(/\r$/, "", l) }
    l ~ re { gsub(/\t/, " ", l); printf "PROTOTYPE_IMPORT\t%s\t%s\t%d\t%s\n", ENVIRON["P"], ENVIRON["D"], NR, l }
  ' "$_new"
}

# --------------------------------------------------------------------- freeze
FREEZE_FILE=production/localization/freeze-status.md
rule_freeze() {
  case "$1" in assets/data/strings/*) applied freeze ;; *) return 0 ;; esac
  [ -f "$FREEZE_FILE" ] || return 0
  # /localize writes **Status**: ACTIVE or LIFTED; "Active" is spelled both
  # ways in the skill, so the match ignores case.
  _c=$(awk 'BEGIN { BINMODE = 3 }
    { l = $0; sub(/\r$/, "", l); u = toupper(l) }
    u ~ /^\*\*STATUS\*\*:[ \t]*ACTIVE([ \t]|$)/ || u ~ /^STATUS:[ \t]*ACTIVE([ \t]|$)/ { act = 1 }
    u ~ /^\*\*CALLED\*\*:/ { c = l; sub(/^\*\*[Cc][Aa][Ll][Ll][Ee][Dd]\*\*:[ \t]*/, "", c) }
    END { if (act) print (c == "" ? "-" : c) }' "$FREEZE_FILE")
  [ -z "$_c" ] || printf 'FREEZE\t%s\t%s\t%s\n' "$(tsv "$1")" "$FREEZE_FILE" "$(tsv "$_c")"
}

# ---------------------------------------------------------------------- agent
rule_agent() {
  [ -n "$AGENT" ] || return 0
  applied agent
  case "$1" in
    # Agent memory and session-state appends need no approval
    # (.claude/rules/agent-memory.md); they are not the subagent exception.
    .claude/agent-memory/*|production/session-state/active.md) return 0 ;;
  esac
  case "$1" in
    production/*|docs/*|tests/*) ;;
    *) printf 'AGENT_WRITE\t%s\t%s\toutside\n' "$(tsv "$1")" "$(tsv "$AGENT")"; return 0 ;;
  esac
  _e="$EXISTED"; [ -n "$_e" ] || { [ -e "$1" ] && _e=yes || _e=no; }
  [ "$_e" = yes ] && printf 'AGENT_WRITE\t%s\t%s\texisting-file\n' "$(tsv "$1")" "$(tsv "$AGENT")"
  return 0
}

# ------------------------------------------------------------------------ git
rule_git() {
  awk '
    BEGIN {
      BINMODE = 3
      # A segment runs a tool when the tool is its command: first, or after
      # VAR=value words and the wrappers validate-push.sh allows, by name or
      # by a path ending in it. "echo git tag" runs echo.
      PRE = "^([A-Za-z_][A-Za-z0-9_]*=[^ ]* |(sudo|doas|env|nice|nohup|time|exec|command|xargs|stdbuf|winpty) |timeout [0-9.]+[smhd]? )*([^ ]*[/\\\\])?"
      # The options git itself takes before the subcommand, as validate-push.sh
      # reads them: -C, -c and six long options take a value; others stand alone.
      GOPT = "( -[Cc] [^ ]+| --(git-dir|work-tree|namespace|super-prefix|config-env|attr-source) [^ ]+| -[A-Za-z]| --[A-Za-z-]+(=[^ ]+)?)*"
    }
    function words(s,    n) { gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return s }
    {
      seg = $0; sub(/\r$/, "", seg); s = words(seg)
      if (s == "") next
      act = ""
      if (match(s, PRE "[Gg][Ii][Tt](\\.exe)?" GOPT " tag( |$)")) {
        rest = substr(s, RSTART + RLENGTH); a = " " rest " "
        # git tag alone, or with a list, verify or filter option, only reads.
        if (rest != "" && a !~ / (-l|--list|-v|--verify|-n[0-9]*|--contains|--no-contains|--points-at|--merged|--no-merged|--sort(=[^ ]*)?|--format(=[^ ]*)?|--column|--no-column) /) act = "tag"
      }
      else if (match(s, PRE "[Gg][Ii][Tt](\\.exe)?" GOPT " merge( |$)")) {
        a = " " substr(s, RSTART + RLENGTH) " "
        if (a !~ / --(abort|quit) /) act = "merge"
      }
      else if (s ~ (PRE "gh(\\.exe)? release (create|upload|edit|delete)( |$)")) act = "release"
      else if (s ~ (PRE "butler(\\.exe)? push( |$)")) act = "deploy-itch"
      else if (s ~ (PRE "steamcmd(\\.exe|\\.sh)?( |$)") && s ~ /\+run_app_build( |$)/) act = "deploy-steam"
      if (act != "") { gsub(/\t/, " ", seg); printf "GIT_ACTION\t%s\t%s\n", act, seg }
    }'
}

# ----------------------------------------------------------------------- main
case "$CMD" in
  git) rule_git; exit 0 ;;
  artifact)
    i=1
    while [ $i -le $NARG ]; do
      _p=$(rel "${POS[$i]}")
      if [ -e "$_p" ]; then printf 'ARTIFACT\t%s\tpresent\n' "$(tsv "$_p")"; else printf 'ARTIFACT\t%s\tmissing\n' "$(tsv "$_p")"; fi
      i=$((i + 1))
    done
    exit 0 ;;
esac

PATH_REL=$(rel "${POS[1]}")
OUT=$(case "$CMD" in
  (check)
    rule_overwrite "$PATH_REL"
    rule_config "$PATH_REL" "$NEW"
    rule_prototype "$PATH_REL" "$NEW"
    rule_freeze "$PATH_REL"
    rule_agent "$PATH_REL"
    printf 'APPLIED\t%s\n' "$APPLIED" ;;
  (overwrite) rule_overwrite "$PATH_REL"; printf 'APPLIED\t%s\n' "$APPLIED" ;;
  (config) rule_config "$PATH_REL" "$NEW"; printf 'APPLIED\t%s\n' "$APPLIED" ;;
  (prototype) rule_prototype "$PATH_REL" "$NEW"; printf 'APPLIED\t%s\n' "$APPLIED" ;;
  (freeze) rule_freeze "$PATH_REL"; printf 'APPLIED\t%s\n' "$APPLIED" ;;
  (agent) rule_agent "$PATH_REL"; printf 'APPLIED\t%s\n' "$APPLIED" ;;
esac)
# The checked row first: the rules ran inside $( ), so their list comes back
# as the last line.
_applied=$(printf '%s\n' "$OUT" | sed -n 's/^APPLIED	//p')
printf 'checked\t%s\t%s\n' "$(tsv "$PATH_REL")" "${_applied:--}"
printf '%s\n' "$OUT" | grep -v '^APPLIED	' | grep -v '^$'
exit 0
