#!/usr/bin/env bash
# content-count.sh — the counts /content-audit works out by hand: the named
# content the entity registry plans (entries, deprecated ones left out), the
# content files found on disk per engine and per content type, and a
# specified / found pair's percentage and status band, with the gap table's
# totals.
#
# Replaces the hand-run counting in /content-audit (Phase 1 step 2, Phase 2
# and Phase 3) and the "planned content" count /consistency-check and
# /asset-spec make from the same registry.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# A band name is the rule row that matched. Whether a system is HIGH PRIORITY
# (the skill's text does not say whether "NOT STARTED or EARLY, AND tagged MVP
# or Vertical Slice, OR blocking" groups as (A AND B) OR C or A AND (B OR C))
# stays in the skill: each gap row says only whether its band is a low one
# (NOT STARTED or EARLY). The counts are of files and entries; whether a scene
# is a gameplay level or a UI scene is not known here (see by levels).
#
# Usage: bash .claude/scripts/content-count.sh [--root DIR] COMMAND [ARGS]
#   registry        the planned named content: the entries of design/registry/
#                   entities.yaml's entities and items sections, read through
#                   registry.sh, deprecated ones left out
#   found [--engine E] [--files]
#                   content files on disk for the engine (godot, unity,
#                   unreal or web; default: engine.name as project-state.sh reads it)
#   band FOUND SPECIFIED
#                   the percentage and status band of one pair
#   gap             rows `system<TAB>type<TAB>specified<TAB>found` on stdin:
#                   the gap table, with totals
#   --root DIR      the project; defaults to the repo this script is in
#   -h, --help      this text
#
# The status bands (the skill's, with 49.5% and 99.5% no longer in none). The
# edges are half-open, found / specified compared exactly, never as a rounded
# or printed percentage, so every value falls in exactly one band:
#   found = 0                          NOT STARTED
#   0 < found/specified < 50%          EARLY          (the skill's "1-49%")
#   50% <= found/specified < 100%      IN PROGRESS    (the skill's "50-99%")
#   found >= specified                 COMPLETE       (the skill's "100%+")
# A specified of 0 has no percentage and no band: `-`. Percentages are
# truncated, not rounded, to one decimal, so a printed value never sits on the
# far side of a band edge (99.96% prints 99.9, never 100.0).
#
# Where `found` looks, per engine (the skill's Phase 2 globs, with the engine
# rules it gives): assets/ and
#   godot   src/            levels and characters only; no data/ needed under src/
#   unity   Assets/         every type; no data/ segment needed
#   unreal  Content/        every type; no data/ segment needed (Source/ holds
#                           C++ only and is not searched)
# A root is looked for by its exact name, so Assets/ and assets/ are two roots
# even on a case-insensitive disk. Each root is printed present or absent.
# Under assets/ the four data types (characters, items, abilities, quests)
# need a data/ folder as the first folder, as the skill's assets/data/** globs
# do; levels and dialogue do not.
#   levels      the engine's scene files: .tscn, .unity, .umap (one extension
#               per engine, not all three); by levels counts them in folders
#               named levels, areas, maps, worlds or stages. A UI scene counts
#               too, as the skill says to count every match.
#   characters  folders enemies, characters, npcs (npcs: the skill's heading
#               names NPCs but its globs do not)
#   items       folders items, equipment, loot; on Unity also any file named
#               *Item*.asset (by items *Item*.asset)
#   abilities   folders abilities, skills, spells
#   quests      folders quests, missions, objectives (objectives likewise)
#   dialogue    .dialogue, .csv, .ink files under any root but src/ (by ext)
# Folder names compare in any case (items and Items). Files in them count when
# their extension is one of the engine's data extensions: godot json, tres,
# asset and, for characters, yaml, tscn and prefab, and for quests json and
# yaml only; unity json, yaml, asset, prefab; unreal uasset. A file in two
# folders of a type counts once in the type and once in each folder row.
#
# Output: TSV.
#   registry:  registry <path> <entries | missing | layout>, planned
#              entities <n>, planned items <n>, planned_total <n>,
#              deprecated_skipped <n>, no_status <n> (counted, status absent),
#              status_other <n> <values> (counted, status not active or
#              deprecated), duplicate_names <n> (a name twice in a section),
#              source <gdd> <n> per source GDD of the planned entries, then
#              PLANNED <section> <name> <source> and
#              SKIPPED <section> <name> <source> deprecated, in registry order
#   found:     engine <name> <source: project.yaml, project.local.yaml, flag...>,
#              root <dir> <present|absent>, found <type> <n> (six types), by
#              <type> <folder | extension> <n>, and with --files
#              FILE <type> <path>
#   band:      band <F>/<S> <name | -> <percent | -> <rule>
#   gap:       rows <counted> <read>, excluded <n>, total_specified,
#              total_found, total_gap (specified - found, as the skill's
#              summary has it; negative when over-built), gap_pct (that over
#              total_specified), unbuilt (the sum of each row's shortfall,
#              which an over-built row cannot hide), unbuilt_pct, systems <n>,
#              ROW <system> <type> <specified> <found> <gap> <percent>
#              <status> <low>, EXCLUDED <system> <type> <reason>
#              gap = specified - found, not below 0; percent = found / specified
#              low = yes for NOT STARTED and EARLY; a row whose specified or
#              found is not a number (Unspecified, NOT ASSESSED) is excluded
#              from the rows and totals and named
#
# Exit codes: 0 answered; 1 the root cannot be read, or a script it needs is
# missing; 2 usage error; 3 found: no engine, or an engine without rules
# (prints its engine row); gap: no row with numbers; 4 registry: the layout is
# unsupported (registry.sh's LAYOUT rows are printed); found: none of the
# engine's roots exists, so nothing was scanned. Reads only; never writes,
# never prompts.
#
# bash 3.2 and BWK awk safe, no Python. BWK awk's split() with
# a one-character separator also splits on newlines, so split() is used here
# only on a single line (a path, a TSV row).

