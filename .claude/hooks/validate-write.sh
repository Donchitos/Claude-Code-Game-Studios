#!/bin/bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured),
#      unless cwd is itself named .claude: a stray .claude/.claude/ would
#      make .claude/ a root, and the hooks would write .claude/production/
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment),
#      unless it names a .claude folder, for the same reason as rule 2
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || { [ -d ".claude" ] && [ "${PWD##*/}" != ".claude" ]; }; then
  CCGS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ] && case "${CLAUDE_PROJECT_DIR%/}" in */.claude|*\\.claude) false ;; *) true ;; esac; then
  CCGS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code PreToolUse hook: warns when a Write or Edit would break one of the
# rules skills state in prose -- a file they never overwrite, the config guard,
# the prototype boundary, the localization freeze, or the subagent write
# exception. It runs BEFORE the write, while the old file can still be read.
#
# The logic is `.claude/scripts/write-guard.sh check`, its helper twin; this
# hook reads the payload through `.claude/scripts/hook-input.sh` and calls it.
# A skill that writes a guarded file runs write-guard.sh itself as its last
# step, because hooks do not run in every tool.
#
# Exit behavior:
#   exit 0 always = advisory (it warns, never blocks)
#
# Input schema (PreToolUse for Write|Edit), plus agent_type inside a subagent:
# { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." } }
# { "tool_name": "Edit",  "tool_input": { "file_path": "...", "old_string": "...",
#                                         "new_string": "...", "replace_all": false } }

INPUT=$(cat)

# Most writes touch none of the guarded files. Leave before any parsing, with
# builtins only: every rule needs a subagent's agent_type in the payload, one
# of the words below in the file's path (a guarded name or a folder the rules
# watch), or "prototypes" in the text written (a code file reaching into
# prototypes/ names it). The path is tested only below the project root: the
# payload's cwd and transcript_path, and the root part of an absolute path,
# are the project's own folder, which can be named anything (.../Source/proj),
# and matching them sent every Write through the full parse. A path value that
# may end at an escaped quote is not trusted: then the whole payload is tested,
# as before.
case "$INPUT" in
  *'"tool_input"'*'"file_path"'*) ;;
  *) exit 0 ;;
