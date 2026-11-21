#!/usr/bin/env bash
# one-shot-check.sh — the one-shot's small check: play the game once by a few scripted key
# presses from a fresh start, screenshot where the run stops, measure the text on that screen,
# compare play with and without the keys, and read the brief's words, emoji and checklist.
# Everything goes in the game's evidence/ folder. --record then writes the small check's
# results, which /prototype reads from these rows, into evidence/check-run.yaml.
#
# Cheap and fixed: one short run and two shorter replays, never a robot player and never a
# tuning loop. A person trying ideas is the check on whether it plays well. Built on
# one-shot-run.sh, which replays from a fresh start. It measures and reports: which rows fail a
# check is /prototype's call, and --record only checks the shape of that call.
#
# Before the run it compares the pins on brief.md's Keep lines with config.js (the keep rows),
# so a change that moves a value the person loves is caught even when the run cannot start.
#
# Usage: bash .claude/scripts/one-shot-check.sh <folder> --keys "<inputs>" [--root DIR]
#        bash .claude/scripts/one-shot-check.sh <folder> --keep
#        bash .claude/scripts/one-shot-check.sh <folder> --checklist
#        bash .claude/scripts/one-shot-check.sh <folder> --record boots=<r> shot=<r> outlines=<r>
#   <folder>          the game's folder, prototypes/<name>
#   --keys TEXT       the run's inputs, in one-shot-run.sh --log's format ("Enter wait:1
#                     ArrowRight:1.5 Space"): from the title into play, then a few of the
#                     game's own keys; the run stops half a second after the last, and after
#                     60 s of real time at most
#   --root DIR        the project; defaults to the repo this script is in
#   --keep            only the keep rows, on stdout: no runs, nothing written
#   --checklist       only the checklist rows, on stdout: no runs, nothing written
#                     A round holds two runs at most (the first and one after the small check's
#                     one fix round): a third is refused before it plays (exit 2). A run counts
#                     when it played (evidence/self-check.runs); --record ends the round
#   --record          the one-shot's small check: boots, shot and outlines given (pass, fail,
#                     or not_run:not-assessed:<why>), each refused as a pass the rows do not
#                     show (a crash or a blank screen, no screenshot of play on disk, no
#                     evidence/figures.png), and refused while a brief word is unlisted or an
#                     emoji is in the game's code; brief-words and emoji are written from the
#                     rows, the step time as a measure. Refused too while a brief checklist
#                     item is unlisted or a pass has no evidence; each item goes in under
#                     brief_checklist, pass or fail (missing, broken). Refused too while a
#                     conflict row stands (Features promising a system past its Your systems mark).
#   -h, --help        this text
#
# Output: TSV, also written to <folder>/evidence/self-check.tsv.
#   time          <YYYY-MM-DD HH:MM:SS>
#   keep          lines <n> pinned <m>             brief.md's Keep lines, and how many end in pins
#   keep          <line> same|changed|gone <key> <pinned> <now, or - when gone>   a pin against config.js
#   keep          <line> unpinned|unreadable <text>   a line with no pins; a pin that is not <key> <value>
#   browser      <browser/version>                 webgl  <renderer>   (when the game uses it)
#   lane          play <why it stopped: stop, real time, crash> <seconds played> <real ms>
#   scene         play <step> <name>               the screens the run entered, in order
#   end           play <step> <scene>              it reached results or over
#   left | noexit | stuck  play <step> <scene> ...  (one-shot-run.sh --help)
#   crash | error  play <step> <message>
#   nonfinite     play <step> <path> <value>       a number in the state that is NaN or Infinity
#   uncaught      play <count>
#   console       play <line> <message>
#   saved         play <step> localstorage|indexeddb <key>   what the game keeps for next time
#   staged | recovered | norecover  play <step> <scene> ...   a staged failure, and whether it recovered
#   responds      changed|same <step>              play with the keys against none, from the first
#                 key in play, 60 steps on
#   measure       step-time play <mean ms> <slowest ms> <steps>   real time of the game's step
#                 alone, the drawing left out: the simulation's cost (16.7 ms a step is 60 a second)
#   checklist     <id> pass|missing|broken|not_assessed|unlisted|noevidence <evidence> <item> <note>   the brief
#                 checklist: each Features item (F1...), First minute sentence (M1...), Challenge
#                 sentence (C1...), Look and references line (L1...) and Your systems line marked
#                 in the slice or thin stand-in (S1...; a later one is not built) of brief.md, against
#                 evidence/checklist.tsv; noevidence is a pass with no file on disk and no number
#   conflict      <system> thin stand-in|later <F id> <item>   a Features item naming a system Your
#                 systems marks later, or thin stand-in without saying (thin stand-in): one mark a
#                 system, and the Your systems mark decides how deep it is built
#   briefword     <word> shown <evidence path> | missed <why> | unlisted   each look, view and
#                 reference word in the brief's "In your words", against evidence/brief-words.tsv
#   art           emoji <file>:<line>              an emoji in the game's own code, unless the
#                 brief asks for emoji (bot.js is left out)
#   shot          play <path>                      the screenshot where the run stopped
#   screen        <scene> blank|drawn
#   text          <scene> canvas|html <x0,y0,x1,y1> <glyph px at 1080p> <contrast|-> inside|outside <text>
#   textunmapped  <scene> <count>                  text the check could not place on screen
#   overlap       <scene> <text> <text>            two texts whose boxes share a quarter of the smaller
#   digits <lane> ...                              the digits' rows (one-shot-run.sh --help)
#   not_assessed  <what> <why>
#
# Exit codes: 0 the runs were made (or the file was written); 1 the folder or, for --record, its
# self-check.tsv is missing; 2 usage error, or a --record result in the wrong shape; 3 not
# assessed (no browser, a served game, no check hooks).
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR=""; KEYS=""; ROOT_ARG=""; RECORD=0; RESULTS=""; KEEP=0; CHECKLIST=0
need() { [ "$2" -ge 2 ] || { echo "one-shot-check: $1 needs a value" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --keys) need "$1" $#; KEYS="$2"; shift 2 ;;
    --root) need "$1" $#; ROOT_ARG="$2"; shift 2 ;;
    --record) RECORD=1; shift ;;
    --keep) KEEP=1; shift ;;
    --checklist) CHECKLIST=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) echo "one-shot-check: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    *) if [ -z "$DIR" ]; then DIR="$1"
       elif [ "$RECORD" = 1 ]; then RESULTS="$RESULTS$1