set -u
# Byte semantics for awk, sort and tolower.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "content-count: $1 (try --help)" >&2; exit 2; }
TAB=$(printf '\t')

CMD=""; ROOT_ARG=""; ENGINE_ARG=""; SHOWFILES=0; NPOS=0; P1=""; P2=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --engine) [ $# -ge 2 ] || usage "--engine needs a name"; ENGINE_ARG="$2"; shift 2 ;;
    --engine=*) ENGINE_ARG="${1#--engine=}"; shift ;;
    --files) SHOWFILES=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) usage "unknown argument: $1" ;;
    *)
      if [ -z "$CMD" ]; then CMD="$1"
      else
        NPOS=$((NPOS + 1))
        case $NPOS in 1) P1="$1" ;; 2) P2="$1" ;; *) usage "too many arguments" ;; esac
      fi
      shift ;;
  esac
done
case "$CMD" in
  registry|gap) [ $NPOS -eq 0 ] || usage "$CMD takes no arguments" ;;
  found) [ $NPOS -eq 0 ] || usage "found takes no arguments" ;;
  band) [ $NPOS -eq 2 ] || usage "band needs FOUND and SPECIFIED"
        case "$P1$P2" in *[!0-9]*) usage "band takes whole numbers" ;; esac
        [ -n "$P1" ] && [ -n "$P2" ] || usage "band takes whole numbers" ;;
  "") usage "no command" ;;
  *) usage "unknown command: $CMD" ;;
esac
[ "$CMD" = found ] || [ -z "$ENGINE_ARG" ] || usage "--engine belongs to found"
[ "$CMD" = found ] || [ "$SHOWFILES" -eq 0 ] || usage "--files belongs to found"

# The band and percentage arithmetic, shared by band and gap. All comparisons
# cross-multiply whole numbers, so a value is never decided on a rounded one.
AWK_LIB='
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  # found as tenths of a percent of specified, truncated: 99/200 -> 49.5
  function pct1(f, s,    t) {
    if (s == 0) return "-"
    t = int(f * 1000 / s)
    return sprintf("%d.%d", int(t / 10), t % 10)
  }
  # Sets BNAME and BRULE.
  function band(f, s) {
    if (s == 0) { BNAME = "-"; BRULE = "specified is 0: no percentage"; return }
    if (f == 0) { BNAME = "NOT STARTED"; BRULE = "found = 0"; return }
    if (f >= s) { BNAME = "COMPLETE"; BRULE = "found >= specified"; return }
    if (f * 2 >= s) { BNAME = "IN PROGRESS"; BRULE = "50% <= found/specified < 100%"; return }
    BNAME = "EARLY"; BRULE = "0 < found/specified < 50%"
  }
'

if [ "$CMD" = band ]; then
  F="$P1" S="$P2" awk "$AWK_LIB"'BEGIN {
    f = ENVIRON["F"] + 0; s = ENVIRON["S"] + 0
    band(f, s)
    printf "band\t%d/%d\t%s\t%s\t%s\n", f, s, BNAME, pct1(f, s), BRULE
  }'
  exit 0
fi

