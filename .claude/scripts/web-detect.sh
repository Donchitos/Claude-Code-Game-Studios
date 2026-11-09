#!/usr/bin/env bash
# web-detect.sh — reads an existing web project (a package.json at its root) for
# /setup-engine web: its package manager, the commands its own scripts give, its
# code and test roots, language, bundler, test runner and library, and whether
# the game-state hook is wired in. It reads files only: it writes nothing, runs
# no package manager and installs nothing.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# What to write, what to ask and whether to stop (a workspaces project, two
# lockfiles, no src/) is /setup-engine's call (references/web.md, W1).
#
# Usage: bash .claude/scripts/web-detect.sh [--root DIR] [--pm npm|pnpm|yarn|bun]
#   --root DIR   the project; defaults to the repo this script is in
#   --pm NAME    the package manager the person chose, when the project has two
#                lockfiles (the commands are written for it)
#   -h, --help   this text
#
# Package manager: package.json's `packageManager` field, else the lockfile
# (package-lock.json or npm-shrinkwrap.json npm, pnpm-lock.yaml pnpm, yarn.lock
# yarn, bun.lock or bun.lockb bun); lockfiles of two managers print `?`; none is
# npm. Commands, each in that manager's form: run from the `dev` script, else
# `start`, else `serve`; build from `build`; test from `test` (npm's placeholder,
# "no test specified", is no test); smoke from `smoke`, else the build command
# (a build that compiles is the parse check an existing project has).
#
# Output: TSV, in this order (a row that cannot apply is left out).
#   package_json     present | absent           absent: nothing else (exit 3)
#   workspaces       yes <where> | no           yes: a monorepo, which the framework does not cover
#   lockfile         <file> <manager>           one row per lockfile found
#   package_manager  <npm|pnpm|yarn|bun|?> <source>
#   script           <name> <its text>          dev, start, serve, build, test, smoke
#   command          <run|build|test|smoke|install> <command|-> <script it runs, or why none>
#                                               install: the lockfile's exact install (npm ci,
#                                               pnpm or bun --frozen-lockfile, yarn --frozen-lockfile
#                                               or --immutable); - with no lockfile, which an install writes
#   code_root        <src|-> <why>
#   code_root_candidate <dir>                   with no src/: a folder holding .js or
#                                               .ts files (`.` for the project root)
#   test_root        <dir|-> <table|write> <why>   table: the engine table's tests/,
#                                               nothing to write; write: engine.test_root
#   test_files       <n> <up to 5 folders>      test and spec files outside node_modules
#   language         <TypeScript|JavaScript> <evidence>
#   bundler          <name> <package> <range|-> <evidence>   the first row is the one
#                                               the build uses; - when none is found
#   engine_version   <version|-> <source>       the bundler's, installed, else package.json's
#   test_runner      <vitest|jest|playwright|mocha|ava|uvu|cypress|web-test-runner|jasmine|tap|other|none> <evidence>
#   library          <package> <range>          a game library in the dependencies
#   hook             <present|absent> <file|->  window.game, the game-state hook
#
# Exit codes: 0 read; 1 the root cannot be read; 2 usage error; 3 no
# package.json (not an existing web project). Never prompts.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "web-detect: $1 (try --help)" >&2; exit 2; }
ROOT_ARG=""; PM_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --root|--pm)
      [ $# -ge 2 ] || usage "$1 needs a value"
      case "$1" in --root) ROOT_ARG="$2" ;; --pm) PM_ARG="$2" ;; esac
      shift 2 ;;
    *) usage "unknown argument: $1" ;;
  esac
done
case "$PM_ARG" in ""|npm|pnpm|yarn|bun) ;; *) usage "--pm is npm, pnpm, yarn or bun" ;; esac
if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "web-detect: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "web-detect: cannot reach the repo root" >&2; exit 1; }
fi
[ -f "$HERE/json-flat.awk" ] || { echo "web-detect: $HERE/json-flat.awk is missing" >&2; exit 1; }

