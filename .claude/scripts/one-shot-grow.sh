#!/usr/bin/env bash
# one-shot-grow.sh — the parts of /prototype's grow step (references/one-shot-5-grow.md) that a
# script can do: grow a one-shot in prototypes/<name>/ into a web project at the project root.
# Everything is copied out of the one-shot; nothing in prototypes/<name>/ is edited, moved or
# deleted. The skill does the rest: splitting the code, TypeScript, the tests, the commits.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/"). It reports what
# it found, wrote and compared; what to tell the person, and whether to go on, is the skill's.
#
# Usage: bash .claude/scripts/one-shot-grow.sh guard  <name> [--root DIR]
#        bash .claude/scripts/one-shot-grow.sh copy   <name> [--root DIR]
#        bash .claude/scripts/one-shot-grow.sh replay <name> --as WHICH [--stop STEP] [--log TEXT]
#                                                     [--root DIR]
#        bash .claude/scripts/one-shot-grow.sh record <name> [--root DIR]
#        bash .claude/scripts/one-shot-grow.sh accept <name> [--root DIR]
#   guard    the four grow conditions (the grow's guard), each a row; writes nothing
#   copy     the web scaffold's tooling, then the one-shot's page, script, values, assets and
#            feel log, still JavaScript (the guard runs first; a failed check writes nothing)
#   replay   the same-seed scripted run. --as reference plays the one-shot twice, and keeps the
#            first as the reference; --as copy or --as typescript plays dist-single/index.html
#            (npm run build:single) and compares it with the reference. bot.js's BOT.end plays,
#            or --log's inputs (one-shot-run.sh's format) when there is no bot.js. Rows and
#            screenshots go to production/qa/evidence/grow-<name>/. --as story plays the grown
#            game the same way after a story (/dev-story) and compares it with the last run the
#            person accepted (accepted.tsv), or the reference when none was accepted yet
#   accept   the last story run becomes the one later stories are compared with: story.tsv and
#            story.png copied to accepted.tsv and accepted.png (the person said its change was
#            meant)
#   record   project.yaml's engine.name Web and engine.version (Vite's, from package.json),
#            written only when engine.name is unset; a set Web is left as it is. On Web, CLAUDE.md's
#            engine reference import and Technology Stack placeholders too, as /setup-engine does
#   --hookless   a game without the starter's hook (brought in by the door): the runs step its own loop
#                (one-shot-run.sh --hookless); a later replay uses the reference's choice
#   --stop STEP  where the run stops (60 a second), default 3600 (a minute of play); the frames of its last two
#            seconds are compared too. A later replay uses the reference's --stop and --log
#   --root DIR   the project; defaults to the repo this script is in
#   -h, --help   this text
#
# Output: TSV.
#  guard:  guard  node    pass|fail <vX.Y.Z|-> <ok|too-old|absent> <range>
#          guard  engine  pass|fail <name|unset>      unset or Web passes; any other engine fails
#          guard  root    pass|fail <why>             fails on a package.json, a file in the
#                                                     code root (Web's, from the engine table:
#                                                     src/; the template's CLAUDE.md, README.md
#                                                     and .gitkeep do not count), an
#                                                     engine.code_root set to another folder, or
#                                                     a grown/* tag
#          guard  clean   pass|fail <n> <first path>  the one-shot's files have no uncommitted
#                                                     changes (brief.md, evidence/, dist/ aside)
#          guard  git     pass|none                   none: not a git project, no tags
#          one_shot <folder> | not_one_shot <why>     first: the folder this grows from
#          commit <hash>            the last commit of the one-shot's files (git only)
#          tag    one-shot/<name> <hash>|none
#          brief_dirty <path>       the debrief's lines not yet committed (brief.md and its copy)
#  copy:   the guard's rows, then CREATED <path> | EXISTS <path> (never overwritten), and
#          config   <n entries> <n sliders>           data/config.json, one entry a line
#          config_lost <key> <why>                    a value JSON cannot hold (a function...)
#          gitignore <line> added                      a scaffold line the .gitignore lacked
#          left     <what> <detail>                   not carried: the skill's (vendor, scripts)
#          NEEDS    npm_install npm ci
#  replay: run <which> <rows file> <png> <exit>       one row a run (one-shot-run.sh's exit)
#          exact yes | exact no <row>                 reference: the second run against the first
#          match yes | match no <row>                 copy, typescript: against the reference
#          against accepted|reference                 story: the run it was compared with
#          was <row>                                  after a no: the reference's row there. Rows
#                                                     compared: scene, state, the last two seconds'
#                                                     frames, screen, errors, done; never the
#                                                     browser, the time or the save's path
#          match not_assessed <why>                   no reference, or the one-shot's own runs
#                                                     differ (then only screens and errors count)
#          errors <n>                                 crash, error and uncaught rows in the run
#          not_assessed <why>                         nothing was played
#  record: engine written|kept|set <name> [<version>]   set: another engine; nothing is written
#          claude_md written|kept|not_written <why>   on Web: CLAUDE.md's engine import and stack
#  accept: accepted <rows file> <png>                 not_assessed <why> (exit 4): no story run
#
# Exit codes: 0 done (guard: every check passed); 1 a file could not be read or written;
# 2 usage error; 3 a guard check failed (copy: nothing written); 4 replay: not assessed.
#
# bash 3.2 and BWK awk safe, no Python. Node is needed for copy (the guard checks it).

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
GROW="$HERE/../engines/web/grow"
use() { echo "one-shot-grow: $1 (try --help)" >&2; exit 2; }

