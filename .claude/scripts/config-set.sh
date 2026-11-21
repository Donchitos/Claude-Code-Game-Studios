#!/usr/bin/env bash
# config-set.sh — set one key in project.yaml or project.local.yaml, after the
# checks /project-settings makes before a write, and read the value back.
#
# Replaces /project-settings Phases 1b, 4 and 5 done by hand: the enum check, the local
# whitelist, the base-file check, the reserved-setting warning (a `grep -B14`
# over effects-map.md), the shadow warning, and the edit Cases A-D.
#
# THE ASK STAYS IN THE SKILL. This script never prompts and never judges. Run it
# with --dry-run first to get the check rows, show the user the warnings, ask,
# then run it again without --dry-run. A reserved key is written, never refused
# (storing the value a user means is legitimate; storing it silently is the
# defect, so the `reserved` row is the skill's to say out loud).
#
# Usage: bash .claude/scripts/config-set.sh [--local] KEY VALUE [--dry-run] [--root DIR]
#        bash .claude/scripts/config-set.sh [--local] KEY=VALUE ...
#   KEY         a dotted YAML path, for example modes.review_mode
#   VALUE       the new value; quote one with spaces ("Systems Design"). KEY=VALUE
#               splits at the first `=`
#   --local     write project.local.yaml (gitignored) instead of project.yaml
#   --dry-run   print every row; write nothing
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
# KEY and VALUE must both be non-empty. A VALUE with a newline, one that starts
# with `#`, or one holding ` #` would be cut or turned into a comment by YAML,
# so it is refused (exit 2) rather than written. So is one that starts with a
# quote: the readers drop the quotes, so give the value bare and config-set
# quotes it where the file already quotes that key.
#
# Where the facts come from, so nothing here is a second copy of them:
#   enums and the local whitelist  the _yaml_helper_enums and
#                                  _yaml_helper_locally_overridable constants in
#                                  .claude/hooks/yaml-helper.sh, read as text
#   reserved keys                  effects-map.md: the `## ` heading above each
#                                  `> ### RESERVED` banner, split on " and "
#   known keys                     those two lists, the effects-map headings
#                                  (a key under a heading's dotted prefix counts),
#                                  and the keys in effects-map's "Complete
#                                  example `project.yaml`" block (a key under one
#                                  of its scalar keys counts: an OS-aware
#                                  command, a system override)
#   reading a value back           yaml-get.awk, as project-state.sh does
# project.stage is not edited here: it goes through set-stage.sh, which also
# keeps production/stage.txt in step (the stage mirror).
#
# What the edit does (comments, other keys, line endings and a UTF-8 BOM kept):
#   A  the key is set: its value is replaced, keeping quotes and an inline comment;
#      a value holding the file's quote takes the other quote, and one holding
#      both is written bare; when the key is set more than once the LAST one is
#      edited, as every reader uses that one
#   B  a parent block exists, the leaf does not: the leaf goes at the end of the
#      deepest existing block, at that block's child indent, with any missing
#      blocks between written out
#   C  no top-level block holds it: a new block goes at the end of the file after
#      one blank line, or first in a file of blank lines only
#   D  a layout it will not edit (exit 5): the key is a block with children or
#      holds multi-line text (a `|` or `>` value with lines under it), or one of
#      its parents is a one-line value. Nothing is written.
# The lines of a multi-line text value are text, never keys: a `review_mode:`
# line inside `notes: |` is neither edited nor counted as the key.
# A missing project.local.yaml is created with a one-line header comment.
# A file already holding the value is left byte-for-byte alone. The new text is
# made in full and read back first, then copied over the file in place, so the
# file keeps its mode and a symlink stays one.
#
# Output: TSV, in this order.
#   file       <project.yaml|project.local.yaml>  <present|absent>
#   enum       <ok|invalid|none>  <allowed values, or - when the key has no enum>
#   whitelist  <overridable|locked>  <yaml-helper.sh's list>
#   reserved   <yes|no>  <the effects-map heading, or ->
#   known      <yes|no>  <why>; on no, ending "; nearest: KEY" when a known
#              key is at most two single-character edits away (a typo)
#   shadow     <yes|no>  <the project.local.yaml value>   (project.yaml writes only)
#   current    <value now in the file, or ->  <file>
#   edit       <replaced|inserted|added-block|created|unchanged|refused|via set-stage.sh>  <line or ->
#   readback   <value read back from the edited text>  <file>
# Rows that cannot apply are left out (no shadow row for --local). A write that is
# refused still prints the rows up to the one that refused it. For project.stage,
# set-stage.sh's rows (project.yaml, stage.txt, stage_yaml, stage_txt) follow
# `edit via set-stage.sh` in place of `readback`.
#
# Exit codes: 0 done (or a dry run that would be); 1 cannot read the root, the
# yaml-helper.sh constants or a file, or cannot write; 2 usage error; 3 the value
# is not in the key's enum; 4 --local on a key that is not on the whitelist;
# 5 a layout it will not edit; 6 no project.yaml; 7 the value read
# back is not the one asked for. 3 to 7 write nothing. project.stage exits with
# set-stage.sh's code, which means the same, its 4 (the files disagree) given as 7.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk: the BOM and CR tests below compare bytes.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
LOCAL=0; DRY=0; ROOT_ARG=""; KEY=""; VALUE=""; HAVE_VALUE=0
usage() { echo "config-set: $1 (try --help)" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) usage "unknown argument: $1" ;;
    *)
      if [ -z "$KEY" ]; then
        case "$1" in
          *=*) KEY="${1%%=*}"; VALUE="${1#*=}"; HAVE_VALUE=1 ;;
          *) KEY="$1" ;;
        esac
        [ -n "$KEY" ] || usage "the key is empty"
      elif [ "$HAVE_VALUE" = 0 ]; then VALUE="$1"; HAVE_VALUE=1
      else usage "one KEY and one VALUE only (quote a value with spaces)"
      fi
      shift ;;
  esac