if [ "$CMD" = gap ]; then
  awk "$AWK_LIB"'
    BEGIN { BINMODE = 3 }
    {
      line = $0; sub(/\r$/, "", line)
      if (line == "") next
      nread++
      n = split(line, c, "\t")
      sy = trim(c[1]); ty = trim(c[2]); sp = trim(c[3]); fo = trim(c[4])
      if (n < 4) { ne++; ex[ne] = sy "\t" ty "\tfewer than 4 columns"; next }
      if (sp !~ /^[0-9]+$/) { ne++; ex[ne] = sy "\t" ty "\tspecified is not a number: " sp; next }
      if (fo !~ /^[0-9]+$/) { ne++; ex[ne] = sy "\t" ty "\tfound is not a number: " fo; next }
      sp += 0; fo += 0
      nc++
      band(fo, sp)
      sg = (sp > fo) ? sp - fo : 0
      rows[nc] = sprintf("ROW\t%s\t%s\t%d\t%d\t%d\t%s\t%s\t%s", sy, ty, sp, fo, sg, pct1(fo, sp), BNAME, (BNAME == "-") ? "-" : ((BNAME == "EARLY" || BNAME == "NOT STARTED") ? "yes" : "no"))
      ts += sp; tf += fo; ub += sg
      if (!(sy in sysseen)) { sysseen[sy] = 1; nsys++ }
    }
    END {
      printf "rows\t%d\t%d\nexcluded\t%d\n", nc, nread, ne
      if (nc == 0) {
        printf "total_specified\t-\ntotal_found\t-\ntotal_gap\t-\ngap_pct\t-\nunbuilt\t-\nunbuilt_pct\t-\nsystems\t0\n"
      } else {
        d = ts - tf
        printf "total_specified\t%d\ntotal_found\t%d\ntotal_gap\t%d\n", ts, tf, d
        if (ts == 0) printf "gap_pct\t-\n"
        else if (d < 0) printf "gap_pct\t-%s\n", pct1(-d, ts)
        else printf "gap_pct\t%s\n", pct1(d, ts)
        printf "unbuilt\t%d\nunbuilt_pct\t%s\nsystems\t%d\n", ub, pct1(ub, ts), nsys
      }
      for (i = 1; i <= nc; i++) print rows[i]
      for (i = 1; i <= ne; i++) printf "EXCLUDED\t%s\n", ex[i]
      exit ((nc == 0) ? 3 : 0)
    }
  '
  rc=$?
  [ $rc -ne 3 ] || echo "content-count: no row with a specified and a found number" >&2
  exit $rc
fi

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "content-count: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "content-count: cannot reach the repo root" >&2; exit 1; }
fi

# ------------------------------------------------------------------- registry
if [ "$CMD" = registry ]; then
  [ -f "$HERE/registry.sh" ] || { echo "content-count: $HERE/registry.sh is missing" >&2; exit 1; }
  OUT=$(bash "$HERE/registry.sh" --root . list entities 2>/dev/null); RC=$?
  case $RC in 0|4) ;; *) echo "content-count: registry.sh list entities failed (exit $RC)" >&2; exit 1 ;; esac
  printf '%s\n' "$OUT" | awk '
    BEGIN { BINMODE = 3; FS = "\t" }
    $1 == "registry" { rpath = $3; rstate = $4 }
    $1 == "LAYOUT" { lay[++nlay] = $0 }
    $1 == "ENTRY" && ($3 == "entities" || $3 == "items") {
      sec = $3; nm = $5; stt = $6; src = $7
      if (tolower(stt) == "deprecated") {
        nskip++; rows[++nr] = "SKIPPED\t" sec "\t" nm "\t" src "\tdeprecated"
      } else {
        planned[sec]++; total++
        rows[++nr] = "PLANNED\t" sec "\t" nm "\t" src
        if (stt == "-") nostat++
        else if (tolower(stt) != "active") {
          nother++
          if (!(stt in oseen)) { oseen[stt] = 1; olist = olist (olist == "" ? "" : ",") stt }
        }
        k = sec "\t" nm; nameN[k]++
        if (nameN[k] == 2) ndup++
        if (!(src in srcN)) so[++ns] = src
        srcN[src]++
      }
    }
    END {
      printf "registry\t%s\t%s\n", (rpath == "") ? "design/registry/entities.yaml" : rpath, (rstate == "") ? "missing" : rstate
      if (rstate == "layout") { for (i = 1; i <= nlay; i++) print lay[i]; exit 4 }
      printf "planned\tentities\t%d\nplanned\titems\t%d\nplanned_total\t%d\n", planned["entities"], planned["items"], total
      printf "deprecated_skipped\t%d\nno_status\t%d\nstatus_other\t%d\t%s\nduplicate_names\t%d\n", nskip, nostat, nother, (olist == "") ? "-" : olist, ndup
      for (i = 2; i <= ns; i++) { x = so[i]; for (j = i - 1; j >= 1 && so[j] > x; j--) so[j + 1] = so[j]; so[j + 1] = x }
      for (i = 1; i <= ns; i++) printf "source\t%s\t%d\n", so[i], srcN[so[i]]
      for (i = 1; i <= nr; i++) print rows[i]
    }
  '
  if [ "$RC" -eq 4 ]; then
    echo "content-count: unsupported registry layout; the LAYOUT rows give each line and the layout expected there" >&2
    exit 4
  fi
  exit 0
