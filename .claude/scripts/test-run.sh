#!/usr/bin/env bash
# test-run.sh — run a project's automated tests the way /smoke-check Phase 2
# does, under a timeout, and read the result with that phase's exit-code ladder
# for the engine: the command, the timeout, the exit code, the zero-tests
# marker, the counts, and the ladder row that matched.
#
# Replaces the hand-run test command, `timeout`, exit-code reading and "looks
# like success and is not" cases.
#
# OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/"). The
# `rule` row says which row of the ladder the exit code and output fall on, in
# plain words; PASS, FAIL, NOT ASSESSED and "PASS WITH WARNINGS" stay with
# /smoke-check, which also decides what an unmatched exit code means.
#
# Usage: bash .claude/scripts/test-run.sh <engine> [options]
#   <engine>            godot, unity, unreal or web (any case)
#   --cmd COMMAND       the test command to run, instead of project.yaml's
#                       commands.test or the engine's default
#   --exe PATH          the editor executable (default: the one commands.test
#                       names, for godot only when its name says godot, else
#                       engine.path, else godot / Unity on PATH); for unreal,
#                       the UE root
#   --platform P        unity only: editmode (default) or playmode
#   --timeout SECONDS   default 900; 1800 for unreal
#   --os windows|linux|macos
#                       unreal only: default is read from `uname -s`
#   --filter ROOT       unreal: the automation test root (default: the
#                       .uproject's name); read one test name when unsure.
#                       web, with its two halves: a file or folder under
#                       tests/unit/ runs Vitest on it alone, one under
#                       tests/integration/ runs Playwright on it alone, and an
#                       @tag runs Playwright's tests with that tag
#   --no-build          unreal only: skip the build that comes first
#   --tool T            force the timeout tool: timeout, gtimeout, perl or none (the
#                       tests use this to reach the perl and no-tool paths)
#   --log FILE          keep the runner's output here (default: a temp file); the
#                       import's or the build's output goes to FILE.pre
#   --dry-run           print what would run; run nothing
#   --root DIR          the project; defaults to the repo this script is in
#   -h, --help          this text
#
# The timeout is `timeout`, else `gtimeout`, else perl (the command in its own
# process group, which gets TERM at the timeout and KILL five seconds on, as
# coreutils timeout does), whichever exists first; the `timeout` row names it,
# or `none` when no timeout tool exists and the run is unbounded. An exit of
# 124 (timeout, gtimeout) or 142 (perl) is a timeout.
#
# Before the test run, per engine: godot checks addons/gdUnit4/bin/GdUnitCmdTool.gd,
# then runs the import (`--headless --path . --import`) with the editor
# executable, whether the test command is commands.test or the default; unity
# checks Packages/manifest.json names com.unity.test-framework and deletes the
# old results file; unreal builds the editor target first (it needs the UE root),
# and a build that fails or times out runs no test, because the tests would run
# against the last good binaries or not load at all. A check that fails runs
# nothing and prints why. The import and the build each have a row saying what
# runs, or why it does not, and their output goes to its own log (pre_log), so
# nothing they print is read as the tests' output. web has no step before the
# tests. When its test command is the engine table's (npm test, from
# commands.test or by default) and package.json has the web scaffold's
# test:unit (Vitest) and test:e2e (Playwright) scripts, the two halves run one
# after the other, whatever the first did, each under the timeout, and each is
# read apart:
# Vitest (npm run test:unit) and Playwright (npm run test:e2e: build:single,
# then the browser). Any other web command is read by the runners it reaches
# (the `runner` row): the command, and for a package manager's script (npm test,
# pnpm run x, yarn x, bun run x) package.json's scripts, three deep. Vitest, Jest
# and Playwright are read by their zero-tests line, summary and failing tests;
# any other runner by its exit code only, which the `runner` and `rule` rows
# say. A package manager's test command over a package.json with no test script
# (or npm's placeholder, "no test specified") runs nothing: web:no-test-script.
#
# Output: TSV, in this order (a row that cannot apply is left out).
#   engine      <Godot|Unity|Unreal|Web>
#   exe         <path|->  <commands.test|engine.path|path|--exe|->
#   command     <--cmd|commands.test|default>  <the command>
#   import      <command> | - <skipped: why>                godot, before the tests
#   build       <command> | - <skipped: why>                unreal, before the tests
#   timeout     <seconds>  <timeout|gtimeout|perl|none>
#   runner      <vitest,jest,playwright|other>  <read from>   web, any other command
#   precheck    <what>  <present|absent>
#   import_exit, build_exit   <code>                        when it ran
#   import_timed_out, build_timed_out   <yes|no>            when it ran
#   ran         <yes|no>  <why not, or ->
#   exit        <code of the test command>
#   timed_out   <yes|no>
#   results_file  <path>  <present|absent>                  unity
#   zero_tests  <yes|no|unknown>  <the marker line, or ->   godot, unity, unreal, web halves
#                                                           (yes when either half found none);
#                                                           web by exit code (runner other): `unknown`
#   tests       total=<n> passed=<n> failed=<n>             unity (the <test-run> element),
#                                                           unreal (Result={...} lines), web
#                                                           halves (summed);
#                                                           godot: `-  not sourced`
#   web halves, before the run:
#   half        <unit|e2e>  <command> | - <skipped: why>
#   browser     <path|->  page-shot.sh --which              the browser Playwright launches
#   and after it, per half (unit_..., e2e_...):
#   <h>_exit, <h>_timed_out, <h>_zero_tests <yes|no> <marker>,
#   <h>_tests total=<n> passed=<n> failed=<n>, <h>_log <path>; e2e_build <ok|failed>,
#   e2e_browser <started|failed> <the line>
#   failed      <a line naming a failing test>  (up to 10, then `failed_more <n>`)
#   evidence    <a line that backs the rule>
#   rule        <id>  <what that row of the ladder says>     `-` when no row fits
#   pre_log     <path>                                      when the import or build ran
#   log         <path>
# Rule ids: timeout, runner-unavailable, godot:no-gdunit4, godot:0, godot:0-zero,
# godot:101, godot:100, godot:105, godot:103, godot:104, godot:1, godot:1-no-import,
# unity:no-test-framework, unity:0, unity:zero-tests, unity:no-count,
# unity:no-results, unity:2, unity:1, unity:3, unity:4, unity:other,
# unreal:mac-unsourced, unreal:build-failed, unreal:result-fail,
# unreal:no-tests-matched, unreal:pass, unreal:other-nonzero, web:0, web:nonzero,
# web:pass, web:failed, web:zero-tests, web:build-failed, web:no-browser,
# web:no-test-script.
#
# Exit codes: 0 the helper finished (whatever the tests did: read the rows);
# 1 cannot read the root or write the log; 2 usage error; 3 unknown engine.
# It runs the project's own test command and writes under the project (Unity's
# results file, the engine's caches); it never prompts and never edits
# project.yaml.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
# Byte semantics for awk and sort.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "test-run: $1 (try --help)" >&2; exit 2; }
ENGINE_ARG=""; CMD_ARG=""; EXE_ARG=""; PLATFORM="editmode"; TIMEOUT=""; OS_ARG=""; FILTER=""
NOBUILD=0; LOG=""; DRY=0; ROOT_ARG=""; TOOL_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --dry-run) DRY=1; shift ;;
    --no-build) NOBUILD=1; shift ;;
    --cmd|--exe|--platform|--timeout|--os|--filter|--log|--root|--tool)
      [ $# -ge 2 ] || usage "$1 needs a value"
      case "$1" in
        --cmd) CMD_ARG="$2" ;; --exe) EXE_ARG="$2" ;; --platform) PLATFORM="$2" ;;
        --timeout) TIMEOUT="$2" ;; --os) OS_ARG="$2" ;; --filter) FILTER="$2" ;;
        --log) LOG="$2" ;; --root) ROOT_ARG="$2" ;; --tool) TOOL_ARG="$2" ;;
      esac
      shift 2 ;;
    -?*) usage "unknown argument: $1" ;;
    *) [ -z "$ENGINE_ARG" ] || usage "one engine only"; ENGINE_ARG="$1"; shift ;;
  esac
