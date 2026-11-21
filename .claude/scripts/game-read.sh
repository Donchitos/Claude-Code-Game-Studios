#!/usr/bin/env bash
# game-read.sh — what a browser game's files show, for /reverse-document brief
# (references/from-a-game.md) and the door: the page, its scripts, the loop, the inputs, what
# it asks the network for, what is missing, and what cannot be read (minified or bundled code).
# It reads only; it writes nothing.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/"). Which Features
# a game has, and what to call it, is the skill's reading of the code these rows point at.
#
# Usage: bash .claude/scripts/game-read.sh <file or folder> [--root DIR]
#   <file>       one .html file; <folder>: the folder with index.html at its top
#   --root DIR   the project, for a relative path; defaults to the repo this script is in
#   -h, --help   this text
#
# Output: TSV, in this order.
#   page      <path>                         the page read
#   title     <text> | none
#   script    inline <n> <lines> | <path> <lines> <bytes> | module <path> <lines> <bytes>
#   minified  <path or inline n> <why>       rules not read from it: Features from the screenshots
#   network   <url> <asked by>               a file from the network (CDN library, font, image)
#   server    <kind> <where>                 a request to a host (fetch, XMLHttpRequest, EventSource), a WebSocket
#   missing   <path> <asked by>              a local file the page or a script asks for, not there
#   loop      <how> <where> | loop none      requestAnimationFrame, setInterval, setTimeout
#   input     <event> <where> <codes>        a listener, and the key codes its file names
#   count     Math.random|Date.now|performance.now <n>   observations for a later freeze step
#   save      localStorage|indexedDB <n>
#   sound     <what> <n>                     AudioContext, new Audio, <audio>
#   other     Worker|SharedWorker|serviceWorker|iframe <where>   not read
#   states    <values>                       quoted names given to a state, scene, mode or screen
#   todo      <where> <text>                 TODO, FIXME, "coming soon"
#   tune      <where> <name> <value>         a named number: a top-level const or let, upper case
#   files     <scripts read> <lines read>
#
# Exit codes: 0 read; 1 no such file or folder, or no page; 2 usage error.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
use() { echo "game-read: $1 (try --help)" >&2; exit 2; }
SRC=""; ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || use "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) use "unknown argument: $1" ;;
    *) [ -z "$SRC" ] || use "one path only"; SRC="$1"; shift ;;
  esac
done
[ -n "$SRC" ] || use "a game's file or folder is needed"
ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "game-read: no such folder: $ROOT_ARG" >&2; exit 1; }
case "$SRC" in /*|[A-Za-z]:*) ;; *) SRC="$ROOT/$SRC" ;; esac
SRC=${SRC%/}
if [ -f "$SRC" ]; then PAGE=$SRC; DIR=$(dirname "$SRC")
elif [ -f "$SRC/index.html" ]; then PAGE="$SRC/index.html"; DIR=$SRC
else echo "game-read: no page: $SRC is not an .html file or a folder with index.html" >&2; exit 1; fi
T=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/game-read-$$"); mkdir -p "$T"
trap 'rm -rf "$T"' EXIT
rel() { case "$1" in "$DIR"/*) printf '%s' "${1#"$DIR"/}" ;; *) printf '%s' "$1" ;; esac; }

printf 'page\t%s\n' "$(rel "$PAGE")"
TITLE=$(tr -d '\r' < "$PAGE" | tr '\n' ' ' | sed -n 's:.*<[Tt][Ii][Tt][Ll][Ee][^>]*>\([^<]*\)</[Tt][Ii][Tt][Ll][Ee]>.*:\1:p' | sed 's/^ *//; s/ *$//')
printf 'title\t%s\n' "${TITLE:-none}"