CMD=""; NAME=""; ROOT_ARG=""; AS=""; STOP=""; LOGIN=""; HAVE_LOG=0; HOOKLESS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || use "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --as) [ $# -ge 2 ] || use "--as needs a value"; AS="$2"; shift 2 ;;
    --stop) [ $# -ge 2 ] || use "--stop needs a value"; STOP="$2"; shift 2 ;;
    --log) [ $# -ge 2 ] || use "--log needs a value"; LOGIN="$2"; HAVE_LOG=1; shift 2 ;;
    --hookless) HOOKLESS=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) use "unknown argument: $1" ;;
    *) if [ -z "$CMD" ]; then CMD="$1"; elif [ -z "$NAME" ]; then NAME="$1"; else use "one command and one name"; fi; shift ;;
  esac
done
case "$CMD" in guard|copy|replay|record|accept) ;; "") use "a command is needed" ;; *) use "unknown command: $CMD" ;; esac
[ -n "$NAME" ] || use "the one-shot's name is needed: prototypes/<name>"
NAME=${NAME#prototypes/}; NAME=${NAME%/}
case "$NAME" in *[!A-Za-z0-9._-]*|.*) use "not a one-shot's folder name: $NAME" ;; esac
if [ "$CMD" = replay ]; then
  case "$AS" in reference|copy|typescript|story) ;; "") use "replay needs --as reference, copy, typescript or story" ;; *) use "--as is reference, copy, typescript or story" ;; esac
else
  [ -z "$AS$STOP" ] && [ "$HAVE_LOG" = 0 ] && [ "$HOOKLESS" = 0 ] || use "--as, --stop, --log and --hookless go with replay"