done
[ -n "$KEY" ] || usage "no key given"
[ "$HAVE_VALUE" = 1 ] && [ -n "$VALUE" ] || usage "no value given for $KEY"
case "$KEY" in
  *[!A-Za-z0-9_.-]*|.*|*.|*..*) usage "'$KEY' is not a dotted key (letters, digits, _ and -, joined by dots)" ;;
esac
NL='
'
case "$VALUE" in
  *"$NL"*) usage "the value has a newline" ;;
  "#"*|*" #"*) usage "the value starts with # or holds ' #', which YAML reads as a comment" ;;
esac
case "$VALUE" in
  " "*|*" ") usage "the value has leading or trailing spaces, which YAML drops" ;;
  \"*|\'*) usage "the value starts with a quote, which the readers drop; give it without quotes (the file's own quoting is kept)" ;;
esac

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "config-set: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "config-set: cannot reach the repo root" >&2; exit 1; }
fi
YH="$HERE/../hooks/yaml-helper.sh"
EM="$HERE/../docs/effects-map.md"
[ -f "$YH" ] || { echo "config-set: $YH is missing; the enums and the whitelist live there" >&2; exit 1; }
[ -f "$EM" ] || { echo "config-set: $EM is missing; the reserved settings live there" >&2; exit 1; }
[ -f "$HERE/yaml-get.awk" ] || { echo "config-set: $HERE/yaml-get.awk is missing" >&2; exit 1; }

# yh_const NAME — the lines of the shell string NAME="\ ... " in yaml-helper.sh.
yh_const() {
  awk -v n="$1" '
    $0 == n "=\"\\" { on = 1; next }
    on { l = $0; end = (l ~ /"$/); if (end) sub(/"$/, "", l); print l; if (end) exit }
  ' "$YH"
}
ENUMS=$(yh_const _yaml_helper_enums)
WHITELIST=$(yh_const _yaml_helper_locally_overridable)
[ -n "$ENUMS" ] && [ -n "$WHITELIST" ] || { echo "config-set: found no enum or whitelist constants in $YH" >&2; exit 1; }

# yget FILE KEY — the value at a dotted path, by the one shared reader.
yget() { YG_PATH="$2" awk -f "$HERE/yaml-get.awk" "$1"; }

# --- the checks --------------------------------------------------------------
TARGET="project.yaml"; [ "$LOCAL" = 1 ] && TARGET="project.local.yaml"
if [ -f "$TARGET" ]; then printf 'file\t%s\tpresent\n' "$TARGET"; else printf 'file\t%s\tabsent\n' "$TARGET"; fi

# enum: the allowed set is whatever follows `KEY::`. testing.strict is not in
# the table (its shape is a map of five types); one value written to it is the
# back-compat boolean, which validate_enum_value in yaml-helper.sh checks too.
ALLOWED=$(printf '%s\n' "$ENUMS" | awk -v k="$KEY" 'index($0, k "::") == 1 { print substr($0, length(k) + 3); exit }')
[ "$KEY" = testing.strict ] && ALLOWED="true|false"
EXIT=0
if [ -z "$ALLOWED" ]; then
  printf 'enum\tnone\t-\n'
else
  ENUM_OK=invalid
  oldIFS="$IFS"; IFS='|'
  for v in $ALLOWED; do [ "$VALUE" = "$v" ] && ENUM_OK=ok; done
  IFS="$oldIFS"
  printf 'enum\t%s\t%s\n' "$ENUM_OK" "$ALLOWED"
  [ "$ENUM_OK" = ok ] || EXIT=3
fi

# whitelist
if printf '%s\n' "$WHITELIST" | grep -qxF "$KEY"; then WL=overridable; else WL=locked; fi
printf 'whitelist\t%s\t%s\n' "$WL" "yaml-helper.sh _yaml_helper_locally_overridable"
[ "$LOCAL" = 1 ] && [ "$WL" = locked ] && [ "$EXIT" = 0 ] && EXIT=4

# headings: every `## ` line of effects-map.md, " and " split, and which of them
# sit under a RESERVED banner (the last heading before the banner).
ALL_HEADS=$(awk '/^## / { h = substr($0, 4); sub(/[ \t\r]+$/, "", h); print h }' "$EM")
HEADINGS=$(awk '/^## / { last = substr($0, 4); sub(/[ \t\r]+$/, "", last) } /^> ### RESERVED/ { print last }' "$EM")
split_and() { printf '%s\n' "$1" | sed 's/ and /\
/g'; }
RES_HIT="-"
while IFS= read -r h; do
  [ -n "$h" ] || continue
  while IFS= read -r one; do
    [ "$one" = "$KEY" ] && RES_HIT="$h"
  done <<EOF
$(split_and "$h")
EOF
done <<EOF
$HEADINGS
EOF
if [ "$RES_HIT" = "-" ]; then printf 'reserved\tno\t-\n'; else printf 'reserved\tyes\t%s\n' "$RES_HIT"; fi

# known: an enum key, a whitelisted key, a key at or under an effects-map heading,
# or a key of effects-map's complete example project.yaml, which is the only
# place that names some keys skills read (engine.version, platform.targets).
KNOWN=no; WHY="no enum, whitelist entry, effects-map heading or complete-example key names it"
[ -n "$ALLOWED" ] && { KNOWN=yes; WHY="enum key"; }
[ "$KNOWN" = no ] && [ "$WL" = overridable ] && { KNOWN=yes; WHY="whitelisted key"; }
if [ "$KNOWN" = no ]; then
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    while IFS= read -r one; do
      case "$KEY" in "$one"|"$one".*) KNOWN=yes; WHY="effects-map heading: $h" ;; esac
    done <<EOF
