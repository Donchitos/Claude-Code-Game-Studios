#!/usr/bin/env bash
# adr-dep-graph.sh — build the ADR dependency graph, detect cycles, and give
# the order to implement the ADRs in.
#
# Replaces a full read of every ADR (to extract one table row each) plus a manual
# cycle trace. A model tracing A→B→C→A across a dozen ADRs will eventually miss an
# edge; a graph walk cannot. This is the deterministic half of
# /gate-check's pre-production "ADR Circular Dependency Check" and of
# /architecture-review's dependency ordering.
#
# EMITS OBSERVATIONS, NOT A VERDICT (per .claude/docs/context-management.md rule 2).
# The caller (gate-pre-production) decides FAIL vs CONCERNS per tier. In
# particular NO_DEPS_SECTION and UNFILLED_DEPS are load-bearing: they make "no
# cycles because the graph is clean" distinguishable from "no cycles because
# half the ADRs have no dependency section, or never filled it in".
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
#   UNFILLED_DEPS: adr-X, ...     ADRs whose Depends On row is still the
#                                 template's [bracketed] placeholder: what they
#                                 depend on is unknown, not none
#   CYCLE: adr-A -> adr-B         one line per ADR on a dependency cycle (an ADR
#                                 that depends, through its edges, on itself),
#                                 with its edges to the ADRs on that cycle: one
#                                 of those edges is the one to cut
#   BLOCKED_BY_CYCLE: adr-X, ...  ADRs on no cycle that depend on one, directly
#                                 or through others: they wait for the cycle to
#                                 break, and none of their own edges is the one
#                                 to cut
#   ORDER: adr-A, adr-B, ...      every other ADR, dependencies first: those
#                                 that depend on nothing, then those whose
#                                 dependencies are all listed before them, and so
#                                 on, by id within each step. An ADR in
#                                 NO_DEPS_SECTION or UNFILLED_DEPS is placed as
#                                 if it depended on nothing; a Depends On target
#                                 with no file of its own is listed too
#   CYCLE and BLOCKED_BY_CYCLE are absent when there are none; ORDER is
#   "(none)" when every ADR is on or behind a cycle.
#
# CORRECTNESS NOTES (mirrors review-scope.sh):
#   - `while IFS= read -r` everywhere: an ADR path with a space must not split.
#   - IDs are normalised to lowercase `adr-NNNN` so a `Depends On: ADR-0003`
#     reference matches the file `adr-0003-*.md`.
#   - The Depends On row is read as adr-status.sh reads it: every ADR-N on the
#     row is an edge, and the value cell decides placeholder versus none.

case "${1:-}" in
  -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

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