if [ ! -f package.json ]; then printf 'package_json\tabsent\n'; exit 3; fi
printf 'package_json\tpresent\n'
TAB=$(printf '\t'); NL='
'
# Read once: package.json flattened (json-flat.awk), then a table per kind, each
# line "<key><TAB><value>". Lookups below are shell only: one process per lookup
# made the helper take seconds on Windows.
FLAT=$(awk -f "$HERE/json-flat.awk" package.json | tr -d '\r')
SCRIPTS_T=$(printf '%s\n' "$FLAT" | awk -F'\t' '$1 == "scripts" && $2 != "" { print $2 "\t" $3 }')
DEPS_T=$(printf '%s\n' "$FLAT" | awk -F'\t' '
  ($1 == "dependencies" || $1 == "devDependencies" || $1 == "peerDependencies" || $1 == "optionalDependencies") && $2 != "" { print $2 "\t" $3 "\t" $1 "." $2 }')
PMF=$(printf '%s\n' "$FLAT" | awk -F'\t' '$1 == "packageManager" && $2 == "" { print $3; exit }')
WS=$(printf '%s\n' "$FLAT" | awk -F'\t' '$1 == "workspaces" { print ($2 == "" ? $3 : $2 "=" $3); exit }')
# tget TABLE KEY — REPLY is the rest of KEY's line (after its tab), or empty.
tget() {
  REPLY=""
  case "$NL$1" in
    *"$NL$2$TAB"*) REPLY="${NL}$1"; REPLY="${REPLY#*"$NL$2$TAB"}"; REPLY="${REPLY%%"$NL"*}" ;;
  esac
}
# script NAME — REPLY is package.json's script of that name, or empty.
script() { tget "$SCRIPTS_T" "$1"; }
# dep NAME — REPLY is "<range><TAB><section>.<name>" for a dependency, or empty.
dep() { tget "$DEPS_T" "$1"; }
# Command words are split on spaces and on / & ; | ( ) and quotes.
_D='[/&;|()"'"'"']'
# word_in TEXT WORD — whether WORD (one word, or two such as "bun build") is a command word in TEXT.
word_in() { _w=" $1 "; _w="${_w//$_D/ }"; _w="${_w//$TAB/ }"; case "$_w" in *" $2 "*) return 0 ;; esac; return 1; }

# --- workspaces ---------------------------------------------------------------
if [ -n "$WS" ]; then printf 'workspaces\tyes\tpackage.json workspaces: %s\n' "$WS"
elif [ -f pnpm-workspace.yaml ]; then printf 'workspaces\tyes\tpnpm-workspace.yaml\n'
else printf 'workspaces\tno\n'; fi

# --- package manager ----------------------------------------------------------
MGRS=""; LOCKS=""
for lf in package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb; do
  [ -f "$lf" ] || continue
  case "$lf" in package-lock.json|npm-shrinkwrap.json) m=npm ;; pnpm-lock.yaml) m=pnpm ;; yarn.lock) m=yarn ;; *) m=bun ;; esac
  printf 'lockfile\t%s\t%s\n' "$lf" "$m"
  LOCKS="${LOCKS:+$LOCKS, }$lf"
  case " $MGRS " in *" $m "*) ;; *) MGRS="${MGRS:+$MGRS }$m" ;; esac
done
PMF_NAME=${PMF%%@*}
PM=""; PM_SRC=""
if [ -n "$PM_ARG" ]; then PM="$PM_ARG"; PM_SRC="--pm"
else
  case "$PMF_NAME" in
    npm|pnpm|yarn|bun) PM="$PMF_NAME"; PM_SRC="packageManager: $PMF" ;;
    *)
      case "$MGRS" in
        "") PM=npm; PM_SRC="no lockfile (npm, the default)" ;;
        *" "*) PM="?"; PM_SRC="lockfiles of more than one manager: $LOCKS" ;;
        *) PM="$MGRS"; PM_SRC="$LOCKS" ;;
      esac ;;
  esac
fi
printf 'package_manager\t%s\t%s\n' "$PM" "$PM_SRC"

# --- scripts and commands -----------------------------------------------------
for s in dev start serve build test smoke; do
  script "$s"; [ -n "$REPLY" ] && printf 'script\t%s\t%s\n' "$s" "$REPLY"
done
# pmcmd SCRIPT — the manager's command for a script.
pmcmd() {
  case "$PM:$1" in
    npm:test) printf 'npm test' ;;
    pnpm:test|yarn:test) printf '%s test' "$PM" ;;
    *) printf '%s run %s' "$PM" "$1" ;;
  esac
}
script test; TS="$REPLY"
if [ "$PM" = "?" ]; then
  for c in run build test smoke install; do printf 'command\t%s\t-\twhich package manager: two lockfiles (--pm)\n' "$c"; done