$(split_and "$h")
EOF
  done <<EOF
$ALL_HEADS
EOF
fi
if [ "$KNOWN" = no ]; then
  # The example's key paths, each `leaf` (holds a value) or `parent` (opens a
  # mapping), read the way yaml-get.awk reads a file; list items are skipped.
  EXAMPLE=$(awk '
    /^## Complete example `project\.yaml`/ { sec = 1; next }
    sec && /^## / { exit }
    sec && !on && /^```/ { on = 1; next }
    on && /^```/ { exit }
    on {
      l = $0; sub(/\r$/, "", l)
      n = 0; while (substr(l, n + 1, 1) == " ") n++
      s = substr(l, n + 1); c = substr(s, 1, 1)
      if (s == "" || c == "#" || c == "-") next
      p = index(s, ":"); if (p == 0) next
      k = substr(s, 1, p - 1); v = substr(s, p + 1); sub(/^[ \t]+/, "", v)
      while (d > 0 && ind[d] >= n) d--
      full = ""; for (i = 1; i <= d; i++) full = full keys[i] "."; full = full k
      if (v == "" || substr(v, 1, 1) == "#") { d++; ind[d] = n; keys[d] = k; print "parent\t" full }
      else print "leaf\t" full
    }
  ' "$EM")
  if [ -z "$EXAMPLE" ]; then
    WHY="$WHY (effects-map.md has no complete example block, so it was not read)"
  else
    while IFS="$(printf '\t')" read -r kind p; do
      case "$kind:$KEY" in
        "parent:$p"|"leaf:$p"|"leaf:$p".*) KNOWN=yes; WHY="effects-map complete example: $p"; break ;;
      esac
    done <<EOF
