#!/bin/bash
# template-update-check.sh — keep ONE open issue saying a template update is
# waiting. Run by .github/workflows/template-update-check.yml; see STUDIO.md.
#
# Which template it checks depends on where it runs:
#   - in the studio template repo (STUDIO_REPO): upstream's newest release
#     (UPSTREAM_REPO, tags like v1.3.0);
#   - anywhere else (a game): the studio's newest release (STUDIO_REPO, tags
#     like studio-v1.0.0), or TEMPLATE_REPO when that is set.
#
# Then, using the issue labelled `template-update`:
#   - this repo already contains that release → close the open issue, if any;
#   - no open issue → open one;
#   - an open issue for an older release → retitle and rewrite that same issue
#     and comment on it (one issue per repo, never one per release);
#   - an open issue for this release already → leave it alone.
#
# Usage: bash tools/template-update-check.sh [--dry-run]
#   --dry-run   print what it would do to issues; change nothing
# Environment:
#   REPO            owner/name of this repo (GitHub Actions: github.repository)
#   GH_TOKEN        token for `gh` with issues: write (Actions: github.token)
#   TEMPLATE_REPO   optional override of the repo to check (owner/name)
#   BRANCH          optional; the branch to compare (default: HEAD)
#   SOURCE_GIT_URL  optional; fetch the release from here instead of
#                   https://github.com/<repo>.git (for testing)
#
# Exit: 0 done (including "nothing to do"); 1 could not check (the reason is
# printed — a run that could not check never closes or rewrites an issue).

set -u
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
CONF="$ROOT/.claude/studio.conf"
fail() { echo "template-update-check: NOT CHECKED — $*" >&2; exit 1; }
[ -f "$CONF" ] || fail "no $CONF"
conf_get() { awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); sub(/[ \t\r]+$/, ""); print; exit }' "$CONF"; }
STUDIO_REPO=$(conf_get STUDIO_REPO)
UPSTREAM_REPO=$(conf_get UPSTREAM_REPO)
STUDIO_PREFIX=$(conf_get STUDIO_TAG_PREFIX)

[ -n "${REPO:-}" ] || fail "REPO is not set (owner/name of this repo)"
command -v gh >/dev/null 2>&1 || fail "the gh CLI is not installed"
cd "$ROOT" || fail "cannot enter $ROOT"
BRANCH="${BRANCH:-HEAD}"

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
LABEL=template-update

if [ "$(lower "$REPO")" = "$(lower "$STUDIO_REPO")" ]; then
  KIND=upstream
  SOURCE="$UPSTREAM_REPO"
  PREFIX=v
  REMOTE_NAME=upstream
  GUIDE="STUDIO.md, \"Taking an upstream update\""
else
  KIND=studio
  SOURCE="${TEMPLATE_REPO:-$STUDIO_REPO}"
  PREFIX="$STUDIO_PREFIX"
  REMOTE_NAME=template
  GUIDE="STUDIO.md, \"Taking a studio update\""
fi
[ -n "$SOURCE" ] || fail "no repo to check"

# --- The newest release of SOURCE whose tag is PREFIX + x.y.z ---------------
# Releases, not bare tags: a release is the "this one is approved" step.
# Drafts and pre-releases are skipped. REST (`gh api`) throughout, not GraphQL.
RELEASES=$(gh api "repos/$SOURCE/releases?per_page=50" \
             --jq '.[] | select(.draft | not) | select(.prerelease | not) | [.tag_name, .html_url] | @tsv' 2>&1) \
  || fail "could not list releases of $SOURCE: $RELEASES"
LATEST=$(printf '%s\n' "$RELEASES" | awk -F'\t' -v p="$PREFIX" 'index($1, p) == 1 {
           v = substr($1, length(p) + 1)
           if (v !~ /^[0-9]+\.[0-9]+\.[0-9]+$/) next
           split(v, a, "."); printf "%09d%09d%09d\t%s\t%s\n", a[1], a[2], a[3], $1, $2 }' \
         | sort | tail -1)
[ -n "$LATEST" ] || fail "$SOURCE has no release tagged ${PREFIX}x.y.z yet"
TAG=$(printf '%s' "$LATEST" | cut -f2)
REL_URL=$(printf '%s' "$LATEST" | cut -f3)
echo "template-update-check: newest $KIND release of $SOURCE is $TAG"

# --- Does this repo already contain it? -------------------------------------
# Fetched into a private ref, so neither repo's tags are touched.
REF="refs/template-update-check/$TAG"
git fetch --quiet --no-tags "${SOURCE_GIT_URL:-https://github.com/$SOURCE.git}" "+refs/tags/$TAG:$REF" 2>/dev/null \
  || fail "could not fetch $TAG from $SOURCE"
HEAD_SHA=$(git rev-parse --verify --quiet "$BRANCH^{commit}") || fail "no branch $BRANCH here"
if git merge-base --is-ancestor "$REF" "$HEAD_SHA"; then
  STATE=current