fi
case "$STOP" in *[!0-9]*) use "--stop is a whole number of steps" ;; esac

ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "one-shot-grow: no such folder: $ROOT_ARG" >&2; exit 1; }
cd "$ROOT" || exit 1
OS="prototypes/$NAME"
EVD="production/qa/evidence/grow-$NAME"
yget() { [ -f "$2" ] && YG_PATH=$1 awk -f "$HERE/yaml-get.awk" "$2"; }
# The grown game's code root: Web's, from the engine table, never a folder written here.
CROOT=$(awk -F'\t' -v engine=Web -v col=code_root -f "$HERE/engine-row.awk" "$HERE/../engines/engines.tsv" 2>/dev/null | tr -d '\r')
isgit() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# ---- guard ---------------------------------------------------------------------------------
# Prints the guard's rows; returns 3 when a check fails.
guard() {
  local fail=0 why n first eng node
  case "$NAME" in
    *-concept|*-spike-*|*-vertical-slice) printf 'not_one_shot\t%s\tan engine or paper prototype: it does not grow\n' "$OS"; return 3 ;;
  esac
  if [ ! -f "$OS/index.html" ]; then
    printf 'not_one_shot\t%s\tno index.html there\n' "$OS"; return 3
  fi
  printf 'one_shot\t%s\n' "$OS"
  [ -f "$OS/config.js" ] || printf 'no_config\t%s\tno config.js (a game brought in by the door): no data/config.json is made\n' "$OS"

  # 1. Node, read the way web-scaffold.sh reads it (its first row), from an empty folder.
  t=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-grow-$$")
  mkdir -p "$t"
  node=$(bash "$HERE/web-scaffold.sh" --dry-run --root "$t" 2>/dev/null | awk -F'\t' '$1 == "node" { print $2 "\t" $3 "\t" $4; exit }')
  rm -rf "$t"
  [ -n "$node" ] || node="-	absent	^22.12 || ^24 || >=26"
  case "$node" in *"	ok	"*) printf 'guard\tnode\tpass\t%s\n' "$node" ;; *) printf 'guard\tnode\tfail\t%s\n' "$node"; fail=1 ;; esac

  # 2. The engine: unset or Web.
  eng=""
  for f in project.local.yaml project.yaml; do [ -n "$eng" ] || eng=$(yget engine.name "$f" | tr -d '\r'); done
  if [ -z "$eng" ] && [ ! -f project.yaml ] && [ -f CLAUDE.md ]; then
    eng=$(grep -m1 -E '^[[:space:]]*-[[:space:]]*\*\*Engine\*\*:' CLAUDE.md | sed 's/.*\*\*Engine\*\*:[[:space:]]*//; s/[[:space:]].*$//' | tr -d '\r')
  fi
  case "$eng" in ""|"["*|*"TO BE CONFIGURED"*) eng="" ;; esac
  case "$eng" in
    "") printf 'guard\tengine\tpass\tunset\n' ;;
    Web) printf 'guard\tengine\tpass\tWeb\n' ;;
    *) printf 'guard\tengine\tfail\t%s\n' "$eng"; fail=1 ;;
  esac

  # 3. The root is not grown already. The code root is Web's, from the engine table: the
  #    grown game is a Web project, and the scaffold's configs build from that folder, so an
  #    engine.code_root naming another folder fails here rather than growing a game that
  #    does not build.
  why=""
  [ -n "$CROOT" ] || why="the engine table has no code root for Web (.claude/engines/engines.tsv)"
  ov=$(yget engine.code_root project.yaml | tr -d '\r')
  case "$ov" in
    ""|"["*|"~"|null|Null|NULL|"$CROOT"|"$CROOT/"|"./$CROOT"|"./$CROOT/") ;;
    *) [ -n "$why" ] || why="engine.code_root is $ov: a grown game's code goes in $CROOT/, Web's code root" ;;
  esac
  [ -z "$why" ] && [ -e package.json ] && why="package.json is at the root"
  [ -z "$why" ] && [ -e index.html ] && why="index.html is at the root (a game left there?)"
  if [ -z "$why" ] && [ -d "$CROOT" ]; then
    first=$(find "$CROOT" -type f ! -path "$CROOT/CLAUDE.md" ! -path "$CROOT/README.md" ! -name .gitkeep 2>/dev/null | head -1)
    [ -n "$first" ] && why="$CROOT/ holds $first"
  fi
  if [ -z "$why" ] && isgit; then
    first=$(git tag -l 'grown/*' 2>/dev/null | head -1)
    [ -n "$first" ] && why="the tag $first is here"
  fi
  if [ -n "$why" ]; then printf 'guard\troot\tfail\t%s\n' "$why"; fail=1; else printf 'guard\troot\tpass\tnot grown\n'; fi

  # 4. No uncommitted changes in the one-shot's files.
  if isgit; then
    printf 'guard\tgit\tpass\n'
    git status --porcelain --untracked-files=all -- "$OS" 2>/dev/null | tr -d '\r' \
      | awk -v os="$OS/" '{ p = substr($0, 4); sub(/^"/, "", p); sub(/"$/, "", p); sub(/.* -> /, "", p)
          r = substr(p, length(os) + 1)
          if (r == "brief.md" || r ~ /^evidence\// || r ~ /^dist\//) next
          n++; if (n == 1) f = p }
        END { printf "%d\t%s\n", n, (n ? f : "-") }' > "$ROOT/.grow-clean.$$"
    n=$(cut -f1 "$ROOT/.grow-clean.$$"); first=$(cut -f2 "$ROOT/.grow-clean.$$"); rm -f "$ROOT/.grow-clean.$$"
    if [ "$n" = 0 ]; then printf 'guard\tclean\tpass\t0\t-\n'; else printf 'guard\tclean\tfail\t%s\t%s\n' "$n" "$first"; fail=1; fi
    first=$(git log -1 --format=%h -- "$OS" 2>/dev/null)
    printf 'commit\t%s\n' "${first:--}"
    first=$(git rev-parse --short "one-shot/$NAME^{commit}" 2>/dev/null)
    printf 'tag\tone-shot/%s\t%s\n' "$NAME" "${first:-none}"
    for f in "$OS/brief.md" design/game-brief.md; do
      [ -f "$f" ] && [ -n "$(git status --porcelain -- "$f" 2>/dev/null)" ] && printf 'brief_dirty\t%s\n' "$f"
    done
  else
    printf 'guard\tgit\tnone\n'
    printf 'guard\tclean\tpass\t0\tnot a git project: the one-shot folder is the backup\n'
  fi
  [ "$fail" = 0 ] || return 3
  return 0
}

