#!/usr/bin/env bash
# review-receipts.sh — content-hash change detection for review skills.
#
# WHY HASHES, NOT GIT OR MTIME
# A review baseline must not depend on the user's commit habits. `git diff`
# needs a committed baseline; `git status` catches uncommitted edits but only
# relative to git's own view; file mtimes lie under backup restores and cloud
# sync (an old-mtime restore with new content silently escapes review — a
# false NEGATIVE, the dangerous direction). Hashing the bytes has neither
# problem: content changed <=> hash changed. The residual failure directions
# are false POSITIVES (re-review something unchanged — wasted tokens, never a
# missed review): a hash tool changing between stamp and check, a receipt
# file that was never written, or no hash tool at all (git, sha1sum, shasum),
# which makes everything read CHANGED and says so on stderr.
#
# ONE EXCEPTION, and it is deliberate. `check` stays silent on an absent
# LITERAL path, because a caller may name an optional input on every run
# (/design-review does exactly this with the entity registry) and reporting it
# would block a legitimate skip. That silence is a false negative only if a
# caller passes a literal path it believes must exist — so callers name
# optional inputs and nothing else.
#
# An unexpanded GLOB is the case the same code path can swallow, and is NOT
# covered by the above: it means a whole document class was
# requested and none examined, which a caller could not distinguish from
# "nothing to do". It is now reported as UNRESOLVED.
#
# Observation-only per the load-bearing convention in CLAUDE.md: this script
# emits facts (UNCHANGED / CHANGED / NEW / RECEIPT: NONE), never verdicts.
# The calling skill decides what to do — including automation-mode handling,
# which this script cannot see.
#
# Usage:
#   bash .claude/scripts/review-receipts.sh hash <file> [<file>...]
#     Prints one stamp line per file:
#       Reviewed-Content-Hash: <path> <hash>
#     The calling skill pastes these lines into the review report / log
#     entry it is writing. Paths are normalised to forward slashes.
#
#   bash .claude/scripts/review-receipts.sh check <receipt-file> <file> [<file>...]
#     First line:  RECEIPT: <receipt-file>   (or RECEIPT: NONE if missing/empty)
#     Then, per file:
#       UNCHANGED: <path>   hash matches the LATEST stamp for that path
#       CHANGED: <path>     hash differs from the latest stamp
#       NEW: <path>         no stamp for that path in the receipt file
#       UNRESOLVED: <pat>   the argument is a glob the shell never expanded,
#                           so a whole class of documents was asked for and
#                           none was examined. NOT the same as an absent
#                           literal path, which stays silent on purpose --
#                           see is_unexpanded_glob() for why.
#     With RECEIPT: NONE, every file is reported NEW (nothing to compare).
#
#     A caller that skips work on "everything UNCHANGED" MUST treat an
#     UNRESOLVED line as disqualifying: the set it compared was not the set
#     it asked for.
#
#   bash .claude/scripts/review-receipts.sh sections-hash <file>
#     Per ^## section of the file (plus __preamble__ for content before the
#     first ^##), prints:
#       Reviewed-Section-Hash: <path>#<heading> <hash>
#     Enables DELTA re-reviews: the next pass learns WHICH sections changed
#     without anything storing the old content. Duplicate headings get a
#     " #N" suffix (same algorithm on stamp and check side, so they match).
#
#   bash .claude/scripts/review-receipts.sh sections-check <receipt-file> <file>
#     Compares the file's current sections against the LATEST section stamps
#     for that path in the receipt file. Prints, per section:
#       SECTION-UNCHANGED: <heading>
#       SECTION-CHANGED: <heading>
#       SECTION-NEW: <heading>        current section with no stored stamp
#     then, for stored stamps whose section no longer exists:
#       SECTION-REMOVED: <heading>
#     With no stamps for the path at all: prints SECTIONS: NONE first and
#     every current section as SECTION-NEW.
#
# The LATEST stamp wins: receipt files are append-only logs, so the last
# occurrence of a path is the most recent review of it.