else
  RUN_S=""; for s in dev start serve; do script "$s"; [ -n "$REPLY" ] && { RUN_S=$s; break; }; done
  if [ -n "$RUN_S" ]; then printf 'command\trun\t%s\tscripts.%s\n' "$(pmcmd "$RUN_S")" "$RUN_S"
  else printf 'command\trun\t-\tno dev, start or serve script\n'; fi
  BUILD_CMD=""
  script build
  if [ -n "$REPLY" ]; then BUILD_CMD=$(pmcmd build); printf 'command\tbuild\t%s\tscripts.build\n' "$BUILD_CMD"
  else printf 'command\tbuild\t-\tno build script\n'; fi
  case "$TS" in
    "") printf 'command\ttest\t-\tno test script\n' ;;
    *"no test specified"*) printf 'command\ttest\t-\tthe test script is npm'"'"'s placeholder (no test specified)\n' ;;
    *) printf 'command\ttest\t%s\tscripts.test\n' "$(pmcmd test)" ;;
  esac
  script smoke
  if [ -n "$REPLY" ]; then printf 'command\tsmoke\t%s\tscripts.smoke\n' "$(pmcmd smoke)"
  elif [ -n "$BUILD_CMD" ]; then printf 'command\tsmoke\t%s\tno smoke script: the build command\n' "$BUILD_CMD"
  else printf 'command\tsmoke\t-\tno smoke or build script\n'; fi
  # The install that changes no file: exactly what the lockfile pins.
  INST=""
  case "$PM" in
    npm) if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then INST="npm ci"; fi ;;
    pnpm) [ -f pnpm-lock.yaml ] && INST="pnpm install --frozen-lockfile" ;;
    yarn) if [ -f yarn.lock ]; then
            case "$PMF" in yarn@[2-9]*|yarn@[1-9][0-9]*) INST="yarn install --immutable" ;; *) INST="yarn install --frozen-lockfile" ;; esac
          fi ;;
    bun) if [ -f bun.lock ] || [ -f bun.lockb ]; then INST="bun install --frozen-lockfile"; fi ;;
  esac
  if [ -n "$INST" ]; then printf 'command\tinstall\t%s\tthe lockfile, unchanged\n' "$INST"
  else printf 'command\tinstall\t-\tno %s lockfile: an install would write one\n' "$PM"; fi
fi

# --- files --------------------------------------------------------------------
# Source files, outside the folders a project does not write by hand.
PRUNE='-name node_modules -o -name .git -o -name dist -o -name dist-single -o -name build -o -name .claude -o -name coverage -o -name .cache -o -name production -o -name docs -o -name design'
SRCF=$(eval "find . \\( $PRUNE \\) -prune -o -type f \\( -name '*.js' -o -name '*.mjs' -o -name '*.ts' -o -name '*.tsx' -o -name '*.jsx' \\) -print" 2>/dev/null | sed 's|^\./||')
TESTPAT='(^|/)[^/]*\.(test|spec)\.[a-z]+$'
# An exact name match: `[ -d src ]` is also true for SRC/ on Windows and macOS.
LS=$(ls -1A . 2>/dev/null)
has_dir() { case "$NL$LS$NL" in *"$NL$1$NL"*) [ -d "$1" ] ;; *) return 1 ;; esac; }
if has_dir src; then
  CROOT=src; printf 'code_root\tsrc\tsrc/ exists (the engine table'"'"'s)\n'
else
  CROOT=""; printf 'code_root\t-\tno src/: the person names it (. for a flat game)\n'
  printf '%s\n' "$SRCF" | grep -v -E "$TESTPAT"'|\.config\.[a-z]+$|^(test|tests|__tests__|e2e)/' \
    | awk -F/ 'NF == 0 { next } NF == 1 { print "."; next } { print $1 }' | sort -u \
    | awk '{ print "code_root_candidate\t" $0 }'