# ---- copy ----------------------------------------------------------------------------------
put() { # put <path> <source file> -- a new file, never over one that is there
  if [ -e "$1" ]; then printf 'EXISTS\t%s\n' "$1"; return 0; fi
  mkdir -p "$(dirname "$1")" && cp "$2" "$1" || { printf 'FAILED\t%s\n' "$1"; return 1; }
  printf 'CREATED\t%s\n' "$1"
}

copy() {
  local title slug rc=0 f
  [ -f "$GROW/tune.ts" ] && [ -f "$GROW/config.js" ] || { echo "one-shot-grow: .claude/engines/web/grow/ is missing" >&2; exit 1; }
  t=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-grow-$$"); mkdir -p "$t/s" "$t/w"
  trap 'rm -rf "$t"' EXIT
  title=$(tr -d '\r' < "$OS/index.html" | sed -n 's:.*<title>\(.*\)</title>.*:\1:p' | head -1)
  [ -n "$title" ] || title=$NAME
  slug=$(printf '%s' "$NAME" | tr 'A-Z' 'a-z')

  # The scaffold's tooling, from a copy made in a temp folder: package.json (named after the
  # game), the lockfile, the three configs and the game-state hook. Its page, its square game,
  # its values and its tests are not taken: the one-shot's take their place.
  bash "$HERE/web-scaffold.sh" --root "$t/s" --title "$title" > "$t/scaffold.tsv" 2>&1 || { cat "$t/scaffold.tsv" >&2; exit 1; }
  for f in package.json package-lock.json; do
    # The lockfile names the package twice: at its top and as packages[""].
    awk -v s="$slug" '{ gsub(/"name": "web-game"/, "\"name\": \"" s "\""); print }' "$t/s/$f" > "$t/w/$f"
    put "$f" "$t/w/$f" || rc=1
  done
  for f in vite.config.ts tsconfig.json playwright.config.ts "$CROOT/hook.ts"; do put "$f" "$t/s/$f" || rc=1; done
  if [ -f .gitignore ]; then
    tr -d '\r' < "$t/s/.gitignore" | while IFS= read -r l; do
      [ -n "$l" ] || continue
      tr -d '\r' < .gitignore | grep -qxF "$l" || printf '%s\n' "$l"
    done > "$t/miss"
    if [ -s "$t/miss" ]; then
      { [ -z "$(tail -c 1 .gitignore)" ] || echo; echo; echo '# === Web: Vite, Vitest and Playwright output ==='; cat "$t/miss"; } >> .gitignore
      while IFS= read -r l; do printf 'gitignore\t%s\tadded\n' "$l"; done < "$t/miss"
    fi
  else put .gitignore "$t/s/.gitignore" || rc=1; fi

  # The page: the one-shot's markup and styles; its header, config.js and tune.js tags go, and
  # its one inline script becomes main.js in the code root.
  HASCFG=0; [ -f "$OS/config.js" ] && HASCFG=1
  tr -d '\r' < "$OS/index.html" | awk -v page="$t/w/index.html" -v js="$t/w/main.js" -v cfg="$HASCFG" -v croot="$CROOT" '
    BEGIN { print "// The game: the one-shot'"'"'s script, carried over as it was. The grow step splits it" > js
            print "// by what the code does and moves it to TypeScript." > js
            if (cfg) print "import '"'"'./config.js'"'"';" > js; print "" > js }
    /^[ \t]*<!--[ \t]*(PROTOTYPE - NOT FOR PRODUCTION|Question:|Date:)/ && NR <= 6 { next }
    inl { if ($0 ~ /^[ \t]*<\/script>[ \t]*$/) { inl = 0; next } print > js; next }
    /^[ \t]*<script[ \t]+src="(\.\/)?(config|tune)\.js"[ \t]*><\/script>[ \t]*$/ { next }
    !moved && /^[ \t]*<script>[ \t]*$/ { inl = 1; moved = 1; print "<script type=\"module\" src=\"./" croot "/main.js\"></script>" > page; next }
    /<script/ { tag = $0; sub(/^[ \t]+/, "", tag); print "left\tscript\t" tag }
    { print > page }
    END { if (!moved) print "left\tscript\tno inline script was found: " croot "/main.js holds only the config import" }' > "$t/left"
  cat "$t/left"
  put index.html "$t/w/index.html" || rc=1
  put "$CROOT/main.js" "$t/w/main.js" || rc=1
  if [ "$HASCFG" = 1 ]; then
    put "$CROOT/config.js" "$GROW/config.js" || rc=1
    sed "s/@NAME@/$(basename "$ROOT" | sed 's/[\\/&'"'"']/\\&/g')/" "$GROW/tune.ts" > "$t/w/tune.ts"
    put "$CROOT/dev/tune.ts" "$t/w/tune.ts" || rc=1
  fi

  # The values: config.js's window.CONFIG, read by Node, one entry a line (one-shot-tune.sh
  # reads a grown game's values so); its comments go to data/config-notes.md.
  if [ "$HASCFG" = 0 ]; then :
  elif [ -e data/config.json ]; then printf 'EXISTS\tdata/config.json\n'
  else
    mkdir -p data
    node -e '
      const fs = require("fs"), vm = require("vm");
      const sb = { window: {} }; sb.globalThis = sb; vm.createContext(sb);
      vm.runInContext(fs.readFileSync(process.argv[1], "utf8"), sb, { filename: "config.js", timeout: 2000 });
      const C = sb.window.CONFIG;
      if (!C || typeof C !== "object") { console.error("config.js sets no window.CONFIG"); process.exit(5); }
      const four = ["value", "min", "max", "step"];
      const slider = v => v && typeof v === "object" && four.every(f => typeof v[f] === "number");
      const lost = (v, p) => typeof v === "function" ? p + "\ta function" : typeof v === "number" && !isFinite(v) ? p + "\tnot a finite number" : v === undefined ? p + "\tundefined" :
        v && typeof v === "object" ? Object.keys(v).map(k => lost(v[k], p + "." + k)).find(Boolean) : "";
      const keys = Object.keys(C); let n = 0;
      const lines = keys.map((k, i) => {
        const v = C[k], why = lost(v, k);
        if (why) process.stdout.write("config_lost\t" + why + "\n");
        const body = slider(v) ? "{ " + four.concat(Object.keys(v).filter(f => !four.includes(f))).map(f => JSON.stringify(f) + ": " + JSON.stringify(v[f])).join(", ") + " }" : JSON.stringify(v);
        if (slider(v)) n++;
        return "  " + JSON.stringify(k) + ": " + body + (i < keys.length - 1 ? "," : "");
      });
      fs.writeFileSync(process.argv[2], "{\n" + lines.join("\n") + "\n}\n");
      process.stdout.write("config\t" + keys.length + "\t" + n + "\n");
    ' "$OS/config.js" data/config.json || { printf 'FAILED\tdata/config.json\tconfig.js could not be read by Node\n'; rc=1; }
    [ -f data/config.json ] && printf 'CREATED\tdata/config.json\n'
  fi
  if [ "$HASCFG" = 0 ]; then :
  elif [ ! -e data/config-notes.md ]; then
    tr -d '\r' < "$OS/config.js" | awk -v os="$OS" '
      BEGIN { print "# The values'"'"' notes"; print ""; print "What `" os "/config.js` said beside its values, kept here because `data/config.json`"
              print "holds no comments. The values themselves are in `data/config.json`."; print "" }
      /window\.CONFIG[ \t]*=/ { in_ = 1; next }
      !in_ { next }
      /^\};?[ \t]*$/ { in_ = 0; next }
      /^[ \t]*\/\// { t = $0; sub(/^[ \t]*\/\/[ \t]?/, "", t); print t; next }
      /^[ \t]*$/ { print ""; next }
      { if (match($0, /[ \t]\/\/.*$/)) { c = substr($0, RSTART); sub(/^[ \t]*\/\/[ \t]*/, "", c)
          k = $0; sub(/^[ \t]*["\047]?/, "", k); sub(/["\047]?[ \t]*:.*$/, "", k)
          if (k ~ /^[A-Za-z_$][A-Za-z0-9_$]*$/) print "- `" k "`: " c } }' | cat -s > "$t/w/notes.md"
    put data/config-notes.md "$t/w/notes.md" || rc=1
  else printf 'EXISTS\tdata/config-notes.md\n'; fi

  # Assets, provenance with them; vendor/ is the skill's (a pinned npm dependency).
  if [ -d "$OS/assets" ]; then
    ( cd "$OS" && find assets -type f ) | while IFS= read -r f; do put "$f" "$OS/$f" || exit 1; done || rc=1
  fi
  if [ -d "$OS/vendor" ]; then
    ( cd "$OS" && find vendor -type f ) | while IFS= read -r f; do printf 'left\tvendor\t%s\n' "$f"; done
  fi

  # The feel log, with no prototype header: the grown files are the game now.
  if [ -f "$OS/feel-log.md" ]; then
    tr -d '\r' < "$OS/feel-log.md" | awk 'NR <= 4 && /^<!--[ \t]*(PROTOTYPE - NOT FOR PRODUCTION|Question:|Date:)/ { next } { print }' > "$t/w/feel-log.md"
    put design/feel-log.md "$t/w/feel-log.md" || rc=1
  fi
  [ -d node_modules ] || printf 'NEEDS\tnpm_install\tnpm ci\n'
  [ "$rc" = 0 ] || exit 1
}