done
[ -n "$ENGINE_ARG" ] || usage "no engine given"
case "$(printf '%s' "$ENGINE_ARG" | tr 'A-Z' 'a-z')" in
  godot) ENGINE=godot; ENAME=Godot ;;
  unity) ENGINE=unity; ENAME=Unity ;;
  unreal) ENGINE=unreal; ENAME=Unreal ;;
  web) ENGINE=web; ENAME=Web ;;
  *) echo "test-run: '$ENGINE_ARG' is not an engine this knows (godot, unity, unreal, web)" >&2; exit 3 ;;
esac
case "$PLATFORM" in editmode|playmode) ;; *) usage "--platform is editmode or playmode" ;; esac
case "$OS_ARG" in ""|windows|linux|macos) ;; *) usage "--os is windows, linux or macos" ;; esac
# /smoke-check Phase 2's limits: `timeout 900` for a test run, `timeout 1800` for
# Unreal, whose editor build and start-up come before any test.
if [ -z "$TIMEOUT" ]; then if [ "$ENGINE" = unreal ]; then TIMEOUT=1800; else TIMEOUT=900; fi; fi
case "$TIMEOUT" in ''|*[!0-9]*) usage "--timeout is whole seconds" ;; esac
[ "$TIMEOUT" -gt 0 ] || usage "--timeout must be above 0"

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "test-run: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "test-run: cannot reach the repo root" >&2; exit 1; }
fi
[ -f "$HERE/yaml-get.awk" ] || { echo "test-run: $HERE/yaml-get.awk is missing" >&2; exit 1; }
yget() { [ -f project.yaml ] && YG_PATH="$1" awk -f "$HERE/yaml-get.awk" project.yaml; }

printf 'engine\t%s\n' "$ENAME"

# --- the editor executable ----------------------------------------------------
CFG_TEST=$(yget commands.test); ENGINE_PATH=$(yget engine.path)
# exe_ok P — an existing file, or a command found on PATH.
exe_ok() { [ -n "$1" ] && { [ -f "$1" ] || command -v "$1" >/dev/null 2>&1; }; }
EXE=""; EXE_SRC="-"
if [ -n "$EXE_ARG" ]; then
  EXE="$EXE_ARG"; EXE_SRC="--exe"
else
  # The executable commands.test names: its quoted path, else its first word.
  # For Godot it counts only when its file name says godot (godot, godot4,
  # Godot_v4.7-stable_win64.exe): a wrapper such as `bash run-tests.sh` is not
  # the editor, and the import would run it with the editor's flags.
  first=""
  if [ -n "$CFG_TEST" ]; then
    case "$CFG_TEST" in
      \"*) first=${CFG_TEST#\"}; first=${first%%\"*} ;;
      \'*) first=${CFG_TEST#\'}; first=${first%%\'*} ;;
      *) first=${CFG_TEST%% *} ;;
    esac
  fi
  if [ "$ENGINE" = godot ]; then
    _base=${first##*/}; _base=$(printf '%s' "${_base##*\\}" | tr 'A-Z' 'a-z')
    case "$_base" in *godot*) ;; *) first="" ;; esac
  fi
  if [ "$ENGINE" != unreal ] && exe_ok "$first"; then EXE="$first"; EXE_SRC="commands.test"
  elif [ -n "$ENGINE_PATH" ] && { [ "$ENGINE" = unreal ] && [ -d "$ENGINE_PATH" ] || { [ "$ENGINE" != unreal ] && exe_ok "$ENGINE_PATH"; }; }; then EXE="$ENGINE_PATH"; EXE_SRC="engine.path"
  elif [ "$ENGINE" = godot ] && exe_ok godot; then EXE="godot"; EXE_SRC="path"
  elif [ "$ENGINE" = unity ] && exe_ok Unity; then EXE="Unity"; EXE_SRC="path"
  elif [ "$ENGINE" = web ] && exe_ok npm; then EXE="npm"; EXE_SRC="path"
  fi
