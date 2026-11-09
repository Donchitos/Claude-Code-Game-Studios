#!/usr/bin/env bash
# vendor-three.sh — put three.js into a one-shot's vendor/ folder so a 3D game plays from a
# double-clicked index.html, offline, and record where it came from.
#
# Replaces the hand-made 3D setup. A browser will not load JavaScript modules from a file
# opened by double-click, and three.js ships only as modules, so with Node.js this bundles
# three.js and the add-ons named into one plain script, vendor/three.js, that sets a global
# THREE. Without Node.js but with curl it downloads the module files instead, and the game
# must then be served (it prints the command). It fetches once; the game never does.
#
# Usage: bash .claude/scripts/vendor-three.sh <game-folder> [add-on ...] [--dry-run] [--root DIR]
#   <game-folder>  the one-shot's folder, for example prototypes/beacon-storm
#   add-on         a path under three.js's examples/jsm, without .js, for example
#                  controls/OrbitControls or loaders/GLTFLoader; each becomes THREE.<name>
#   --dry-run      say which way it would go and what it would bundle; fetch nothing
#   --root DIR     the project; defaults to the repo this script is in
#   -h, --help     this text
#
# Output: TSV.
#   mode      bundled | served          bundled: index.html loads vendor/three.js as a plain
#                                       script; served: an import map and a local server
#   file      <path> <bytes>            each file written under vendor/
#   addon     <name> <bundled|missing>  missing: served mode takes three.js alone
#   serve     <command>                 served mode only
#   origin    <added|kept>              the vendor/three.js entry in assets/provenance.yaml
#   not_done  <why>                     exit 3 or 4
#
# Exit codes: 0 done; 1 the folder is missing; 2 usage error; 3 neither Node.js nor curl is
# installed; 4 the fetch or the bundle failed (offline, or a wrong add-on name).
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

# Pinned so every game gets the same library: the newest releases at least two weeks old on
# 2026-10-25. Moving them is a deliberate change, tested like any other.
THREE_VERSION=0.186.1
ESBUILD_VERSION=0.28.2

HERE="$(cd "$(dirname "$0")" && pwd)"
GAME=""; ADDONS=""; DRY=0; ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --root) [ $# -ge 2 ] || { echo "vendor-three: --root needs a value" >&2; exit 2; }; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "vendor-three: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) if [ -z "$GAME" ]; then GAME="$1"; else
         case "$1" in
           *..*|/*|*[!A-Za-z0-9/_-]*) echo "vendor-three: '$1' is not an add-on path (for example controls/OrbitControls)" >&2; exit 2 ;;
         esac
         ADDONS="$ADDONS $1"
       fi; shift ;;
  esac
done
[ -n "$GAME" ] || { echo "vendor-three: a game folder is needed (try --help)" >&2; exit 2; }
ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "vendor-three: no such folder: $ROOT_ARG" >&2; exit 1; }
GAME="${GAME%/}"
DEST="$ROOT/$GAME"
[ -d "$DEST" ] || { echo "vendor-three: no such game folder: $GAME" >&2; exit 1; }

MODE=""
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then MODE=bundled
elif command -v curl >/dev/null 2>&1; then MODE=served
else printf 'not_done\tneither Node.js nor curl is installed; install Node.js from nodejs.org\n'; exit 3
fi
printf 'mode\t%s\n' "$MODE"

ENTRY="export * from 'three';"
for a in $ADDONS; do ENTRY="$ENTRY
export { ${a##*/} } from 'three/addons/$a.js';"; done
if [ "$DRY" = 1 ]; then
  printf 'entry\t%s\n' "$(printf '%s' "$ENTRY" | tr '\n' ' ')"
  for a in $ADDONS; do printf 'addon\t%s\t%s\n' "${a##*/}" "$([ "$MODE" = bundled ] && echo bundled || echo missing)"; done
  exit 0
fi

mkdir -p "$DEST/vendor" || { echo "vendor-three: cannot make $GAME/vendor" >&2; exit 1; }
WORK=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/vendor-three-$$")
mkdir -p "$WORK"; trap 'rm -rf "$WORK"' EXIT
size() { wc -c < "$1" | tr -d ' '; }

if [ "$MODE" = bundled ]; then
  printf '{"name":"vendor-three","private":true}\n' > "$WORK/package.json"
  printf '%s\n' "$ENTRY" > "$WORK/entry.js"
  # Its own cache: a sandbox can refuse writes to ~/.npm, and npm then fails before it fetches.
  echo "vendor-three: fetching three.js and esbuild from npm (about 20 MB). On a slow connection this can take a few minutes, with retries. Let it finish: do not move it to the background." >&2
  ( cd "$WORK" && npm install --cache "$WORK/npm-cache" --loglevel=error --fetch-retries=4 --no-audit --no-fund \
      "three@$THREE_VERSION" "esbuild@$ESBUILD_VERSION" ) >"$WORK/npm.log" 2>&1 \
    || { printf 'not_done\tnpm could not fetch three@%s and esbuild@%s: %s\n' "$THREE_VERSION" "$ESBUILD_VERSION" "$(grep -m1 -i error "$WORK/npm.log" || tail -1 "$WORK/npm.log")"; exit 4; }
  ( cd "$WORK" && npx --no-install esbuild entry.js --bundle --format=iife --global-name=THREE \
      --minify --legal-comments=eof --log-level=error --outfile=out.js ) >"$WORK/esbuild.log" 2>&1 \
    || { printf 'not_done\tthe bundle failed (a wrong add-on name?): %s\n' "$(head -3 "$WORK/esbuild.log" | tr '\n' ' ')"; exit 4; }
  cp "$WORK/out.js" "$DEST/vendor/three.js" || { echo "vendor-three: cannot write $GAME/vendor/three.js" >&2; exit 1; }
  printf 'file\t%s\t%s\n' "$GAME/vendor/three.js" "$(size "$DEST/vendor/three.js")"
  for a in $ADDONS; do printf 'addon\t%s\tbundled\n' "${a##*/}"; done
  TOOL="esbuild $ESBUILD_VERSION, one plain script for play from a file"
else
  for f in three.module.js three.core.js; do
    curl -fsSL "https://cdn.jsdelivr.net/npm/three@$THREE_VERSION/build/$f" -o "$DEST/vendor/$f" \
      || { printf 'not_done\tcurl could not fetch three@%s/build/%s (offline?)\n' "$THREE_VERSION" "$f"; exit 4; }
    printf 'file\t%s\t%s\n' "$GAME/vendor/$f" "$(size "$DEST/vendor/$f")"
  done
  for a in $ADDONS; do printf 'addon\t%s\tmissing\n' "${a##*/}"; done
  printf 'serve\tpython -m http.server 8000 (in %s), then open http://localhost:8000\n' "$GAME"
  TOOL="downloaded from cdn.jsdelivr.net; play it through a local server"
fi

PROV="$DEST/assets/provenance.yaml"
mkdir -p "$DEST/assets"
if [ -f "$PROV" ] && grep -q '^- path: vendor/three' "$PROV"; then
  printf 'origin\tkept\n'
else
  _p=vendor/three.js; [ "$MODE" = served ] && _p=vendor/three.module.js
  cat >> "$PROV" <<EOF
- path: $_p
  origin: licensed
  source: {product: three.js, version: "$THREE_VERSION", url: https://threejs.org}
  licence: {id: MIT}
  tool: "$TOOL"
  date: $(date +%Y-%m-%d)
  ships: true
EOF
  printf 'origin\tadded\n'
fi
exit 0