# ---- replay --------------------------------------------------------------------------------
# The rows two runs are compared on: what happened in the game, never the browser or the clock.
norm() {
  awk -F'\t' '
    $1 ~ /^(scene|state|frame|screen|end|left|noexit|stuck|crash|error|playinput|nonfinite|staged|recovered|norecover|badinput)$/ { print; next }
    $1 == "uncaught" { print $1 "\t" $2; next }
    $1 == "done" { print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 }' "$1"
}
firstdiff() { # firstdiff <a> <b> -- the first row of b that differs, then "was" and a's row there
  norm "$1" > "$1.n"; norm "$2" > "$2.n"
  awk 'NR == FNR { a[FNR] = $0; na = FNR; next }
       { if (!(FNR in a) || a[FNR] != $0) { print; print "was\t" (FNR in a ? a[FNR] : "(no row: the reference stopped)"); d = 1; exit } nb = FNR }
       END { if (!d && nb < na) { print "(no row: the run stopped early)"; print "was\t" a[nb + 1] } }' "$1.n" "$2.n"
  rm -f "$1.n" "$2.n"
}
said() { # said <row> <firstdiff output> -- "<row> yes", or "<row> no <row>" and the was row
  if [ -z "$2" ]; then printf '%s\tyes\n' "$1"
  else printf '%s\tno\t%s\n' "$1" "$(printf '%s\n' "$2" | head -1)"; printf '%s\n' "$2" | sed -n 2p; fi
}