# ---- The page's references and inline scripts ----------------------------------------------
# Each inline script goes to its own file; src= and href= values are listed with who asked.
tr -d '\r' < "$PAGE" | awk -v t="$T" '
  { line = $0
    while (match(line, /(src|href)[ \t]*=[ \t]*["\047][^"\047]+["\047]/)) {
      v = substr(line, RSTART, RLENGTH); sub(/^[^"\047]*["\047]/, "", v); sub(/["\047]$/, "", v)
      tag = substr(line, 1, RSTART); print v > (t "/refs"); line = substr(line, RSTART + RLENGTH) }
    l = $0
    if (!ins && match(tolower(l), /<script[^>]*>/)) {
      head = substr(l, RSTART, RLENGTH)
      if (head ~ /src[ \t]*=/) { if (tolower(head) ~ /type[ \t]*=[ \t]*["\047]module/) mod = 1; next }
      ins = 1; n++; f = t "/inline-" n ".js"; printf "" > f; l = substr(l, RSTART + RLENGTH)
      if (tolower(head) ~ /importmap/) { im = 1 }
    }
    if (ins) {
      if (match(tolower(l), /<\/script>/)) { print substr(l, 1, RSTART - 1) >> f; ins = 0; if (im) { system("cp \"" f "\" \"" t "/importmap.json\""); im = 0 } }
      else print l >> f
    }
  }'
[ -f "$T/refs" ] || : > "$T/refs"

# The local scripts the page loads, and the modules they import (one level down).
: > "$T/scripts"
grep -Eio '<script[^>]*src[[:blank:]]*=[[:blank:]]*["'"'"'][^"'"'"']+' "$PAGE" | sed 's/.*src[[:blank:]]*=[[:blank:]]*["'"'"']//' | while IFS= read -r s; do
  case "$s" in http:*|https:*|//*) ;; *) printf '%s\n' "${s%%[?#]*}" ;; esac
done > "$T/srcs"
while IFS= read -r s; do
  s=${s#./}; [ -f "$DIR/$s" ] && printf '%s\n' "$s" >> "$T/scripts"
  [ -f "$DIR/$s" ] && grep -Eo "(import|from)[[:blank:]]*[\"'][^\"']+[\"']" "$DIR/$s" 2>/dev/null | sed "s/.*[\"']\([^\"']*\)[\"']/\1/" | while IFS= read -r m; do
    case "$m" in ./*|../*) p="$(dirname "$s")/$m"; p=$(printf '%s' "$p" | sed 's|/\./|/|g; s|^\./||'); printf '%s\timport\t%s\n' "$p" "$s" >> "$T/imports" ;;
      http:*|https:*|//*) printf '%s\t%s\n' "$m" "$s" >> "$T/net" ;; esac
  done
done < "$T/srcs"
[ -f "$T/imports" ] && cut -f1,3 "$T/imports" | while IFS="$(printf '\t')" read -r p by; do
  if [ -f "$DIR/$p" ]; then grep -qxF "$p" "$T/scripts" || printf '%s\n' "$p" >> "$T/scripts"; else printf 'missing\t%s\t%s\n' "$p" "$by" >> "$T/miss"; fi
done

# ---- Each script: size, and whether it can be read -----------------------------------------
NREAD=0; LREAD=0
for f in "$T"/inline-*.js; do
  [ -f "$f" ] || continue
  n=${f##*/inline-}; n=${n%.js}; L=$(grep -c '' "$f")
  printf 'script\tinline\t%s\t%s\n' "$n" "$L"
  echo "$f	inline $n" >> "$T/read"
done
while IFS= read -r s; do
  [ -n "$s" ] || continue
  L=$(grep -c '' "$DIR/$s"); B=$(wc -c < "$DIR/$s" | tr -d ' ')
  kind=script; grep -qxF "$s" "$T/srcs" || kind=module
  [ "$kind" = script ] && printf 'script\t%s\t%s\t%s\n' "$s" "$L" "$B" || printf 'script\tmodule\t%s\t%s\t%s\n' "$s" "$L" "$B"
  echo "$DIR/$s	$s" >> "$T/read"
done < "$T/scripts"
[ -f "$T/read" ] || : > "$T/read"
while IFS="$(printf '\t')" read -r f name; do
  why=$(awk '{ n++; c += length($0); if (length($0) > m) m = length($0) } /__webpack_require__|webpackJsonp|parcelRequire|System\.register\(|^\/\/# sourceMappingURL=/ { b = 1 }
    END { if (b) print "a bundler built it"; else if (n && c / n > 300) print "minified: lines average " int(c / n) " characters"; else if (m > 2000 && n < 20) print "minified: " n " lines, the longest " m " characters" }' "$f")
  if [ -n "$why" ]; then printf 'minified\t%s\t%s\n' "$name" "$why"; else cat "$f" >> "$T/code"; NREAD=$((NREAD + 1)); LREAD=$((LREAD + $(grep -c '' "$f"))); printf '%s\t%s\n' "$name" "$f" >> "$T/readable"; fi
done < "$T/read"
[ -f "$T/code" ] || : > "$T/code"; [ -f "$T/readable" ] || : > "$T/readable"

# ---- What it asks for: the network, a server, missing files --------------------------------
while IFS= read -r r; do
  case "$r" in
    http:*|https:*|//*) printf '%s\tthe page\n' "$r" >> "$T/net" ;;
    \#*|data:*|mailto:*|javascript:*|"") ;;
    *) p=${r%%[?#]*}; p=${p#./}; [ -e "$DIR/$p" ] || printf 'missing\t%s\tthe page\n' "$p" >> "$T/miss" ;;
  esac
done < "$T/refs"
[ -f "$T/importmap.json" ] && grep -Eo '"(https?:)?//[^"]+"' "$T/importmap.json" | tr -d '"' | while IFS= read -r u; do printf '%s\tthe import map\n' "$u" >> "$T/net"; done
[ -f "$T/net" ] && sort -u "$T/net" | awk -F'\t' '{ print "network\t" $1 "\t" $2 }'
[ -f "$T/miss" ] && sort -u "$T/miss"
# ---- One pass over the readable code: the server, the loop, the inputs, what it uses ---------
# The map file names each readable script; awk reads it first, then every script once.
MAPF="$T/readable"; set --; while IFS="$(printf '\t')" read -r name f; do set -- "$@" "$f"; done < "$MAPF"
{ [ $# -gt 0 ] && awk -v mapf="$MAPF" -v page="$PAGE" '
  BEGIN { FS = "\n"; while ((getline l < mapf) > 0) { split(l, a, "\t"); nm[a[2]] = a[1] }
          while ((getline l < page) > 0) { if (tolower(l) ~ /<audio/) audiotag++; if (tolower(l) ~ /<iframe/) iframe = 1 } }
  function at() { return nm[FILENAME] ":" FNR }
  function first(k) { if (!(k in seen)) { seen[k] = at(); order[++no] = k } }
  { l = $0
    # A server: a request to a host (a local file is not one), or any WebSocket.
    if (l ~ /fetch\([ \t]*["\047`](https?:|\/\/)/) first("server\tfetch")
    if (l ~ /\.open\([^,]*,[ \t]*["\047`](https?:|\/\/)/) first("server\tXMLHttpRequest")
    if (l ~ /new WebSocket\(/) first("server\tWebSocket")
    if (l ~ /new EventSource\([ \t]*["\047`](https?:|\/\/)/) first("server\tEventSource")
    if (l ~ /requestAnimationFrame\(/) first("loop\trequestAnimationFrame")
    if (l ~ /setInterval\(/) first("loop\tsetInterval")
    if (l ~ /setTimeout\(/) first("loop\tsetTimeout")
    n = split("keydown keyup pointerdown mousedown touchstart click gamepadconnected", ev, " ")
    for (i = 1; i <= n; i++) if (index(l, "\"" ev[i] "\"") || index(l, "\047" ev[i] "\047")) first("input\t" ev[i])
    if (l ~ /\.key[^C]|\.key$/) usekey = 1
    s = l; while (match(s, /(Key[A-Z]|Digit[0-9]|Arrow(Up|Down|Left|Right)|Shift(Left|Right)|Space|Enter|Escape|Tab)[^A-Za-z0-9]/)) {
      c = substr(s, RSTART, RLENGTH - 1); if (!(c in code)) { code[c] = 1; codes = codes " " c }; s = substr(s, RSTART + RLENGTH - 1) }
    s = l; while (match(s, /===?[ \t]*["\047]([a-z]|enter|escape|arrow(up|down|left|right)| )["\047]/)) {
      c = substr(s, RSTART, RLENGTH); sub(/^===?[ \t]*["\047]/, "", c); sub(/["\047]$/, "", c); if (c == " ") c = "space"
      if (!(("k:" c) in code)) { code["k:" c] = 1; keys = keys " " c }; s = substr(s, RSTART + RLENGTH) }
    s = l; while (match(s, /Math\.random\(/)) { cr++; s = substr(s, RSTART + RLENGTH) }
    s = l; while (match(s, /Date\.now\(/)) { cd++; s = substr(s, RSTART + RLENGTH) }
    s = l; while (match(s, /performance\.now\(/)) { cp++; s = substr(s, RSTART + RLENGTH) }
    if (l ~ /localStorage/) ls++; if (l ~ /indexedDB/) idb++
    if (l ~ /AudioContext/) ac++; if (l ~ /new Audio\(/) na++
    if (l ~ /new Worker\(/) first("other\tWorker"); if (l ~ /new SharedWorker\(/) first("other\tSharedWorker"); if (l ~ /serviceWorker/) first("other\tserviceWorker")
    s = l; while (match(s, /(state|scene|mode|screen|gameState)[ \t]*==?=?[ \t]*["\047][A-Za-z_-]+["\047]/)) {
      c = substr(s, RSTART, RLENGTH); sub(/^[^"\047]*["\047]/, "", c); sub(/["\047]$/, "", c); if (!(("s:" c) in code) && ns < 20) { code["s:" c] = 1; st = st " " c; ns++ }; s = substr(s, RSTART + RLENGTH) }
    if (l ~ /TODO|FIXME|[Cc]oming [Ss]oon/ && nt < 10) { t = l; sub(/^[ \t]*/, "", t); todo[++nt] = at() "\t" substr(t, 1, 120) }
    if (l ~ /^(const|let|var)[ \t]+[A-Z][A-Z0-9_][A-Z0-9_]+[ \t]*=[ \t]*-?[0-9.]+[ \t]*[,;]/ && nu < 40) { t = l; sub(/^(const|let|var)[ \t]+/, "", t); nmv = t; sub(/[ \t]*=.*/, "", nmv); v = t; sub(/^[^=]*=[ \t]*/, "", v); sub(/[ \t]*[,;].*/, "", v); tune[++nu] = at() "\t" nmv "\t" v }
  }
  END {
    for (i = 1; i <= no; i++) if (order[i] ~ /^server/) print order[i] "\t" seen[order[i]]
    lp = 0; for (i = 1; i <= no; i++) if (order[i] ~ /^loop/) { print order[i] "\t" seen[order[i]]; lp = 1 }
    if (!lp) print "loop\tnone"
    all = codes; if (usekey) all = all keys; sub(/^ /, "", all)
    for (i = 1; i <= no; i++) if (order[i] ~ /^input/) print order[i] "\t" seen[order[i]] "\t" ((order[i] ~ /key(down|up)$/) ? (all == "" ? "-" : all) : "-")
    print "count\tMath.random\t" cr + 0; print "count\tDate.now\t" cd + 0; print "count\tperformance.now\t" cp + 0
    if (ls) print "save\tlocalStorage\t" ls; if (idb) print "save\tindexedDB\t" idb
    if (ac) print "sound\tAudioContext\t" ac; if (na) print "sound\tnew Audio\t" na; if (audiotag) print "sound\t<audio>\t" audiotag
    for (i = 1; i <= no; i++) if (order[i] ~ /^other/) print order[i] "\t" seen[order[i]]
    if (iframe) print "other\tiframe\tthe page"
    if (st != "") { sub(/^ /, "", st); print "states\t" st }
    for (i = 1; i <= nt; i++) print "todo\t" todo[i]
    for (i = 1; i <= nu; i++) print "tune\t" tune[i]
  }' "$@"; } || printf 'loop\tnone\n'
printf 'files\t%s\t%s\n' "$NREAD" "$LREAD"
exit 0