$EXAMPLE
EOF
  fi
fi
# An unknown key is most often a typo of a known one (qa.levl), so name the
# nearest known key when it is at most two single-character edits away. The
# candidates are every key the checks above accept by name.
if [ "$KNOWN" = no ]; then
  NEAR=$( { printf '%s\n' "$ENUMS" | sed 's/::.*//'
            printf '%s\n' "$WHITELIST"
            printf '%s\n' "$ALL_HEADS" | sed 's/ and /\
/g'
            printf '%s\n' "${EXAMPLE:-}" | cut -f2; } | awk -v k="$KEY" '
    function lev(a, b,    la, lb, i, j, c, x, y, z, d) {
      la = length(a); lb = length(b)
      for (j = 0; j <= lb; j++) d[0, j] = j
      for (i = 1; i <= la; i++) {
        d[i, 0] = i
        for (j = 1; j <= lb; j++) {
          c = (substr(a, i, 1) == substr(b, j, 1)) ? 0 : 1
          x = d[i - 1, j] + 1; y = d[i, j - 1] + 1; z = d[i - 1, j - 1] + c
          d[i, j] = (x < y) ? ((x < z) ? x : z) : ((y < z) ? y : z)
        }
      }
      return d[la, lb]
    }
    { sub(/\r$/, "") }
    /^[a-z0-9_]+(\.[a-z0-9_]+)*$/ && !seen[$0]++ {
      e = lev(k, $0)
      if (e > 0 && e <= 2 && (best == "" || e < be)) { best = $0; be = e }
    }
    END { if (best != "") print best }')
  [ -n "$NEAR" ] && WHY="$WHY; nearest: $NEAR"
fi
printf 'known\t%s\t%s\n' "$KNOWN" "$WHY"

if [ "$EXIT" != 0 ]; then
  case "$EXIT" in
    3) echo "config-set: Invalid value '$VALUE' for '$KEY'. Allowed: $ALLOWED" >&2 ;;
    4) echo "config-set: $KEY cannot be locally overridden: it is a project-wide setting. Set it in project.yaml without --local." >&2 ;;
  esac
  exit "$EXIT"
fi

# base check: local overrides need a base, and /project-settings never creates project.yaml.
if [ ! -f project.yaml ]; then
  echo "config-set: project.yaml is missing, so there is nothing to set or override. Run /start to create one first." >&2
  exit 6
fi

# shadow: a local value hides the one about to be written to project.yaml.
if [ "$LOCAL" = 0 ]; then
  SH=""; [ -f project.local.yaml ] && SH=$(yget project.local.yaml "$KEY")
  if [ -n "$SH" ]; then printf 'shadow\tyes\t%s\n' "$SH"; else printf 'shadow\tno\t-\n'; fi
fi

CUR="-"; [ -f "$TARGET" ] && { CUR=$(yget "$TARGET" "$KEY"); [ -n "$CUR" ] || CUR="-"; }
printf 'current\t%s\t%s\n' "$CUR" "$TARGET"