fi

# ---------------------------------------------------------------------- found
if [ -n "$ENGINE_ARG" ]; then
  RAW="$ENGINE_ARG"; ESRC="flag"
else
  # engine.name from project.local.yaml, then project.yaml, read by the shared
  # yaml-get.awk as project-state.sh reads it (and much faster than running it);
  # only when neither names one, project-state.sh's legacy fallback decides.
  RAW=""; ESRC=""
  [ -f "$HERE/yaml-get.awk" ] || { echo "content-count: $HERE/yaml-get.awk is missing; pass --engine" >&2; exit 1; }
  for yf in project.local.yaml project.yaml; do
    if [ -z "$RAW" ] && [ -f "$yf" ]; then
      RAW=$(YG_PATH=engine.name awk -f "$HERE/yaml-get.awk" "$yf")
      [ -z "$RAW" ] || ESRC="$yf"
    fi
  done
  if [ -z "$RAW" ] && [ -f "$HERE/project-state.sh" ]; then
    ROW=$(bash "$HERE/project-state.sh" --root . | awk -F'\t' '$1 == "engine" { print $2 "\t" $3 }')
    RAW="${ROW%%"$TAB"*}"; ESRC="${ROW#*"$TAB"}"
  fi
fi
if [ -z "$RAW" ] || [ "$RAW" = "-" ]; then
  printf 'engine\t-\tunset\n'
  echo "content-count: no engine is set (engine.name in project.yaml); pass --engine" >&2
  exit 3
fi
LOW=$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]')
# cell COLUMN -- the engine's cell of the engine table (engine-row.awk), empty for `-`.
ETAB="$HERE/../engines/engines.tsv"
[ -f "$ETAB" ] && [ -f "$HERE/engine-row.awk" ] || { echo "content-count: the engine table $ETAB or engine-row.awk is missing" >&2; exit 1; }
cell() { awk -F'\t' -v engine="$RAW" -v col="$1" -f "$HERE/engine-row.awk" "$ETAB"; }
# The rules below differ per engine, so the engine keeps its own case.
case "$LOW" in
  godot) ENG=godot ;;
  unity) ENG=unity ;;
  unreal*) ENG=unreal ;;
  web) ENG=web ;;
  *)
    if [ "$ESRC" = flag ]; then usage "--engine takes godot, unity, unreal or web, got $RAW"; fi
    printf 'engine\t%s\t%s\n' "$RAW" "$ESRC"
    echo "content-count: engine $RAW has no content rules here (godot, unity, unreal or web)" >&2
    exit 3 ;;
esac
# The roots, from the engine table: assets/, then the engine's asset root
# (Unity Assets/, Unreal Content/), or its code root where that asset root is
# assets/ itself (Godot src/, Web src/). Web's data files sit in data/.
AROOT=$(cell asset_root); CROOT=$(cell code_root)
if [ "$AROOT" = assets ]; then ROOTS="assets $CROOT"; else ROOTS="assets $AROOT"; fi
[ "$ENG" = web ] && ROOTS="assets data $CROOT"
printf 'engine\t%s\t%s\n' "$ENG" "$ESRC"

PRESENT=""; NPRES=0
for r in $ROOTS; do
  # The exact name, from the listing: -d would say yes to Assets for a
  # directory called assets on a case-insensitive disk.
  if [ -n "$(find . -maxdepth 1 -type d -name "$r" 2>/dev/null)" ]; then
    printf 'root\t%s\tpresent\n' "$r"; PRESENT="$PRESENT $r"; NPRES=$((NPRES + 1))
  else
    printf 'root\t%s\tabsent\n' "$r"
  fi
done
LIST=""
# shellcheck disable=SC2086
[ -z "$PRESENT" ] || LIST=$(find $PRESENT -type f 2>/dev/null | sort)