set -u
export LC_ALL=C

# SHA-1 of stdin, as "<hex>  -". The fallback when git cannot hash: sha1sum is
# GNU coreutils, which older macOS releases do not ship; every macOS has
# shasum, which prints the same hex. Each is RUN before it is used -- a tool that is found but fails must
# not win. Returns 1 when neither runs.
sha1_stdin() {
  if [ -z "${_RR_SHA1+x}" ]; then
    _RR_SHA1=""
    if printf '' | sha1sum >/dev/null 2>&1; then _RR_SHA1=sha1sum
    elif printf '' | shasum -a 1 >/dev/null 2>&1; then _RR_SHA1=shasum
    fi
  fi
  case "$_RR_SHA1" in
    sha1sum) sha1sum ;;
    shasum)  shasum -a 1 ;;
    *)       return 1 ;;
  esac
}

# Printed at most once per run, on stderr: with no hash tool nothing can be
# verified unchanged, and the caller should know why everything reads CHANGED.
_rr_warned=""
warn_no_hash() {
  [ -n "$_rr_warned" ] && return 0
  echo "review-receipts: no hash tool (git, sha1sum or shasum) -- nothing can read UNCHANGED" >&2
  _rr_warned=1
}

hash_file() {
  # git hash-object is preferred (stable, content-addressed, no mtime input).
  # The SHA-1 fallback produces a DIFFERENT hash for the same bytes (git
  # prepends a blob header) — so a stamp made with one tool and checked with
  # the other reads CHANGED. That failure direction is safe (re-review).
  # The file goes in on stdin: sha1sum starts its line with "\" when the file
  # name holds a backslash, as a Windows path can.
  if command -v git >/dev/null 2>&1; then
    git hash-object -- "$1" 2>/dev/null && return 0
  fi
  sha1_stdin < "$1" 2>/dev/null | cut -d' ' -f1
}

norm_path() {
  printf '%s\n' "$1" | sed 's|\\|/|g'
}

# An argument that does not name a file is one of two very different things,
# and `check` must NOT treat them alike:
#
#   a literal path that is absent   -> an optional input the caller named on
#                                      purpose. /design-review passes
#                                      design/registry/entities.yaml on every
#                                      run and documents that an absent
#                                      registry "doesn't appear in the output
#                                      and doesn't block the skip". Reporting
#                                      it would break that skip and force a
#                                      full re-review (~46k tokens, measured)
#                                      on every project without a registry.
#                                      Staying silent here is DELIBERATE.
#
#   a pattern the shell never       -> the caller asked for a whole class of
#   expanded                           documents and got none. bash passes an
#                                      unmatched glob through verbatim, so the
#                                      wildcard surviving into argv IS the
#                                      evidence that nothing matched.
#
# Only the second is a coverage hole, and only the second is reported. The
# discriminator is exact: a real filename cannot reach this script still
# carrying an unexpanded wildcard, so this cannot fire on the registry case.
is_unexpanded_glob() {
  case "$1" in
    *'*'*|*'?'*|*'['*) return 0 ;;
    *)                 return 1 ;;
  esac
}

# Emit "start<TAB>end<TAB>heading" per ^## section of a file. Content before
# the first ^## (if any) is a __preamble__ span; a file with no ^## at all is
# one __preamble__ span. Duplicate headings get " #N" so keys stay unique —
# the SAME function runs on stamp and check side, so suffixes always agree.
section_spans() {
  awk '
    BEGIN { pre = 1 }
    /^## / {
      if (pre && NR > 1) print 1 "\t" NR-1 "\t__preamble__"
      pre = 0
      if (s) print s "\t" NR-1 "\t" h
      s = NR
      h = substr($0, 4)
      if (seen[h]++) h = h " #" seen[h]
    }
    END {
      if (pre && NR > 0) print 1 "\t" NR "\t__preamble__"
      if (s) print s "\t" NR "\t" h
    }
  ' "$1"
}

