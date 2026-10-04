#!/usr/bin/env bash
# adr-dep-graph.sh — build the ADR dependency graph and detect cycles.
#
# Replaces a full read of every ADR (to extract one table row each) plus a manual
# cycle trace. A model tracing A→B→C→A across a dozen ADRs will eventually miss an
# edge; Kahn's algorithm cannot. This is the deterministic half of
# /gate-check's pre-production "ADR Circular Dependency Check".
#
# EMITS OBSERVATIONS, NOT A VERDICT (per .claude/docs/context-management.md rule 2).
# The caller (gate-pre-production) decides FAIL vs CONCERNS per tier. In
# particular NO_DEPS_SECTION is load-bearing: it makes "no cycles because the
# graph is clean" distinguishable from "no cycles because half the ADRs have no
# dependency section".
#
# Usage: bash .claude/scripts/adr-dep-graph.sh [adr-dir]
#   adr-dir defaults to docs/architecture (relative to repo root). An explicit
#   dir (used by the test suite) is taken as-is.
#
# Output:
#   ADRS: <n>
#   EDGES:                        one "adr-A -> adr-B" per Depends-On reference
#     (or "  (none)")
#   NO_DEPS_SECTION: adr-X, ...   ADRs with no `## ADR Dependencies` / no Depends On
#   CYCLE: adr-A -> adr-B -> adr-A   one line per node in a dependency cycle
#     (absent when the graph is acyclic)
#
# CORRECTNESS NOTES (mirrors review-scope.sh):
#   - `while IFS= read -r` everywhere: an ADR path with a space must not split.
#   - IDs are normalised to lowercase `adr-NNNN` so a `Depends On: ADR-0003`
#     reference matches the file `adr-0003-*.md`.

set -u

# Default to the repo's ADR dir; an explicit arg (absolute or CWD-relative, used
# by the suite) is taken as-is without cd-ing to the repo root.
if [ -n "${1:-}" ]; then
    ADR_DIR="$1"
else
    cd "$(dirname "$0")/../.." || { echo "adr-dep-graph: cannot reach repo root" >&2; exit 1; }
    ADR_DIR="docs/architecture"
fi

# Normalise any adr reference (filename or "ADR-0003") to `adr-0003`.
adr_id() {
    printf '%s' "$1" | grep -oiE 'adr-[0-9]+' | head -1 | tr 'A-Z' 'a-z'
}

adr_files=$(find "$ADR_DIR" -maxdepth 1 -name 'adr-*.md' -type f 2>/dev/null \
            | sed 's|\\|/|g' | sort)

if [ -z "$adr_files" ]; then
    echo "ADRS: 0"
    echo "EDGES:"
    echo "  (none — no ADRs in $ADR_DIR)"
    exit 0
fi

n=0; edges=""; no_deps=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    from=$(adr_id "$f")

    # Slice the `## ADR Dependencies` section, take the `**Depends On**` row, and
    # pull every ADR-NNNN out of its value cell. `None` yields no matches.
    deps_row=$(awk '
        /^## /{ insec = ($0 ~ /## ADR Dependencies/) ? 1 : 0 }
        insec && /\*\*Depends On\*\*/ { print }
    ' "$f")

    if [ -z "$deps_row" ]; then
        no_deps="$no_deps $from"
        continue
    fi

    to_ids=$(printf '%s' "$deps_row" | grep -oiE 'adr-[0-9]+' | tr 'A-Z' 'a-z' | sort -u)
    if [ -z "$to_ids" ]; then
        # Section present but Depends On is "None" (or empty) — a real leaf, not a
        # missing section. Not reported under NO_DEPS_SECTION.
        continue
    fi
    while IFS= read -r t; do
        [ -n "$t" ] || continue
        [ "$t" = "$from" ] && continue   # ignore a self-reference
        edges="$edges$from	$t"$'\n'
    done <<EOF
$to_ids
EOF
done <<EOF
$adr_files
EOF

echo "ADRS: $n"

echo "EDGES:"
if [ -z "$edges" ]; then
    echo "  (none)"
else
    printf '%s' "$edges" | while IFS='	' read -r a b; do
        [ -n "$a" ] || continue
        echo "  $a -> $b"
    done
fi

# no_deps carries a leading space per append; strip it, then comma-join.
[ -n "$no_deps" ] && echo "NO_DEPS_SECTION: $(printf '%s' "${no_deps# }" | sed 's/ /, /g')"

# Cycle detection — Kahn's algorithm on out-degree (a node "depends on" its
# out-neighbours; a leaf depends on nothing remaining). Whatever cannot be peeled
# away is part of a cycle. Reported as an observation; the caller sets the verdict.
if [ -n "$edges" ]; then
    cyc=$(printf '%s' "$edges" | awk -F'\t' '
        NF==2 {
            e_from[++ne]=$1; e_to[ne]=$2
            node[$1]=1; node[$2]=1
            od[$1]++
        }
        END {
            total=0; for (x in node) total++
            removed=0; progress=1
            while (progress) {
                progress=0
                for (x in node) {
                    if (gone[x] || od[x] > 0) continue
                    gone[x]=1; removed++; progress=1
                    for (i=1;i<=ne;i++)
                        if (e_to[i]==x && !edone[i]) { edone[i]=1; od[e_from[i]]-- }
                }
            }
            if (removed < total)
                for (x in node) if (!gone[x]) print x
        }
    ' | sort)
    if [ -n "$cyc" ]; then
        # printf '%s\n' (not '%s') so the final node isn't dropped by read.
        printf '%s\n' "$cyc" | while IFS= read -r x; do
            [ -n "$x" ] || continue
            # Show each cycle node with the in-cycle edges it participates in.
            outs=$(printf '%s' "$edges" | awk -F'\t' -v x="$x" '$1==x{printf " -> %s", $2}')
            echo "CYCLE: $x$outs"
        done
    fi
fi
