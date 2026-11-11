#!/bin/bash
# studio-check.sh — which Dont-Know-Studios repo is this checkout? See STUDIO.md.
#
# OBSERVATIONS, NEVER VERDICTS (CLAUDE.md, "Helpers in .claude/scripts/"). It
# reports what the git remotes say; what to do about it is the caller's call.
#
# Usage: bash .claude/scripts/studio-check.sh [--guard] [--root DIR]
#   (no flag)   TSV rows, one per fact:
#                 role            template | game | upstream-clone | unknown | no-git
#                 origin_url      the `origin` remote's URL, or empty
#                 template_url    the `template` remote's URL, or empty
#                 studio_repo     STUDIO_REPO from .claude/studio.conf
#                 studio_version  STUDIO_VERSION from .claude/studio.conf
#   --guard     prints a short instruction block only when role is `template`
#               (this checkout IS the studio template), and nothing otherwise.
#               Skills inject it with `!` so it lands in their prompt.
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
#
# Roles:
#   template        origin is STUDIO_REPO: the studio template itself.
#   game            the `template` remote is STUDIO_REPO and origin is not:
#                   a game made with tools/new-game.sh.
#   upstream-clone  origin is UPSTREAM_REPO: a plain clone of the framework.
#   unknown         a git repo matching none of the above.
#   no-git          no git repo, or git is not installed.
#
# Exit: 0 always when it could read .claude/studio.conf; 1 when it could not.

ROOT=""
GUARD=0
while [ $# -gt 0 ]; do
  case "$1" in
    --guard) GUARD=1 ;;
    --root) shift; ROOT="$1" ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "studio-check: unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done
if [ -z "$ROOT" ]; then
  HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  ROOT=$(cd "$HERE/../.." && pwd)
fi

CONF="$ROOT/.claude/studio.conf"
if [ ! -f "$CONF" ]; then
  [ "$GUARD" = 1 ] && exit 0   # a guard with nothing to check says nothing
  echo "studio-check: no $CONF" >&2
  exit 1
fi
conf_get() { awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); sub(/[ \t\r]+$/, ""); print; exit }' "$CONF"; }
STUDIO_REPO=$(conf_get STUDIO_REPO)
UPSTREAM_REPO=$(conf_get UPSTREAM_REPO)
STUDIO_VERSION=$(conf_get STUDIO_VERSION)

# 0 when URL $1 names repo $2 (owner/name): any host or proxy prefix, an
# optional .git and trailing slash, case ignored. "…/name-fork" does not match.
url_is() {
  local u r
  u=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]'); u="${u%/}"; u="${u%.git}"
  r=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
  [ -n "$u" ] && [ -n "$r" ] || return 1
  case "$u" in
    "$r"|*/"$r"|*:"$r") return 0 ;;
  esac
  return 1
}

ORIGIN=""; TEMPLATE=""; ROLE=""
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  ORIGIN=$(git -C "$ROOT" remote get-url origin 2>/dev/null)
  TEMPLATE=$(git -C "$ROOT" remote get-url template 2>/dev/null)
  if url_is "$ORIGIN" "$STUDIO_REPO"; then ROLE=template
  elif url_is "$TEMPLATE" "$STUDIO_REPO"; then ROLE=game
  elif url_is "$ORIGIN" "$UPSTREAM_REPO"; then ROLE=upstream-clone
  else ROLE=unknown
  fi
else
  ROLE=no-git
fi

if [ "$GUARD" = 1 ]; then
  [ "$ROLE" = template ] || exit 0
  cat <<EOF
**STUDIO TEMPLATE GUARD — read before anything else in this skill.** This
checkout's \`origin\` is the studio template repo ($STUDIO_REPO). Games are
never built in it: a game made here would be committed into the template every
other game is cloned from. Do not run this skill's steps. Tell the user, in one
or two lines, that a game gets its own repo first, and start \`/new-game\` with
the Skill tool, passing along what they asked for (no Skill tool: ask them to
type \`/new-game\`). The one exception: the user says they are maintaining the
template itself, not starting a game; then carry on.
EOF
  exit 0
fi

printf 'role\t%s\n' "$ROLE"
printf 'origin_url\t%s\n' "$ORIGIN"
printf 'template_url\t%s\n' "$TEMPLATE"
printf 'studio_repo\t%s\n' "$STUDIO_REPO"
printf 'studio_version\t%s\n' "$STUDIO_VERSION"
exit 0
