#!/usr/bin/env bash
# review-scope.sh — compute the GDD scope for an incremental cross-GDD review.
#
# Replaces the git archaeology /review-all-gdds would otherwise reason through:
# finds the most recent cross-review report, lists GDDs changed since it, and
# lists each changed GDD's declared dependencies (which must also be in scope).
#
# Usage: bash .claude/scripts/review-scope.sh
#
# Output:
#   PRIOR_REVIEW: <path>          (or "NONE (full review required)")
#   CHANGED:                      GDDs modified since that review
#   DEPS ...:                     declared .md dependencies of the changed GDDs
#
# CORRECTNESS NOTES — three silent-data-loss bugs were fixed when porting this.
# All three dropped files without warning, which in a review tool means a changed
# design doc quietly escapes review:
#
#   1. git pathspecs are fnmatch WITHOUT FNM_PATHNAME, so `*` crosses `/`:
#      'design/gdd/*.md' also matched design/gdd/reviews/*.md, pulling the
#      review logs this script writes into the review scope. Fixed with
#      :(glob) magic, which restricts * to one path segment.
#   2. `git status --porcelain | awk '{print $NF}'` mangles any path containing
#      a space (returns the trailing fragment) and returns the wrong field for
#      renames (`R old -> new`). Fixed with -z, which disables quoting entirely.
#   3. `for f in $changed` word-splits on IFS and glob-expands, so a GDD whose
#      filename contains a space was split into two nonexistent paths and
#      silently discarded. Fixed with `while IFS= read -r`.

set -u

cd "$(dirname "$0")/../.." || { echo "review-scope: cannot reach repo root" >&2; exit 1; }

GDD_GLOB=':(glob)design/gdd/*.md'

# Single definition — this list is needed at three call sites and is exactly the
# kind of thing that drifts when copied.
not_a_system_gdd() {
    case "$(basename "$1")" in
        game-concept.md|systems-index.md|game-pillars.md|gdd-cross-review-*.md) return 0 ;;
        gameplay-tags.md|fixture-swap-ledger.md|entity-registry.md)             return 0 ;;
        sound-bible.md)                                                         return 0 ;;
        *) return 1 ;;
    esac
}

all_gdds() {
    find design/gdd -maxdepth 1 -name '*.md' -type f 2>/dev/null | sed 's|\\|/|g' | sort \
    | while IFS= read -r f; do
        not_a_system_gdd "$f" || echo "$f"
      done
}

# `sort | tail -1` is chronological ONLY because the report filename carries an
# ISO 8601 date. /review-all-gdds now states that requirement at the point it
# asks permission to write the file; if that ever loosens, this line silently
# picks the wrong baseline and every GDD changed since the real last review
# escapes the next one -- failure number four in the list above, reached from
# the filename instead of the path handling.
#
# Not mtime: on a fresh clone every file carries the checkout time, so `ls -t`
# here would order the reports arbitrarily. The date in the name is the only
# ordering that survives being cloned.
last_review=$(find design/gdd -maxdepth 1 -name 'gdd-cross-review-*.md' -type f 2>/dev/null \
              | sed 's|\\|/|g' | sort | tail -1)

if [ -z "$last_review" ]; then
    echo "PRIOR_REVIEW: NONE (full review required)"
    echo "CHANGED:"
    gdds=$(all_gdds)
    if [ -z "$gdds" ]; then
        echo "  (no system GDDs found)"
    else
        printf '%s\n' "$gdds" | sed 's/^/  /'
    fi
    exit 0
fi

echo "PRIOR_REVIEW: $last_review"

# Prefer git history if the review file is committed; fall back to file mtime.
base=$(git log -1 --format=%H -- "$last_review" 2>/dev/null)
if [ -n "$base" ]; then
    changed=$( {
        git diff --name-only "$base" -- "$GDD_GLOB" 2>/dev/null
        # -z emits NUL-delimited, unquoted paths; cut -c4- strips the fixed-width
        # "XY " status prefix. For a rename, -z emits new NUL old, so taking the
        # first of each pair gives the new name, which is what we want.
        git status --porcelain -z -- "$GDD_GLOB" 2>/dev/null | tr '\0' '\n' | cut -c4-
    } | sed 's|\\|/|g' | sort -u )
else
    changed=$(find design/gdd -maxdepth 1 -name '*.md' -type f -newer "$last_review" 2>/dev/null \
              | sed 's|\\|/|g' | sort)
fi

scope=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    not_a_system_gdd "$f" && continue
    [ -f "$f" ] && scope="$scope$f"$'\n'
done <<EOF
$changed
EOF

echo "CHANGED:"
if [ -z "$scope" ]; then
    echo "  (none — no GDDs modified since last review)"
    exit 0
fi
printf '%s' "$scope" | sed 's/^/  /'

echo "DEPS (declared in changed GDDs — include these in review scope too):"
printf '%s' "$scope" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    deps=$(awk '
        /^## /{
            h = tolower($0); sub(/^##[ \t]+/, "", h); sub(/^[0-9]+[.)]?[ \t]*/, "", h)
            dep = (h ~ /^dependencies/) ? 1 : 0
        }
        dep { print }
    ' "$f" | grep -oE '[A-Za-z0-9_-]+\.md' | sort -u)
    if [ -n "$deps" ]; then
        printf '%s\n' "$deps" | sed "s|^|  $(basename "$f") -> |"
    fi
done