fi
printf 'exe\t%s\t%s\n' "${EXE:--}" "$EXE_SRC"

# --- timeout tool -------------------------------------------------------------
if [ -n "$TOOL_ARG" ]; then
  case "$TOOL_ARG" in timeout|gtimeout|perl|none) TOOL="$TOOL_ARG" ;; *) usage "--tool is timeout, gtimeout, perl or none" ;; esac
elif command -v timeout >/dev/null 2>&1; then TOOL=timeout
elif command -v gtimeout >/dev/null 2>&1; then TOOL=gtimeout
elif command -v perl >/dev/null 2>&1; then TOOL=perl
else TOOL=none; fi
# The perl fallback does what coreutils timeout does: the command runs in a
# process group of its own, and at the timeout the whole group gets TERM, then
# KILL five seconds on, so an editor that a compound command started (cd x &&
# godot ...) ends with it. It exits 142 (128 + SIGALRM's 14) on a timeout,
# else with the command's own code.
PERL_TIMEOUT='
  my $t = shift @ARGV;
  my $pid = fork;
  defined $pid or die "test-run: fork failed: $!\n";
  if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; }
  setpgrp($pid, $pid);
  my $timed = 0;
  $SIG{ALRM} = sub { if ($timed++) { kill "KILL", -$pid } else { kill "TERM", -$pid; alarm 5 } };
  for my $s (qw(INT TERM HUP)) { $SIG{$s} = sub { kill $_[0], -$pid } }
  alarm $t;
  my $st = 0;
  while (1) {
    my $w = waitpid($pid, 0);
    if ($w == $pid) { $st = $?; last }
    last if $w == -1;
  }
  alarm 0;
  if ($timed) {
    for (1 .. 50) { last unless kill 0, -$pid; select(undef, undef, undef, 0.1) }
    kill "KILL", -$pid if kill 0, -$pid;
    exit 142;
  }
  exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
'
# run_timed SECONDS COMMAND — COMMAND under the timeout tool, output on stdout and stderr.
run_timed() {
  case "$TOOL" in
    timeout|gtimeout) "$TOOL" "$1" bash -c "$2" ;;
    perl) perl -e "$PERL_TIMEOUT" "$1" bash -c "$2" ;;
    *) bash -c "$2" ;;
  esac
}
# is_timeout CODE — whether CODE is the tool's timeout exit: 124 from timeout and
# gtimeout, 142 (128 + SIGALRM's 14) from the perl alarm.
is_timeout() {
  case "$TOOL" in
    timeout|gtimeout) [ "$1" = 124 ] ;;
    perl) [ "$1" = 142 ] ;;
    *) return 1 ;;
  esac
}

