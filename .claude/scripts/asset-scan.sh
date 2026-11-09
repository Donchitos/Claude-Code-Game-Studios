#!/usr/bin/env bash
# asset-scan.sh — the measurements /asset-audit takes by hand: asset names
# against the naming rule, PNG power-of-two dimensions, file sizes against the
# budgets you pass, audio sample rates where `file` reports one, and assets no
# source file references (orphans) or source references to a file that is not
# there (missing), each with the check that ran or the reason it did not.
#
# Replaces the hand-run asset scan: the file listing, `wc -c`, the PNG header
# read with `od`, the sample rate read with `file`, and the orphan and
# missing-asset searches.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/").
# A row is a rule that matched a file; the counts under "hits" are rows, not
# violations, and the words the skill ranks its report by (COMPLIANT,
# WARNINGS, NON-COMPLIANT, NOT ASSESSED) stay in the skill. A check that did
# not run says so in a `check` row and its hits are `-`, never 0: a scan that
# measured nothing is not a scan that found nothing.
#
# Usage: bash .claude/scripts/asset-scan.sh [--root DIR] [--engine E] [--category C]
#          [--budget KEY=SIZE ...] [--max-dim N] [--sample-rates LIST]
#          [--name-regex ERE] [--files]
#   --root DIR          the project; defaults to the repo this script is in
#   --engine E          godot, unity, unreal or web (default: engine.name from
#                       project.local.yaml, then project.yaml, as content-count.sh)
#   --category C        keep one category: on godot a folder of assets/ (art,
#                       audio, vfx, shaders or data); on unity and unreal the
#                       first folder under the asset root (any case)
#   --budget KEY=SIZE   a size budget in bytes, or with a K (1024) or M
#                       (1048576) suffix. Budgets are prose in the art bible,
#                       so they are flags and never read from it. KEY is `all`,
#                       a type (texture, audio, data, other) or a file
#                       extension (png, ogg, ...); the most specific one that
#                       applies wins: extension, then type, then all. A key
#                       given twice is an error. A file of exactly SIZE bytes
#                       is inside its budget.
#   --max-dim N         a texture whose width or height is above N pixels
#   --sample-rates L    comma-separated Hz values audio may have (44100,48000)
#   --name-regex ERE    the art bible's naming rule: replaces the built-in rule,
#                       and is the only naming rule on unity and unreal; matched
#                       against the file name with its extension
#   --files             one FILE row per scanned file
#   -h, --help          this text
#
# What is scanned (the skill's Phase 2):
#   godot   assets/art, assets/audio, assets/vfx, assets/shaders, assets/data
#           (other folders of assets/ are counted as outside_scope, not scanned)
#   unity   Assets/, leaving out scripts (.cs, .asmdef) and .meta files
#   unreal  Content/*.uasset and Content/*.umap
# Left out on every engine: .gitkeep placeholders. Left out on godot: .import
# files (the importer writes one beside each source asset; it is not an asset
# and its source_file line is not a reference) and .uid files (Godot 4.4+
# writes one beside each script and shader). Each left-out kind is counted in
# an `excluded` row.
#
# Naming (the skill's Phase 3): all file names lowercase with underscores. The
# built-in rule is the characters a-z 0-9 and _ in the name and a-z 0-9 in the
# extension, one dot before the extension; a NAMING row lists what broke it, in
# order of first appearance: uppercase, space, hyphen, dot (an extra one), other.
# The art and audio patterns ([category]_[name]_[variant]_[size].[ext] and
# [category]_[context]_[name]_[variant].[ext]) are NOT CHECKABLE from the
# skill: it defines no category or size values and its own examples disagree
# on what fills the size slot, so a `check` row says so with the number of
# files each would cover, and nothing is compared against them.
#
# Textures: PNG width and height are read from the IHDR header (24 bytes: 8 of
# signature, 4 of chunk length, 4 of chunk name, 4 of width, 4 of height, all
# big-endian) with `od`. A dimension is a power of two when halving it reaches
# 1 without an odd step (awk here has no bitwise operators); 0 is not one. A
# texture in another format, or a PNG with no readable header, is a NOTREAD
# row. Compression for 3D and PNG for UI are not checked: the skill does not
# say how to tell a UI texture from a 3D one. On unreal an asset file keeps
# neither its source format nor its dimensions, so dimensions and sample
# rates are not read there.
#
# Audio: the sample rate is the `N Hz` (or `N.N kHz`) that `file -b` prints; a
# file `file` reports no rate for is a NOTREAD row. Duration is not measurable
# here. File size is `wc -c`, never `stat`, which differs between GNU and BSD;
# for the same reason the last-modified time the skill lists with its orphans
# is not read.
#
# Orphans and missing (godot only): the references are the res:// paths found
# in every .gd, .cs, .gdshader, .gdshaderinc, .tscn and .tres file of the
# project (except under .godot/ and .git/) and in project.godot, so a scene or
# resource that names an asset counts. A path ends at a quote, a bracket, a
# comma, a semicolon or (when it did not start in quotes) a space. An asset is
# an ORPHAN when no other file names its path. A path ending in / is a folder
# prefix (DYNAMIC prefix): it covers every asset below it, and the row says how
# many. A path with % or * or ? is a built name (DYNAMIC pattern) and covers
# nothing. A reference to a file under assets/ that does not exist is MISSING,
# with the first place it appears and how many places name it. Both need at
# least one .gd, .cs or .gdshader file under src/ (the skill: no code to
# search means not assessed), and run only on godot: on unity and unreal most
# references live in scenes, prefabs and other assets, and no reference syntax
# for them is defined here.
#
# Output: TSV, in this order.
#   engine <name> <source: flag, project.yaml, ...>, root <dir> present|absent,
#   category_filter <name> (with --category), scanned <n>, outside_scope <n> <note>
#   (godot), excluded <kind> <n> per kind, category <name> <n> per category
#   (godot: art, audio, vfx, shaders, data; others: by name, `-` for files
#   directly in the root), check <name> <ran | not_run | not_checkable> <detail>
#   for naming, art_pattern, audio_pattern, pot, size, dim, rate, orphans,
#   missing, data, format and last_modified, then hits <kind> <n | -> for
#   naming, pot, size, dim, rate, notread, orphan and missing, then the rows:
#   NAMING <path> <rule> <what broke it>
#   POT <path> <WxH> <width | height | both>
#   SIZE <path> <bytes> <budget> <overage> <key: all | type:T | ext:E>
#   DIM <path> <WxH> <max>
#   RATE <path> <hz> <allowed>
#   NOTREAD <path> <dims | rate> <reason>
#   ORPHAN <path> <bytes>
#   MISSING <expected path> <file:line of the first reference> <references>
#   DYNAMIC <prefix | pattern> <path> <file:line> <assets covered | ->
#   FILE <path> <category> <type> <bytes> <WxH | -> <hz | ->   (with --files)
#   Rows of one kind are in path order (bytewise).
#
# Exit codes: 0 scanned (whatever it found, none included); 1 the root cannot
# be read, or a script it needs is missing; 2 usage error; 3 no engine set, or
# an engine without rules (prints its engine row); 4 the asset root is absent
# (its root row says absent), so nothing was scanned. Reads only; never
# writes, never prompts.
#
# bash 3.2 and BWK awk safe, no Python. BWK awk's split() with
# a one-character separator also splits on newlines, so split() is used here
# only on a single line (a path, a row) or on a list whose separator is the
# newline itself. Listings reach awk on stdin with "./" in front of every
# file name (never as arguments), so a file called x=1.gd is not an assignment.