SOH=$(printf '\001')
n=0; edges=""; nodes=""; no_deps=""; unfilled=""
while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    from=$(adr_id "$f")
    [ -n "$from" ] && nodes="$nodes$from"$'\n'

    # Slice the `## ADR Dependencies` section and print its `**Depends On**`
    # rows, then, after a \001, the first row's value cell (the whole row when
    # it is not a table row).
    deps=$(awk '
        { sub(/\r$/, "") }
        /^## /{ insec = ($0 ~ /## ADR Dependencies/) ? 1 : 0 }
        insec && /\*\*Depends On\*\*/ {
            print
            if (!got) {
                got = 1; k = split($0, c, "|"); cell = (k >= 3) ? c[3] : ""
                sub(/^[ \t]+/, "", cell); sub(/[ \t]+$/, "", cell)
                if (cell == "") cell = $0
            }
        }
        END { if (got) printf "\001%s\n", cell }
    ' "$f")

    if [ -z "$deps" ]; then
        no_deps="$no_deps $from"
        continue
    fi
    cell=${deps##*"$SOH"}
    deps_row=${deps%"$SOH"*}

    to_ids=$(printf '%s' "$deps_row" | grep -oiE 'adr-[0-9]+' | tr 'A-Z' 'a-z' | sort -u)
    if [ -z "$to_ids" ]; then
        # Section present but Depends On names no ADR: "None" (or empty) is a
        # real leaf; the template's [bracketed] text was never filled in.
        case "$cell" in '['*) unfilled="$unfilled $from" ;; esac
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

# no_deps and unfilled carry a leading space per append; strip it, then comma-join.
[ -n "$no_deps" ] && echo "NO_DEPS_SECTION: $(printf '%s' "${no_deps# }" | sed 's/ /, /g')"
[ -n "$unfilled" ] && echo "UNFILLED_DEPS: $(printf '%s' "${unfilled# }" | sed 's/ /, /g')"

# An ADR is on a cycle when it can reach itself, which a walk from each ADR
# answers. Peeling leaves (Kahn's algorithm) alone cannot: what is left over is
# the cycles AND every ADR that depends on one, and naming those as cycle
# members told the user to cut an edge that was fine. The order is the peeling,
# done on the ADRs neither on nor behind a cycle. Observations only; the caller
# sets the verdict.
{ printf '%s' "$nodes" | awk 'NF { print "N\t" $0 }'
  printf '%s' "$edges" | awk -F'\t' 'NF == 2 { print "E\t" $1 "\t" $2 }'; } | awk -F'\t' '
    $1 == "N" { node[$2] = 1; next }
    $1 == "E" { ne++; ef[ne] = $2; et[ne] = $3; node[$2] = 1; node[$3] = 1; adj[$2] = adj[$2] " " $3 }
    function join(a, k,    s, i) { s = ""; for (i = 1; i <= k; i++) s = s (i > 1 ? ", " : "") a[i]; return s }
    END {
        nn = 0; for (x in node) nl[++nn] = x
        for (i = 2; i <= nn; i++) { v = nl[i]; for (j = i - 1; j >= 1 && nl[j] > v; j--) nl[j + 1] = nl[j]; nl[j + 1] = v }
        # reach[s, y]: s depends on y through one or more edges.
        for (i = 1; i <= nn; i++) {
            s = nl[i]; split("", seen); q = 0; h = 1
            k = split(adj[s], o, " "); for (j = 1; j <= k; j++) if (!(o[j] in seen)) { seen[o[j]] = 1; qu[++q] = o[j] }
            while (h <= q) {
                u = qu[h++]; k = split(adj[u], o, " ")
                for (j = 1; j <= k; j++) if (!(o[j] in seen)) { seen[o[j]] = 1; qu[++q] = o[j] }
            }
            for (y in seen) reach[s, y] = 1
        }
        for (i = 1; i <= nn; i++) { x = nl[i]; if ((x, x) in reach) on[x] = 1 }
        nb = 0
        for (i = 1; i <= nn; i++) {
            x = nl[i]
            if (x in on) { line = "CYCLE: " x
                # Only the edges into its own cycle: y on a cycle with x reaches x back.
                for (e = 1; e <= ne; e++) if (ef[e] == x && (et[e] in on) && ((et[e], x) in reach)) line = line " -> " et[e]
                print line; continue }
            for (y in on) if ((x, y) in reach) { blocked[x] = 1; bl[++nb] = x; break }
        }
        if (nb) print "BLOCKED_BY_CYCLE: " join(bl, nb)
        # The rest, layer by layer. None of their edges leads to a cycle (that
        # would block them), so every out-degree counts only ADRs in this set.
        for (e = 1; e <= ne; e++) if (!(ef[e] in on) && !(ef[e] in blocked)) od[ef[e]]++
        nord = 0
        do {
            k = 0
            for (i = 1; i <= nn; i++) { x = nl[i]; if (!(x in on) && !(x in blocked) && !(x in placed) && od[x] + 0 == 0) layer[++k] = x }
            for (j = 1; j <= k; j++) { placed[layer[j]] = 1; ord[++nord] = layer[j] }
            for (j = 1; j <= k; j++) for (e = 1; e <= ne; e++) if (et[e] == layer[j]) od[ef[e]]--
        } while (k > 0)
        print "ORDER: " (nord ? join(ord, nord) : "(none)")
    }'