# --- the commands -------------------------------------------------------------
ABS=$(pwd -W 2>/dev/null || pwd)
RESULTS=""; BUILD=""; CMD=""; CMD_SRC="default"; PRE_FAIL=""; PRE_ID=""; PRE_WHY=""
case "$ENGINE" in
  web)
    # The engine table's test command (.claude/engines/engines.tsv).
    if [ -f "$HERE/engine-row.awk" ] && [ -f "$HERE/../engines/engines.tsv" ]; then
      CMD=$(awk -F'\t' -v engine=web -v col=test -f "$HERE/engine-row.awk" "$HERE/../engines/engines.tsv")
    fi
    [ -n "$CMD" ] && CMD="$CMD 2>&1"
    ;;
  godot)
    CMD="\"${EXE:-godot}\" --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode 2>&1"
    ;;
  unity)
    if [ "$PLATFORM" = playmode ]; then P=PlayMode; RESULTS=test-results/playmode.xml; else P=EditMode; RESULTS=test-results/editmode.xml; fi
    CMD="\"${EXE:-Unity}\" -batchmode -runTests -projectPath . -testPlatform $P -testResults $RESULTS"
    ;;
  unreal)
    if [ -n "$OS_ARG" ]; then OSN=$OS_ARG
    else case "$(uname -s)" in Linux) OSN=linux ;; Darwin) OSN=macos ;; *) OSN=windows ;; esac; fi
    PROJ=""
    for u in ./*.uproject; do [ -f "$u" ] && { PROJ=${u#./}; PROJ=${PROJ%.uproject}; break; }; done
    [ -n "$FILTER" ] || FILTER="$PROJ"
    case "$OSN" in
      windows)
        BUILD="\"$EXE/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe\" ${PROJ}Editor Win64 Development -Project=\"$ABS/$PROJ.uproject\" 2>&1"
        CMD="\"$EXE/Engine/Binaries/Win64/UnrealEditor-Cmd.exe\" \"$ABS/$PROJ.uproject\" -ExecCmds=\"Automation RunTests $FILTER.; Quit\" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1" ;;
      linux)
        BUILD="\"$EXE/Engine/Build/BatchFiles/Linux/Build.sh\" ${PROJ}Editor Linux Development -Project=\"$ABS/$PROJ.uproject\" 2>&1"
        CMD="\"$EXE/Engine/Binaries/Linux/UnrealEditor\" \"$ABS/$PROJ.uproject\" -ExecCmds=\"Automation RunTests $FILTER.; Quit\" -unattended -nullrhi -stdout -FullStdOutLogOutput 2>&1" ;;
      macos)
        BUILD="\"$EXE/Engine/Build/BatchFiles/Mac/Build.sh\" ${PROJ}Editor Mac Development -Project=\"$ABS/$PROJ.uproject\" 2>&1"
        CMD="" ;;
    esac
    ;;
esac
# commands.test and --cmd win over the default. Unreal keeps the build first.
if [ -n "$CMD_ARG" ]; then CMD="$CMD_ARG"; CMD_SRC="--cmd"
elif [ -n "$CFG_TEST" ]; then CMD="$CFG_TEST"; CMD_SRC="commands.test"; fi
# A Unity results file named in the command is the one to read and to delete first.
if [ "$ENGINE" = unity ] && [ "$CMD_SRC" != default ]; then
  # -E: BSD sed has no \| in a basic regex.
  named=$(printf '%s\n' "$CMD" | sed -n -E 's/.*-testResults[ =]*("[^"]*"|[^ ]*).*/\1/p' | head -1)
  named=${named#\"}; named=${named%\"}
  [ -n "$named" ] && RESULTS="$named"
fi
# Web's two halves: the table's npm test over the web scaffold's test:unit and
# test:e2e scripts. A filter goes to the half it names.
HALVES=0; UNIT_CMD=""; E2E_CMD=""; UNIT_WHY=""; E2E_WHY=""
PJ_FLAT=""
[ "$ENGINE" = web ] && [ -f package.json ] && [ -f "$HERE/json-flat.awk" ] && PJ_FLAT=$(awk -f "$HERE/json-flat.awk" package.json | tr -d '\r')
# pj_script NAME -- package.json's script of that name, or empty.
pj_script() { printf '%s\n' "$PJ_FLAT" | awk -F'\t' -v n="$1" '$1 == "scripts" && $2 == n { print $3; exit }'; }
# script_runs SCRIPT WORD -- whether the script names that command word.
script_runs() { printf ' %s ' "$(pj_script "$1")" | grep -qE "[ /&;|(]$2[ ;&|)]"; }
if [ "$ENGINE" = web ] && { [ "$CMD_SRC" = default ] || [ "$CFG_TEST" = "npm test" ]; } && [ "$CMD_SRC" != --cmd ] \
   && script_runs test:unit vitest && script_runs test:e2e playwright; then
  HALVES=1
  TROOT=$(yget engine.test_root); TROOT=${TROOT:-tests}; TROOT=${TROOT%/}
  case "$FILTER" in
    "") UNIT_CMD="npm run test:unit"; E2E_CMD="npm run test:e2e" ;;
    *\'*) usage "a web --filter cannot hold a single quote" ;;
    "$TROOT"/unit|"$TROOT"/unit/*)
      UNIT_CMD="npm run test:unit -- '$FILTER'"; E2E_WHY="skipped: the filter names a Vitest test" ;;
    "$TROOT"/integration|"$TROOT"/integration/*)
      E2E_CMD="npm run test:e2e -- '$FILTER'"; UNIT_WHY="skipped: the filter names a Playwright test" ;;
    @*) E2E_CMD="npm run test:e2e -- --grep '$FILTER'"; UNIT_WHY="skipped: the filter is a Playwright tag" ;;
    *) usage "a web --filter is a path under $TROOT/unit/ or $TROOT/integration/, or an @tag" ;;
  esac
elif [ "$ENGINE" = web ] && [ -n "$FILTER" ]; then
  usage "a web --filter needs the npm test command and package.json's test:unit and test:e2e scripts"
fi
# Any other web command: the runners it reaches, read from the command and, for
# a package manager's script (npm test, pnpm run x, yarn x, bun run x), from
# package.json's scripts two deep. Vitest, Jest and Playwright are read by their
# output; any other runner by its exit code only.
WEB_RUNNERS=""; WEB_RSRC=""; NO_TEST_SCRIPT=""
if [ "$ENGINE" = web ] && [ "$HALVES" = 0 ] && [ -n "$CMD" ]; then
  _c=${CMD% 2>&1}
  # pm_script TEXT -- the script names a package manager runs in TEXT.
  pm_script() {
    printf '%s\n' "$1" | grep -oE '(^|[;&|( ])(npm|pnpm|yarn|bun) (run |run-script )?[A-Za-z0-9:_.-]+' \
      | awk '{ n = $NF; if (n == "t" || n == "tst") n = "test"; print n }'
  }
  _txt="$_c"; _t="$_c"; _named=""
  for _depth in 1 2 3; do
    _next=""
    for _n in $(pm_script "$_t"); do
      [ "$_depth" = 1 ] && _named="${_named:-$_n}"
      _v=$(pj_script "$_n"); [ -n "$_v" ] && _next="$_next ; $_v"
    done
    [ -n "$_next" ] || break
    _txt="$_txt$_next"; _t="$_next"
  done
  if [ "$_named" = test ] && [ -n "$PJ_FLAT" ]; then
    _ts=$(pj_script test)
    if [ -z "$_ts" ]; then NO_TEST_SCRIPT="package.json has no test script"
    else case "$_ts" in *"no test specified"*) NO_TEST_SCRIPT="package.json's test script is npm's placeholder: $_ts" ;; esac; fi
  fi
  for _r in vitest jest playwright; do
    printf ' %s ' "$_txt" | grep -qE "[ /&;|(\"']$_r[ ;&|)\"']" && WEB_RUNNERS="${WEB_RUNNERS:+$WEB_RUNNERS }$_r"
  done
  if [ -n "$_named" ] && [ -n "$PJ_FLAT" ]; then WEB_RSRC="the command, and package.json's scripts.$_named"
  else WEB_RSRC="the command"; fi
fi
# The step before the tests: Godot's import, Unreal's build.
PRE_NAME=""; PRE_CMD=""; PRE_WHY=""
case "$ENGINE" in
  godot)
    PRE_NAME=import
    if [ -n "$EXE" ]; then PRE_CMD="\"$EXE\" --headless --path . --import"
    else PRE_WHY="skipped: no Godot executable (--exe, commands.test, engine.path, PATH)"; fi ;;
  unreal)
    PRE_NAME=build
    if [ "$NOBUILD" = 1 ]; then PRE_WHY="skipped: --no-build"
    elif [ -z "$EXE" ]; then PRE_WHY="skipped: no UE root (--exe or engine.path)"
    else PRE_CMD="$BUILD"; fi ;;
esac
[ -n "$CMD" ] && printf 'command\t%s\t%s\n' "$CMD_SRC" "$CMD"
if [ -n "$PRE_CMD" ]; then printf '%s\t%s\n' "$PRE_NAME" "$PRE_CMD"
elif [ -n "$PRE_NAME" ]; then printf '%s\t-\t%s\n' "$PRE_NAME" "$PRE_WHY"; fi
printf 'timeout\t%s\t%s\n' "$TIMEOUT" "$TOOL"
if [ "$HALVES" = 1 ]; then
  if [ -n "$UNIT_CMD" ]; then printf 'half\tunit\t%s\n' "$UNIT_CMD"; else printf 'half\tunit\t-\t%s\n' "$UNIT_WHY"; fi
  if [ -n "$E2E_CMD" ]; then printf 'half\te2e\t%s\n' "$E2E_CMD"; else printf 'half\te2e\t-\t%s\n' "$E2E_WHY"; fi
  if [ -n "$E2E_CMD" ]; then
    _br=$(bash "$HERE/page-shot.sh" --which 2>/dev/null | tr -d '\r')
    printf 'browser\t%s\tpage-shot.sh --which\n' "${_br:--}"
  fi
fi
if [ "$ENGINE" = web ] && [ "$HALVES" = 0 ] && [ -n "$CMD" ]; then
  if [ -n "$WEB_RUNNERS" ]; then printf 'runner\t%s\t%s\n' "$(printf '%s' "$WEB_RUNNERS" | tr ' ' ',')" "$WEB_RSRC"
  else printf 'runner\tother\tno Vitest, Jest or Playwright in %s: read by exit code only\n' "$WEB_RSRC"; fi
fi

# --- prechecks ----------------------------------------------------------------
ran_no() { printf 'ran\tno\t%s\n' "$2"; printf 'rule\t%s\t%s\n' "$1" "$3"; exit 0; }
case "$ENGINE" in
  godot)
    if [ -f addons/gdUnit4/bin/GdUnitCmdTool.gd ]; then printf 'precheck\taddons/gdUnit4/bin/GdUnitCmdTool.gd\tpresent\n'
    else
      printf 'precheck\taddons/gdUnit4/bin/GdUnitCmdTool.gd\tabsent\n'
      ran_no godot:no-gdunit4 "gdUnit4 is not installed at addons/gdUnit4/" "gdUnit4 not installed, so no runner was started"
    fi ;;
  unity)
    if [ -f Packages/manifest.json ] && grep -q 'com.unity.test-framework' Packages/manifest.json; then printf 'precheck\tcom.unity.test-framework\tpresent\n'
    else
      printf 'precheck\tcom.unity.test-framework\tabsent\n'
      ran_no unity:no-test-framework "Unity Test Framework is not in Packages/manifest.json" "the Unity Test Framework is not installed; the editor would hang, so it was not started"
    fi ;;
  unreal)
    if [ "$OSN" = macos ] && [ -z "$CMD_ARG" ] && [ -z "$CFG_TEST" ]; then
      printf 'precheck\tmacos test command\tabsent\n'
      ran_no unreal:mac-unsourced "no sourced Unreal test command on macOS and no commands.test" "no sourced Unreal test command on macOS: set commands.test"
    fi ;;
  web)
    [ -n "$CMD" ] || ran_no runner-unavailable "no test command (--cmd, commands.test or the engine table)" "no test command was found, so the tests could not be run here"
    [ -z "$NO_TEST_SCRIPT" ] || ran_no web:no-test-script "$NO_TEST_SCRIPT" "the project has no test script, so no test ran" ;;
esac
if [ -z "$EXE" ] && [ "$CMD_SRC" = default ]; then
  ran_no runner-unavailable "no editor executable (commands.test, engine.path, PATH)" "the engine executable was not found, so the tests could not be run here"
fi
if [ "$DRY" = 1 ]; then printf 'ran\tno\tdry run\n'; exit 0; fi

# --- run ----------------------------------------------------------------------
if [ -z "$LOG" ]; then
  LOG=$(mktemp "${TMPDIR:-/tmp}/test-run-XXXXXX" 2>/dev/null) || { echo "test-run: cannot create a log file" >&2; exit 1; }
fi
: > "$LOG" 2>/dev/null || { echo "test-run: cannot write the log $LOG" >&2; exit 1; }
[ "$ENGINE" = unity ] && [ -n "$RESULTS" ] && rm -f "$RESULTS"

# --- web: the two halves, each run and read apart --------------------------------
if [ "$HALVES" = 1 ]; then
  ESC=$(printf '\033')
  # hl_first HALF PATTERN -- the half's first output line matching the extended regex.
  hl_first() { grep -E -m 1 "$2" "$LOG.$1" 2>/dev/null | head -1 | sed 's/^[[:blank:]]*//'; }
  # hl_num HALF PATTERN -- the number before the word in the half's first line
  # with "<n> <word>", e.g. "2 passed".
  hl_num() { _l=$(grep -E -m 1 "$2" "$LOG.$1" 2>/dev/null); printf '%s\n' "$_l" | sed -n -E "s/.*[^0-9]([0-9]+) $3.*/\\1/p; s/^([0-9]+) $3.*/\\1/p" | head -1; }
  # list_failed_web PATTERN FILE -- up to 10 failing tests as `failed` rows, then the overflow.
  list_failed_web() {
    n=$(grep -E -c "$1" "$2" 2>/dev/null); n=${n:-0}
    grep -E "$1" "$2" 2>/dev/null | head -10 | sed 's/^[[:blank:]]*//' | while IFS= read -r l; do printf 'failed\t%s\n' "$l"; done
    [ "$n" -gt 10 ] && printf 'failed_more\t%s\n' "$((n - 10))"
    return 0
  }
  ANY_TIMED=no; FIRST_BAD=0; TOT=0; TPASS=0; TFAIL=0; ZERO=""; FAILED_HALVES=""
  BUILD_BAD=""; BROWSER_BAD=""
  printf 'ran\tyes\t-\n'
  for H in unit e2e; do
    if [ "$H" = unit ]; then HC="$UNIT_CMD"; else HC="$E2E_CMD"; fi
    [ -n "$HC" ] || continue
    : > "$LOG.$H"
    # NO_COLOR, and the colour codes that still come stripped, so the lines read plainly.
    run_timed "$TIMEOUT" "NO_COLOR=1 $HC 2>&1" 2>&1 | sed "s/${ESC}\\[[0-9;]*[A-Za-z]//g" | tr -d '\r' > "$LOG.$H"
    HCODE=${PIPESTATUS[0]}
    cat "$LOG.$H" >> "$LOG"
    HT=no; is_timeout "$HCODE" && { HT=yes; ANY_TIMED=yes; }
    printf '%s_exit\t%s\n%s_timed_out\t%s\n' "$H" "$HCODE" "$H" "$HT"
    [ "$HCODE" = 0 ] || [ "$FIRST_BAD" != 0 ] || FIRST_BAD=$HCODE
    if [ "$H" = unit ]; then
      zm=$(hl_first unit 'No test files found')
      tl=$(hl_first unit '^[[:blank:]]*Tests[[:blank:]]')
      np=$(hl_num unit '^[[:blank:]]*Tests[[:blank:]]' passed); nf=$(hl_num unit '^[[:blank:]]*Tests[[:blank:]]' failed)
      failpat='^[[:blank:]]*FAIL[[:blank:]]'
    else
      zm=$(hl_first e2e 'No tests found')
      np=$(hl_num e2e '^[[:blank:]]*[0-9]+ passed' passed); nf=$(hl_num e2e '^[[:blank:]]*[0-9]+ failed' failed)
      failpat='^[[:blank:]]*[0-9]+\) '
      bl=$(hl_first e2e 'browserType\.launch|Executable doesn.t exist|Failed to launch')
      if [ -n "$bl" ]; then printf 'e2e_browser\tfailed\t%s\n' "$bl"; BROWSER_BAD="$bl"
      elif grep -qE '^Running [0-9]+ tests? using' "$LOG.e2e"; then printf 'e2e_browser\tstarted\t-\n'; fi
      # No "Running" line and no zero-tests line: build:single failed before Playwright ran.
      if [ "$HCODE" != 0 ] && [ -z "$zm" ] && ! grep -qE '^Running [0-9]+ tests? using' "$LOG.e2e"; then
        printf 'e2e_build\tfailed\n'; BUILD_BAD=$(hl_first e2e 'error TS[0-9]+|error during build|[Ee]rror:')
        [ -n "$BUILD_BAD" ] && printf 'evidence\t%s\n' "$BUILD_BAD"; BUILD_BAD=${BUILD_BAD:-build:single failed}
      else printf 'e2e_build\tok\n'; fi
    fi
    np=${np:-0}; nf=${nf:-0}
    if [ -n "$zm" ]; then printf '%s_zero_tests\tyes\t%s\n' "$H" "$zm"; ZERO="${ZERO:-$zm}"; else printf '%s_zero_tests\tno\t-\n' "$H"; fi
    printf '%s_tests\ttotal=%s passed=%s failed=%s\n' "$H" "$((np + nf))" "$np" "$nf"
    printf '%s_log\t%s\n' "$H" "$LOG.$H"
    TOT=$((TOT + np + nf)); TPASS=$((TPASS + np)); TFAIL=$((TFAIL + nf))
    [ "$nf" -gt 0 ] && FAILED_HALVES="$FAILED_HALVES ${H}"
  done
  printf 'exit\t%s\n' "$FIRST_BAD"
  printf 'timed_out\t%s\n' "$ANY_TIMED"
  if [ -n "$ZERO" ]; then printf 'zero_tests\tyes\t%s\n' "$ZERO"; else printf 'zero_tests\tno\t-\n'; fi
  printf 'tests\ttotal=%s passed=%s failed=%s\n' "$TOT" "$TPASS" "$TFAIL"
  for H in unit e2e; do
    [ -f "$LOG.$H" ] || continue
    if [ "$H" = unit ]; then list_failed_web '^[[:blank:]]*FAIL[[:blank:]]' "$LOG.unit"
    else list_failed_web '^[[:blank:]]*[0-9]+\) ' "$LOG.e2e"; fi
  done
  _names() { printf '%s' "$1" | sed 's/^ //; s/unit/Vitest/; s/e2e/Playwright/; s/ / and /'; }
  if [ "$ANY_TIMED" = yes ]; then RID=timeout; RTX="the run did not complete: timed out after ${TIMEOUT}s, so nothing was verified"
  elif [ -n "$BROWSER_BAD" ]; then RID=web:no-browser; RTX="the browser did not start, so Playwright ran no test: $BROWSER_BAD"
  elif [ -n "$BUILD_BAD" ]; then RID=web:build-failed; RTX="build:single failed, so Playwright ran no test: $BUILD_BAD"
  elif [ -n "$FAILED_HALVES" ]; then RID=web:failed; RTX="a test failed in $(_names "$FAILED_HALVES")"
  elif [ -n "$ZERO" ]; then RID=web:zero-tests; RTX="a half found no tests ($ZERO), which is not a pass"
  elif [ "$FIRST_BAD" = 126 ] || [ "$FIRST_BAD" = 127 ]; then RID=runner-unavailable; RTX="the test command did not start (command not found or not executable)"
  elif [ "$FIRST_BAD" != 0 ]; then RID=web:nonzero; RTX="a half exited $FIRST_BAD with no failed test, zero-tests line or build error read"
  else RID=web:pass; RTX="exit 0 in each half that ran; tests passed: ${TPASS}"; fi
  printf 'rule\t%s\t%s\n' "$RID" "$RTX"
  printf 'log\t%s\n' "$LOG"
  exit 0