set -u
# Byte semantics for awk, sort and tolower.
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
usage() { echo "asset-scan: $1 (try --help)" >&2; exit 2; }
TAB=$(printf '\t')

ROOT_ARG=""; ENGINE_ARG=""; CATF=""; BUDGETS=""; BUDGET_FLAGS=""; MAXDIM=""
RATES=""; NAMERE=""; SHOWFILES=0; BSPEC=""; BGOT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || usage "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    --root=*) ROOT_ARG="${1#--root=}"; shift ;;
    --engine) [ $# -ge 2 ] || usage "--engine needs a name"; ENGINE_ARG="$2"; shift 2 ;;
    --engine=*) ENGINE_ARG="${1#--engine=}"; shift ;;
    --category) [ $# -ge 2 ] || usage "--category needs a name"; CATF="$2"; shift 2 ;;
    --category=*) CATF="${1#--category=}"; shift ;;
    --budget) [ $# -ge 2 ] || usage "--budget needs KEY=SIZE"; BSPEC="$2"; BGOT=1; shift 2 ;;
    --budget=*) BSPEC="${1#--budget=}"; BGOT=1; shift ;;
    --max-dim) [ $# -ge 2 ] || usage "--max-dim needs a number"; MAXDIM="$2"; shift 2 ;;
    --max-dim=*) MAXDIM="${1#--max-dim=}"; shift ;;
    --sample-rates) [ $# -ge 2 ] || usage "--sample-rates needs a list"; RATES="$2"; shift 2 ;;
    --sample-rates=*) RATES="${1#--sample-rates=}"; shift ;;
    --name-regex) [ $# -ge 2 ] || usage "--name-regex needs a pattern"; NAMERE="$2"; shift 2 ;;
    --name-regex=*) NAMERE="${1#--name-regex=}"; shift ;;
    --files) SHOWFILES=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -?*) usage "unknown argument: $1" ;;
    *) usage "unexpected argument: $1" ;;
  esac
  # A --budget was just read: check it and add it. (Done after the case so
  # that both spellings share the checks.)
  if [ "$BGOT" = 1 ]; then
    case "$BSPEC" in *=*) ;; *) usage "--budget takes KEY=SIZE, got $BSPEC" ;; esac
    BK="${BSPEC%%=*}"; BV="${BSPEC#*=}"
    [ -n "$BK" ] && [ -n "$BV" ] || usage "--budget takes KEY=SIZE, got $BSPEC"
    case "$BK" in *[!A-Za-z0-9]*) usage "--budget key must be letters and digits, got $BK" ;; esac
    case "$BV" in *[!0-9KkMm]*) usage "--budget size is a number of bytes with an optional K or M, got $BV" ;; esac
    BD="${BV%[KkMm]}"
    case "$BD" in ''|*[!0-9]*) usage "--budget size is a number of bytes with an optional K or M, got $BV" ;; esac
    # K is 1024 bytes and M is 1048576: sizes are file sizes, not marketing sizes.
    BN=$((10#$BD))
    case "$BV" in *[Kk]) BN=$((BN * 1024)) ;; *[Mm]) BN=$((BN * 1048576)) ;; esac
    BL=$(printf '%s' "$BK" | tr 'A-Z' 'a-z')
    case "$BL" in
      all) BCAN="all" ;;
      texture|audio|data|other) BCAN="type:$BL" ;;
      *) BCAN="ext:$BL" ;;
    esac
    case "