replay() {
  local stop dir rc d base
  mkdir -p "$EVD" || exit 1
  if [ "$AS" = reference ]; then
    stop=${STOP:-3600}
    { printf 'stop\t%s\n' "$stop"; [ "$HAVE_LOG" = 1 ] && printf 'log\t%s\n' "$LOGIN"; [ "$HOOKLESS" = 1 ] && printf 'hookless\t1\n'; } > "$EVD/replay.args"
  else
    [ -f "$EVD/replay.args" ] || { printf 'match\tnot_assessed\tno reference run: replay --as reference first\n'; exit 4; }
    stop=$(awk -F'\t' '$1 == "stop" { print $2 }' "$EVD/replay.args")
    grep -q '^hookless	' "$EVD/replay.args" && HOOKLESS=1
    if [ "$HAVE_LOG" = 0 ] && grep -q '^log	' "$EVD/replay.args"; then LOGIN=$(awk -F'\t' '$1 == "log" { sub(/^log\t/, ""); print }' "$EVD/replay.args"); HAVE_LOG=1; fi
  fi
  [ "$stop" -gt 120 ] 2>/dev/null || { printf 'not_assessed\t--stop must be past 120 steps\n'; exit 4; }
  if [ "$HAVE_LOG" = 1 ]; then set -- --log "$LOGIN"
  elif [ -f "$OS/bot.js" ]; then set -- --bot end
  else printf 'not_assessed\tno bot.js in %s and no --log: nothing plays the game\n' "$OS"; exit 4; fi
  set -- "$@" --stop "$stop" --trace $((stop - 120))
  [ "$HOOKLESS" = 1 ] && set -- "$@" --hookless

  t=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-grow-$$"); mkdir -p "$t/game"
  trap 'rm -rf "$t"' EXIT
  if [ "$AS" = reference ]; then dir=$OS
  else
    [ -f dist-single/index.html ] || { printf 'not_assessed\tno dist-single/index.html: npm run build:single first\n'; exit 4; }
    cp dist-single/index.html "$t/game/index.html" || exit 1
    [ -f "$OS/bot.js" ] && cp "$OS/bot.js" "$t/game/bot.js"
    dir="$t/game"
  fi

  bash "$HERE/one-shot-run.sh" "$dir" "$EVD/$AS.png" "$@" --root "$ROOT" > "$EVD/$AS.tsv" 2>"$t/err"; rc=$?
  printf 'run\t%s\t%s\t%s\t%s\n' "$AS" "$EVD/$AS.tsv" "$EVD/$AS.png" "$rc"
  if [ "$rc" = 3 ] || [ ! -s "$EVD/$AS.tsv" ]; then
    awk -F'\t' '$1 == "not_assessed"' "$EVD/$AS.tsv"
    [ -s "$t/err" ] && sed 's/^/not_assessed\t/' "$t/err" | head -3
    exit 4
  fi
  printf 'errors\t%s\n' "$(awk -F'\t' '$1 == "crash" || $1 == "error" || ($1 == "uncaught" && $2 + 0 > 0) { n++ } END { print n + 0 }' "$EVD/$AS.tsv")"

  if [ "$AS" = reference ]; then
    bash "$HERE/one-shot-run.sh" "$dir" "$t/again.png" "$@" --root "$ROOT" > "$EVD/reference-again.tsv" 2>/dev/null
    printf 'run\treference-again\t%s\t-\t%s\n' "$EVD/reference-again.tsv" "$?"
    d=$(firstdiff "$EVD/reference.tsv" "$EVD/reference-again.tsv")
    said exact "$d"
    if [ -z "$d" ]; then echo yes > "$EVD/exact"; else echo no > "$EVD/exact"; fi
    return 0
  fi
  [ -f "$EVD/reference.tsv" ] || { printf 'match\tnot_assessed\tno reference run: replay --as reference first\n'; return 0; }
  if [ "$(cat "$EVD/exact" 2>/dev/null)" != yes ]; then
    printf 'match\tnot_assessed\tthe one-shot'"'"'s own two runs differ, so no run can match it exactly\n'; return 0
  fi
  base=reference
  [ "$AS" = story ] && [ -f "$EVD/accepted.tsv" ] && base=accepted
  [ "$AS" = story ] && printf 'against\t%s\n' "$base"
  said match "$(firstdiff "$EVD/$base.tsv" "$EVD/$AS.tsv")"
}