section_hash() { # <file> <start> <end>
  # Mirrors hash_file above, and for the same reason it was written that way.
  # This called bare `sha1sum`, which is GNU coreutils and absent on older macOS. The
  # failure was not a visible error: sha1sum missing makes this return EMPTY,
  # an empty `cur` compares EQUAL to an empty stored hash, and the check below
  # then prints SECTION-UNCHANGED for every section however it was edited.
  # That is the false-NEGATIVE direction this script's header names as the
  # dangerous one -- a changed section silently escaping review -- and it was
  # reachable on any machine without GNU coreutils.
  _sec=""
  if command -v git >/dev/null 2>&1; then
    _sec=$(sed -n "$2,$3p" "$1" | git hash-object --stdin 2>/dev/null)
  fi
  [ -n "$_sec" ] || _sec=$(sed -n "$2,$3p" "$1" | sha1_stdin 2>/dev/null | cut -d' ' -f1)
  # Never empty. An unhashable section must be visible in the receipt rather
  # than silently equal to the next unhashable one -- and sections-check never
  # reads this placeholder as UNCHANGED, since it matches every section.
  [ -n "$_sec" ] || _sec="NO-HASH-TOOL"
  printf '%s' "$_sec"
}

mode="${1:-}"
case "$mode" in
  hash)
    shift
    [ $# -ge 1 ] || { echo "review-receipts: hash mode needs at least one file" >&2; exit 2; }
    rc=0
    for f in "$@"; do
      if [ ! -f "$f" ]; then
        echo "review-receipts: no such file: $f" >&2
        rc=2
        continue
      fi
      h=$(hash_file "$f")
      [ -n "$h" ] || { echo "review-receipts: could not hash: $f" >&2; rc=2; continue; }
      printf 'Reviewed-Content-Hash: %s %s\n' "$(norm_path "$f")" "$h"
    done
    exit "$rc"
    ;;

  check)
    shift
    receipt="${1:-}"
    shift 2>/dev/null || true
    [ $# -ge 1 ] || { echo "review-receipts: check mode needs a receipt file and at least one file" >&2; exit 2; }

    if [ ! -s "${receipt:-}" ]; then
      echo "RECEIPT: NONE"
      for f in "$@"; do
        if [ ! -f "$f" ]; then
          is_unexpanded_glob "$f" && printf 'UNRESOLVED: %s\n' "$(norm_path "$f")"
          continue
        fi
        printf 'NEW: %s\n' "$(norm_path "$f")"
      done
      exit 0
    fi

    echo "RECEIPT: $(norm_path "$receipt")"
    for f in "$@"; do
      if [ ! -f "$f" ]; then
        is_unexpanded_glob "$f" && printf 'UNRESOLVED: %s\n' "$(norm_path "$f")"
        continue
      fi
      p=$(norm_path "$f")
      # Last occurrence wins (append-only log). grep -F on the path avoids
      # regex surprises from dots/dashes in filenames.
      stored=$(grep -F "Reviewed-Content-Hash: $p " "$receipt" 2>/dev/null | tail -1 | awk '{print $NF}')
      if [ -z "$stored" ]; then
        printf 'NEW: %s\n' "$p"
        continue
      fi
      current=$(hash_file "$f")
      [ -n "$current" ] || warn_no_hash
      if [ "$current" = "$stored" ]; then
        printf 'UNCHANGED: %s\n' "$p"
      else
        printf 'CHANGED: %s\n' "$p"
      fi
    done
    exit 0
    ;;

  sections-hash)
    shift
    f="${1:-}"
    [ -f "${f:-}" ] || { echo "review-receipts: sections-hash needs an existing file" >&2; exit 2; }
    p=$(norm_path "$f")
    while IFS=$(printf '\t') read -r s e h; do
      [ -n "$h" ] || continue
      sec_hash=$(section_hash "$f" "$s" "$e")
      [ "$sec_hash" = "NO-HASH-TOOL" ] && warn_no_hash
      printf 'Reviewed-Section-Hash: %s#%s %s\n' "$p" "$h" "$sec_hash"
    done <<EOF_SH