# --- project.stage goes through set-stage.sh ---------------------------------
if [ "$KEY" = project.stage ]; then
  [ -f "$HERE/set-stage.sh" ] || { echo "config-set: $HERE/set-stage.sh is missing" >&2; exit 1; }
  printf 'edit\tvia set-stage.sh\t-\n'
  # set-stage.sh's rows stand in for `readback`. Its exit codes mean what this
  # script's do, except its 4 (the two files disagree after writing), which is
  # this script's 7, so a 4 here always means nothing was written.
  if [ "$DRY" = 1 ]; then bash "$HERE/set-stage.sh" "$VALUE" --dry-run --root .; else bash "$HERE/set-stage.sh" "$VALUE" --root .; fi
  rc=$?
  [ "$rc" = 4 ] && rc=7
  exit "$rc"
fi

# --- the edit ----------------------------------------------------------------
# replace_file TARGET NEWFILE — the new text, made in full in NEWFILE first,
# copied over TARGET in place, so TARGET keeps its mode, a symlink stays a
# symlink and a hard link sees the change (a mv would put a new file there).
replace_file() {
  if ! cat "$2" > "$1" 2>/dev/null; then
    echo "config-set: could not write $1; the new text is kept in $2" >&2
    exit 1
  fi
  rm -f "$2"
}
NEW=$(mktemp "./.ccgs-set-XXXXXX" 2>/dev/null) || { echo "config-set: cannot create a temporary file in $(pwd)" >&2; exit 1; }
STATUS="$NEW.status"
ACTION=""; LINE="-"; DUPS=""
if [ ! -f "$TARGET" ]; then
  ACTION="created"
  # A new local file: header (the line /project-settings Phase 5 writes), then the key
  # wrapped in its parent blocks, two spaces a level, as the shipped project.yaml
  # and every new block below are indented.
  awk -v key="$KEY" -v val="$VALUE" 'BEGIN {
    print "# project.local.yaml — per-developer overrides (gitignored)"
    n = split(key, s, ".")
    for (i = 1; i <= n; i++) {
      pad = ""; for (j = 1; j < i; j++) pad = pad "  "
      if (i < n) print pad s[i] ":"; else print pad s[i] ": " val
    }
  }' > "$NEW"
  LINE=$(awk 'END { print NR }' "$NEW")