fi
PRE_LOG=""; PRE_CODE=""; PRE_TIMED=no
if [ -n "$PRE_CMD" ]; then
  PRE_LOG="$LOG.pre"
  : > "$PRE_LOG" 2>/dev/null || { echo "test-run: cannot write the log $PRE_LOG" >&2; exit 1; }
  run_timed "$TIMEOUT" "$PRE_CMD" > "$PRE_LOG" 2>&1
  PRE_CODE=$?
  is_timeout "$PRE_CODE" && PRE_TIMED=yes
  printf '%s_exit\t%s\n' "$PRE_NAME" "$PRE_CODE"
  printf '%s_timed_out\t%s\n' "$PRE_NAME" "$PRE_TIMED"
fi
# A build that did not finish cleanly runs no test (/smoke-check: a failed build
# is a failure): the editor would load the last good binaries, or none.
if [ "$PRE_NAME" = build ] && [ -n "$PRE_CMD" ] && [ "$PRE_CODE" != 0 ]; then
  if [ "$PRE_TIMED" = yes ]; then
    printf 'ran\tno\tthe editor build timed out after %ss\n' "$TIMEOUT"
    printf 'rule\ttimeout\tthe build did not complete: timed out after %ss, so nothing was verified\n' "$TIMEOUT"
  else
    printf 'ran\tno\tthe editor build failed (exit %s)\n' "$PRE_CODE"
    printf 'rule\tunreal:build-failed\tthe editor build failed, so no test ran\n'
  fi
  printf 'pre_log\t%s\n' "$PRE_LOG"
  exit 0