$(section_spans "$f")
EOF_SH
    exit 0
    ;;

  sections-check)
    shift
    receipt="${1:-}"
    f="${2:-}"
    [ -f "${f:-}" ] || { echo "review-receipts: sections-check needs a receipt file and an existing file" >&2; exit 2; }
    p=$(norm_path "$f")

    # Latest stamp per section key for this path (append-only log: last wins).
    #
    # TAB-DELIMITED ACCUMULATORS, NOT `declare -A`. Associative arrays are bash
    # 4, and macOS ships bash 3.2 as /bin/bash. There `declare -A` fails but
    # execution CONTINUES -- and a string subscript is then evaluated as
    # ARITHMETIC, so every heading collapses to index 0, each stamp overwrites
    # the last, and the UNCHANGED / CHANGED / REMOVED verdicts come out garbage
    # with nothing reported. A review tool reporting UNCHANGED for an edited
    # section is the false-negative direction this script's header calls the
    # dangerous one.
    #
    # Safe as a delimited string because a section key is heading text, which
    # cannot contain a TAB or a newline. Matching is field-exact via awk, never
    # a substring grep, so one heading cannot match another that contains it.
    _RR_TAB=$(printf '\t')
    STORED=""
    STORED_N=0
    if [ -s "${receipt:-}" ]; then
      while IFS= read -r line; do
        case "$line" in
          "Reviewed-Section-Hash: $p#"*) ;;
          *) continue ;;
        esac
        rest="${line#Reviewed-Section-Hash: $p#}"
        key="${rest% *}"
        [ -n "$key" ] || continue
        STORED="$STORED$key$_RR_TAB${rest##* }
"
        STORED_N=$((STORED_N + 1))
      done <<EOF_SC
$(grep -F "Reviewed-Section-Hash: $p#" "$receipt" 2>/dev/null)
EOF_SC
    fi
    if [ "$STORED_N" -eq 0 ]; then
      echo "SECTIONS: NONE"
    fi

    # Last occurrence wins, matching the append-only rule stated in the header.
    stored_get() {
      printf '%s' "$STORED" | awk -F"$_RR_TAB" -v k="$1" '$1==k{v=$2} END{printf "%s", v}'
    }

    CURRENT=""
    while IFS="$_RR_TAB" read -r s e h; do
      [ -n "$h" ] || continue
      CURRENT="$CURRENT$h
"
      cur=$(section_hash "$f" "$s" "$e")
      sv=$(stored_get "$h")
      # `-z` not a key-existence test, exactly as the array version did: a
      # stamp recorded with an empty hash reads NEW, not UNCHANGED.
      if [ -z "$sv" ]; then
        printf 'SECTION-NEW: %s\n' "$h"
      elif [ "$cur" = "NO-HASH-TOOL" ]; then
        # Nothing could hash this section, so nothing can call it unchanged --
        # least of all a stored placeholder, which equals every other one. A
        # wasted re-review is safe; a changed section skipped is not.
        warn_no_hash
        printf 'SECTION-CHANGED: %s\n' "$h"
      elif [ "$cur" = "$sv" ]; then
        printf 'SECTION-UNCHANGED: %s\n' "$h"
      else
        printf 'SECTION-CHANGED: %s\n' "$h"
      fi
    done <<EOF_SC2
$(section_spans "$f")
EOF_SC2

    printf '%s' "$STORED" | awk -F"$_RR_TAB" 'NF{print $1}' | sort -u | while IFS= read -r k; do
      [ -n "$k" ] || continue
      printf '%s' "$CURRENT" | awk -v k="$k" '$0==k{f=1} END{exit f?0:1}' \
        || printf 'SECTION-REMOVED: %s\n' "$k"
    done
    exit 0
    ;;

  *)
    echo "Usage: review-receipts.sh hash <file>... | check <receipt-file> <file>... | sections-hash <file> | sections-check <receipt-file> <file>" >&2
    exit 2
    ;;
esac
