#!/usr/bin/env bash
# one-shot-run.sh — play a one-shot in a headless browser from a fresh start, by an input log
# or by its bot, take a screenshot where the run stops, and report what happened.
#
# The game's folder is copied to a temp folder and one-shot-driver.js is put in front of its
# first script there, so nothing check-related is ever written into the game. The driver fixes
# time and chance, so the same inputs give the same game: one-shot-check.sh reaches any moment
# of a run by playing it again, and the cold play run plays one turn at a time this way. It
# reports; what a row means is the skill's call.
#
# Usage: bash .claude/scripts/one-shot-run.sh <folder> <out.png> [--log TEXT | --bot end|lose]
#            [--stop STEP] [--quiet STEP [--press KEY]] [--trace STEP] [--cap SECONDS]
#            [--seed N] [--limit SECONDS] [--audio SECONDS] [--profile DIR] [--cold [--prev PNG]]
#            [--hookless] [--size WxH] [--root DIR]
#   <folder>       the game's folder, prototypes/<name>
#   <out.png>      where the screenshot goes
#   --log TEXT     inputs, in order: Enter (a press), ArrowRight:1.5 (hold 1.5 s),
#                  ArrowLeft+Space:0.5 (hold both), wait:2, click:640,360 (a point of the
#                  1280x720 window), click:text=Clock_in (the button with these words,
#                  underscores for spaces, scrolled into view); the run stops half a second
#                  after the last one
#   --bot WANT     play with bot.js's BOT.end or BOT.lose instead; stops half a second after
#                  the game leaves its end screen, or five seconds after it reaches one
#   --stop STEP    stop at this step (60 a second); --quiet STEP: no input from this step on
#   --press KEY    with --quiet: press this one key (event.code) at the quiet step, held two
#                  steps as a log's press is (click:x,y once), and nothing after it
#   --trace STEP   from this step on, draw the screen after every step and report its hash
#   --cap SECONDS  the longest a bot run plays, default 600; --seed N: the game's seed
#   --limit SECONDS  real time before the run is cut (done ... real time), default 150
#   --audio SECONDS  render the game's sound offline when the run stops: its first SECONDS
#                  (the game always gets an offline audio context; only this renders it)
#   --profile DIR  a browser profile kept between runs, so a second visit finds the save
#   --hookless     a game without the starter's hook (window.game), such as one brought in by the door:
#                  its requestAnimationFrame and timers are taken over and stepped on the check's
#                  clock, so it is played by --log the same way every time (a hookless row first)
#   --cold         the cold player's view: only the shot, whether the screen changed since
#                  --prev, and whether the game stopped working
#   --size WxH     the window, default 1280x720 (a frame's cost grows with its pixels)
#   --root DIR     the project; defaults to the repo this script is in
#   -h, --help     this text
#
# Output: TSV. page-shot.sh's rows (browser, time, shot, uncaught, console), then one row per
# driver report, its kind first:
#   scene <step> <name>          state <step> <scene> <json>     playinput <step> <keys>
#   end <step> <scene>           left <step> <from> <to>         noexit <step> <scene>
#   stuck <step> <scene> <secs> [staged]                         nonfinite <step> <path> <value>
#   crash <step> <message>       error <step> <message>          botfail <step> <message>
#   badinput <tokens>            ua <browser/version>            webgl <renderer>
#   saved <step> localstorage|indexeddb <key>
#   staged <step> <scene> <what> recovered <step> <scene>        norecover <step> <scene> <what>
#   text <scene> canvas|html <x0,y0,x1,y1> <glyph px at 1080p> <contrast|-> inside|outside <text>
#   textunmapped <scene> <count> screen <step> <scene> <hash> blank|drawn
#   steptime <steps> <mean ms> <slowest ms>   real time of the game's step(1, false) alone, the
#                                drawing left out: the simulation's cost, for a performance claim
#   frametime <frames> <mean ms> <slowest ms> <at step> <over 16.7> <over 50>   play's once-a-second
#                                drawings, each with its step, timed until the pixels are done
#   frame <step> <hash>          (--trace) the screen drawn after that step
#   hookless <how>               (--hookless) the game is stepped through its own loop
#   loop <run> act|result|reward <count> <first step> | repeat|fail|restart <count> | none <why>
#   first <run> show <step> try <step> test <step> | act-in-try <n> | none <why>
#   ending <run> over|results gained|none <what the run gained>
#   digits <run> <font> tabular|proportional <widest less narrowest digit, px>
#   done <step> <scene> <why it stopped> <seconds played> <real ms>
#   audio <seconds> <peak dBFS> <clipped samples> <rms dBFS> <silent %> <sounds>
#   audio none | audio media | audio failed <why>     (--audio only: nothing played; <audio>
#                                elements, which an offline render cannot hear; the render failed)
#   not_assessed <why>
# With --cold only: shot, changed yes|no|first, stopped_working yes|no, not_assessed (and then
# no stopped_working row: nothing ran).
#
# Exit codes: 0 the run finished and the picture was saved; 1 the folder or its index.html is
# missing; 2 usage error; 3 not assessed (no browser, a browser that stopped without a picture,
# no bot.js, a served game); 4 no picture.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR=""; OUT=""; LOGIN=""; BOT=""; STOP=""; QUIET=""; CAP=""; SEED=""; LIMIT=150; COLD=0; PREV=""; ROOT_ARG=""; HAVE_LOG=0; SIZE=1280x720
AUDIO=""; PROFILE=""; PRESS=""; TRACE=""; HOOKLESS=0
need() { [ "$2" -ge 2 ] || { echo "one-shot-run: $1 needs a value" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --log) need "$1" $#; LOGIN="$2"; HAVE_LOG=1; shift 2 ;;
    --bot) need "$1" $#; BOT="$2"; shift 2 ;;
    --stop) need "$1" $#; STOP="$2"; shift 2 ;;
    --quiet) need "$1" $#; QUIET="$2"; shift 2 ;;
    --press) need "$1" $#; PRESS="$2"; shift 2 ;;
    --trace) need "$1" $#; TRACE="$2"; shift 2 ;;
    --cap) need "$1" $#; CAP="$2"; shift 2 ;;
    --size) need "$1" $#; SIZE="$2"; shift 2 ;;
    --seed) need "$1" $#; SEED="$2"; shift 2 ;;
    --limit) need "$1" $#; LIMIT="$2"; shift 2 ;;
    --audio) need "$1" $#; AUDIO="$2"; shift 2 ;;
    --profile) need "$1" $#; PROFILE="$2"; shift 2 ;;
    --prev) need "$1" $#; PREV="$2"; shift 2 ;;
    --cold) COLD=1; shift ;;
    --hookless) HOOKLESS=1; shift ;;
    --root) need "$1" $#; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "one-shot-run: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) if [ -z "$DIR" ]; then DIR="$1"; elif [ -z "$OUT" ]; then OUT="$1"
       else echo "one-shot-run: one folder and one output only" >&2; exit 2; fi; shift ;;
  esac