else
  CS_KEY="$KEY" CS_VALUE="$VALUE" CS_STATUS="$STATUS" awk '
    # opens(s, n): when line s (at indent n, its leading spaces removed) opens
    # a block scalar (a value of | or >, with any indicators), the indent its
    # text must exceed; else -1. The rule yaml-get.awk reads by.
    function opens(s, n,    r, p, v) {
      r = s
      if (r == "-" || substr(r, 1, 2) == "- ") {
        r = substr(r, 2); sub(/^ +/, "", r)
        if (r ~ /^[|>][-+0-9]*[ \t]*(#.*)?$/) return n
        n = n + length(s) - length(r)
      }
      if (r == "" || r ~ /^[:# \t]/) return -1
      p = index(r, ":"); if (p == 0) return -1
      v = substr(r, p + 1); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      return (v ~ /^[|>][-+0-9]*[ \t]*(#.*)?$/) ? n : -1
    }
    # Git for Windows gawk reads files in text mode and drops the CR of a CRLF
    # line; BINMODE 3 keeps every byte. Other awks treat it as a plain variable.
    BEGIN { BINMODE = 3 }
    { raw[NR] = $0 }
    END {
      key = ENVIRON["CS_KEY"]; val = ENVIRON["CS_VALUE"]; status = ENVIRON["CS_STATUS"]
      nseg = split(key, seg, ".")
      depth = 0; blk = -1; crlf = (raw[1] ~ /\r$/); eol = crlf ? "\r" : ""
      # "\357\273\277" is the UTF-8 byte-order mark. It comes off line 1 here
      # and goes back in front of the output, so an edit of line 1 cuts the
      # key line, not the mark.
      bom = ""
      if (NR > 0 && substr(raw[1], 1, 3) == "\357\273\277") { bom = substr(raw[1], 1, 3); raw[1] = substr(raw[1], 4) }
      # Parse every line the way yaml-get.awk does: indent, key, value, full path.
      for (L = 1; L <= NR; L++) {
        line = raw[L]
        sub(/\r$/, "", line)
        n = 0
        while (substr(line, n + 1, 1) == " ") n++
        s = substr(line, n + 1)
        t = s
        sub(/^[ \t]+/, "", t)
        kind[L] = "other"
        if (t == "") { kind[L] = "blank"; continue }
        if (substr(t, 1, 1) == "#") { kind[L] = "comment"; continue }
        indent[L] = n
        # A block scalar text line stays "other": content of the block above it.
        if (blk >= 0) { if (n > blk) continue; blk = -1 }
        blk = opens(s, n); text[L] = (blk >= 0)
        c = substr(s, 1, 1)
        if (c == ":" || c == "#" || c == "\t") continue
        p = index(s, ":")
        if (p == 0) continue
        k = substr(s, 1, p - 1)
        sub(/[ \t]+$/, "", k)
        v = substr(s, p + 1)
        sub(/^[ \t]+/, "", v)
        sub(/[ \t]+$/, "", v)
        q = substr(v, 1, 1)
        if (q == "#") v = ""
        else if (q == "\"" || q == "\047") {
          rest = substr(v, 2); e = index(rest, q)
          v = (e > 0) ? substr(rest, 1, e - 1) : rest
        } else {
          h = index(v, " #")
          if (h > 0) { v = substr(v, 1, h - 1); sub(/[ \t]+$/, "", v) }
        }
        while (depth > 0 && ind[depth] >= n) depth--
        full = ""
        for (i = 1; i <= depth; i++) full = full keys[i] "."
        full = full k
        kind[L] = "key"; hasval[L] = (v != ""); fullp[L] = full; colon[L] = n + p; curv[L] = v
        if (v == "") { depth++; ind[depth] = n; keys[depth] = k }
        cnt[full]++; lastat[full] = L
        if (full == key) dupl = dupl (cnt[full] > 1 ? "," : "") L
      }
      # blockend(L): the last content line of the block a key line opens.
      # Comments and blank lines after it belong to whatever comes next.
      # hasval keys have no block.
      action = ""; at = 0
      T = (key in lastat) ? lastat[key] : 0
      if (T > 0) {
        last = T
        for (j = T + 1; j <= NR; j++) {
          if (kind[j] == "key" && indent[j] <= indent[T]) break
          if (kind[j] == "other" && indent[j] <= indent[T]) break
          if (kind[j] == "key" || kind[j] == "other") last = j
        }
        if (last > T && !hasval[T]) { print "unsupported\t" T "\tblock" > status; exit 0 }
        if (last > T && text[T]) { print "unsupported\t" T "\ttext" > status; exit 0 }
        if (curv[T] == val) action = "unchanged"
        else {
          action = "replaced"
          line = raw[T]; cr = (line ~ /\r$/); sub(/\r$/, "", line)
          pre = substr(line, 1, colon[T]); after = substr(line, colon[T] + 1)
          lead = after; sub(/[^ \t].*$/, "", lead); if (lead == "") lead = " "
          a = after; sub(/^[ \t]+/, "", a)
          q = substr(a, 1, 1); nv = val
          if (a == "") tail = ""
          else if (q == "#") tail = " " a
          else if (q == "\"" || q == "\047") {
            e = index(substr(a, 2), q)
            tail = (e > 0) ? substr(a, e + 2) : ""
            # The readers end a quoted value at its first matching quote, so a
            # value holding the quote the file uses takes the other one, and a
            # value holding both is written bare (it cannot start with a quote:
            # the usage check refuses that), which they read whole.
            o = (q == "\"") ? "\047" : "\""
            if (index(val, q) == 0) nv = q val q
            else if (index(val, o) == 0) nv = o val o
            else nv = val
          } else {
            # Keep an inline comment and the spaces before it; drop the old value.
            h = index(a, " #"); tail = ""
            if (h > 0) { tok = substr(a, 1, h - 1); sub(/[ \t]+$/, "", tok); tail = substr(a, length(tok) + 1) }
          }
          raw[T] = pre lead nv tail (cr ? "\r" : "")
        }
        at = T
      } else {
        # The deepest existing parent: the longest proper prefix that is a key line.
        m = 0; path = ""; pm = ""
        for (i = 1; i < nseg; i++) {
          path = path (i > 1 ? "." : "") seg[i]
          if (path in lastat) m = i
        }
        if (m > 0) {
          pm = seg[1]; for (i = 2; i <= m; i++) pm = pm "." seg[i]
          A = lastat[pm]
          if (hasval[A]) { print "unsupported\t" A "\tscalar-parent" > status; exit 0 }
          last = A; ci = -1
          for (j = A + 1; j <= NR; j++) {
            if ((kind[j] == "key" || kind[j] == "other") && indent[j] <= indent[A]) break
            if (kind[j] == "key" || kind[j] == "other") { last = j; if (ci < 0) ci = indent[j] }
          }
          # An empty block has no child indent to copy: two spaces deeper, and
          # two more for each missing block below it, as the shipped file nests.
          if (ci < 0) ci = indent[A] + 2
          block = ""
          for (i = m + 1; i <= nseg; i++) {
            pad = ""; for (j = 0; j < ci + 2 * (i - m - 1); j++) pad = pad " "
            block = block (i > m + 1 ? "\n" : "") pad seg[i] ":" (i == nseg ? " " val : "") eol
          }
          ins[last] = block; action = "inserted"; at = last + 1
        } else {
          # No top-level block holds it: a new block after the last non-blank line.
          last = NR
          while (last > 0 && kind[last] == "blank") last--
          block = ""
          for (i = 1; i <= nseg; i++) {
            pad = ""; for (j = 1; j < i; j++) pad = pad "  "
            block = block (i > 1 ? "\n" : "") pad seg[i] ":" (i == nseg ? " " val : "") eol
          }
          sep = (last > 0) ? eol "\n" : ""
          ins[last] = sep block; action = "added-block"; at = last + (last > 0 ? 2 : 1)
        }
      }
      # A new block in an empty file, or one of blank lines only, goes first
      # (last is 0 there), before whatever blank lines it holds.
      printf "%s", bom
      if (0 in ins) print ins[0]
      for (L = 1; L <= NR; L++) {
        print raw[L]
        if (L in ins) print ins[L]
      }
      printf "%s\t%s\t%s\n", action, at, dupl > status
    }
  ' "$TARGET" > "$NEW"
  IFS="$(printf '\t')" read -r ACTION LINE DUPS < "$STATUS" 2>/dev/null
  rm -f "$STATUS"
  if [ "${ACTION:-}" = "unsupported" ]; then
    rm -f "$NEW"
    printf 'edit\trefused\t%s\n' "$LINE"
    case "$DUPS" in
      block) echo "config-set: $TARGET line $LINE: $KEY cannot be set there. It is a block with entries under it." >&2 ;;
      text) echo "config-set: $TARGET line $LINE: $KEY cannot be set there. It holds multi-line text (a | or > value with lines under it)." >&2 ;;
      *) echo "config-set: $TARGET line $LINE: $KEY cannot be set there. A parent of it is a one-line value." >&2 ;;
    esac
    echo "  Nothing was written; edit the file by hand." >&2
    exit 5
  fi
  [ -n "${ACTION:-}" ] || { rm -f "$NEW"; echo "config-set: could not parse $TARGET; nothing was written" >&2; exit 1; }
  if [ -n "${DUPS:-}" ] && [ "$DUPS" != "$LINE" ]; then
    case "$DUPS" in *,*) echo "config-set: $KEY is set more than once in $TARGET (lines $DUPS); the last is the one readers use, so that is the one edited" >&2 ;; esac
  fi
  [ "$ACTION" = "unchanged" ] && { rm -f "$NEW"; NEW=""; }
fi

printf 'edit\t%s\t%s\n' "$ACTION" "$LINE"
if [ "$DRY" = 1 ]; then
  [ -n "$NEW" ] && rm -f "$NEW"
  exit 0
fi

# Read the value back from the new text before it replaces the file, so a
# write whose readback is wrong never lands.
BACK=$(yget "${NEW:-$TARGET}" "$KEY")
printf 'readback\t%s\t%s\n' "${BACK:--}" "$TARGET"
if [ "$BACK" != "$VALUE" ]; then
  [ -n "$NEW" ] && rm -f "$NEW"
  echo "config-set: the edited $TARGET would read '$BACK' for $KEY, not '$VALUE', so nothing was written. Edit the file by hand." >&2
  exit 7
fi
[ -n "$NEW" ] && replace_file "$TARGET" "$NEW"
exit 0
