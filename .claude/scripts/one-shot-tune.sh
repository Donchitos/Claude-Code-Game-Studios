#!/usr/bin/env bash
# one-shot-tune.sh — write the tweak panel's values into a one-shot's config.js, with a line in
# its feel-log.md for each, from the block the panel's Save copied:
#     Tuned in the panel: <name>
#     jump_height 3 → 4
# or from a number the person said (--said).
#
# /prototype runs it when the person pastes that block or says a number. A value is written only
# where config.js still holds the value the panel started from, the new value lies within the
# value's min and max, and the value sits on one line of config.js with its min and max. Every
# other line of the block gets a row saying why it was left alone; whether to ask about one is
# /prototype's call.
#
# A grown game (a folder with data/config.json and no config.js) is read the same way: its values
# in data/config.json, one entry a line, its log in design/feel-log.md, with no prototype header
# (the grown files are the game now).
#
# Usage: bash .claude/scripts/one-shot-tune.sh <folder> <line>... [--why TEXT] [--said] [--widen]
#   <folder>     the game's folder, prototypes/<name> (a grown game: the project, .)
#   <line>       a line of the pasted block as it was pasted, one argument each: the first line
#                "Tuned in the panel: <name>", then "<key> <from> → <to>" ("->" is read too)
#   --why TEXT   what the person said about the tuning, in their words, for the feel log
#   --said       the value was said out loud, not tuned in the panel: "<key> <now> → <to>"
#   --widen      a value past its min or max moves the range to take it (the person asked to)
#   --root DIR   the project; defaults to the repo this script is in
#   -h, --help   this text
#
# Output: TSV, a row for each line of the block, in order.
#   game          <name>                     the folder's name, first
#   set           <key> <from> <to>          written into config.js, with a feel-log line
#   same          <key> <value>              config.js holds it already
#   moved         <key> <from> <now> <to>    config.js no longer holds the value the panel started from
#   out_of_range  <key> <to> <min> <max>     past the value's min or max
#   unknown       <key>                      config.js has no such key
#   unreadable    <key>                      not on one line with value, min and max: write it by hand
#   bad_line      <line>                     not "<key> <from> → <to>" with numbers
#   pick          <key> <to>                 a switch with options: never written here, it is
#                                            changed in config.js by hand
#   other_game    <name>                     the block is another game's: nothing is written (exit 4)
#   widened       <key> <min,max> <min,max>  --widen: the range before and after, said in the log
#   log           feel-log.md <lines added>  last; the log is made, with its header, on its first line
#
# Exit codes: 0 done; 1 no config.js, or a write failed; 2 usage error; 4 the block names another
# game. The rows say what was written.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR=""; ROOT_ARG=""; WHY=""; LINES=""; NL=0; SAID=0; WIDEN=0
use() { echo "one-shot-tune: $1 (try --help)" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --why) [ $# -ge 2 ] || use "--why needs a value"; WHY="$2"; shift 2 ;;
    --root) [ $# -ge 2 ] || use "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --said) SAID=1; shift ;;
    --widen) WIDEN=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) use "unknown argument: $1" ;;
    *) if [ -z "$DIR" ]; then DIR="$1"; else LINES="$LINES$1
"; NL=$((NL + 1)); fi; shift ;;
  esac
done
[ -n "$DIR" ] || use "a folder is needed"
[ "$NL" -gt 0 ] || use "no lines given: pass each line of the pasted block"

ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "one-shot-tune: no such folder: $ROOT_ARG" >&2; exit 1; }
case "$DIR" in /*|[A-Za-z]:*) ;; *) DIR="$ROOT/$DIR" ;; esac
DIR=$(cd "$DIR" 2>/dev/null && pwd) || { echo "one-shot-tune: no such folder: $DIR" >&2; exit 1; }
if [ -f "$DIR/config.js" ]; then CFG="$DIR/config.js"; LOGREL="feel-log.md"; GROWN=0
elif [ -f "$DIR/data/config.json" ]; then CFG="$DIR/data/config.json"; LOGREL="design/feel-log.md"; GROWN=1
else echo "one-shot-tune: no config.js in $DIR" >&2; exit 1; fi
LOG="$DIR/$LOGREL"; CFGREL=${CFG#"$DIR"/}
NAME="${DIR##*/}"
TMPD=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-tune-$$")
mkdir -p "$TMPD" || { echo "one-shot-tune: cannot make a temporary folder" >&2; exit 1; }
trap 'rm -rf "$TMPD"' EXIT
printf 'game\t%s\n' "$NAME"