"
       else echo "one-shot-check: one folder only" >&2; exit 2; fi; shift ;;
  esac
done
[ -n "$DIR" ] || { echo "one-shot-check: a folder is needed (try --help)" >&2; exit 2; }

ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "one-shot-check: no such folder: $ROOT_ARG" >&2; exit 1; }
case "$DIR" in /*|[A-Za-z]:*) ;; *) DIR="$ROOT/$DIR" ;; esac
[ -f "$DIR/index.html" ] || { echo "one-shot-check: no index.html in $DIR" >&2; exit 1; }
EV="$DIR/evidence"

# ---- Keep: the brief's pins against config.js -------------------------------------------------
# A Keep line may end "· pins: <key> <value>, ...": the config.js values behind what the person
# loves. A pin whose value moved, or whose key is gone, is a change that broke a Keep line;
# whether they asked for it is /prototype's call.
keep_rows() {
  [ -f "$DIR/brief.md" ] || { printf 'not_assessed\tkeep\tno brief.md\n'; return; }
  tr -d '\r' < "$DIR/brief.md" | grep -q '^## Keep[[:space:]]*$' || { printf 'not_assessed\tkeep\tthe brief has no Keep section\n'; return; }
  [ -f "$DIR/config.js" ] || { printf 'not_assessed\tkeep\tno config.js\n'; return; }
  awk -v cfgf="$DIR/config.js" -v sq="'" '
    function num(x) { return x ~ /^[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)$/ }
    function unq(x) { gsub("[\"" sq "]", "", x); return x }
    function same(a, b) { a = unq(a); b = unq(b); return a == b || (num(a) && num(b) && a + 0 == b + 0) }
    function val(key,   s, rest, b) { # the key as an object key, not part of a longer name
      s = " " cfg
      if (!match(s, "[^A-Za-z0-9_$][\"" sq "]?" key "[\"" sq "]?[ \t]*:")) return "\001"
      rest = substr(s, RSTART + RLENGTH); sub(/^[ \t]+/, "", rest)
      if (substr(rest, 1, 1) == "{") {
        b = index(rest, "}"); if (b) rest = substr(rest, 1, b)
        if (!match(rest, /[^A-Za-z0-9_]value[ \t]*:[ \t]*/)) return "\001"
        rest = substr(rest, RSTART + RLENGTH)
      }
      return match(rest, /^[^ \t,}]+/) ? substr(rest, 1, RLENGTH) : "\001"
    }
    function row(r) { nr++; out[nr] = r }
    BEGIN {
      while ((getline l < cfgf) > 0) { sub(/\r$/, "", l); sub(/^[ \t]*\/\/.*$/, "", l); sub(/[ \t]\/\/.*$/, "", l); cfg = cfg " " l }
      close(cfgf)
    }
    { sub(/\r$/, "") }
    /^## / { on = ($0 ~ /^## Keep[ \t]*$/); next }
    /^---[ \t]*$/ { on = 0; next }
    !on { next }
    inc { if (index($0, "-->")) inc = 0; next }
    /^[ \t]*<!--/ { if (!index($0, "-->")) inc = 1; next }
    !/^[-*][ \t]+[^ \t]/ { next }
    {
      item = $0; sub(/^[-*][ \t]+/, "", item); sub(/[ \t]+$/, "", item); gsub(/\t/, " ", item); n++
      if (!match(item, /[ \t]pins:[ \t]*/)) { row("keep\t" n "\tunpinned\t" item); next }
      np++; k = split(substr(item, RSTART + RLENGTH), pp, ",")
      for (i = 1; i <= k; i++) {
        x = pp[i]; sub(/^[ \t]+/, "", x); sub(/[ \t]+$/, "", x)
        if (x == "") continue
        if (x !~ /^[A-Za-z_][A-Za-z0-9_]*[ \t]+[^ \t]+$/) { row("keep\t" n "\tunreadable\t" x); continue }
        key = x; sub(/[ \t].*$/, "", key); want = x; sub(/^[^ \t]+[ \t]+/, "", want)
        now = val(key)
        if (now == "\001") row("keep\t" n "\tgone\t" key "\t" want "\t-")
        else row("keep\t" n "\t" (same(want, now) ? "same" : "changed") "\t" key "\t" want "\t" now)
      }
    }
    END { printf "keep\tlines\t%d\tpinned\t%d\n", n, np; for (i = 1; i <= nr; i++) print out[i] }' "$DIR/brief.md"
}
emoji_rows() { # an emoji in the game's own code: as art it disqualifies a game, unless the brief
  # asks for emoji. Every pictograph starts with the bytes F0 9F; a symbol shown as emoji carries
  # EF B8 8F. A bot.js is a check's, not the game's.
  { [ -f "$DIR/brief.md" ] && grep -qi 'emoji' "$DIR/brief.md"; } && return 0
  _emo="$(printf '\360\237')\|$(printf '\357\270\217')"
  for _f in "$DIR"/*.html "$DIR"/*.js; do
    [ -f "$_f" ] || continue
    case "${_f##*/}" in bot.js) continue ;; esac
    grep -n "$_emo" "$_f" 2>/dev/null | head -5 | while IFS=: read -r _ln _rest; do printf 'art\temoji\t%s:%s\n' "${_f##*/}" "$_ln"; done
  done
}
brief_words() { # the look, view and reference words in the brief's "In your words", each against
  # evidence/brief-words.tsv (<word> TAB <how the game shows it, or miss: why> TAB <evidence shot>).
  # A word the person wrote is never dropped in silence: shown with a picture, or missed with a why.
  [ -f "$DIR/brief.md" ] || return 0
  _bw=$(awk '/^## In your words/ { on = 1; next } on && /^## / { exit } on && !/^<!--/' "$DIR/brief.md" | tr -d '\r' |
    LC_ALL=C grep -oiE '(2\.5 ?d|2d|3d|isometric|top[- ]down|side[- ]on|side[- ]scroll(ing|er)?|first[- ]person|third[- ]person|pixel[- ]art|low[- ]poly|voxel|vector|hand[- ]drawn|cel[- ]shaded|claymation|like [A-Z][^ ,.;:!?()"]*( [A-Z][^ ,.;:!?()"]*){0,2}|[A-Z][^ ,.;:!?()"]*-like)' |
    sed -e 's/^like //' -e 's/^\(.*\)-like$/\1/' | LC_ALL=C awk '!seen[tolower($0)]++')
  [ -n "$_bw" ] || return 0
  printf '%s\n' "$_bw" | while IFS= read -r _w; do
    _r=$(LC_ALL=C awk -F'\t' -v w="$_w" 'tolower($1) == tolower(w) { print; exit }' "$EV/brief-words.tsv" 2>/dev/null | tr -d '\r')
    _how=$(printf '%s' "$_r" | cut -f2); _shot=$(printf '%s' "$_r" | cut -f3)
    if [ -z "$_r" ] || [ -z "$_how" ]; then printf 'briefword\t%s\tunlisted\n' "$_w"
    else case "$_how" in
      miss:*) printf 'briefword\t%s\tmissed\t%s\n' "$_w" "$(printf '%s' "${_how#miss:}" | sed 's/^ *//')" ;;
      *) if [ -n "$_shot" ] && [ -f "$DIR/$_shot" ]; then printf 'briefword\t%s\tshown\t%s\n' "$_w" "$_shot"
         else printf 'briefword\t%s\tunlisted\tno shot at %s\n' "$_w" "${_shot:--}"; fi ;;
    esac; fi
  done
}
checklist_rows() { # the brief checklist: each Features item, First minute and Challenge sentence,
  # Look and references line and Your systems line not marked later of brief.md, against evidence/checklist.tsv (<id> TAB pass|missing|broken|not_assessed
  # TAB <evidence: a file in the game's folder, or a measured value> TAB <what was seen, or why it could not be>). A pass
  # needs its evidence on disk, or a number; the check never judges whether the item is good.
  [ -f "$DIR/brief.md" ] || return 0
  awk -v OFS='\t' -v dir="$DIR" -v cl="$EV/checklist.tsv" '
    function add(k, t) { gsub(/^[ \t]+|[ \t]+$/, "", t); if (t == "" || t ~ /^([A-Za-z]+: )?\[/) return; n++; id[n] = k (++c[k]); tx[n] = t
      if (k == "F") { nf++; fid[nf] = id[n]; ftx[nf] = tolower(t) } }
    function beats(k, s,   a, m, i, b) { # a sentence a beat; one going on in lower case ("Strong hit!" when) is the same beat
      gsub(/[.!?]["'"'"')]* +/, "&\n", s); m = split(s, a, "\n"); b = ""
      for (i = 1; i <= m; i++) { if (b != "" && a[i] ~ /^[a-z]/) b = b a[i]; else { add(k, b); b = a[i] } }
      add(k, b) }
    function exists(p,   l) { if ((getline l < p) >= 0) { close(p); return 1 } return 0 }
    { sub(/\r$/, "") }
    inc { if (/-->/) inc = 0; next }
    /^<!--/ { if ($0 !~ /-->/) inc = 1; next }
    /^## / { sec = substr($0, 4); next }
    sec == "Features" && /^- \[[ xX]\] / { add("F", substr($0, 7)); next }
    sec == "Look and references" && /^- / { add("L", substr($0, 3)); next }
    sec == "Your systems" && /^- [^[]/ && / · (thin stand-in|later)( |$)/ { # one mark a system: Features never past it
      ns++; sn[ns] = tolower(substr($0, 3)); sub(/ · .*$/, "", sn[ns]); sub(/^(a|an|the) /, "", sn[ns]); sm[ns] = ($0 ~ / · later( |$)/ ? "later" : "thin stand-in") }
    sec == "Your systems" && /^- / && $0 !~ / · later( |$)/ { add("S", substr($0, 3)); next }
    (sec == "First minute" || sec == "Challenge") && NF { p[sec] = p[sec] " " $0 }
    END {
      if ("First minute" in p) beats("M", p["First minute"])
      if ("Challenge" in p) beats("C", p["Challenge"])
      while ((getline l < cl) > 0) { sub(/\r$/, "", l); split(l, f, "\t"); r[f[1]] = f[2]; e[f[1]] = f[3]; w[f[1]] = f[4] }
      for (i = 1; i <= n; i++) {
        k = id[i]; st = (k in r) ? r[k] : "unlisted"; ev = (k in e) ? e[k] : "-"
        if (st != "pass" && st != "missing" && st != "broken" && st != "not_assessed") st = "unlisted"
        if (st == "not_assessed" && w[k] == "") st = "unlisted" # not assessed needs its why
        if (st == "pass") {
          if (ev ~ /\// || ev ~ /\.(png|jpe?g|webp|tsv|txt|ya?ml|json)$/) { if (!exists(dir "/" ev)) st = "noevidence" }
          else if (ev !~ /[0-9]/) st = "noevidence"
        }
        print "checklist", k, st, (ev == "" ? "-" : ev), tx[i], w[k]
      }
      for (j = 1; j <= ns; j++) for (i = 1; i <= nf; i++)
        if (sn[j] != "" && index(ftx[i], sn[j]) && (sm[j] == "later" || ftx[i] !~ /thin stand-in/)) print "conflict", sn[j], sm[j], fid[i], ftx[i]
    }' "$DIR/brief.md"
}
if [ "$KEEP" = 1 ]; then
  [ "$RECORD" = 0 ] || { echo "one-shot-check: --keep or --record, not both" >&2; exit 2; }
  keep_rows; exit 0
fi
if [ "$CHECKLIST" = 1 ]; then
  [ "$RECORD" = 0 ] || { echo "one-shot-check: --checklist or --record, not both" >&2; exit 2; }
  checklist_rows; exit 0
fi

# ---- --record: the results file ---------------------------------------------------------------
# The verdicts are /prototype's; this checks their shape and adds what the evidence holds.
if [ "$RECORD" = 1 ]; then
  [ -f "$EV/self-check.tsv" ] || { echo "one-shot-check: no evidence/self-check.tsv in $DIR: run the check before --record" >&2; exit 1; }
  INTENT=""
  [ -f "$DIR/brief.md" ] && INTENT=$(sed -n 's/^\*\*Intent:\*\* *//p' "$DIR/brief.md" | head -1)
  OUTF="$EV/check-run.yaml"
  # The one-shot's small check: four rows, the hard rules and a run. boots, shot and
  # outlines are given; brief-words and emoji are read from the rows here.
    CLF=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-cl-$$"); checklist_rows > "$CLF"
    printf '%s' "$RESULTS" | awk -v clf="$CLF" -v sc="$EV/self-check.tsv" -v dir="$DIR" -v out="$OUTF" -v bwbad="$(brief_words | awk -F'	' '$3 == "unlisted" { printf " %s", $2 }')" -v bwmiss="$(brief_words | awk -F'	' '$3 == "missed" { printf "; %s: %s", $2, $4 }')" '
      function q(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return "\"" s "\"" }
      function bad(m) { printf "one-shot-check: --record: %s\n", m > "/dev/stderr"; err = 1 }
      function exists(p,   l) { if ((getline l < p) >= 0) { close(p); return 1 } return 0 }
      BEGIN {
        ng = split("boots shot outlines", given, " "); for (i = 1; i <= ng; i++) isg[given[i]] = 1
        while ((getline l < sc) > 0) {
          split(l, f, "\t")
          if (f[1] == "time") tm = f[2]
          else if (f[1] == "browser") br = f[2]
          else if (f[1] == "crash" || f[1] == "error" || f[1] == "nonfinite") crash = crash "; " f[1] " " f[2] " " f[3]
          else if (f[1] == "uncaught" && f[3] + 0 > 0) crash = crash "; " f[3] " uncaught in " f[2]
          else if (f[1] == "screen" && f[3] == "blank") crash = crash "; " f[2] " blank"
          else if (f[1] == "shot" && f[2] != "return") { p = f[3]; sub(/^.*\/evidence\//, "evidence/", p); if (exists(dir "/" p)) { nsh++; shots[nsh] = p } }
          else if (f[1] == "measure" && f[2] == "step-time") { sv = f[5]; sd = "mean " f[4] " ms, slowest " f[5] " ms, " f[6] " steps" }
          else if (f[1] == "art" && f[2] == "emoji") emo = emo " " f[3]
          else if (f[1] == "not_assessed") { nna++; naw[nna] = f[2]; nay[nna] = f[3] }
        }
        close(sc)
        # The note of build rule 2: its presence and content only, never a verdict on copying.
        nf = dir "/evidence/nearest-game.txt"
        while ((getline l < nf) > 0) { sub(/\r$/, "", l); if (l ~ /^Nearest game:/) { ngl = l; break } }
        close(nf)
      }
      NF == 0 || $0 == "" { next }
      {
        arg = $0; eq = index(arg, "=")
        if (eq < 2) { bad(arg ": not <check>=<result>[:<mark>[:<why>]]"); next }
        id = substr(arg, 1, eq - 1); rest = substr(arg, eq + 1)
        if (!(id in isg)) { bad(id ": the small check gives boots, shot and outlines; brief-words and emoji are read from the rows"); next }
        if (id in r) { bad(id ": given twice"); next }
        c = index(rest, ":"); res = c ? substr(rest, 1, c - 1) : rest; mw = c ? substr(rest, c + 1) : ""
        c = index(mw, ":"); mark = c ? substr(mw, 1, c - 1) : mw; why = c ? substr(mw, c + 1) : ""
        if (res != "pass" && res != "fail" && res != "not_run") { bad(arg ": the result is pass, fail or not_run"); next }
        if (res == "pass" && mark != "") { bad(arg ": a pass takes no mark"); next }
        if (res == "not_run" && (mark != "not-assessed" || why == "")) { bad(arg ": not_run needs not-assessed and a why"); next }
        if (res == "fail" && mark != "") { why = (why == "" ? mark : mark ":" why); mark = "" }
        r[id] = res; m[id] = mark; w[id] = why; n++; ids[n] = id
      }
      END {
        if (err) exit 2
        for (i = 1; i <= ng; i++) if (!(given[i] in r)) miss = miss " " given[i]
        if (miss != "") bad("the small check needs all three given rows; missing:" miss)
        if (r["boots"] == "pass" && crash != "") bad("boots: the rows show" substr(crash, 2) ": a fix-round finding, never a pass")
        if (r["shot"] == "pass" && !nsh) bad("shot: no screenshot of play is on disk in evidence/: take one, look at it, then give shot=pass")
        if (r["outlines"] == "pass" && !exists(dir "/evidence/figures.png")) bad("outlines: no evidence/figures.png: shoot the figures scene, look at each outline, then give outlines=pass")
        if (bwbad != "") bad("brief words:" bwbad ": the person wrote them; build each and list it in evidence/brief-words.tsv with the shot that shows it, or write miss: <why>")
        if (emo != "") bad("emoji: an emoji in the game code (" substr(emo, 2) "): never art unless the brief asks for emoji; draw it")
        while ((getline l < clf) > 0) {
          split(l, f, "\t")
          if (f[1] == "conflict") { clx = clx ", " f[2] " (" f[3] ", " f[4] ")"; continue }
          ncl++; ci[ncl] = f[2]; cr[ncl] = f[3]; ce[ncl] = f[4]; ct[ncl] = f[5]; cn[ncl] = f[6]
          if (f[3] == "unlisted") clu = clu " " f[2]
          else if (f[3] == "noevidence") cln = cln " " f[2]
        }
        close(clf)
        if (clu != "") bad("brief checklist:" clu ": play the game to each and list it in evidence/checklist.tsv as pass, missing, broken, or not_assessed with its why (one-shot-check.sh --checklist)")
        if (clx != "") bad("Your systems: " substr(clx, 3) ": Features promises more than the mark; write each at its mark (a stand-in ends (thin stand-in), a later one goes only in Out of scope), or change the mark")
        if (cln != "") bad("brief checklist:" cln ": a pass needs its evidence, a file in the game'"'"'s folder or a measured value")
        if (ngl == "") bad("nearest game: no \"Nearest game: <name>; this one differs in <what>\" line in evidence/nearest-game.txt: write it before the hook (build rule 2)")
        else {
          ngn = ngl; sub(/^Nearest game:[ \t]*/, "", ngn); ngd = ngn; sub(/;.*$/, "", ngn); gsub(/^[ \t]+|[ \t]+$/, "", ngn)
          if (index(ngd, ";")) sub(/^[^;]*;/, "", ngd); else ngd = ""
          if (ngn == "" || tolower(ngn) ~ /^(none|no game|nothing|n\/a|na|tbd|unknown|-+|\?+|<name>)$/) bad("nearest game: the note names no game (" ngl "): name the nearest real game, and change the hook if this one is it")
          else if (ngd !~ /differs in[ \t]*[^ \t<]/) bad("nearest game: the note says no difference (" ngl "): say what this one changes, or change the hook'"'"'s form first")
        }
        if (err) exit 2
        print "# The one-shot'"'"'s small check (check-run/1)." > out
        print "# Written by one-shot-check.sh --record: the results are /prototype'"'"'s reading of" > out
        print "# evidence/self-check.tsv; never edited by hand." > out
        print "kind: check-run/1" > out
        print "engine: web" > out
        print "browser: " q(br == "" ? "unknown" : br) > out
        print "time: " q(tm) > out
        print "checks:" > out
        for (i = 1; i <= n; i++) {
          id = ids[i]
          print "  - id: " id > out
          print "    result: " r[id] > out
          if (m[id] != "") { mk = m[id]; gsub(/-/, " ", mk); print "    mark: " mk > out }
          if (w[id] != "") print "    why: " q(w[id]) > out
          print "    evidence:" > out
          if (id == "shot") for (j = 1; j <= nsh; j++) print "      - " q(shots[j]) > out
          else if (id == "outlines") print "      - \"evidence/figures.png\"" > out
          else print "      - \"evidence/self-check.tsv\"" > out
        }
        print "  - id: brief-words\n    result: pass" > out
        if (bwmiss != "") print "    why: " q("missed" bwmiss) > out
        print "    evidence:\n      - \"evidence/brief-words.tsv\"" > out
        print "  - id: emoji\n    result: pass\n    evidence:\n      - \"evidence/self-check.tsv\"" > out
        print "  - id: nearest-game\n    result: pass\n    evidence:\n      - \"evidence/nearest-game.txt\"" > out
        if (ncl) {
          print "brief_checklist:" > out
          for (i = 1; i <= ncl; i++) {
            print "  - id: " ci[i] > out
            print "    result: " (cr[i] == "pass" ? "pass" : cr[i] == "not_assessed" ? "not_run\n    mark: not assessed" : "fail") > out
            if (cr[i] == "missing" || cr[i] == "broken") print "    why: " cr[i] > out
            else if (cr[i] == "not_assessed") print "    why: " q(cn[i]) > out
            if (ce[i] != "-") print "    evidence: " q(ce[i]) > out
            print "    item: " q(ct[i]) > out
          }
        }
        if (sv != "") {
          print "measures:" > out
          print "  - id: step-time\n    value: " sv > out
          print "    unit: ms\n    by: browser" > out
          print "    detail: " q(sd) > out
        }
        if (nna) {
          print "not_assessed:" > out
          for (i = 1; i <= nna; i++) { print "  - what: " q(naw[i]) > out; print "    why: " q(nay[i]) > out }
        }
        printf "recorded\t%s\n", out
      }' || { rm -f "$CLF"; exit 2; }
    rm -f "$CLF"
    rm -f "$EV/self-check.runs" # the round ends here
    exit 0
fi

[ -n "$KEYS" ] || { echo "one-shot-check: --keys \"<inputs>\" is needed: from the title into play, then a few of the game's own keys (one-shot-run.sh --log's format)" >&2; exit 2; }
mkdir -p "$EV" || { echo "one-shot-check: cannot make $EV" >&2; exit 1; }
# Two runs a round, the first and one after the small check's one fix round. A fix inside a
# round is checked with the one run it needs (one-shot-run.sh or a page-shot.sh of the scene);
# --record ends the round.
RUNS="$EV/self-check.runs"
if [ -f "$RUNS" ] && [ "$(wc -l < "$RUNS" | tr -d ' ')" -ge 2 ]; then
  echo "one-shot-check: this would be the round's third run: the small check runs twice before the handover, the first and one after its one fix round. Check a fix with the one run it needs (one-shot-run.sh, page-shot.sh), then --record ends the round" >&2
  exit 2
fi
TMP=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/one-shot-check-$$")
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT
REPORT="$TMP/report.tsv"
: > "$REPORT"
say() { printf '%s\n' "$*" | tee -a "$REPORT"; }
rel() { case "$1" in "$ROOT"/*) printf '%s' "${1#"$ROOT"/}" ;; *) printf '%s' "$1" ;; esac; }
say "$(printf 'time\t%s' "$(date '+%Y-%m-%d %H:%M:%S')")"
keep_rows >> "$REPORT"
brief_words >> "$REPORT"
checklist_rows >> "$REPORT"
emoji_rows >> "$REPORT"

run() { # run <lane> <out.png> <args...>: one-shot-run.sh into $TMP/<lane>.tsv
  _lane="$1"; _out="$2"; shift 2
  # stdin from /dev/null: inside a while-read loop the run must never eat the loop's lines.
  bash "$HERE/one-shot-run.sh" "$DIR" "$_out" --root "$ROOT" "$@" > "$TMP/$_lane.tsv" < /dev/null
}
lane_rows() { # the rows of a played lane that the skill reads, with the lane named
  awk -F'\t' -v lane="$1" -v OFS='\t' '
    $1 == "done" { print "lane", lane, $4, $5, $6; next }
    $1 == "steptime" { print "measure", "step-time", lane, $3, $4, $2; next }
    $1 ~ /^(scene|end|left|noexit|stuck|crash|error|nonfinite|saved|staged|recovered|norecover)$/ { $1 = $1 OFS lane; print; next }
    $1 == "uncaught" { print "uncaught", lane, $2; next }
    $1 == "digits" { print; next }
    $1 == "console" { print "console", lane, $2, $3; next }' "$TMP/$1.tsv"
}
shot_rows() { # shot_rows <label> <path> <lane>: what was on the screen it took
  awk -F'\t' -v label="$1" -v path="$2" -v OFS='\t' '
    $1 == "not_assessed" { print "not_assessed", "shot " label, $2; next }
    $1 == "shot" && $3 + 0 > 0 { print "shot", label, path }
    $1 == "screen" { print "screen", label, $5 }
    $1 == "text" || $1 == "textunmapped" { $2 = label; print }' "$TMP/$3.tsv"
}

# ---- The run: the keys from a fresh start, and the screenshot where it stops ----------------
run play "$EV/play.png" --log "$KEYS" --limit 60; RC=$?
if [ "$RC" = 3 ] || awk -F'\t' '$1 == "not_assessed" { f = 1 } END { exit !f }' "$TMP/play.tsv"; then
  awk -F'\t' -v OFS='\t' '$1 == "not_assessed" { print "not_assessed", "scripted run", $2 }' "$TMP/play.tsv" | tee -a "$REPORT"
  cp "$REPORT" "$EV/self-check.tsv"; exit 3
fi
# A run the game never reported finishing played nothing the rows could stand for: without
# this, its uncaught 0 would read as a run that found nothing.
if ! awk -F'\t' '$1 == "done" { f = 1 } END { exit !f }' "$TMP/play.tsv"; then
  printf 'not_assessed\tscripted run\tthe run did not finish (one-shot-run.sh exit %s, no done row)\n' "$RC" | tee -a "$REPORT"
  cp "$REPORT" "$EV/self-check.tsv"; exit 3
fi
printf 'run\n' >> "$RUNS" # the run played: it counts toward the round's two
awk -F'\t' -v OFS='\t' '$1 == "ua" && !u { print "browser", $2; u = 1 } $1 == "webgl" && !g { print "webgl", $2; g = 1 }' "$TMP/play.tsv" >> "$REPORT"
lane_rows play >> "$REPORT"
shot_rows play "$(rel "$EV/play.png")" play >> "$REPORT"

# ---- Responds: the keys in play against no input, from the same start ------------------------
_k=$(awk -F'\t' '$1 == "playinput" { print $2; exit }' "$TMP/play.tsv")
if [ -z "$_k" ]; then
  printf 'not_assessed\tresponds\tno key reached the play scene: start --keys with what leaves the title\n' >> "$REPORT"
else
  run resp-in "$TMP/responds-input.png" --log "$KEYS" --trace "$_k" --stop $((_k + 60))
  run resp-quiet "$TMP/responds-quiet.png" --log "$KEYS" --quiet "$_k" --trace "$_k" --stop $((_k + 60))
  _a=$(awk -F'\t' '$1 == "screen" { h = $4 } END { print h }' "$TMP/resp-in.tsv")
  _b=$(awk -F'\t' '$1 == "screen" { h = $4 } END { print h }' "$TMP/resp-quiet.tsv")
  if [ -z "$_a" ] || [ -z "$_b" ]; then printf 'not_assessed\tresponds\ta replay did not finish\n' >> "$REPORT"
  elif [ "$_a" = "$_b" ]; then printf 'responds\tsame\t%s\n' "$_k" >> "$REPORT"
  else printf 'responds\tchanged\t%s\n' "$_k" >> "$REPORT"; fi
fi

# Two different texts on the screen whose boxes share a quarter or more of the smaller one.
awk -F'\t' -v OFS='\t' '$1 == "text" && !seen[$2 FS $4 FS $8]++ {
    split($4, b, ","); n = ++c[$2]; x0[$2, n] = b[1]; y0[$2, n] = b[2]; x1[$2, n] = b[3]; y1[$2, n] = b[4]; tx[$2, n] = $8 }
  END { for (s in c) for (i = 1; i < c[s]; i++) for (j = i + 1; j <= c[s]; j++) {
    if (tx[s, i] == tx[s, j]) continue
    w = (x1[s, i] < x1[s, j] ? x1[s, i] : x1[s, j]) - (x0[s, i] > x0[s, j] ? x0[s, i] : x0[s, j])
    h = (y1[s, i] < y1[s, j] ? y1[s, i] : y1[s, j]) - (y0[s, i] > y0[s, j] ? y0[s, i] : y0[s, j])
    if (w <= 0 || h <= 0) continue
    ai = (x1[s, i] - x0[s, i]) * (y1[s, i] - y0[s, i]); aj = (x1[s, j] - x0[s, j]) * (y1[s, j] - y0[s, j])
    if (w * h * 4 >= (ai < aj ? ai : aj)) print "overlap", s, tx[s, i], tx[s, j] } }' "$REPORT" >> "$REPORT.o"
[ -s "$REPORT.o" ] && cat "$REPORT.o" >> "$REPORT"; rm -f "$REPORT.o"

# The rows, without repeats.
awk '!seen[$0]++' "$REPORT" > "$EV/self-check.tsv"
awk -F'\t' 'NR > 1' "$EV/self-check.tsv"
exit 0