fi
TESTF=$(printf '%s\n' "$SRCF" | grep -E "$TESTPAT"'|(^|/)__tests__/')
TN=0; [ -n "$TESTF" ] && TN=$(printf '%s\n' "$TESTF" | grep -c .)
TDIRS=$(printf '%s\n' "$TESTF" | awk -F/ 'NF == 0 { next } NF == 1 { print "."; next } { print $1 }' | sort -u | head -5 | tr '\n' ' ')
TDIRS=${TDIRS% }
if has_dir tests; then printf 'test_root\ttests\ttable\ttests/ exists\n'
elif has_dir test; then printf 'test_root\ttest\twrite\ttest/ exists, not tests/\n'
elif has_dir __tests__; then printf 'test_root\t__tests__\twrite\t__tests__/ exists, not tests/\n'
elif [ "$TN" -gt 0 ] && [ -n "$CROOT" ] && case "$NL$TESTF" in *"$NL$CROOT/"*) true ;; *) false ;; esac; then
  printf 'test_root\t%s\twrite\tthe tests sit beside the code\n' "$CROOT"
elif [ "$TN" -gt 0 ]; then printf 'test_root\t%s\twrite\tthe first folder holding test files\n' "${TDIRS%% *}"
else printf 'test_root\t-\ttable\tno test files: the engine table'"'"'s tests/\n'; fi
printf 'test_files\t%s\t%s\n' "$TN" "${TDIRS:--}"

# --- language -----------------------------------------------------------------
dep typescript
if [ -f tsconfig.json ]; then printf 'language\tTypeScript\ttsconfig.json\n'
elif [ -n "$REPLY" ]; then printf 'language\tTypeScript\t%s\n' "${REPLY#*"$TAB"}"
else
  case "$NL$SRCF$NL" in
    *.ts"$NL"*|*.tsx"$NL"*) printf 'language\tTypeScript\t.ts files\n' ;;
    *) printf 'language\tJavaScript\tno tsconfig.json, no typescript dependency\n' ;;
  esac
fi

# --- bundler ------------------------------------------------------------------
# name:package pairs; Bun builds with no package (`bun build` in a script). The
# bundler a build, dev, start or serve script names comes first, then the rest
# in this order.
BUNDLERS="Vite:vite webpack:webpack Parcel:parcel Parcel:parcel-bundler esbuild:esbuild Rspack:@rspack/core Rspack:@rspack/cli"
script build; SCRIPTS_TXT="$REPLY"
for s in dev start serve; do script "$s"; SCRIPTS_TXT="$SCRIPTS_TXT ; $REPLY"; done
FOUND=""; FIRST=""; REST=""
for pair in $BUNDLERS; do
  name=${pair%%:*}; pkg=${pair#*:}
  dep "$pkg"; [ -n "$REPLY" ] || continue
  case " $FOUND " in *" $name "*) continue ;; esac
  FOUND="$FOUND $name"
  # The command word: vite, webpack (and webpack-dev-server), parcel, esbuild, rspack.
  case "$pkg" in @rspack/*) w=rspack ;; parcel-bundler) w=parcel ;; *) w=$pkg ;; esac
  row="$name$TAB$pkg$TAB${REPLY%%"$TAB"*}$TAB${REPLY#*"$TAB"}"
  if word_in "$SCRIPTS_TXT" "$w" || word_in "$SCRIPTS_TXT" "$w-dev-server"; then FIRST="$FIRST$row$NL"
  else REST="$REST$row$NL"; fi
done
word_in "$SCRIPTS_TXT" "bun build" && FIRST="${FIRST}Bun$TAB-$TAB-${TAB}bun build in a script$NL"
BROWS="$FIRST$REST"; BROWS=${BROWS%"$NL"}
if [ -n "$BROWS" ]; then
  printf '%s\n' "$BROWS" | awk '{ print "bundler\t" $0 }'
  B1=${BROWS%%"$NL"*}; B_NAME=${B1%%"$TAB"*}; B1=${B1#*"$TAB"}; B_PKG=${B1%%"$TAB"*}; B1=${B1#*"$TAB"}; B_RANGE=${B1%%"$TAB"*}
  IV=""
  if [ "$B_PKG" != - ] && [ -f "node_modules/$B_PKG/package.json" ]; then
    IV=$(awk -f "$HERE/json-flat.awk" "node_modules/$B_PKG/package.json" | awk -F'\t' '$1 == "version" && $2 == "" { print $3; exit }' | tr -d '\r')
  fi
  if [ -n "$IV" ]; then printf 'engine_version\t%s\tnode_modules/%s/package.json\n' "$IV" "$B_PKG"
  elif [ "$B_RANGE" != - ]; then
    V=$(printf '%s' "$B_RANGE" | sed -E 's/^[^0-9]*//; s/[ |].*//')
    printf 'engine_version\t%s\tpackage.json %s (not installed)\n' "${V:--}" "$B_RANGE"
  else printf 'engine_version\t-\tno version for %s\n' "$B_NAME"; fi