elif git merge-base "$REF" "$HEAD_SHA" >/dev/null 2>&1; then
  STATE=behind
  BEHIND=$(git rev-list --count "$HEAD_SHA..$REF")
  FILES=$(git diff --name-only "$HEAD_SHA...$REF" | wc -l | tr -d ' ')
else
  STATE=unrelated
fi
git update-ref -d "$REF" 2>/dev/null
echo "template-update-check: this repo is $STATE"

# --- The one open issue ------------------------------------------------------
OPEN=$(gh api "repos/$REPO/issues?labels=$LABEL&state=open&per_page=50" \
         --jq '.[] | select(.pull_request | not) | [.number, .title] | @tsv' 2>&1) \
  || fail "could not list issues of $REPO: $OPEN"
# Oldest first; the oldest open one is THE issue, any others are strays.
OPEN=$(printf '%s\n' "$OPEN" | awk -F'\t' 'NF' | sort -n)
ISSUE=$(printf '%s\n' "$OPEN" | head -1 | cut -f1)
ISSUE_TITLE=$(printf '%s\n' "$OPEN" | head -1 | cut -f2-)
STRAYS=$(printf '%s\n' "$OPEN" | sed -n '2,$p' | cut -f1)

run() {
  if [ "$DRY" = 1 ]; then
    printf 'DRY-RUN:'; printf ' %q' "$@" | cut -c1-300; printf '\n'
  else
    "$@" || fail "GitHub refused: $*"
  fi
}
comment() { run gh api -X POST "repos/$REPO/issues/$1/comments" -f body="$2" --silent; }

for n in $STRAYS; do
  comment "$n" "Closing as a duplicate: #$ISSUE tracks template updates for this repo."
  run gh api -X PATCH "repos/$REPO/issues/$n" -f state=closed -f state_reason=not_planned --silent
done

if [ "$STATE" = current ]; then
  if [ -n "$ISSUE" ]; then
    comment "$ISSUE" "This repo now contains $TAG, the newest $KIND release. Closing; the next release opens a fresh issue."
    run gh api -X PATCH "repos/$REPO/issues/$ISSUE" -f state=closed -f state_reason=completed --silent
  else
    echo "template-update-check: up to date, no open issue — nothing to do"
  fi
  exit 0
fi

TITLE="Template update available: $TAG"
if [ "$KIND" = upstream ]; then
  WHAT="A new upstream release of the framework ($SOURCE) is out. Review it, merge it into the studio template, then cut a studio release so games receive it."
  REMOTE_URL="https://github.com/$SOURCE.git"
else
  WHAT="A new studio template release is out. Merge it when it suits this game — between milestones is a good time."
  REMOTE_URL="https://github.com/$SOURCE.git"
fi

if [ "$STATE" = behind ]; then
  STEPS=$(cat <<EOF
\`\`\`bash
# once per clone; skip it if \`git remote -v\` already lists $REMOTE_NAME
git remote add $REMOTE_NAME $REMOTE_URL

git fetch $REMOTE_NAME --tags
git checkout main && git pull
git checkout -b template-update/$TAG
git merge $TAG
# resolve conflicts (see $GUIDE), run the game and its tests,
# then push the branch and open a pull request into main
\`\`\`

Behind by $BEHIND commit(s); $FILES file(s) differ from this repo's main.
EOF
)
else
  STEPS=$(cat <<EOF
**This repo shares no git history with $SOURCE**, so a plain merge would flag
every file as a conflict. Do not use \`--allow-unrelated-histories\`. See
$GUIDE, "No shared history".
EOF
)
fi

BODY=$(cat <<EOF
<!-- template-update-check: managed by .github/workflows/template-update-check.yml. One issue per repo: a newer release rewrites this issue instead of opening another. -->

$WHAT

| | |
|---|---|
| Release | [$TAG]($REL_URL) |
| From | \`$SOURCE\` |
| Into | \`$REPO\` (\`main\`) |

## How to take it

$STEPS

When \`main\` contains $TAG, the next check closes this issue by itself.
EOF
)

ensure_label() {
  gh api "repos/$REPO/labels/$LABEL" --silent >/dev/null 2>&1 && return 0
  run gh api -X POST "repos/$REPO/labels" -f name="$LABEL" -f color=5319e7 \
    -f description="A template release is waiting to be merged (managed by template-update-check)" --silent
}

if [ -z "$ISSUE" ]; then
  ensure_label
  run gh api -X POST "repos/$REPO/issues" -f title="$TITLE" -f body="$BODY" -f "labels[]=$LABEL" --silent
  echo "template-update-check: opened an issue for $TAG"
elif [ "$ISSUE_TITLE" = "$TITLE" ]; then
  echo "template-update-check: issue #$ISSUE already tracks $TAG — nothing to do"
else
  run gh api -X PATCH "repos/$REPO/issues/$ISSUE" -f title="$TITLE" -f body="$BODY" --silent
  comment "$ISSUE" "Updated: **$TAG** is now the newest $KIND release (was: ${ISSUE_TITLE#Template update available: }). The steps above now merge $TAG."
  echo "template-update-check: rewrote issue #$ISSUE for $TAG"
fi
exit 0
