#!/usr/bin/env bash
# web-scaffold.sh — copies the web scaffold (.claude/engines/web/scaffold/) into a
# project for /setup-engine web, never overwriting a file, and prints per path
# whether it was created or already there; first, the Node.js the project needs.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# It reports Node, each path and what is still needed; whether to install, and
# what to tell the person, is the skill's call.
#
# Usage: bash .claude/scripts/web-scaffold.sh [--dry-run | --list] [--root DIR]
#          [--title TEXT] [--gitignore] [--starter NAME]
#   --dry-run     print what would be created (WOULD_CREATE), write nothing
#   --list        print the project-relative paths the scaffold creates, one per
#                 line and nothing else, whatever already exists
#   --root DIR    the project; defaults to the repo this script is in
#   --title TEXT  the game's name, for index.html's <title> (the title screen
#                 shows it); default: the project folder's name
#   --gitignore   when the project already has a .gitignore, add the scaffold's
#                 lines it lacks at its end, under one header line; without it
#                 they are only listed (gitignore ... missing)
#   --starter NAME  none (the default: plain Canvas 2D), three, phaser or pixi.
#                 A starter is .claude/engines/web/starters/NAME/: its package.json,
#                 package-lock.json and src/main.ts are copied instead of the
#                 scaffold's; every other file is the scaffold's
#   -h, --help    this text
#
# A project with a package.json is an existing web project: nothing is copied
# (refused row, exit 3); /setup-engine web records such a project as it is.
#
# Node: the scaffold's tools need Node ^22.12 || ^24 || >=26 (Vitest 5's range,
# inside Vite 8's and Playwright's; docs/engine-reference/web/VERSION.md). The
# node row is read from `node --version`; nothing here runs npm.
#
# Output: TSV.
#   node      <vX.Y.Z|->  <ok|too-old|absent>  <the range>
#   mode      write|dry-run
#   starter   <name>  <its library at the pinned version, or ->
#   refused   package.json  <why>              then nothing else (exit 3)
#   CREATED <path> | WOULD_CREATE <path> | EXISTS <path> | FAILED <path> <reason>
#   gitignore <line> <missing|added>          a scaffold .gitignore line the
#                                             project's own .gitignore lacks
#   created (or would_create) <n>, exists <n> (and failed <n> when above 0)
#   NEEDS     <id> <what>                       what is still to do: node, npm_install
#
# Exit codes: 0 every path created or already there; 1 the root or the scaffold
# cannot be read; 2 usage error; 3 refused (a package.json is there); 4 a file
# could not be created (FAILED). Never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../engines/web/scaffold"
usage() { echo "web-scaffold: $1 (try --help)" >&2; exit 2; }

MODE=write; ROOT_ARG=""; TITLE=""; TITLE_SET=0; GITIGNORE=0; STARTER=none
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) [ "$MODE" != list ] || usage "--list and --dry-run cannot be combined"; MODE=dry-run; shift ;;
    --list) [ "$MODE" != dry-run ] || usage "--list and --dry-run cannot be combined"; MODE=list; shift ;;
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --title) [ $# -ge 2 ] || usage "--title needs a value"; TITLE="$2"; TITLE_SET=1; shift 2 ;;
    --gitignore) GITIGNORE=1; shift ;;
    --starter) [ $# -ge 2 ] || usage "--starter needs a value"; STARTER="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) usage "unknown argument: $1" ;;
  esac
done
[ "$TITLE_SET" = 0 ] || [ -n "$TITLE" ] || usage "--title needs a value"
[ -d "$SRC" ] || { echo "web-scaffold: the scaffold is missing: $SRC" >&2; exit 1; }
case "$STARTER" in
  none) ST="" ;;
  three|phaser|pixi) ST="$HERE/../engines/web/starters/$STARTER"
    [ -d "$ST" ] || { echo "web-scaffold: the $STARTER starter is missing: $ST" >&2; exit 1; } ;;
  *) usage "--starter is none, three, phaser or pixi" ;;
esac

# The scaffold's files, project-relative, in name order. A file a test runner
# finds by its name (rules.test.ts, boot.spec.ts) is stored with .tmpl after it,
# so the Jest or Vitest of a project that holds the framework does not run the scaffold's
# tests as its own; the copy drops the .tmpl.
list_paths() { ( cd "$SRC" && find . -type f | sed 's|^\./||; s|\.tmpl$||' | sort ); }
# stored <path> -- the file for a project path: the starter's, else the scaffold's.
stored() {
  if [ -n "$ST" ] && [ -f "$ST/$1" ]; then printf '%s' "$ST/$1"
  elif [ -f "$SRC/$1" ]; then printf '%s' "$SRC/$1"; else printf '%s' "$SRC/$1.tmpl"; fi
}
if [ "$MODE" = list ]; then list_paths; exit 0; fi

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "web-scaffold: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "web-scaffold: cannot reach the repo root" >&2; exit 1; }
fi