else
  printf 'bundler\t-\t-\t-\tnone of Vite, webpack, Parcel, esbuild, Rspack or Bun\n'
  printf 'engine_version\t-\tno bundler\n'
fi

# --- test runner --------------------------------------------------------------
# pm_names TEXT — REPLY is the script names a package manager runs in TEXT
# (npm test, npm run x, pnpm x, yarn run x, bun run x).
pm_names() {
  REPLY=""; _a=""; _x=" $1 "; _x="${_x//$_D/ }"; _x="${_x//$TAB/ }"
  set -f
  for _tok in $_x; do
    if [ "$_a" = pm ] && { [ "$_tok" = run ] || [ "$_tok" = run-script ]; }; then _a=pmrun; continue; fi
    if [ "$_a" = pm ] || [ "$_a" = pmrun ]; then
      case "$_tok" in t|tst) _tok=test ;; esac
      case "$_tok" in -*) ;; *) REPLY="$REPLY $_tok" ;; esac
      _a=""; continue
    fi
    case "$_tok" in npm|pnpm|yarn|bun) _a=pm ;; *) _a="" ;; esac
  done
  set +f
}
# The test script, with each script it runs put in, two deep.
TS_ALL="$TS"; _t="$TS"
for _depth in 1 2; do
  [ -n "$_t" ] || break
  pm_names "$_t"; _names="$REPLY"; _next=""
  for _n in $_names; do script "$_n"; [ -n "$REPLY" ] && _next="$_next ; $REPLY"; done
  TS_ALL="$TS_ALL$_next"; _t="$_next"
done
RUNNERS="vitest:vitest jest:jest playwright:@playwright/test playwright:playwright mocha:mocha ava:ava uvu:uvu cypress:cypress web-test-runner:@web/test-runner jasmine:jasmine tap:tap"
NR=0; SEEN=""
if [ -n "$TS_ALL" ]; then
  for pair in $RUNNERS; do
    name=${pair%%:*}
    case " $SEEN " in *" $name "*) continue ;; esac
    if word_in "$TS_ALL" "$name"; then
      printf 'test_runner\t%s\tthe test script runs it\n' "$name"; NR=$((NR + 1)); SEEN="$SEEN $name"
    fi
  done
  case "$TS_ALL" in *"no test specified"*) ;; *)
    [ "$NR" = 0 ] && { printf 'test_runner\tother\tthe test script: %s\n' "$TS"; NR=1; } ;;
  esac
fi
if [ "$NR" = 0 ]; then
  for pair in $RUNNERS; do
    name=${pair%%:*}; pkg=${pair#*:}
    case " $SEEN " in *" $name "*) continue ;; esac
    dep "$pkg"; [ -n "$REPLY" ] || continue
    printf 'test_runner\t%s\t%s, but no test script runs it\n' "$name" "${REPLY#*"$TAB"}"; NR=$((NR + 1)); SEEN="$SEEN $name"
  done
fi
[ "$NR" = 0 ] && printf 'test_runner\tnone\tno test script and no test runner in the dependencies\n'

# --- library and hook ---------------------------------------------------------
for pkg in phaser three pixi.js @babylonjs/core babylonjs excalibur kaplay kaboom playcanvas matter-js planck howler; do
  dep "$pkg"; [ -n "$REPLY" ] && printf 'library\t%s\t%s\n' "$pkg" "${REPLY%%"$TAB"*}"
done
# `window.game = ` or `(window as any).game = `, outside the tests: one grep over
# the files (/dev/null among them, so an empty list reads nothing from stdin).
HOOKF=$(printf '%s\n' "$SRCF" | grep -vE "$TESTPAT" | grep . | tr '\n' '\0' \
  | xargs -0 grep -lE '(window|globalThis)[^.;=]{0,24}\.game[[:space:]]*=' /dev/null 2>/dev/null | head -1)
if [ -n "$HOOKF" ]; then printf 'hook\tpresent\t%s\n' "$HOOKF"; else printf 'hook\tabsent\t-\n'; fi
exit 0