done
[ -n "$DIR" ] && [ -n "$OUT" ] || { echo "one-shot-run: a folder and an output are needed (try --help)" >&2; exit 2; }
[ -n "$BOT" ] && [ "$HAVE_LOG" = 1 ] && { echo "one-shot-run: --log or --bot, not both" >&2; exit 2; }
[ -z "$BOT" ] && [ "$HAVE_LOG" = 0 ] && { echo "one-shot-run: --log or --bot is needed" >&2; exit 2; }
case "$BOT" in ""|end|lose) ;; *) echo "one-shot-run: --bot is end or lose" >&2; exit 2 ;; esac
for _n in "$STOP" "$QUIET" "$SEED" "$LIMIT" "$AUDIO" "$TRACE"; do case "$_n" in *[!0-9]*) echo "one-shot-run: --stop, --quiet, --trace, --seed, --limit and --audio are whole numbers" >&2; exit 2 ;; esac; done
if [ -n "$PRESS" ]; then
  [ -n "$QUIET" ] || { echo "one-shot-run: --press goes with --quiet: the step it is pressed at" >&2; exit 2; }
  printf '%s' "$PRESS" | grep -Eq '^([A-Za-z0-9]+|click:[0-9]+,[0-9]+|click:text=[^ ]+)$' || { echo "one-shot-run: --press is a key's event.code, click:x,y or click:text=Words" >&2; exit 2; }