printf '%s\n' "$LIST" | ENG="$ENG" SHOWFILES="$SHOWFILES" awk '
  BEGIN {
    BINMODE = 3; eng = ENVIRON["ENG"]
    ng = split("levels characters items abilities dialogue quests", G, " ")
    nfl["levels"] = split("levels areas maps worlds stages", t1, " ")
    nfl["characters"] = split("enemies characters npcs", t2, " ")
    nfl["items"] = split("items equipment loot", t3, " ")
    nfl["abilities"] = split("abilities skills spells", t4, " ")
    nfl["dialogue"] = split(".dialogue .csv .ink", t5, " ")
    nfl["quests"] = split("quests missions objectives", t6, " ")
    for (i = 1; i <= 6; i++) { FL["levels", i] = t1[i]; FL["characters", i] = t2[i]; FL["items", i] = t3[i]
      FL["abilities", i] = t4[i]; FL["dialogue", i] = t5[i]; FL["quests", i] = t6[i] }
    if (eng == "unity") { nfl["items"]++; FL["items", nfl["items"]] = "*Item*.asset" }
  }
  # Is e one of the engine data extensions for type g.
  function extok(g, e) {
    if (eng == "unreal") return (e == "uasset")
    if (eng == "unity") return (e == "json" || e == "yaml" || e == "asset" || e == "prefab")
    if (g == "characters") return (e == "json" || e == "tres" || e == "asset" || e == "yaml" || e == "tscn" || e == "prefab")
    if (g == "quests") return (e == "json" || e == "yaml")
    return (e == "json" || e == "tres" || e == "asset")
  }
  function isfolder(g, name,    i) {
    for (i = 1; i <= nfl[g]; i++) if (FL[g, i] == name) return 1
    return 0
  }
  NF > 0 {
    p = $0; sub(/\r$/, "", p)
    n = split(p, seg, "/")
    if (n < 2) next
    root = seg[1]; fname = seg[n]
    ext = ""
    if (match(fname, /\.[^.]*$/)) ext = tolower(substr(fname, RSTART + 1))
    # The first folder to look in: under assets/ only below assets/data/.
    first = 2; datalock = 0
    if (root == "assets") { datalock = 1; first = (n >= 3 && tolower(seg[2]) == "data") ? 3 : n }
    srcroot = (eng == "godot" && root == "src")
    for (gi = 1; gi <= ng; gi++) {
      g = G[gi]; hit = 0; nh = 0
      # Web has no scene files: its levels are data files in a levels/ folder.
      if (g == "levels" && eng != "web") {
        sceneext = (eng == "godot") ? "tscn" : ((eng == "unity") ? "unity" : "umap")
        if (ext != sceneext) continue
        hit = 1
        for (i = 2; i < n; i++) { w = tolower(seg[i]); if (isfolder(g, w) && !(w in hs)) { hs[w] = 1; hn[++nh] = w } }
      } else if (g == "dialogue") {
        if (srcroot) continue
        if (ext != "dialogue" && ext != "csv" && ext != "ink") continue
        hit = 1; hn[++nh] = "." ext
      } else {
        if (srcroot && g != "characters") continue
        if (extok(g, ext)) {
          for (i = first; i < n; i++) { w = tolower(seg[i]); if (isfolder(g, w) && !(w in hs)) { hs[w] = 1; hn[++nh] = w; hit = 1 } }
        }
        if (eng == "unity" && g == "items" && root == "Assets" && ext == "asset" && index(fname, "Item") > 0) { hit = 1; hn[++nh] = "*Item*.asset" }
      }
      if (hit) {
        tot[g]++
        for (i = 1; i <= nh; i++) by[g, hn[i]]++
        if (ENVIRON["SHOWFILES"] == "1") frow[++nfr] = "FILE\t" g "\t" p
      }
      for (i = 1; i <= nh; i++) delete hs[hn[i]]
    }
  }
  END {
    for (gi = 1; gi <= ng; gi++) printf "found\t%s\t%d\n", G[gi], tot[G[gi]]
    for (gi = 1; gi <= ng; gi++) {
      g = G[gi]
      for (i = 1; i <= nfl[g]; i++) printf "by\t%s\t%s\t%d\n", g, FL[g, i], by[g, FL[g, i]]
    }
    for (i = 1; i <= nfr; i++) print frow[i]
  }
'
if [ "$NPRES" -eq 0 ]; then
  echo "content-count: none of the roots ($ROOTS) exists; nothing was scanned" >&2
  exit 4
fi
exit 0