# A new log's first lines: the prototype header copied from index.html (the starter's three
# lines), then the heading. A grown game's log has no header.
TITLE=$(tr -d '\r' < "$DIR/index.html" 2>/dev/null | sed -n 's|.*<title>\(.*\)</title>.*|\1|p' | head -1 \
  | sed -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/&quot;/"/g' -e "s/&#39;/'/g" -e 's/&amp;/\&/g')
NH="# Feel log: ${TITLE:-$NAME}"
if [ "$GROWN" = 0 ]; then
  HL=$(tr -d '\r' < "$DIR/index.html" 2>/dev/null | sed -n '1,8p')
  Q=$(printf '%s\n' "$HL" | grep -m1 -E '^<!-- Question: .* -->$')
  D=$(printf '%s\n' "$HL" | grep -m1 -E '^<!-- Date: .* -->$')
  NH="<!-- PROTOTYPE - NOT FOR PRODUCTION -->${Q:+
$Q}
${D:-<!-- Date: $(date +%Y-%m-%d) -->}
$NH"
fi

B="$LINES" W=$(printf '%s' "$WHY" | tr '\r\n' '  ') D=$(date +%Y-%m-%d) NH="$NH" awk \
  -v cfgf="$CFG" -v logf="$LOG" -v newcfg="$TMPD/config" -v newlog="$TMPD/log" -v name="$NAME" -v arrow="→" \
  -v said="$SAID" -v widen="$WIDEN" -v grown="$GROWN" -v logrel="$LOGREL" '
  function num(x) { return x ~ /^[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)$/ }
  function field(body, f,   r) { # the number after "<f>:" (quoted or not) in an object on one line
    if (!match(body, "[{,][ \t]*\"?" f "\"?[ \t]*:[ \t]*")) return ""
    r = substr(body, RSTART + RLENGTH)
    return match(r, /^[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)/) ? substr(r, 1, RLENGTH) : ""
  }
  function setf(line, f, v,   pre, rest) { # that number replaced, the rest of the line kept
    if (!match(line, "[{,][ \t]*\"?" f "\"?[ \t]*:[ \t]*")) return line
    pre = substr(line, 1, RSTART + RLENGTH - 1); rest = substr(line, RSTART + RLENGTH)
    match(rest, /^[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)/)
    return pre v substr(rest, RLENGTH + 1)
  }
  function split2(line) { # CODE and CMT: a line and its trailing // comment
    sub(/\r$/, "", line); CODE = line; CMT = ""
    if (match(line, /[ \t]\/\/.*$/)) { CODE = substr(line, 1, RSTART - 1); CMT = substr(line, RSTART) }
  }
  function entry(line,   t) { # the key an entry line starts with, or ""
    t = line; sub(/\r$/, "", t)
    if (!match(t, /^[ \t]*["\047]?[A-Za-z_$][A-Za-z0-9_$]*["\047]?[ \t]*:/)) return ""
    t = substr(t, RSTART, RLENGTH); gsub(/[ \t"\047:]/, "", t); return t
  }
  function slider(line,   b) { # 1 when the entry holds value, min, max and step on its line: V, LO, HI, ST
    split2(line); V = LO = HI = ST = ""
    if (match(CODE, /\{.*\}/)) { b = substr(CODE, RSTART, RLENGTH); V = field(b, "value"); LO = field(b, "min"); HI = field(b, "max"); ST = field(b, "step") }
    return V != "" && LO != "" && HI != "" && ST != ""
  }
  function keyat(k,   j) { for (j = 1; j <= n; j++) if (entry(c[j]) == k) return j; return 0 }
  function addlog(s) { G[++ng] = s LEOL; logdirty = 1 }
  function tail(why,   src) { # how a line ends: their words, and where the value came from
    src = said ? "you asked" : "tuned in the panel"
    return why != "" ? "\"" why "\" (" src ")" : src
  }
  BEGIN {
    BINMODE = 3
    why = ENVIRON["W"]; day = ENVIRON["D"]
    while ((getline l < cfgf) > 0) c[++n] = l
    close(cfgf)
    EOL = (c[1] ~ /\r$/) ? "\r" : "" # a line written again keeps the file s line ends
    logexists = 0
    while ((getline l < logf) > 0) { logexists = 1; G[++ng] = l }
    close(logf)
    LEOL = (G[1] ~ /\r$/) ? "\r" : ""
    write_block()
    if (cfgdirty) for (j = 1; j <= n; j++) print c[j] > newcfg
    if (logdirty) {
      if (!logexists) { k = split(ENVIRON["NH"], h, "\n"); printf "" > newlog; for (j = 1; j <= k; j++) print h[j] > newlog; print "" > newlog }
      for (j = 1; j <= ng; j++) print G[j] > newlog
    }
    exit 0
  }

  # ---- The block, or a number said --------------------------------------------------------------
  function write_block(   nb, b, i, l, gm, m, f, j, t, k, from, to, at, line, lo2, hi2, nl) {
    nb = split(ENVIRON["B"], b, "\n")
    for (i = 1; i <= nb; i++) {
      l = b[i]; sub(/\r$/, "", l); sub(/^[ \t]+/, "", l); sub(/[ \t]+$/, "", l); b[i] = l
      if (l ~ /^Tuned in the panel: /) { gm = substr(l, 21); if (gm != name) { printf "other_game\t%s\n", gm; exit 4 } }
    }
    for (i = 1; i <= nb; i++) {
      l = b[i]
      if (l == "" || l ~ /^Tuned in the panel: /) continue
      m = split(l, f, /[ \t]+/)
      if (m == 4 && (f[3] == arrow || f[3] == "->") && f[1] ~ /^[A-Za-z_][A-Za-z0-9_]*$/ && f[4] ~ /^[A-Za-z0-9_-]+$/ && !num(f[4])) {
        for (j = 1; j <= n; j++) { # a word: a switch, when the line of the key has options
          t = c[j]; sub(/\r$/, "", t)
          if (t ~ ("^[ \t]*[\"\047]?" f[1] "[\"\047]?[ \t]*:") && t ~ /options[ \t]*:/) break
        }
        if (j <= n) { printf "pick\t%s\t%s\n", f[1], f[4]; continue }
      }
      if (m != 4 || (f[3] != arrow && f[3] != "->") || f[1] !~ /^[A-Za-z_][A-Za-z0-9_]*$/ || !num(f[2]) || !num(f[4])) {
        printf "bad_line\t%s\n", l; continue
      }
      k = f[1]; from = f[2]; to = f[4]
      at = keyat(k)
      if (!at) { printf "unknown\t%s\n", k; continue }
      if (!slider(c[at])) { printf "unreadable\t%s\n", k; continue }
      if (to + 0 == V + 0) { printf "same\t%s\t%s\n", k, V; continue }
      if (from + 0 != V + 0) { printf "moved\t%s\t%s\t%s\t%s\n", k, from, V, to; continue }
      if (to + 0 < LO + 0 || to + 0 > HI + 0) {
        if (!widen) { printf "out_of_range\t%s\t%s\t%s\t%s\n", k, to, LO, HI; continue }
        lo2 = (to + 0 < LO + 0) ? to : LO; hi2 = (to + 0 > HI + 0) ? to : HI
        split2(c[at]); line = setf(setf(CODE, "min", lo2), "max", hi2)
        if (!grown) CMT = CMT == "" ? " // range: widened" : (CMT ~ /range:/ ? CMT : CMT "; range: widened")
        c[at] = line CMT EOL; cfgdirty = 1
        printf "widened\t%s\t%s,%s\t%s,%s\n", k, LO, HI, lo2, hi2
        lg[++nl] = "- " day " · " k " range " LO " to " HI " " arrow " " lo2 " to " hi2 " · " tail(why)
      }
      split2(c[at]); c[at] = setf(CODE, "value", to) CMT EOL; cfgdirty = 1
      printf "set\t%s\t%s\t%s\n", k, V, to
      lg[++nl] = "- " day " · " k " " V " " arrow " " to " · " tail(why)
    }
    for (j = 1; j <= nl; j++) addlog(lg[j])
    if (!nl) cfgdirty = 0
    printf "log\t%s\t%d\n", logrel, nl
  }'
RC=$?
case "$RC" in
  0) ;;
  4) exit "$RC" ;; # another game's block: nothing is written
  *) echo "one-shot-tune: could not read the block or $CFGREL" >&2; exit 1 ;;
esac

if [ -f "$TMPD/config" ]; then cat "$TMPD/config" > "$CFG" || { echo "one-shot-tune: cannot write $CFG" >&2; exit 1; }; fi
if [ -f "$TMPD/log" ]; then
  mkdir -p "$(dirname "$LOG")" && cat "$TMPD/log" > "$LOG" || { echo "one-shot-tune: cannot write $LOG" >&2; exit 1; }
fi
exit 0