fi
case "$LIMIT" in ""|0) echo "one-shot-run: --limit is at least 1" >&2; exit 2 ;; esac
case "$CAP" in *[!0-9.]*) echo "one-shot-run: --cap is a number of seconds" >&2; exit 2 ;; esac

ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "one-shot-run: no such folder: $ROOT_ARG" >&2; exit 1; }
case "$DIR" in /*|[A-Za-z]:*) ;; *) DIR="$ROOT/$DIR" ;; esac
case "$OUT" in /*|[A-Za-z]:*) ;; *) OUT="$ROOT/$OUT" ;; esac
case "$PREV" in ""|/*|[A-Za-z]:*) ;; *) PREV="$ROOT/$PREV" ;; esac
[ -f "$DIR/index.html" ] || { echo "one-shot-run: no index.html in $DIR" >&2; exit 1; }
DRIVER="$HERE/one-shot-driver.js"
[ -f "$DRIVER" ] || { echo "one-shot-run: one-shot-driver.js is missing beside this script" >&2; exit 1; }

if [ -n "$BOT" ] && [ ! -f "$DIR/bot.js" ]; then
  printf 'not_assessed\tno bot.js in the folder: the scripted run needs one\n'; exit 3
fi
# A game that loads modules through an import map is the served 3D kind: a file opened from
# disk cannot load it.
if grep -qi 'importmap' "$DIR/index.html"; then
  printf 'not_assessed\tthe game loads modules (served 3D): a page opened from disk cannot run it\n'; exit 3
fi
grep -qi '<script' "$DIR/index.html" || { printf 'not_assessed\tindex.html has no script to run\n'; exit 3; }

TMP=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-run-$$")
mkdir -p "$TMP/game"
trap 'rm -rf "$TMP"' EXIT
( cd "$DIR" && tar cf - --exclude=./evidence . ) | ( cd "$TMP/game" && tar xf - ) || { echo "one-shot-run: could not copy $DIR" >&2; exit 1; }

# The driver goes in front of the first script; bot.js after it for a bot run.
awk -v drv="$DRIVER" -v bot="$BOT" '
  !done && tolower($0) ~ /<script/ {
    print "<script>"
    while ((getline l < drv) > 0) print l
    print "</script>"
    if (bot != "") print "<script src=\"bot.js\"></script>"
    done = 1
  }
  { print }' "$DIR/index.html" > "$TMP/game/index.html"

enc() { printf '%s' "$1" | awk '
  BEGIN { for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i }
  { s = ""; for (i = 1; i <= length($0); i++) { c = substr($0, i, 1)
      if (c ~ /[A-Za-z0-9._~-]/) s = s c; else s = s sprintf("%%%02X", ord[c]) }
    printf "%s", s }'; }
QUERY="manual=1"
[ -n "$SEED" ] && QUERY="$QUERY&seed=$SEED"
if [ -n "$BOT" ]; then QUERY="$QUERY&bot=$BOT"; else QUERY="$QUERY&log=$(enc "$LOGIN")"; fi
[ -n "$STOP" ] && QUERY="$QUERY&stop=$STOP"
[ -n "$QUIET" ] && QUERY="$QUERY&quiet=$QUIET"
[ -n "$PRESS" ] && QUERY="$QUERY&press=$(enc "$PRESS")"
[ -n "$TRACE" ] && QUERY="$QUERY&trace=$TRACE"
QUERY="$QUERY&limit=$((LIMIT * 1000))"
[ -n "$CAP" ] && QUERY="$QUERY&cap=$CAP"
[ "$HOOKLESS" = 1 ] && QUERY="$QUERY&hookless=1"
[ -n "$AUDIO" ] && [ "$AUDIO" != 0 ] && QUERY="$QUERY&audio=$AUDIO"
KEEP=""; [ -n "$PROFILE" ] && KEEP="--profile"
# The browser takes the picture when the page's time runs out (--wait). A run that renders its
# sound gets a minute of it, so the time cannot run out while the driver holds the page for the
# render: half a second is too short for the sound render.
WAIT=500; [ -n "$AUDIO" ] && [ "$AUDIO" != 0 ] && WAIT=60000

# The browser gets half a minute more than the run, for loading and the picture. WebGL runs in
# software, so a run draws the same pixels on any machine, and with page-shot.sh's render=cheap.
# --once: a real-time retry would play the run again and print its rows twice.
PAGE_SHOT_TIMEOUT=$((LIMIT + 30)) bash "$HERE/page-shot.sh" "$TMP/game/index.html" "$OUT" --query "$QUERY" --wait "$WAIT" --root "$ROOT" --software --once ${KEEP:+"$KEEP" "$PROFILE"} --size "$SIZE" > "$TMP/shot.tsv"
RC=$?

if [ "$COLD" = 1 ]; then
  awk -F'\t' -v prev="$PREV" -v out="$OUT" '
    $1 == "not_assessed" { print; na = 1; next }
    $1 == "shot" { print }
    $1 == "uncaught" && $2 + 0 > 0 { broke = 1 }
    $1 == "console" && ($3 ~ /^RUN\|(crash|error)\|/) { broke = 1 }
    END { if (na) exit; if (broke) print "stopped_working\tyes"; else print "stopped_working\tno" }' "$TMP/shot.tsv"
  if [ "$RC" = 0 ]; then
    if [ -z "$PREV" ] || [ ! -f "$PREV" ]; then printf 'changed\tfirst\n'
    elif cmp -s "$PREV" "$OUT"; then printf 'changed\tno\n'
    else printf 'changed\tyes\n'; fi
  fi
  exit "$RC"
fi

# Driver rows become TSV. The frame is measured again on each resize; only the last
# measurement (measured, text, textunmapped, screen) is the frame in the screenshot.
awk -F'\t' '
  # Two console lines the check itself causes: its own pixel reads, and audio that a
  # synthetic key press is not allowed to start.
  $1 == "console" && ($3 ~ /^Canvas2D: Multiple readback operations/ || $3 ~ /^The AudioContext was not allowed to start/) { next }
  {
    if ($1 == "console" && $3 ~ /^RUN\|/) { r = substr($3, 5); gsub(/\|/, "\t", r) } else r = $0
    n++; line[n] = r; split(r, f, "\t"); kind[n] = f[1]; if (f[1] == "measured") last = n
  }
  END {
    for (i = 1; i <= n; i++) {
      k = kind[i]
      if (i < last && (k == "measured" || k == "text" || k == "textunmapped" || k == "screen")) continue
      print line[i]
    }
  }' "$TMP/shot.tsv"
exit "$RC"