# ---- accept --------------------------------------------------------------------------------
accept() {
  [ -f "$EVD/story.tsv" ] || { printf 'not_assessed\tno story run: replay --as story first\n'; exit 4; }
  cp "$EVD/story.tsv" "$EVD/accepted.tsv" || exit 1
  [ -f "$EVD/story.png" ] && { cp "$EVD/story.png" "$EVD/accepted.png" || exit 1; }
  printf 'accepted\t%s\t%s\n' "$EVD/accepted.tsv" "$EVD/accepted.png"
}

# ---- record --------------------------------------------------------------------------------
record() {
  local eng ver
  eng=$(yget engine.name project.yaml | tr -d '\r')
  case "$eng" in "["*|*"TO BE CONFIGURED"*) eng="" ;; esac
  ver=$(tr -d '\r' < package.json 2>/dev/null | sed -n 's/^[[:blank:]]*"vite":[[:blank:]]*"\([^"]*\)".*/\1/p' | head -1)
  if [ -n "$eng" ]; then
    if [ "$eng" = Web ]; then printf 'engine\tkept\tWeb\n'; claude_md "$ver"; else printf 'engine\tset\t%s\n' "$eng"; fi
    return 0
  fi
  [ -f project.yaml ] || { printf 'engine\tnot_written\tno project.yaml\n'; return 0; }
  # An engine: block gets its name (and version, when it has none set); with no block, one is
  # added at the end.
  tr -d '\r' < project.yaml | awk -v ver="$ver" '
    function flush() { if (inb && !named) print "  name: \"Web\""; if (inb && !versioned && ver != "") print "  version: \"" ver "\""; inb = 0 }
    /^engine:[ \t]*(#.*)?$/ { found = 1; inb = 1; print; next }
    inb && /^[^ \t#]/ { flush() }
    inb && /^  name:/ { print "  name: \"Web\""; named = 1; next }
    inb && /^  version:[ \t]*("?\[|""|$|#)/ { if (ver != "") print "  version: \"" ver "\""; versioned = 1; next }
    inb && /^  version:/ { versioned = 1 }
    { print }
    END { flush(); if (!found) { print ""; print "engine:"; print "  name: \"Web\""; if (ver != "") print "  version: \"" ver "\"" } }' > project.yaml.grow || { rm -f project.yaml.grow; exit 1; }
  mv project.yaml.grow project.yaml || exit 1
  printf 'engine\twritten\tWeb\t%s\n' "${ver:--}"
  claude_md "$ver"
}

# CLAUDE.md on a Web project, as /setup-engine writes it: the ENGINE-REFERENCE-IMPORT line points
# at the web reference, and each Technology Stack line still a placeholder ([CHOOSE...] or
# [SPECIFY...]) gets Web's. A line already filled in is left as it is. The template ships with
# no import line until an engine is set, so with none the line goes in right after the marker
# comment's closing -->.
claude_md() { # claude_md <vite version>
  [ -f CLAUDE.md ] || { printf 'claude_md\tnot_written\tno CLAUDE.md\n'; return 0; }
  tr -d '\r' < CLAUDE.md | awk -v ver="$1" '
    /^@docs\/engine-reference\/[a-z]+\/VERSION\.md/ && !imp { imp = 1; pend = 0; print "@docs/engine-reference/web/VERSION.md"; next }
    pend { pend = 0; if (!imp) { imp = 1; print "@docs/engine-reference/web/VERSION.md" } }
    /ENGINE-REFERENCE-IMPORT/ && !mk { mk = 1 }
    mk == 1 && /-->/ { mk = 2; pend = 1; print; next }
    /^- \*\*Engine\*\*: \[/ { print "- **Engine**: Web" (ver != "" ? " (Vite " ver ")" : ""); next }
    /^- \*\*Language\*\*: \[/ { print "- **Language**: TypeScript"; next }
    /^- \*\*Build System\*\*: \[/ { print "- **Build System**: Vite — `npm run build` for `dist/`, `npm run build:single` for one self-contained HTML file"; next }
    /^- \*\*Asset Pipeline\*\*: \[/ { print "- **Asset Pipeline**: plain files in `assets/`, imported in the code"; next }
    { print }' > CLAUDE.md.grow || { rm -f CLAUDE.md.grow; exit 1; }
  if tr -d '\r' < CLAUDE.md | cmp -s CLAUDE.md.grow -; then
    rm -f CLAUDE.md.grow; printf 'claude_md\tkept\n'
  else
    mv CLAUDE.md.grow CLAUDE.md || exit 1; printf 'claude_md\twritten\n'
  fi
}

case "$CMD" in
  guard) guard; exit $? ;;
  copy) guard; [ $? = 0 ] || exit 3; copy; exit 0 ;;
  replay) replay; exit 0 ;;
  record) record; exit 0 ;;
  accept) accept; exit 0 ;;
esac
