#!/usr/bin/env bash
# page-shot.sh — open a web game's page in a headless Chrome, Edge or Chromium, save a
# screenshot, and list what the page printed to its console.
#
# Replaces the hand-run browser call: /prototype's build uses it to see its first
# scene; the self-check builds on it. It looks and reports; whether the picture reads, and
# whether a console line matters, is the skill's call.
#
# Usage: bash .claude/scripts/page-shot.sh <page.html> <out.png> [--query TEXT] [--size WxH]
#                                          [--wait MS] [--root DIR] [--profile DIR] [--software]
#                                          [--file-access] [--full] [--once]
#        bash .claude/scripts/page-shot.sh --which
#   <page.html>    the page, relative to the project or absolute
#   <out.png>      where the screenshot goes, relative to the project or absolute
#   --query TEXT   added to the address after ?, for example scene=look or seed=7; render=cheap
#                  follows it unless --full
#   --size WxH     the window, default 1280x720
#   --wait MS      page time before the picture, default 2000; the browser runs the page's
#                  timers and frames on its own clock, so 2000 is two seconds of play
#   --root DIR     the project; defaults to the repo this script is in
#   --profile DIR  a browser profile to keep (made if missing, never deleted), so what the page
#                  saved is there next run; by default each run gets a fresh profile
#   --software     WebGL in software (SwiftShader), so a page draws the same on any machine, a
#                  GPU or none; the self-check's runs use it. Without it WebGL uses the
#                  machine's GPU: a 3D page that draws every frame took 125 s in software
#                  against 3 s on a GPU for two seconds of play
#   --file-access  the page may load the files beside it from disk: module scripts and its own
#                  XHR and fetch (Phaser's loader, for one), which a page opened from disk is
#                  refused (origin null). For an existing project's own build only: a one-shot
#                  is shot without it, as a person who double-clicks it sees it. A path from
#                  the root (/assets/x.png, Vite's default base) still fails from disk
#   --full         leave render=cheap out of the address. Every other shot asks the page for
#                  the cheap render (the starter's CHEAP: a 3D game draws at half resolution
#                  with no shadows, antialiasing or post effects), since software WebGL's cost
#                  grows with pixels and shadows: a three.js city took about 6 s a frame
#                  at full cost. --full is for a shot that judges the look itself
#   --once         no real-time retry after the cap (one-shot-run.sh: a retry would replay its
#                  run and print its rows twice)
#   --which        print the browser a shot would start with, as a full path in the system's
#                  own form (C:\... on Windows), and nothing else; exit 3 with none. A web
#                  project's Playwright config launches it, so every check uses one browser
#   -h, --help     this text
# PAGE_SHOT_BROWSER, when set, is the browser to use; otherwise the usual places are searched,
# with a headless shell last.
# PAGE_SHOT_TIMEOUT, when set, is the seconds a run may take before it is stopped; default 60.
# A shot stopped there with no picture is taken once more in real time: no page time budget, so
# the picture comes when the page has loaded, or at Chrome's --timeout (half the cap) if it has
# not: a capped row, and a picture instead of none. A heavy WebGL page in software can keep a
# page time budget from ever running out: a three.js city gave no picture in 900 s with
# a 2 s budget, and its picture in 66 s this way.
#
# A browser that stops without a picture is tried once more as a headless shell
# (chrome-headless-shell, Chrome's build for automated screenshots), from the PATH or
# Playwright's browsers folder, when one is found. Inside a shell sandbox that refuses Unix
# sockets, as Claude Code's does on Linux and WSL2, Chrome and Chromium stop at launch
# ("socket() failed: Operation not permitted"); the headless shell runs there.
#
# Output: TSV.
#   browser       <path>
#   time          <YYYY-MM-DD HH:MM:SS>   the clock when the picture was taken
#   render        cheap|full                  whether the address asked for the cheap render
#   capped        <cap s> <real s>            the page time budget hit the cap with no picture,
#                                      so the shot was taken in real time, by <real s> at most
#   stopped       <path> <why>         the browser stopped without a picture, and the headless
#                                      shell in the next browser row tries instead
#   shot          <out.png> <bytes>
#   console       <line> <message>     one row per console message, in order
#   uncaught      <count>              messages that are uncaught errors
#   not_assessed  <why>                no browser found, or it stopped without a picture: how
#                                      it stopped and its first FATAL line, and, with no
#                                      headless shell found, "; no headless shell to try
#                                      (<how to install one>)" (exit 3)
#
# Exit codes: 0 the picture was saved; 1 the page is missing or the output folder cannot be
# made; 2 usage error; 3 not assessed: no browser found, or the browser stopped without a
# picture; 4 the browser was stopped after PAGE_SHOT_TIMEOUT seconds (60 by default) with no
# picture, and again in real time (or not retried, with --once): the page did not let it finish.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
PAGE=""; OUT=""; QUERY=""; SIZE="1280x720"; WAIT=2000; ROOT_ARG=""; KEEP=""; SOFT=0; WHICH=0; FILES=0; FULL=0; ONCE=0
need() { [ "$2" -ge 2 ] || { echo "page-shot: $1 needs a value" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --query) need "$1" $#; QUERY="$2"; shift 2 ;;
    --profile) need "$1" $#; KEEP="$2"; shift 2 ;;
    --size) need "$1" $#; SIZE="$2"; shift 2 ;;
    --wait) need "$1" $#; WAIT="$2"; shift 2 ;;
    --root) need "$1" $#; ROOT_ARG="$2"; shift 2 ;;
    --software) SOFT=1; shift ;;
    --file-access) FILES=1; shift ;;
    --full) FULL=1; shift ;;
    --once) ONCE=1; shift ;;
    --which) WHICH=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "page-shot: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) if [ -z "$PAGE" ]; then PAGE="$1"; elif [ -z "$OUT" ]; then OUT="$1"
       else echo "page-shot: one page and one output only" >&2; exit 2; fi; shift ;;
  esac