esac
_VW_T=${INPUT#*'"tool_input"'}
_VW_P=${_VW_T#*'"file_path"'}; _VW_P=${_VW_P#*'"'}
_VW_REST="${_VW_T%%'"file_path"'*}${_VW_P#*'"'}"   # the tool_input but the path
_VW_P=${_VW_P%%'"'*}
_vw_bs='\'
case "$_VW_P" in
  *"$_vw_bs") _VW_P=$INPUT; _VW_REST=$INPUT ;;
  *"$_vw_bs$_vw_bs"*) _VW_P=${_VW_P//"$_vw_bs$_vw_bs"//} ;;   # C:\\Users\\... as C:/Users/...
esac
# The root in both spellings Git Bash gives it: /c/Users/... and C:/Users/...
# (the second read from the first; under a mount such as /tmp only pwd -W
# knows it, which costs a subshell, so it is asked last).
_vw_w=$PWD
case "$PWD" in /[A-Za-z]/*) _vw_w="${PWD:1:1}:${PWD:2}" ;; esac
shopt -s nocasematch
case "$_VW_P" in
  "$PWD"/*) _VW_P=${_VW_P:${#PWD}+1} ;;
  "$_vw_w"/*) _VW_P=${_VW_P:${#_vw_w}+1} ;;
  [A-Za-z]:/*) _vw_w=$(pwd -W 2>/dev/null)
    case "$_VW_P" in "$_vw_w"/*) [ -n "$_vw_w" ] && _VW_P=${_VW_P:${#_vw_w}+1} ;; esac ;;
esac
shopt -u nocasematch
_vw_go=0
case "$INPUT" in *'"agent_type"'*) _vw_go=1 ;; esac
case "$_VW_P" in
  *EPIC.md*|*project.godot*|*helpers*|*tech-debt-register*|*engine-reference*) _vw_go=1 ;;
  *project.yaml*|*project.local.yaml*|*review-mode.txt*|*prototypes*|*strings*) _vw_go=1 ;;
  *tests*|*.github*|*production*|*Assets*|*Source*) _vw_go=1 ;;
esac
case "$_VW_REST" in *prototypes*) _vw_go=1 ;; esac
[ "$_vw_go" = 1 ] || exit 0

[ -f .claude/hooks/yaml-helper.sh ] && . .claude/hooks/yaml-helper.sh 2>/dev/null
vw_warn() {
  if command -v hook_warn >/dev/null 2>&1; then hook_warn PreToolUse "$1"
  else printf '%s\n' "$1" >&2; fi
  exit 0
}
for _vw_s in hook-input.sh write-guard.sh; do
  [ -f ".claude/scripts/$_vw_s" ] || vw_warn "Write check skipped: the helper .claude/scripts/$_vw_s is missing, so the write goes ahead unchecked."
done

_VW_NEW=$(mktemp 2>/dev/null) || exit 0
trap 'rm -f "$_VW_NEW"' EXIT
_VW_IN=$(printf '%s' "$INPUT" | bash .claude/scripts/hook-input.sh --root . --new "$_VW_NEW" 2>/dev/null)
vw_row() { printf '%s\n' "$_VW_IN" | awk -F '\t' -v k="$1" '$1 == k { print $2; exit }'; }
_VW_WHERE=$(vw_row where); _VW_PATH=$(vw_row path); _VW_TOOL=$(vw_row tool)
[ "$_VW_WHERE" = inside ] || exit 0
case "$_VW_TOOL" in Write|Edit) ;; *) exit 0 ;; esac
_VW_AGENT=$(vw_row agent); _VW_EXISTED=$(vw_row existed); _VW_GOT=$(vw_row new)

set -- check "$_VW_PATH" --tool "$_VW_TOOL" --existed "$_VW_EXISTED"
[ "$_VW_AGENT" != "-" ] && set -- "$@" --agent "$_VW_AGENT"
if [ "$_VW_GOT" = ok ]; then
  _VW_OUT=$(bash .claude/scripts/write-guard.sh --root . "$@" "$_VW_NEW" 2>/dev/null)
else
  # The content could not be rebuilt: the rules that read it (config,
  # prototype) say so below; the others still run on the path.
  _VW_OUT=$(bash .claude/scripts/write-guard.sh --root . "$@" 2>/dev/null)
fi

# At most this many findings in the warning: a longer list buries the point,
# and the helper prints them all.
_VW_MAX=6
_VW_MSG=$(printf '%s\n' "$_VW_OUT" | VW_MAX="$_VW_MAX" VW_GOT="$_VW_GOT" VW_TOOL="$_VW_TOOL" awk -F '\t' '
  function say(s) { n++; if (n <= ENVIRON["VW_MAX"]) print "- " s }
  $1 == "checked" { rules = $3 }
  $1 == "OVERWRITE" { say("It replaces " $2 ", which is never overwritten: " $3 ". Edit it in place, or ask first.") }
  $1 == "ENUM" { say($2 " line " $6 ": " $3 " is " $4 ", not one of " $5 ".") }
  $1 == "NOT_LOCAL" { say($2 " line " $4 ": " $3 " cannot be set locally, so resolution ignores it; it belongs in project.yaml.") }
  $1 == "REVIEW_MODE" { say("It sets the review mode (" $3 ") in " $2 ". That pins it past what modes.rigor would choose; fine if you set it through /project-settings.") }
  $1 == "PROTOTYPE_HEADER" { say($2 " lacks its " $3 " header in its first lines.") }
  $1 == "PROTOTYPE_IMPORT" { say($2 " line " $4 ($3 == "into-production" ? " reaches from prototypes/ into the code root: " : " reaches from the code root into prototypes/: ") $5) }
  $1 == "FREEZE" { say("The string freeze is ACTIVE (" $3 ", called " $4 "): record this change under Post-Freeze Changes there, or lift the freeze first.") }
  $1 == "AGENT_WRITE" { say("A subagent (" $3 ") writes " $2 ($4 == "outside" ? ", outside production/, docs/ and tests/" : ", which already exists") ": the subagent exception covers only a new file at the path its skill named.") }
  $1 == "SKIPPED" { say("Not checked (" $2 "): " $3 ".") }
  END {
    if (n > ENVIRON["VW_MAX"]) print "- and " (n - ENVIRON["VW_MAX"]) " more."
    if (ENVIRON["VW_GOT"] != "ok" && ENVIRON["VW_GOT"] != "" && rules ~ /config|prototype/)
      print "- The content was not read (" ENVIRON["VW_GOT"] "), so the config and prototype rules did not check it."
  }')

[ -n "$_VW_MSG" ] || exit 0
vw_warn "Write check on $_VW_PATH (a warning; the write goes ahead):
$_VW_MSG
To see every finding: bash .claude/scripts/write-guard.sh check $_VW_PATH"
