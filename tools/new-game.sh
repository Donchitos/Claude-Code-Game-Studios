#!/bin/bash
# new-game.sh — start a new game from the Dont-Know-Studios template. See STUDIO.md.
#
# Clones the studio template at its newest studio release, keeping the full
# history (so later studio updates are a plain `git merge`), renames the clone's
# remote to `template`, points `origin` at the game's own repo, and pushes.
#
# Usage: bash tools/new-game.sh <game-name> <game-repo-url> [options]
#   <game-name>       folder to create, e.g. sheep-herder
#   <game-repo-url>   the game's own repo, created EMPTY on GitHub first
#                     (no README, licence or .gitignore), e.g.
#                     https://github.com/Dont-Know-Studios/sheep-herder.git
# Options:
#   --dir DIR         where to create the folder (default: next to this repo)
#   --ref REF         start from this tag or branch instead of the newest
#                     studio release
#   --template-url U  clone from U instead of STUDIO_REPO (for testing)
#   --no-push         set everything up but do not push
#   -h, --help        this text
#
# Exit: 0 done; 1 a step failed (the message says which, and what is left on
# disk); 2 usage error.

set -u

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }
die() { echo "new-game: $*" >&2; exit 1; }

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
CONF="$ROOT/.claude/studio.conf"
[ -f "$CONF" ] || die "no $CONF — run this from the studio template"
conf_get() { awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); sub(/[ \t\r]+$/, ""); print; exit }' "$CONF"; }
STUDIO_REPO=$(conf_get STUDIO_REPO)
UPSTREAM_REPO=$(conf_get UPSTREAM_REPO)
PREFIX=$(conf_get STUDIO_TAG_PREFIX)

NAME=""; URL=""; DIR=""; REF=""; TEMPLATE_URL=""; PUSH=1
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dir) shift; DIR="${1:-}" ;;
    --ref) shift; REF="${1:-}" ;;
    --template-url) shift; TEMPLATE_URL="${1:-}" ;;
    --no-push) PUSH=0 ;;
    -*) echo "new-game: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) if [ -z "$NAME" ]; then NAME="$1"; elif [ -z "$URL" ]; then URL="$1"
       else echo "new-game: unexpected argument: $1" >&2; exit 2; fi ;;
  esac
  shift
done
[ -n "$NAME" ] && [ -n "$URL" ] || { usage >&2; exit 2; }

case "$NAME" in
  *[!A-Za-z0-9._-]*|.*|-*) echo "new-game: game name '$NAME' — use letters, digits, '.', '_' and '-' only" >&2; exit 2 ;;
esac

# The game's repo must not be the template or upstream: that is the mistake
# this script exists to prevent.
norm() { local u; u=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]'); u="${u%/}"; printf '%s' "${u%.git}"; }
for r in "$STUDIO_REPO" "$UPSTREAM_REPO"; do
  r=$(printf '%s' "$r" | tr '[:upper:]' '[:lower:]')
  case "$(norm "$URL")" in
    "$r"|*/"$r"|*:"$r") echo "new-game: $URL is the template repo itself — create a new, empty repo for the game first" >&2; exit 2 ;;
  esac
done

[ -n "$TEMPLATE_URL" ] || TEMPLATE_URL="https://github.com/$STUDIO_REPO.git"
[ -n "$DIR" ] || DIR=$(dirname "$ROOT")
TARGET="$DIR/$NAME"
[ -e "$TARGET" ] && die "$TARGET already exists — pick another name or --dir"
command -v git >/dev/null 2>&1 || die "git is not installed"

# Newest studio release: the highest <prefix>x.y.z tag on the template.
if [ -z "$REF" ]; then
  # Numeric x.y.z sort in awk: `sort -V` is missing on some macOS setups.
  REF=$(git ls-remote --tags --refs "$TEMPLATE_URL" "refs/tags/${PREFIX}*" 2>/dev/null \
        | sed 's#.*refs/tags/##' \
        | awk -v p="$PREFIX" 'index($0, p) == 1 {
            v = substr($0, length(p) + 1)
            if (v !~ /^[0-9]+\.[0-9]+\.[0-9]+$/) next
            split(v, a, "."); printf "%09d%09d%09d %s\n", a[1], a[2], a[3], $0 }' \
        | sort | tail -1 | cut -d' ' -f2)
  if [ -n "$REF" ]; then
    echo "new-game: newest studio release is $REF"
  else
    REF=HEAD   # the template's default branch, resolved after the clone
    echo "new-game: WARNING — no ${PREFIX}x.y.z release found on the template; starting from its default branch."
    echo "          Publish a studio release (STUDIO.md) so games start from a reviewed version."
  fi
fi

echo "new-game: cloning $TEMPLATE_URL into $TARGET"
git clone --origin template "$TEMPLATE_URL" "$TARGET" || die "clone failed; nothing was created"
cd "$TARGET" || die "cannot enter $TARGET"

# A tag first, then the template's branch of that name, then anything git knows.
START=""
for cand in "refs/tags/$REF" "refs/remotes/template/$REF" "$REF"; do
  START=$(git rev-parse --verify --quiet "$cand^{commit}") && break
  START=""
done
[ -n "$START" ] || die "no tag or branch '$REF' on the template; $TARGET is left as a plain clone"
git checkout -q -B main "$START" || die "could not create 'main' at $REF in $TARGET"
git branch --unset-upstream >/dev/null 2>&1 || true
# Only main belongs to the game; the other template branches stay on `template`.
git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r b; do
  [ "$b" = main ] || git branch -q -D "$b" >/dev/null 2>&1
done

git remote add origin "$URL" || die "could not add origin $URL"

if [ "$PUSH" = 0 ]; then
  echo "new-game: --no-push — set up but not pushed. To push: cd \"$TARGET\" && git push -u origin main"
else
  echo "new-game: pushing main to $URL"
  if ! git push -u origin main; then
    cat >&2 <<EOF
new-game: the push failed. $TARGET is set up; nothing reached $URL.
  - Is the repo created, and EMPTY (no README, licence or .gitignore)?
  - Can this machine push to it (git credentials, or the session's GitHub access)?
Then: cd "$TARGET" && git push -u origin main
EOF
    exit 1
  fi
fi

cat <<EOF

new-game: done.
  folder    $TARGET
  origin    $URL   (the game's own repo — commits and pushes go here)
  template  $TEMPLATE_URL   (studio updates come from here)
  started   $REF

Next: open Claude Code in $TARGET and run /start (or /prototype for a quick game).
Studio updates arrive as one 'template-update' issue in the game's repo; STUDIO.md
has the merge steps.
EOF