done
if [ "$WHICH" = 1 ]; then [ -z "$PAGE" ] || { echo "page-shot: --which takes no page" >&2; exit 2; }
else [ -n "$PAGE" ] && [ -n "$OUT" ] || { echo "page-shot: a page and an output are needed (try --help)" >&2; exit 2; }; fi
case "$SIZE" in *[!0-9x]*|*x*x*) SIZE=bad ;; esac
case "$SIZE" in [0-9]*x[0-9]*) ;; *) echo "page-shot: --size is WxH, for example 1280x720" >&2; exit 2 ;; esac
case "$WAIT" in *[!0-9]*|"") echo "page-shot: --wait is a number of milliseconds" >&2; exit 2 ;; esac

WIN=0; command -v cygpath >/dev/null 2>&1 && WIN=1
if [ "$WHICH" = 0 ]; then
  ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "page-shot: no such folder: $ROOT_ARG" >&2; exit 1; }
  case "$PAGE" in /*|[A-Za-z]:*) ;; *) PAGE="$ROOT/$PAGE" ;; esac
  case "$OUT" in /*|[A-Za-z]:*) ;; *) OUT="$ROOT/$OUT" ;; esac
  [ -f "$PAGE" ] || { echo "page-shot: no such page: $PAGE" >&2; exit 1; }
  mkdir -p "$(dirname "$OUT")" || { echo "page-shot: cannot make $(dirname "$OUT")" >&2; exit 1; }
fi
native() { if [ "$WIN" = 1 ]; then cygpath -w "$1"; else printf '%s' "$1"; fi; }

_la=""; [ -n "${LOCALAPPDATA:-}" ] && [ "$WIN" = 1 ] && _la=$(cygpath -u "$LOCALAPPDATA")
find_shell() { # a headless shell: on the PATH, else the newest in Playwright's browsers folder
  command -v chrome-headless-shell >/dev/null 2>&1 && { command -v chrome-headless-shell; return 0; }
  _hs=""
  if [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ]; then set -- "$PLAYWRIGHT_BROWSERS_PATH"
  else set -- "$HOME/.cache/ms-playwright" "$HOME/Library/Caches/ms-playwright" "$_la/ms-playwright"; fi
  for _d in "$@"; do
    for _b in "$_d"/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell \
              "$_d"/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell.exe; do
      [ -f "$_b" ] && _hs="$_b"
    done
  done
  [ -n "$_hs" ] && { printf '%s' "$_hs"; return 0; }
  return 1
}
find_browser() {
  if [ -n "${PAGE_SHOT_BROWSER:-}" ]; then
    [ -x "$PAGE_SHOT_BROWSER" ] || command -v "$PAGE_SHOT_BROWSER" >/dev/null 2>&1 && { printf '%s' "$PAGE_SHOT_BROWSER"; return 0; }
    return 1
  fi
  for _b in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
            "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
            "$_la/Google/Chrome/Application/chrome.exe" \
            "/c/Program Files/Microsoft/Edge/Application/msedge.exe" \
            "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
            "/Applications/Chromium.app/Contents/MacOS/Chromium" \
            "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
    [ -f "$_b" ] && { printf '%s' "$_b"; return 0; }
  done
  for _b in google-chrome google-chrome-stable chromium chromium-browser microsoft-edge msedge; do
    command -v "$_b" >/dev/null 2>&1 && { command -v "$_b"; return 0; }
  done
  find_shell
}
BROWSER=$(find_browser) || {
  if [ "$WHICH" = 1 ]; then
    echo "page-shot: no browser found: Chrome, Edge, Chromium or chrome-headless-shell (set PAGE_SHOT_BROWSER to one)" >&2
    exit 3
  fi
  printf 'not_assessed\tno browser found: Chrome, Edge, Chromium or chrome-headless-shell (set PAGE_SHOT_BROWSER to one)\n'
  exit 3
}
if [ "$WHICH" = 1 ]; then
  # A command name (PAGE_SHOT_BROWSER=chromium, or one found on the PATH) becomes its path.
  case "$BROWSER" in */*) ;; *) BROWSER=$(command -v "$BROWSER") ;; esac
  printf '%s\n' "$(native "$BROWSER")"
  exit 0