$BUDGETS" in *"
$BCAN="*) usage "--budget key $BK given twice" ;; esac
    BUDGETS="$BUDGETS$BCAN=$BN
"
    BUDGET_FLAGS="${BUDGET_FLAGS:+$BUDGET_FLAGS }$BSPEC"
    BGOT=0
  fi
done
if [ -n "$MAXDIM" ]; then
  case "$MAXDIM" in ''|*[!0-9]*) usage "--max-dim takes a whole number of pixels" ;; esac
  [ $((10#$MAXDIM)) -ge 1 ] || usage "--max-dim takes a number above 0"
  MAXDIM=$((10#$MAXDIM))
fi
if [ -n "$RATES" ]; then
  case "$RATES" in ''|*[!0-9,]*|,*|*,|*,,*) usage "--sample-rates takes comma-separated Hz values, got $RATES" ;; esac
fi
if [ -n "$NAMERE" ]; then
  # An invalid pattern is a usage error here, not an awk crash halfway through.
  R="$NAMERE" awk 'BEGIN { x = ("" ~ ENVIRON["R"]) }' >/dev/null 2>&1 || usage "--name-regex is not a valid regular expression: $NAMERE"
fi
CATF=$(printf '%s' "$CATF" | tr 'A-Z' 'a-z')

if [ -n "$ROOT_ARG" ]; then
  cd "$ROOT_ARG" 2>/dev/null || { echo "asset-scan: cannot read root $ROOT_ARG" >&2; exit 1; }
else
  cd "$HERE/../.." 2>/dev/null || { echo "asset-scan: cannot reach the repo root" >&2; exit 1; }
fi

# ----------------------------------------------------------------------- engine
# engine.name from project.local.yaml, then project.yaml, read by the shared
# yaml-get.awk as content-count.sh reads it; only when neither names one,
# project-state.sh's legacy fallback decides.
if [ -n "$ENGINE_ARG" ]; then
  RAW="$ENGINE_ARG"; ESRC="flag"
else
  RAW=""; ESRC=""
  [ -f "$HERE/yaml-get.awk" ] || { echo "asset-scan: $HERE/yaml-get.awk is missing; pass --engine" >&2; exit 1; }
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
  echo "asset-scan: no engine is set (engine.name in project.yaml); pass --engine" >&2
  exit 3
fi
LOW=$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]')
# cell COLUMN -- the engine's cell of the engine table (engine-row.awk), empty for `-`.
ETAB="$HERE/../engines/engines.tsv"
[ -f "$ETAB" ] && [ -f "$HERE/engine-row.awk" ] || { echo "asset-scan: the engine table $ETAB or engine-row.awk is missing" >&2; exit 1; }
cell() { awk -F'\t' -v engine="$RAW" -v col="$1" -f "$HERE/engine-row.awk" "$ETAB"; }
# The asset root per engine is the skill's Phase 2, from the engine table:
# assets/ on Godot and Web, Assets/ on Unity, Content/ on Unreal. The rules
# below differ per engine, so the engine keeps its own case.
case "$LOW" in
  godot) ENG=godot ;;
  unity) ENG=unity ;;
  unreal*) ENG=unreal ;;
  web) ENG=web ;;
  *)
    if [ "$ESRC" = flag ]; then usage "--engine takes godot, unity, unreal or web, got $RAW"; fi
    printf 'engine\t%s\t%s\n' "$RAW" "$ESRC"
    echo "asset-scan: engine $RAW has no asset rules here (godot, unity, unreal or web)" >&2
    exit 3 ;;
esac
ROOTDIR=$(cell asset_root)
if [ "$ENG" = godot ] && [ -n "$CATF" ]; then
  case "$CATF" in
    art|audio|vfx|shaders|data) ;;
    *) usage "--category on godot takes art, audio, vfx, shaders or data, got $CATF" ;;
  esac
fi

printf 'engine\t%s\t%s\n' "$ENG" "$ESRC"
# The exact name from the listing: -d would say yes to Assets for a directory
# called assets on a case-insensitive disk.
if [ -z "$(find . -maxdepth 1 -type d -name "$ROOTDIR" 2>/dev/null)" ]; then
  printf 'root\t%s\tabsent\n' "$ROOTDIR"
  echo "asset-scan: $ROOTDIR/ does not exist; nothing was scanned" >&2
  exit 4