# ------------------------------------------------------------------------ node
RANGE='^22.12 || ^24 || >=26'
NODEV=$(node --version 2>/dev/null | tr -d '\r' | head -1)
NODE_OK=absent
case "$NODEV" in
  v[0-9]*)
    _maj=${NODEV#v}; _maj=${_maj%%.*}; _min=${NODEV#v*.}; _min=${_min%%.*}
    case "$_maj$_min" in *[!0-9]*) NODE_OK=absent ;; *)
      if { [ "$_maj" -eq 22 ] && [ "$_min" -ge 12 ]; } || [ "$_maj" -eq 24 ] || [ "$_maj" -ge 26 ]; then NODE_OK=ok
      else NODE_OK=too-old; fi ;;
    esac ;;
  *) NODEV="" ;;
esac
printf 'node\t%s\t%s\t%s\n' "${NODEV:--}" "$NODE_OK" "$RANGE"
printf 'mode\t%s\n' "$MODE"
# The starter's library: the one dependency its package.json pins (the scaffold has none).
LIB=-
if [ -n "$ST" ]; then
  LIB=$(awk '/"dependencies"/ { on = 1; next } on && /}/ { exit } on { gsub(/[" ,]/, ""); sub(/:/, "@"); print; exit }' "$ST/package.json")
fi
printf 'starter\t%s\t%s\n' "$STARTER" "${LIB:--}"

if [ -e package.json ]; then
  printf 'refused\tpackage.json\tan existing web project is here: it is recorded as it is, and nothing is copied over it\n'
  exit 3
fi

# ----------------------------------------------------------------------- title
[ "$TITLE_SET" = 1 ] || TITLE=$(basename "$(pwd)")
# The title goes into HTML text: &, < and > become entities.
TITLE_HTML=$(TITLE="$TITLE" awk 'BEGIN { t = ENVIRON["TITLE"]; s = ""
  for (i = 1; i <= length(t); i++) { c = substr(t, i, 1)
    if (c == "&") c = "&amp;"; else if (c == "<") c = "&lt;"; else if (c == ">") c = "&gt;"
    s = s c }
  print s }')
fill() { # fill <scaffold file> -- its text with @TITLE@ filled
  T="$TITLE_HTML" awk '{ while ((i = index($0, "@TITLE@")) > 0) $0 = substr($0, 1, i - 1) ENVIRON["T"] substr($0, i + 7); print }' "$1"
}
write_new() { # write_new <path> <scaffold file> -- fails, writing nothing, if the path exists
  mkdir -p "$(dirname "$1")" 2>/dev/null || return 1
  case "$1" in
    index.html) ( set -C; fill "$2" > "$1" ) 2>/dev/null ;;
    *) ( set -C; cat "$2" > "$1" ) 2>/dev/null ;;
  esac
}

# ------------------------------------------------------------------------- run
NCREATE=0; NEXIST=0; NFAIL=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  if [ -e "$p" ] || [ -L "$p" ]; then
    printf 'EXISTS\t%s\n' "$p"; NEXIST=$((NEXIST + 1)); continue
  fi
  if [ "$MODE" = dry-run ]; then printf 'WOULD_CREATE\t%s\n' "$p"; NCREATE=$((NCREATE + 1)); continue; fi
  if write_new "$p" "$(stored "$p")"; then printf 'CREATED\t%s\n' "$p"; NCREATE=$((NCREATE + 1))
  else printf 'FAILED\t%s\tcould not create the folder or the file\n' "$p"; NFAIL=$((NFAIL + 1)); fi
done <<EOF
$(list_paths)
EOF

# A project's own .gitignore stays; the scaffold's lines it lacks are listed, or added.
if [ -f .gitignore ] && [ -f "$SRC/.gitignore" ]; then
  _miss=$(tr -d '\r' < "$SRC/.gitignore" | while IFS= read -r l; do
    [ -n "$l" ] || continue
    tr -d '\r' < .gitignore | grep -qxF "$l" || printf '%s\n' "$l"
  done)
  if [ -n "$_miss" ]; then
    if [ "$GITIGNORE" = 1 ] && [ "$MODE" = write ]; then
      { [ -z "$(tail -c 1 .gitignore)" ] || echo; echo; echo '# === Web: Vite, Vitest and Playwright output ==='; printf '%s\n' "$_miss"; } >> .gitignore
      printf '%s\n' "$_miss" | while IFS= read -r l; do printf 'gitignore\t%s\tadded\n' "$l"; done
    else
      printf '%s\n' "$_miss" | while IFS= read -r l; do printf 'gitignore\t%s\tmissing\n' "$l"; done
    fi
  fi
fi

if [ "$MODE" = dry-run ]; then printf 'would_create\t%d\n' "$NCREATE"; else printf 'created\t%d\n' "$NCREATE"; fi
printf 'exists\t%d\n' "$NEXIST"
[ "$NFAIL" -eq 0 ] || printf 'failed\t%d\n' "$NFAIL"

case "$NODE_OK" in
  absent) printf 'NEEDS\tnode\tinstall Node.js (%s); /prototype needs no Node\n' "$RANGE" ;;
  too-old) printf 'NEEDS\tnode\tNode %s is outside %s: install a current LTS\n' "$NODEV" "$RANGE" ;;
esac
[ -d node_modules ] || printf 'NEEDS\tnpm_install\tnpm install (it runs third-party install scripts and needs the network: ask first)\n'

[ "$NFAIL" -eq 0 ] || exit 4
exit 0