fi
printf 'browser\t%s\n' "$BROWSER"
printf 'time\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
if [ "$FULL" = 1 ]; then printf 'render\tfull\n'; else printf 'render\tcheap\n'; fi

# The address: file:///C:/... on Windows, file:///home/... elsewhere, with spaces and the
# other characters an address cannot hold percent-encoded.
if [ "$WIN" = 1 ]; then _abs="/$(cygpath -m "$PAGE")"; else _abs="$(cd "$(dirname "$PAGE")" && pwd)/$(basename "$PAGE")"; fi
URL="file://$(printf '%s' "$_abs" | awk '
  BEGIN { for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i }
  { s = ""; for (i = 1; i <= length($0); i++) { c = substr($0, i, 1)
      if (c ~ /[A-Za-z0-9\/:._~-]/) s = s c; else s = s sprintf("%%%02X", ord[c]) }
    printf "%s", s }')"
# The cheap render, unless --full: the page reads render=cheap (the starter's CHEAP).
[ "$FULL" = 0 ] && QUERY="${QUERY:+$QUERY&}render=cheap"
[ -n "$QUERY" ] && URL="$URL?$QUERY"

WORK=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/page-shot-$$")
mkdir -p "$WORK"
LOG="$WORK/console.log"
trap 'rm -rf "$WORK"' EXIT
if [ -n "$KEEP" ]; then
  case "$KEEP" in /*|[A-Za-z]:*) ;; *) KEEP="$ROOT/$KEEP" ;; esac
  mkdir -p "$KEEP" || { echo "page-shot: cannot make $KEEP" >&2; exit 1; }
  PROFILE="$KEEP"
else
  PROFILE="$WORK/profile"; mkdir -p "$PROFILE"
fi
# A profile of its own each run (fresh, or the kept one), so an open browser window is never
# reused; the timeout stops a page that never lets the headless browser finish.
# Software WebGL (--software): Chromium's docs/gpu/swiftshader.md lists "--use-gl=angle
# --use-angle=swiftshader-webgl --enable-unsafe-swiftshader" as the opt-in, since the automatic
# fallback "has been deprecated"; it is for testing on headless systems, "not intended for
# running untrusted content". The page is the person's own game.
GL=""; [ "$SOFT" = 1 ] && GL="--use-gl=angle --use-angle=swiftshader-webgl --enable-unsafe-swiftshader"
# --file-access: Chrome's switch that lets a file:// page read other files (origin null otherwise).
FA=""; [ "$FILES" = 1 ] && FA="--allow-file-access-from-files"
_to=${PAGE_SHOT_TIMEOUT:-60}; case "$_to" in ""|*[!0-9]*) _to=60 ;; esac
TO=""; command -v timeout >/dev/null 2>&1 && TO="timeout $_to"
# One try with a browser; its log in $LOG. The subshell keeps the shell's own note of a crash
# ("Aborted") out of the rows. TIME is the page time budget, or for the real-time retry the
# real-time cap (Chrome's --timeout: the picture at load, or then if the page has not loaded).
TIME="--virtual-time-budget=$WAIT"
shoot() {
  rm -f "$OUT"
  ( $TO "$1" --headless=new --user-data-dir="$(native "$PROFILE")" --no-first-run \
      --no-default-browser-check --hide-scrollbars --enable-logging=stderr --v=0 $GL \
      $FA \
      --window-size="${SIZE%x*},${SIZE#*x}" $TIME \
      --screenshot="$(native "$OUT")" "$URL" 2>"$LOG" >/dev/null; exit $? ) 2>/dev/null
}
# How the last try stopped, from its exit status (124 is the timeout's) and its first FATAL line.
how_stopped() {
  if [ "$RC" -gt 128 ]; then _h="signal $((RC - 128))"; else _h="exit $RC"; fi
  _f=$(awk '/:FATAL:/ { l = $0; sub(/^\[[^]]*:FATAL:/, "", l); sub(/\] /, ": ", l); gsub(/\t/, " ", l); print l; exit }' "$LOG")
  printf 'the browser stopped without a picture (%s)%s' "$_h" "${_f:+: $_f}"
}
shoot "$BROWSER"; RC=$?
if [ ! -s "$OUT" ] && [ "$RC" != 124 ]; then
  WHY=$(how_stopped)
  if SHELL_B=$(find_shell); then
    if [ "$SHELL_B" != "$BROWSER" ]; then
      printf 'stopped\t%s\t%s\n' "$BROWSER" "$WHY"
      BROWSER=$SHELL_B; printf 'browser\t%s\n' "$BROWSER"
      shoot "$BROWSER"; RC=$?
      [ ! -s "$OUT" ] && [ "$RC" != 124 ] && WHY=$(how_stopped)
    fi
  else
    WHY="$WHY; no headless shell to try (npx playwright install chromium-headless-shell)"
  fi
  # No page ran, so no console rows: an empty console here would read as a clean page.
  if [ ! -s "$OUT" ] && [ "$RC" != 124 ]; then printf 'not_assessed\t%s\n' "$WHY"; exit 3; fi
fi
# Stopped at the cap with no picture: once more in real time, the picture by half the cap (at
# least a second), so a slow renderer still gives a picture to look at.
if [ ! -s "$OUT" ] && [ "$RC" = 124 ] && [ "$ONCE" = 0 ] && [ -n "$TO" ]; then
  _rt=$((_to / 2)); [ "$_rt" -ge 1 ] || _rt=1
  TIME="--timeout=$((_rt * 1000))"
  shoot "$BROWSER"; RC=$?
  [ -s "$OUT" ] && printf 'capped\t%s\t%s\n' "$_to" "$_rt"
fi

# Console lines look like: [..:INFO:CONSOLE:12] "message", source: file:///... (12)
awk '
  /:CONSOLE[:(]/ {
    l = $0; sub(/^[^\]]*\] "/, "", l)
    src = l; sub(/", source: .*$/, "", l); n = src; sub(/^.*\(/, "", n); sub(/\).*$/, "", n)
    gsub(/\t/, " ", l); if (length(l) > 300) l = substr(l, 1, 300) "..."
    printf "console\t%s\t%s\n", n, l
    if (l ~ /^Uncaught/) u++
  }
  END { printf "uncaught\t%d\n", u + 0 }' "$LOG"

if [ -s "$OUT" ]; then
  printf 'shot\t%s\t%s\n' "$OUT" "$(wc -c < "$OUT" | tr -d ' ')"
  exit 0
fi
printf 'shot\t-\t0\n'
exit 4