fi
if [ "$ENGINE" = web ]; then
  # NO_COLOR, and the colour codes that still come stripped, so the lines read plainly.
  ESC=$(printf '\033')
  run_timed "$TIMEOUT" "export NO_COLOR=1; $CMD" 2>&1 | sed "s/${ESC}\\[[0-9;]*[A-Za-z]//g" | tr -d '\r' > "$LOG"
  CODE=${PIPESTATUS[0]}
else
  run_timed "$TIMEOUT" "$CMD" > "$LOG" 2>&1
  CODE=$?
fi
printf 'ran\tyes\t-\n'
printf 'exit\t%s\n' "$CODE"
TIMED=no
is_timeout "$CODE" && TIMED=yes
printf 'timed_out\t%s\n' "$TIMED"

# --- read ---------------------------------------------------------------------
# first_line PATTERN — the first output line matching the extended regex, or empty.
first_line() { grep -E -m 1 "$1" "$LOG" 2>/dev/null | head -1 | tr -d '\r'; }
# list_failed PATTERN FILE — up to 10 matching lines as `failed` rows, then the
# overflow (Phase 2: "names of any failing tests (up to 10; if more, note the count)").
list_failed() {
  n=$(grep -E -c "$1" "$2" 2>/dev/null); n=${n:-0}
  grep -E "$1" "$2" 2>/dev/null | head -10 | tr -d '\r' | while IFS= read -r l; do printf 'failed\t%s\n' "$(printf '%s' "$l" | sed 's/^[[:blank:]]*//')"; done
  [ "$n" -gt 10 ] && printf 'failed_more\t%s\n' "$((n - 10))"
  return 0
}
RULE_ID="-"; RULE_TXT="no row of the ladder fits"
set_rule() { RULE_ID="$1"; RULE_TXT="$2"; }
case "$ENGINE" in
  godot)
    marker=$(first_line 'No test cases found')
    if [ -n "$marker" ]; then printf 'zero_tests\tyes\t%s\n' "$marker"; else printf 'zero_tests\tno\t-\n'; fi
    printf 'tests\t-\tnot sourced: the gdUnit4 summary format is not documented here\n'
    case "$CODE" in
      0) if [ -n "$marker" ]; then set_rule godot:0-zero "exit 0 over zero tests: the runner found no test cases"
         else set_rule godot:0 "exit 0: every test passed"; fi ;;
      101) set_rule godot:101 "every test passed, but a test leaked nodes (orphans)"
           e=$(first_line '[Oo]rphan'); [ -n "$e" ] && printf 'evidence\t%s\n' "$e" ;;
      100) set_rule godot:100 "a test failed" ;;
      105) set_rule godot:105 "a test script does not parse" ;;
      103) set_rule godot:103 "gdUnit4 refused to run headless (--ignoreHeadlessMode missing)" ;;
      104) set_rule godot:104 "Godot is older than 4.3" ;;
      # The ladder reads exit 1 by whether the import ran first: usually it was
      # skipped (the runner needs the class cache it builds); after it, exit 1
      # is Godot's own error.
      1) if [ "$PRE_CODE" = 0 ]; then
           set_rule godot:1 "Godot's own error: GdUnitCmdTool.gd did not load after the import, so no test ran"
         else
           if [ -z "$PRE_CMD" ]; then why="skipped: no Godot executable"
           elif [ "$PRE_TIMED" = yes ]; then why="timed out"
           else why="exit $PRE_CODE"; fi
           set_rule godot:1-no-import "GdUnitCmdTool.gd did not load, so no test ran, and the import did not complete first ($why)"
         fi
         e=$(first_line 'Failed to load script'); [ -n "$e" ] && printf 'evidence\t%s\n' "$e" ;;
      126|127) set_rule runner-unavailable "the editor did not start (command not found or not executable)" ;;
    esac ;;
  unity)
    if [ -f "$RESULTS" ]; then
      printf 'results_file\t%s\tpresent\n' "$RESULTS"
      run_el=$(grep -E -m 1 '<test-run' "$RESULTS" | tr -d '\r')
      attr() { printf '%s\n' "$run_el" | sed -n "s/.*[ <]$1=\"\\([0-9]*\\)\".*/\\1/p" | head -1; }
      total=$(attr testcasecount); passed=$(attr passed); failed=$(attr failed)
      printf 'tests\ttotal=%s passed=%s failed=%s\n' "${total:--}" "${passed:--}" "${failed:--}"
      if [ -z "$total" ]; then printf 'zero_tests\tunknown\tno testcasecount on a <test-run> element\n'
      elif [ "$total" = 0 ]; then printf 'zero_tests\tyes\ttestcasecount="0"\n'; else printf 'zero_tests\tno\t-\n'; fi
      list_failed '<test-case[^>]*result="Failed"' "$RESULTS"
    else
      printf 'results_file\t%s\tabsent\n' "$RESULTS"; total=""
    fi
    case "$CODE" in
      0) if [ ! -f "$RESULTS" ]; then set_rule unity:no-results "exit 0 but no results file was written"
         elif [ -z "$total" ]; then set_rule unity:no-count "exit 0, but the results file has no <test-run> testcasecount, so no test was counted"
         elif [ "$total" = 0 ]; then set_rule unity:zero-tests "testcasecount is 0: no test was compiled or run"
         else set_rule unity:0 "exit 0: every test passed"; fi ;;
      2) set_rule unity:2 "a test failed" ;;
      1) set_rule unity:1 "the project did not compile (see the editor log for error CS lines)" ;;
      3) set_rule unity:3 "the run itself failed" ;;
      4) set_rule unity:4 "an unknown -testPlatform" ;;
      126|127) set_rule runner-unavailable "the editor did not start (command not found or not executable)" ;;
      *) set_rule unity:other "any other non-zero exit" ;;
    esac ;;
  unreal)
    nok=$(grep -E -c 'Result=\{Success\}' "$LOG"); nfail=$(grep -E -c 'Result=\{Fail\}' "$LOG")
    nok=${nok:-0}; nfail=${nfail:-0}
    printf 'tests\ttotal=%s passed=%s failed=%s\n' "$((nok + nfail))" "$nok" "$nfail"
    marker=$(first_line 'No automation tests matched')
    if [ -n "$marker" ]; then printf 'zero_tests\tyes\t%s\n' "$marker"; else printf 'zero_tests\tno\t-\n'; fi
    list_failed 'Result=\{Fail\}' "$LOG"
    if [ "$nfail" -gt 0 ]; then set_rule unreal:result-fail "Result={Fail} on a line of the output"
    elif [ -n "$marker" ]; then set_rule unreal:no-tests-matched "No automation tests matched (a failing test and a run that matched nothing both exit 255)"
    elif [ "$CODE" = 126 ] || [ "$CODE" = 127 ]; then set_rule runner-unavailable "the editor did not start (command not found or not executable)"
    elif [ "$CODE" = 0 ] && [ "$nok" -gt 0 ]; then set_rule unreal:pass "exit 0 with Result={Success} lines"
    elif [ "$CODE" != 0 ]; then set_rule unreal:other-nonzero "a non-zero exit with no Result={Fail} line and no 'no tests matched': no test ran"
    fi ;;
  web)
    if [ -z "$WEB_RUNNERS" ]; then
      printf 'zero_tests\tunknown\tthe web test command is read by its exit code only\n'
      case "$CODE" in
        0) set_rule web:0 "exit 0: the test command passed (read by exit code only, so a run of zero tests looks the same)" ;;
        126|127) set_rule runner-unavailable "the test command did not start (command not found or not executable)" ;;
        *) set_rule web:nonzero "the test command failed (exit $CODE; read by exit code only)" ;;
      esac
    else
      # Each runner's zero-tests line, summary and failing-test lines, from its
      # real output (Vitest 5, Jest 30, Playwright 1.64).
      # num_before PATTERN WORD -- the number before WORD on the first line matching PATTERN.
      num_before() { first_line "$1" | sed -n -E "s/.*[^0-9]([0-9]+) $2.*/\\1/p; s/^([0-9]+) $2.*/\\1/p" | head -1; }
      zm=""; np=0; nf=0; nsf=0; FPAT=""
      for _r in $WEB_RUNNERS; do
        case "$_r" in
          vitest) _z=$(first_line 'No test files found'); _p=$(num_before '^[[:blank:]]*Tests[[:blank:]]+[0-9]' passed)
                  _f=$(num_before '^[[:blank:]]*Tests[[:blank:]]+[0-9]' failed); _fp='^[[:blank:]]*FAIL[[:blank:]]' ;;
          jest)   _z=$(first_line '^No tests found, exiting with code'); _p=$(num_before '^Tests:[[:blank:]]' passed)
                  _f=$(num_before '^Tests:[[:blank:]]' failed); _fp='^[[:blank:]]*● '
                  _s=$(num_before '^Test Suites:[[:blank:]]' failed); nsf=$((nsf + ${_s:-0})) ;;
          playwright) _z=$(first_line '^Error: No tests found'); _p=$(num_before '^[[:blank:]]*[0-9]+ passed' passed)
                  _f=$(num_before '^[[:blank:]]*[0-9]+ failed' failed); _fp='^[[:blank:]]*[0-9]+\) ' ;;
        esac
        zm="${zm:-$_z}"; np=$((np + ${_p:-0})); nf=$((nf + ${_f:-0}))
        FPAT="${FPAT:+$FPAT|}$_fp"
      done
      if [ -n "$zm" ]; then printf 'zero_tests\tyes\t%s\n' "$zm"; else printf 'zero_tests\tno\t-\n'; fi
      printf 'tests\ttotal=%s passed=%s failed=%s\n' "$((np + nf))" "$np" "$nf"
      list_failed "$FPAT" "$LOG"
      _rn=$(printf '%s' "$WEB_RUNNERS" | sed 's/vitest/Vitest/; s/jest/Jest/; s/playwright/Playwright/; s/ /, /g')
      if [ "$nf" -gt 0 ] || [ "$nsf" -gt 0 ]; then set_rule web:failed "a test failed ($_rn)"
      elif [ -n "$zm" ]; then set_rule web:zero-tests "no tests found ($zm), which is not a pass"
      elif [ "$CODE" = 126 ] || [ "$CODE" = 127 ]; then set_rule runner-unavailable "the test command did not start (command not found or not executable)"
      elif [ "$CODE" = 0 ] && [ "$np" -gt 0 ]; then set_rule web:pass "exit 0; tests passed: $np ($_rn)"
      elif [ "$CODE" = 0 ]; then set_rule web:0 "exit 0, but no $_rn summary line was read, so a run of zero tests looks the same"
      else set_rule web:nonzero "the test command failed (exit $CODE) with no failed test or zero-tests line read ($_rn)"; fi
    fi ;;
esac
if [ "$TIMED" = yes ]; then set_rule timeout "the run did not complete: timed out after ${TIMEOUT}s, so nothing was verified"; fi
printf 'rule\t%s\t%s\n' "$RULE_ID" "$RULE_TXT"
[ -n "$PRE_LOG" ] && printf 'pre_log\t%s\n' "$PRE_LOG"
printf 'log\t%s\n' "$LOG"
exit 0