fi
printf 'root\t%s\tpresent\n' "$ROOTDIR"

# --------------------------------------------------------------------- listing
ALLF=$(find "$ROOTDIR" -type f 2>/dev/null | sort)
CLASS=$(printf '%s\n' "$ALLF" | ENG="$ENG" CATF="$CATF" awk '
  BEGIN { BINMODE = 3; eng = ENVIRON["ENG"]; catf = ENVIRON["CATF"] }
  length($0) > 0 {
    p = $0
    n = split(p, seg, "/")
    base = seg[n]
    ext = ""
    if (match(base, /\.[^.]*$/)) ext = tolower(substr(base, RSTART + 1))
    # Every file but a .import is something a reference could name.
    if (eng == "godot" && ext != "import") print "E\t" p
    reason = ""
    if (base == ".gitkeep") reason = ".gitkeep"
    else if (eng == "godot" && ext == "import") reason = ".import"
    else if (eng == "godot" && ext == "uid") reason = ".uid"
    else if (eng == "unity" && ext == "meta") reason = ".meta"
    else if (eng == "unity" && ext == "cs") reason = ".cs"
    else if (eng == "unity" && ext == "asmdef") reason = ".asmdef"
    else if (eng == "unreal" && ext != "uasset" && ext != "umap") reason = "not .uasset or .umap"
    if (reason != "") { print "X\t" reason; next }
    if (eng == "godot") {
      # The skill scans five folders of assets/; the rest is counted, not scanned.
      s = seg[2]
      if (n < 3 || (s != "art" && s != "audio" && s != "vfx" && s != "shaders" && s != "data")) { print "O\t" p; next }
      cat = s
    } else cat = (n >= 3) ? seg[2] : "-"
    if (catf != "" && tolower(cat) != catf) next
    print "K\t" p
  }
')
KEPT=$(printf '%s\n' "$CLASS" | awk 'substr($0, 1, 2) == "K\t" { print substr($0, 3) }')

# PNG headers (godot and unity; an unreal asset file has none) and audio
# descriptions are collected per file; sizes in one batch of wc -c.
PNGS=""; AUDIOS=""
if [ "$ENG" != unreal ] && [ -n "$KEPT" ]; then
  PNGS=$(printf '%s\n' "$KEPT" | awk 'tolower($0) ~ /\.png$/')
  AUDIOS=$(printf '%s\n' "$KEPT" | awk 'tolower($0) ~ /\.(ogg|wav|mp3|flac|opus|m4a|aac|aif|aiff)$/')
fi
HAVEFILE=0
command -v file >/dev/null 2>&1 && HAVEFILE=1

# The files orphans and missing search: godot only, and only when src/ holds
# code, as the skill says.
SRCN=0; CORPUS=""; NCORP=0
if [ "$ENG" = godot ] && [ -d src ]; then
  SRCN=$(find src -type f \( -name '*.gd' -o -name '*.cs' -o -name '*.gdshader' \) 2>/dev/null | wc -l | tr -d ' ')
  if [ "$SRCN" -gt 0 ]; then
    CORPUS=$(find . -type f \( -name '*.gd' -o -name '*.cs' -o -name '*.gdshader' -o -name '*.gdshaderinc' \
      -o -name '*.tscn' -o -name '*.tres' -o -name 'project.godot' \) \
      -not -path './.godot/*' -not -path './.git/*' 2>/dev/null | sed 's|^\./||' | sort)
    NCORP=$(printf '%s\n' "$CORPUS" | awk 'length($0) > 0' | wc -l | tr -d ' ')
  fi
fi

# ------------------------------------------------------------------ measuring
{
  printf '%s\n' "$CLASS"
  if [ -n "$KEPT" ]; then
    printf '%s\n' "$KEPT" | awk 'length($0) > 0 { printf "./%s\n", $0 }' | tr '\n' '\0' | xargs -0 wc -c 2>/dev/null | \
      awk 'BEGIN { BINMODE = 3 } { i = index($0, "./"); if (i == 0) next; n = $1 + 0; print "S\t" n "\t" substr($0, i + 2) }'
  fi
  if [ -n "$PNGS" ]; then
    printf '%s\n' "$PNGS" | while IFS= read -r p; do
      [ -n "$p" ] || continue
      printf 'P\t%s\t' "$p"
      od -A n -t u1 -v -N 24 "./$p" 2>/dev/null | tr '\n' ' '
      printf '\n'
    done
  fi
  if [ -n "$AUDIOS" ]; then
    printf '%s\n' "$AUDIOS" | awk 'length($0) > 0 { print "L\t" $0 }'
    if [ "$HAVEFILE" = 1 ]; then
      printf '%s\n' "$AUDIOS" | awk 'length($0) > 0 { printf "./%s\n", $0 }' | tr '\n' '\0' | xargs -0 file -b 2>/dev/null | \
        awk 'BEGIN { BINMODE = 3 } { print "D\t" $0 }'
    fi
  fi
  if [ -n "$CORPUS" ]; then
    printf '%s\n' "$CORPUS" | awk 'length($0) > 0 { print "C\t" $0 }'
  fi
} | ENG="$ENG" ROOTDIR="$ROOTDIR" CATF="$CATF" BUDGETS="$BUDGETS" BUDGET_FLAGS="$BUDGET_FLAGS" MAXDIM="$MAXDIM" \
    RATES="$RATES" NAMERE="$NAMERE" SHOWFILES="$SHOWFILES" SRCN="$SRCN" NCORP="$NCORP" HAVEFILE="$HAVEFILE" awk '
  BEGIN {
    BINMODE = 3
    eng = ENVIRON["ENG"]; rootdir = ENVIRON["ROOTDIR"]; catf = ENVIRON["CATF"]
    maxdim = ENVIRON["MAXDIM"] + 0; namere = ENVIRON["NAMERE"]; showfiles = ENVIRON["SHOWFILES"]
    srcn = ENVIRON["SRCN"] + 0; ncorp = ENVIRON["NCORP"] + 0; havefile = ENVIRON["HAVEFILE"]
    # Budgets arrive one per line as key=bytes. The separator is the newline
    # itself, which BWK awk splits on anyway.
    bs = ENVIRON["BUDGETS"]
    nbl = split(bs, bl, "\n")
    for (i = 1; i <= nbl; i++) if (bl[i] != "") { p = index(bl[i], "="); B[substr(bl[i], 1, p - 1)] = substr(bl[i], p + 1) + 0; hasb = 1 }
    nra = 0
    rs = ENVIRON["RATES"]
    if (rs != "") { nra = split(rs, ral, ","); for (i = 1; i <= nra; i++) RA[ral[i] + 0] = 1 }
    # The tagged listing on stdin: K kept file, X left-out kind, O outside the
    # scanned folders, E existing file (godot), S size, P PNG header bytes,
    # L audio file, D what file -b said about it (same order as L), C file to
    # search for references.
    while ((getline line < "/dev/stdin") > 0) {
      tag = substr(line, 1, 1); rest = substr(line, 3)
      if (tag == "K") kept[++nk] = rest
      else if (tag == "X") xc[rest]++
      else if (tag == "O") nout++
      else if (tag == "E") exist[rest] = 1
      else if (tag == "S") { t = index(rest, "\t"); size[substr(rest, t + 1)] = substr(rest, 1, t - 1) + 0 }
      else if (tag == "P") { t = index(rest, "\t"); hdr[substr(rest, 1, t - 1)] = substr(rest, t + 1) }
      else if (tag == "L") lst[++nl] = rest
      else if (tag == "D") dsc[++nd] = rest
      else if (tag == "C") corp[++nc] = rest
    }
    for (i = 1; i <= nl; i++) if (i <= nd) adesc[lst[i]] = dsc[i]
    # "./" in front of a name keeps x=1.gd from reading as an awk assignment.
    for (i = 1; i <= nc; i++) ARGV[ARGC++] = "./" corp[i]
  }

  # --- references, read from each searched file (the main input) -------------
  FNR == 1 { curfile = substr(FILENAME, 3) }
  {
    t = $0; sub(/\r$/, "", t)
    while ((i = index(t, "res://")) > 0) {
      prev = (i > 1) ? substr(t, i - 1, 1) : ""
      rest = substr(t, i + 6)
      if (prev == "\"" || prev == "\047") {
        # Opened by a quote: only the same quote ends it, so a name with a space is whole.
        e = index(rest, prev)
        tok = (e > 0) ? substr(rest, 1, e - 1) : rest
      } else {
        if (match(rest, "[ \t\"\047(){},;<>]|\\]|\\[")) tok = substr(rest, 1, RSTART - 1); else tok = rest
        # A sentence full stop or colon after an unquoted path is not part of it.
        sub(/[.:!?]+$/, "", tok)
      }
      t = substr(t, i + 6 + length(tok))
      if (tok == "" || index(tok, rootdir "/") != 1) continue
      loc = curfile ":" FNR
      if (substr(tok, length(tok), 1) == "/") {
        if (!(tok in dloc)) { dloc[tok] = loc; dkind[tok] = "prefix"; dk[++ndk] = tok }
      } else if (index(tok, "%") > 0 || index(tok, "*") > 0 || index(tok, "?") > 0) {
        if (!(tok in dloc)) { dloc[tok] = loc; dkind[tok] = "pattern"; dk[++ndk] = tok }
      } else {
        refn[tok]++
        if (!(tok in rloc)) { rloc[tok] = loc; rk[++nrk] = tok }
        # A file naming itself does not make itself used.
        if (tok != curfile) other[tok] = 1
      }
    }
  }

  # --- helpers ---------------------------------------------------------------
  function ftype(e) {
    # The types the budgets and the texture checks talk about, by extension.
    if (e ~ /^(png|jpg|jpeg|webp|tga|bmp|exr|hdr|dds|ktx|ktx2)$/) return "texture"
    if (e ~ /^(ogg|wav|mp3|flac|opus|m4a|aac|aif|aiff)$/) return "audio"
    if (e ~ /^(json|yaml|yml)$/) return "data"
    return "other"
  }
  # Powers of two by halving: an odd number above 1 on the way down ends it.
  function pot(n) {
    if (n < 1) return 0
    while (n > 1) { if (n % 2 != 0) return 0; n = n / 2 }
    return 1
  }
  function addcls(k) { if (cseen[k] != cgen) { cseen[k] = cgen; cls = cls (cls == "" ? "" : ",") k } }
  function clsof(c) {
    if (c ~ /[A-Z]/) return "uppercase"
    if (c == " ") return "space"
    if (c == "-") return "hyphen"
    if (c == ".") return "dot"
    return "other"
  }
  # The kinds of break in a name: a-z 0-9 and _ in the stem, a-z 0-9 in the
  # extension (the part after the last dot), in order of first appearance.
  function namebreaks(b,    p, i, stem, ex, c) {
    cls = ""
    cgen++
    p = 0
    for (i = length(b); i >= 1; i--) if (substr(b, i, 1) == ".") { p = i; break }
    if (p == 0) { stem = b; ex = "" } else { stem = substr(b, 1, p - 1); ex = substr(b, p + 1) }
    for (i = 1; i <= length(stem); i++) { c = substr(stem, i, 1); if (c !~ /[a-z0-9_]/) addcls(clsof(c)) }
    for (i = 1; i <= length(ex); i++) { c = substr(ex, i, 1); if (c !~ /[a-z0-9]/) addcls(clsof(c)) }
    return cls
  }
  # The kHz form (44.1 kHz) is turned into Hz and rounded, so 22.05 is 22050.
  function rateof(d,    r) {
    if (match(d, /[0-9]+ Hz/)) return substr(d, RSTART, RLENGTH - 3) + 0
    if (match(d, /[0-9]+(\.[0-9]+)? kHz/)) { r = substr(d, RSTART, RLENGTH - 4) + 0; return int(r * 1000 + 0.5) }
    return ""
  }

  END {
    scanned = nk
    nodata = (scanned == 0) ? ("no assets under " rootdir) : ""
    if (catf != "") printf "category_filter\t%s\n", catf
    printf "scanned\t%d\n", scanned
    if (eng == "godot") printf "outside_scope\t%d\tfiles under assets/ outside art, audio, vfx, shaders and data\n", nout
    if (eng == "godot") { nx = split(".import .uid .gitkeep", xl, " ") }
    else if (eng == "unity") { nx = split(".meta .cs .asmdef .gitkeep", xl, " ") }
    else if (eng == "unreal") { nx = 2; xl[1] = "not .uasset or .umap"; xl[2] = ".gitkeep" }
    else { nx = 1; xl[1] = ".gitkeep" }
    for (i = 1; i <= nx; i++) printf "excluded\t%s\t%d\n", xl[i], xc[xl[i]]

    # --- per-file facts, in path order (the listing arrives sorted) ---
    for (i = 1; i <= nk; i++) {
      p = kept[i]
      n = split(p, seg, "/")
      base = seg[n]
      ex = ""
      if (match(base, /\.[^.]*$/)) ex = tolower(substr(base, RSTART + 1))
      cat = (eng == "godot" || n >= 3) ? seg[2] : "-"
      ty = ftype(ex)
      kcat[i] = cat; ktype[i] = ty
      catn[cat]++
      if (!(cat in catseen)) { catseen[cat] = 1; catlist[++ncat] = cat }
      by = (p in size) ? size[p] : -1
      kbytes[i] = by
      if (cat == "art") nart++
      if (cat == "audio") naud++
    }
    if (eng == "godot") {
      ng = split("art audio vfx shaders data", gl, " ")
      for (i = 1; i <= ng; i++) printf "category\t%s\t%d\n", gl[i], catn[gl[i]]
    } else {
      for (i = 2; i <= ncat; i++) { x = catlist[i]; for (j = i - 1; j >= 1 && catlist[j] > x; j--) catlist[j + 1] = catlist[j]; catlist[j + 1] = x }
      for (i = 1; i <= ncat; i++) printf "category\t%s\t%d\n", catlist[i], catn[catlist[i]]
    }

    # --- which checks run ---
    gdnaming = (eng == "godot" && namere == "")
    if (nodata != "") { namingst = "not_run"; namingd = nodata }
    else if (namere != "") { namingst = "ran"; namingd = "name_regex " namere }
    else if (eng == "godot") { namingst = "ran"; namingd = "lowercase_underscore" }
    else { namingst = "not_run"; namingd = "no naming rule for " eng "; pass the art bible\047s rule with --name-regex" }
    unrealwhy = "asset files do not keep their source format, dimensions or sample rate"
    if (nodata != "") { potst = "not_run"; potd = nodata }
    else if (eng == "unreal") { potst = "not_run"; potd = unrealwhy }
    else { potst = "ran"; potd = "PNG width and height from the IHDR bytes" }
    if (nodata != "") { sizest = "not_run"; sized = nodata }
    else if (!hasb) { sizest = "not_run"; sized = "no --budget flag given" }
    else { sizest = "ran"; sized = ENVIRON["BUDGET_FLAGS"] }
    if (nodata != "") { dimst = "not_run"; dimd = nodata }
    else if (maxdim == 0) { dimst = "not_run"; dimd = "no --max-dim flag given" }
    else if (eng == "unreal") { dimst = "not_run"; dimd = unrealwhy }
    else { dimst = "ran"; dimd = "--max-dim " maxdim }
    if (nodata != "") { ratest = "not_run"; rated = nodata }
    else if (eng == "unreal") { ratest = "not_run"; rated = unrealwhy }
    else if (havefile != 1) { ratest = "not_run"; rated = "file is not installed" }
    else { ratest = "ran"; rated = (nra > 0) ? ("file -b; allowed " ENVIRON["RATES"]) : "file -b; no --sample-rates flag given, none compared" }
    if (nodata != "") { orphst = "not_run"; orphd = nodata }
    else if (eng == "web") { orphst = "not_run"; orphd = "no reference syntax is defined for " eng }
    else if (eng != "godot") { orphst = "not_run"; orphd = "references live in scenes, prefabs and other assets, not in code" }
    else if (srcn == 0) { orphst = "not_run"; orphd = "no source files under src/" }
    else { orphst = "ran"; orphd = ncorp " files searched for res:// paths" }
    if (eng != "godot") { missst = "not_run"; missd = "no reference syntax is defined for " eng }
    else if (srcn == 0) { missst = "not_run"; missd = "no source files under src/" }
    else { missst = "ran"; missd = ncorp " files searched for res:// paths" }

    printf "check\tnaming\t%s\t%s\n", namingst, namingd
    if (gdnaming) {
      if (nodata != "") {
        printf "check\tart_pattern\tnot_run\t%s\ncheck\taudio_pattern\tnot_run\t%s\n", nodata, nodata
      } else {
        printf "check\tart_pattern\tnot_checkable\t%d files under assets/art; the category and size values are not defined and the examples disagree\n", nart
        printf "check\taudio_pattern\tnot_checkable\t%d files under assets/audio; the category values are not defined and the name may hold any number of words\n", naud
      }
    }
    printf "check\tpot\t%s\t%s\n", potst, potd
    printf "check\tsize\t%s\t%s\n", sizest, sized
    printf "check\tdim\t%s\t%s\n", dimst, dimd
    printf "check\trate\t%s\t%s\n", ratest, rated
    printf "check\torphans\t%s\t%s\n", orphst, orphd
    printf "check\tmissing\t%s\t%s\n", missst, missd
    printf "check\tdata\tnot_run\tJSON and YAML validity and schemas are not checked here\n"
    printf "check\tformat\tnot_run\tfile formats are not checked here: the skill does not say how to tell a UI or 3D texture\n"
    printf "check\tlast_modified\tnot_run\tnot read: stat differs between GNU and BSD\n"

    # --- the rows, built per kind in path order ---
    nname = npot = nsize = ndim = nrate = nnot = norph = nmiss = nfile = 0
    for (i = 1; i <= nk; i++) {
      p = kept[i]; n = split(p, seg, "/"); base = seg[n]
      ex = ""
      if (match(base, /\.[^.]*$/)) ex = tolower(substr(base, RSTART + 1))
      ty = ktype[i]; by = kbytes[i]
      dims = "-"; w = -1; h = -1; rate = "-"
      if (namingst == "ran") {
        if (namere != "") { if (!(base ~ namere)) rname[++nname] = "NAMING\t" p "\tname_regex\tdoes not match " namere }
        else { c = namebreaks(base); if (c != "") rname[++nname] = "NAMING\t" p "\tlowercase_underscore\t" c }
      }
      if (ty == "texture" && eng != "unreal") {
        if (ex != "png") rnot[++nnot] = "NOTREAD\t" p "\tdims\tonly PNG headers are read, not " ex
        else {
          m = split(hdr[p], hb, " ")
          if (m < 24) rnot[++nnot] = "NOTREAD\t" p "\tdims\ttoo short to hold a PNG header"
          else if (hb[1] != 137 || hb[2] != 80 || hb[3] != 78 || hb[4] != 71 || hb[5] != 13 || hb[6] != 10 || hb[7] != 26 || hb[8] != 10) rnot[++nnot] = "NOTREAD\t" p "\tdims\tno PNG signature"
          else if (hb[13] != 73 || hb[14] != 72 || hb[15] != 68 || hb[16] != 82) rnot[++nnot] = "NOTREAD\t" p "\tdims\tno IHDR chunk after the signature"
          else {
            w = hb[17] * 16777216 + hb[18] * 65536 + hb[19] * 256 + hb[20]
            h = hb[21] * 16777216 + hb[22] * 65536 + hb[23] * 256 + hb[24]
            dims = w "x" h
            wp = pot(w); hp = pot(h)
            if (!wp || !hp) rpot[++npot] = "POT\t" p "\t" dims "\t" ((!wp && !hp) ? "both" : ((!wp) ? "width" : "height"))
            if (maxdim > 0 && (w > maxdim || h > maxdim)) rdim[++ndim] = "DIM\t" p "\t" dims "\t" maxdim
          }
        }
      }
      if (ty == "audio" && eng != "unreal") {
        if (havefile != 1) rnot[++nnot] = "NOTREAD\t" p "\trate\tfile is not installed"
        else {
          r = rateof(adesc[p])
          if (r == "") rnot[++nnot] = "NOTREAD\t" p "\trate\tfile reports no sample rate"
          else {
            rate = r
            if (nra > 0 && !(r in RA)) rrate[++nrate] = "RATE\t" p "\t" r "\t" ENVIRON["RATES"]
          }
        }
      }
      if (hasb && by >= 0) {
        key = ""
        if (("ext:" ex) in B) key = "ext:" ex
        else if (("type:" ty) in B) key = "type:" ty
        else if ("all" in B) key = "all"
        if (key != "" && by > B[key]) rsize[++nsize] = "SIZE\t" p "\t" by "\t" B[key] "\t" (by - B[key]) "\t" key
      }
      if (showfiles == 1) rfile[++nfile] = "FILE\t" p "\t" kcat[i] "\t" ty "\t" ((by >= 0) ? by : "-") "\t" dims "\t" rate
    }
    # Orphans and missing: one pass over the scanned files and the references.
    if (orphst == "ran") {
      for (i = 1; i <= nk; i++) {
        p = kept[i]
        if (p in other) continue
        covered = 0
        for (j = 1; j <= ndk; j++) if (dkind[dk[j]] == "prefix" && index(p, dk[j]) == 1) { covered = 1; break }
        if (!covered) rorph[++norph] = "ORPHAN\t" p "\t" ((kbytes[i] >= 0) ? kbytes[i] : "-")
      }
    }
    if (missst == "ran") {
      # The references in path order, by insertion sort (there are few).
      for (i = 1; i <= nrk; i++) srt[i] = rk[i]
      for (i = 2; i <= nrk; i++) { x = srt[i]; for (j = i - 1; j >= 1 && srt[j] > x; j--) srt[j + 1] = srt[j]; srt[j + 1] = x }
      for (i = 1; i <= nrk; i++) {
        tk = srt[i]
        if (tk in exist) continue
        q = split(tk, tseg, "/")
        if (catf != "" && tolower(tseg[2]) != catf) continue
        rmiss[++nmiss] = "MISSING\t" tk "\t" rloc[tk] "\t" refn[tk]
      }
    }
    ndyn = 0
    if (orphst == "ran" || missst == "ran") {
      for (i = 1; i <= ndk; i++) dsrt[i] = dk[i]
      for (i = 2; i <= ndk; i++) { x = dsrt[i]; for (j = i - 1; j >= 1 && dsrt[j] > x; j--) dsrt[j + 1] = dsrt[j]; dsrt[j + 1] = x }
      for (i = 1; i <= ndk; i++) {
        tk = dsrt[i]
        q = split(tk, tseg, "/")
        if (catf != "" && tolower(tseg[2]) != catf) continue
        cov = "-"
        if (dkind[tk] == "prefix") { cov = 0; for (j = 1; j <= nk; j++) if (index(kept[j], tk) == 1) cov++ }
        rdyn[++ndyn] = "DYNAMIC\t" dkind[tk] "\t" tk "\t" dloc[tk] "\t" cov
      }
    }

    # --- hits, then the rows ---
    printf "hits\tnaming\t%s\n", (namingst == "ran") ? nname : "-"
    printf "hits\tpot\t%s\n", (potst == "ran") ? npot : "-"
    printf "hits\tsize\t%s\n", (sizest == "ran") ? nsize : "-"
    printf "hits\tdim\t%s\n", (dimst == "ran") ? ndim : "-"
    printf "hits\trate\t%s\n", (ratest == "ran" && nra > 0) ? nrate : "-"
    printf "hits\tnotread\t%s\n", (potst == "ran" || ratest == "ran") ? nnot : "-"
    printf "hits\torphan\t%s\n", (orphst == "ran") ? norph : "-"
    printf "hits\tmissing\t%s\n", (missst == "ran") ? nmiss : "-"
    for (i = 1; i <= nname; i++) print rname[i]
    for (i = 1; i <= npot; i++) print rpot[i]
    for (i = 1; i <= nsize; i++) print rsize[i]
    for (i = 1; i <= ndim; i++) print rdim[i]
    for (i = 1; i <= nrate; i++) print rrate[i]
    for (i = 1; i <= nnot; i++) print rnot[i]
    for (i = 1; i <= norph; i++) print rorph[i]
    for (i = 1; i <= nmiss; i++) print rmiss[i]
    for (i = 1; i <= ndyn; i++) print rdyn[i]
    for (i = 1; i <= nfile; i++) print rfile[i]
  }
'
exit 0
