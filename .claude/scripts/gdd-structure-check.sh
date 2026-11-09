#!/usr/bin/env bash
# gdd-structure-check.sh — deterministic section-presence check for system GDDs.
#
# Replaces a full-document model read per GDD with ~2 lines of output that cannot
# hallucinate a missing section. This is the cheapest real win available: the
# model spends its budget judging content, not counting headings.
#
# REPORTS PRESENCE ONLY — IT DOES NOT JUDGE COMPLETENESS.
# Which sections are REQUIRED depends on the workflow tier and on what the system
# defines (/design-review Phase 2b: Player Fantasy and Tuning Knobs are advisory
# at `standard`; Formulas is required at `standard` whenever the system defines
# numeric rules -- rates, curves, thresholds, costs. The system's category is a
# hint, not the test). A `standard`-tier GDD missing Player Fantasy is
# COMPLETE, so an "N/8" score would actively misreport it. The caller applies the
# tier; this script only says what is on disk.
#
# PLACEHOLDER names present sections that hold nothing yet: /design-system
# writes every heading first with `[To be designed]` under it, so a skeleton
# has every section PRESENT. A section counts as a placeholder when its body,
# down to the next heading at its own level or above, holds only that marker,
# blank lines and sub-headings. Like PRESENT, it is an observation: the
# caller decides what it means at the project's tier.
#
# Usage:
#   bash .claude/scripts/gdd-structure-check.sh                    # all system GDDs
#   bash .claude/scripts/gdd-structure-check.sh design/gdd/foo.md  # one GDD
#
# Output (per GDD; the ABSENT and PLACEHOLDER lines are omitted when empty):
#   combat.md PRESENT: Overview,Player Fantasy,Detailed Rules,...
#   loot.md   PRESENT: Overview,Detailed Rules,Edge Cases
#   loot.md   ABSENT:  Player Fantasy,Formulas,Tuning Knobs
#   loot.md   PLACEHOLDER: Edge Cases

case "${1:-}" in
  -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

set -u

cd "$(dirname "$0")/../.." || { echo "gdd-structure-check: cannot reach repo root" >&2; exit 1; }

# Each MATCH entry is an ERE alternation of every accepted heading for one
# required section; LABEL is the canonical name reported to the caller.
#
# "Detailed Rules" is authored as "## Detailed Design" by the GDD template and by
# /design-system. They denote the SAME required section. Accepting only one name
# reports 7/8 MISSING on every conforming GDD — the exact failure this guard
# exists to prevent, and it is regression-tested.
MATCH=("Overview" \
       "Player Fantasy" \
       "Detailed (Rules|Design)" \
       "Formulas" \
       "Edge Cases" \
       "Dependencies" \
       "Tuning Knobs" \
       "Acceptance Criteria")
LABEL=("Overview" "Player Fantasy" "Detailed Rules" "Formulas" "Edge Cases" \
       "Dependencies" "Tuning Knobs" "Acceptance Criteria")

# Governance and registry docs that live in design/gdd/ but are not system GDDs.
not_a_system_gdd() {
    case "$(basename "$1")" in
        game-concept.md|systems-index.md|game-pillars.md|gdd-cross-review-*.md) return 0 ;;
        gameplay-tags.md|fixture-swap-ledger.md|entity-registry.md)             return 0 ;;
        sound-bible.md)                                                         return 0 ;;
        *) return 1 ;;
    esac
}

check_file() {
    local f="$1" present="" absent="" i s
    for i in "${!MATCH[@]}"; do
        s="${MATCH[$i]}"
        # [[:space:]] not [ \t] — inside double quotes the shell leaves \t literal
        # and ERE reads the class as {space, backslash, t}, so real tabs fail to
        # match while "##tOverview" false-positives.
        if grep -qiE "^##+[[:space:]]+([0-9]+[.)]?[[:space:]]*)?${s}" "$f"; then
            present="$present,${LABEL[$i]}"
        else
            absent="$absent,${LABEL[$i]}"
        fi
    done
    local b; b="$(basename "$f")"
    echo "$b PRESENT: ${present#,}"
    [ -n "$absent" ] && echo "$b ABSENT:  ${absent#,}"
    local held; held=$(placeholders < "$f")
    [ -n "$held" ] && echo "$b PLACEHOLDER: $held"
    return 0
}

# placeholders < GDD -- the LABELs of present sections whose body is only
# `[To be designed]`, blank lines and sub-headings, comma-separated. The first
# heading matching each MATCH entry is the section, as for PRESENT. The file
# comes on stdin, so awk never reads a path such as x=1.md as an assignment.
# [ \t] not [[:space:]]: BWK awk on older macOS lacks the classes.
placeholders() {
    local pats="" labels="" i
    for i in "${!MATCH[@]}"; do pats="$pats;${MATCH[$i]}"; labels="$labels;${LABEL[$i]}"; done
    awk -v pats="${pats#;}" -v labels="${labels#;}" '
        { sub(/\r$/, ""); line[NR] = $0 }
        END {
            n = split(pats, P, ";"); split(labels, L, ";"); out = ""
            for (i = 1; i <= n; i++) {
                re = "^##+[ \t]+([0-9]+[.)]?[ \t]*)?" tolower(P[i])
                h = 0
                for (j = 1; j <= NR; j++) if (tolower(line[j]) ~ re) { h = j; break }
                if (!h) continue
                match(line[h], /^#+/); lvl = RLENGTH
                held = 1
                for (j = h + 1; j <= NR; j++) {
                    t = line[j]
                    if (match(t, /^#+[ \t]/)) { if (RLENGTH - 1 <= lvl) break; continue }
                    gsub(/^[ \t]+|[ \t]+$/, "", t)
                    if (t != "" && t != "[To be designed]") { held = 0; break }
                }
                if (held) out = out "," L[i]
            }
            print substr(out, 2)
        }'
}

if [ $# -gt 0 ] && [ -n "${1:-}" ]; then
    [ -f "$1" ] || { echo "Not found: $1" >&2; exit 1; }
    check_file "$1"
    exit 0
fi

any=0
# -maxdepth 1 keeps design/gdd/reviews/ out of scope — /design-review writes its
# own output there, and sweeping it in makes the tool review its own reports.
while IFS= read -r f; do
    [ -n "$f" ] || continue
    not_a_system_gdd "$f" && continue
    any=1
    check_file "$f"
done <<EOF
$(find design/gdd -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
EOF

[ "$any" -eq 1 ] || echo "No system GDDs found in design/gdd/."
