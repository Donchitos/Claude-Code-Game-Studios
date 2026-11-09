#!/usr/bin/env bash
# door-in.sh — bring a person's own browser game into the project for /prototype --from (the door,
# references/one-shot-0-door.md): copy it byte for byte into prototypes/<name>/, or an engine or
# tool export into references/<name>/, and check every file's SHA-256, source against copy and
# later against the baseline tag. The original is only ever read.
#
# EMITS OBSERVATIONS, NOT A VERDICT (CLAUDE.md, "Helpers in .claude/scripts/"). It says what it
# found and wrote; what to ask the person, and whether to go on, is the skill's.
#
# Usage: bash .claude/scripts/door-in.sh <path> [--name NAME] [--dry-run] [--root DIR]
#        bash .claude/scripts/door-in.sh --verify <name> <path> [--root DIR]
#        bash .claude/scripts/door-in.sh --after <name> <path> [--root DIR]
#        bash .claude/scripts/door-in.sh --shots <name> --start KEYS --play LOG [--check] [--root DIR]
#   <path>       one .html file, or a folder with index.html at its top (in the project or not)
#   --name NAME  the folder name to use, in place of the one made from the page's <title>
#   --dry-run    say what would be copied and where; write nothing (the bring-in question's facts)
#   --verify     after the baseline commit: each file at baseline/<name> (the bytes git stored)
#                against the source
#   --after      after the tag: assets/provenance.yaml (every file brought, origin unknown, its
#                sha256; made only when the game brought none), evidence/door.md (the record),
#                and the game's keep-its-bytes line in the project's .gitattributes, for clones
#   --shots      the game played four times from a fresh start, without the starter's hook (one-shot-run.sh
#                --hookless, on a temp copy): its first screen, after the start key, and after 10
#                and 30 seconds of play, into evidence/baseline/ with each run's rows and the
#                inputs (inputs.txt). --start: the key or keys that start a game (Enter, Space,
#                click:640,360, or click:text=Clock_in for a button by its words, scrolled
#                into view); --play: an input log of play, repeated to fill 30 seconds
#   --check      with --shots: the same four runs again (inputs.txt's when no --start), into
#                evidence/check/, each compared with the baseline's screen
#   --root DIR   the project; defaults to the repo this script is in
#   -h, --help   this text
#
# Output: TSV.
#   source    <path> file|folder <inside|outside>   inside: the original is in the project
#   kind      game | export <what made it> | web_project | not_a_game <why>
#   refused   <why>                                 then nothing else (exit 3); a folder with no
#                                                   index.html but pages of its own names them
#   name      <name> title|file|folder|given         taken names get -2, -3...
#   dest      prototypes/<name>/ | references/<name>/
#   file      <path in the game> <bytes> <sha256>   one a file, the single file as index.html
#   skipped   <path> <why>                          .git/, node_modules/, .DS_Store, Thumbs.db
#   big       <path> <MB>                           over 50 MB (no LFS)
#   total     <files> <bytes>
#   attributes .git/info/attributes <line>          git keeps the game's bytes as they are
#   copied    <files> same|<n> differ               the copy's hashes against the source's
#   verify    <path> same|differs|missing           --verify, a row a file; then verified <n> <of>
#   wrote     <path>                                --after
#   shot      <which> <png> <screen hash> drawn|blank   --shots: first, start, play-10s, play-30s
#   errors    <which> <n>                           crash, error and uncaught rows in that run
#   same | differs  <which> <baseline hash> <now>   --check: the screen against the baseline's
#   not_assessed <which> <why>                      that run did not play (no browser, served 3D)
#   refused   <why>                                 nothing written (exit 3)
#
# Exit codes: 0 done; 1 a file could not be read or written; 2 usage error; 3 refused (not a
# game, a web project with its own build, the destination there already) or, for --verify, a
# file that differs or is missing.
#
# bash 3.2 and BWK awk safe, no Python.

set -u
LC_ALL=C
export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
use() { echo "door-in: $1 (try --help)" >&2; exit 2; }
MODE=copy; SRC=""; NAME=""; NAME_SET=0; ROOT_ARG=""; DRY=0; START=""; PLAY=""; CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --shots) [ "$MODE" = copy ] || use "--shots is a separate run"; MODE=shots
      [ $# -ge 2 ] || use "--shots needs the game's name"; NAME="$2"; SRC=-; shift 2 ;;
    --start) [ $# -ge 2 ] || use "--start needs a value"; START="$2"; shift 2 ;;
    --play) [ $# -ge 2 ] || use "--play needs a value"; PLAY="$2"; shift 2 ;;
    --check) CHECK=1; shift ;;
    --name) [ $# -ge 2 ] || use "--name needs a value"; NAME="$2"; NAME_SET=1; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --verify|--after) [ "$MODE" = copy ] || use "--verify and --after are separate runs"; MODE=${1#--}
      [ $# -ge 3 ] || use "$1 needs a name and the source's path"; NAME="$2"; SRC="$3"; shift 3 ;;
    --root) [ $# -ge 2 ] || use "--root needs a value"; ROOT_ARG="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) use "unknown argument: $1" ;;
    *) [ -z "$SRC" ] || use "one path only"; SRC="$1"; shift ;;
  esac
done
[ -n "$SRC" ] || use "the game's path is needed"
ROOT="$(cd "${ROOT_ARG:-$HERE/../..}" 2>/dev/null && pwd)" || { echo "door-in: no such folder: $ROOT_ARG" >&2; exit 1; }
cd "$ROOT" || exit 1

# ---- --shots: the untouched game, played four times the same way ------------------------------
if [ "$MODE" = shots ]; then
  D="prototypes/$NAME"
  [ -f "$D/index.html" ] || { printf 'refused\tno %s/index.html\n' "$D"; exit 3; }
  B="$D/evidence/baseline"; OUTD=$B; [ "$CHECK" = 1 ] && OUTD="$D/evidence/check"
  if [ "$CHECK" = 1 ] && [ -z "$START$PLAY" ] && [ -f "$B/inputs.txt" ]; then
    START=$(sed -n 's/^start	//p' "$B/inputs.txt"); PLAY=$(sed -n 's/^play	//p' "$B/inputs.txt")
  fi
  [ -n "$START" ] && [ -n "$PLAY" ] || use "--shots needs --start and --play (with --check, the baseline's inputs.txt will do)"
  mkdir -p "$OUTD" || exit 1
  [ "$CHECK" = 1 ] || printf 'start\t%s\nplay\t%s\n' "$START" "$PLAY" > "$B/inputs.txt"
  steps() { printf '%s\n' "$1" | awk '{ for (i = 1; i <= NF; i++) { t = $i
      if (t ~ /^wait:/) { sub(/^wait:/, "", t); n += int(t * 60 + 0.5) }
      else if (t ~ /^click:/) n += 4
      else if (t ~ /:[0-9.]+$/) { sub(/^[^:]*:/, "", t); s = int(t * 60 + 0.5); if (s < 1) s = 1; n += s + 2 }
      else n += 4 } } END { print n + 0 }'; }   # the driver's count: a press is 2 steps and 2 free
  PRE="wait:1 $START wait:1"; pre=$(steps "$PRE"); one=$(steps "$PLAY"); [ "$one" -gt 0 ] || one=60
  LOGP="$PRE"; k=0; while [ "$k" -lt $(( (1800 + one - 1) / one )) ]; do LOGP="$LOGP $PLAY"; k=$((k + 1)); done
  rc=0
  for w in first start play-10s play-30s; do
    case "$w" in
      first) L="wait:1"; S=60 ;;
      start) L="$PRE"; S=$pre ;;
      play-10s) L="$LOGP"; S=$((pre + 600)) ;;
      play-30s) L="$LOGP"; S=$((pre + 1800)) ;;
    esac
    bash "$HERE/one-shot-run.sh" "$D" "$OUTD/$w.png" --hookless --log "$L" --stop "$S" --limit 300 --root "$ROOT" > "$OUTD/$w.tsv" 2>/dev/null
    r=$?
    if [ "$r" = 3 ] || [ ! -f "$OUTD/$w.png" ]; then
      printf 'not_assessed\t%s\t%s\n' "$w" "$(awk -F'\t' '$1 == "not_assessed" { print $2; exit }' "$OUTD/$w.tsv")"; rc=3; continue
    fi
    sc=$(awk -F'\t' '$1 == "screen" { h = $4; b = $5 } END { print h "\t" b }' "$OUTD/$w.tsv")
    printf 'shot\t%s\t%s\t%s\n' "$w" "$OUTD/$w.png" "$sc"
    printf 'errors\t%s\t%s\n' "$w" "$(awk -F'\t' '$1 == "crash" || $1 == "error" || ($1 == "uncaught" && $2 + 0 > 0) { n++ } END { print n + 0 }' "$OUTD/$w.tsv")"
    if [ "$CHECK" = 1 ]; then
      was=$(awk -F'\t' '$1 == "screen" { h = $4 } END { print h }' "$B/$w.tsv" 2>/dev/null)
      now=$(printf '%s' "$sc" | cut -f1)
      if [ -n "$was" ] && [ "$was" = "$now" ]; then printf 'same\t%s\t%s\t%s\n' "$w" "$was" "$now"; else printf 'differs\t%s\t%s\t%s\n' "$w" "${was:--}" "$now"; fi
    fi
  done
  exit "$rc"
fi

case "$SRC" in /*|[A-Za-z]:*) ;; *) SRC="$ROOT/$SRC" ;; esac
SRC=${SRC%/}
[ -e "$SRC" ] || { printf 'refused\tno such file or folder: %s\n' "$SRC"; exit 3; }

sha() { # sha <file> -- its SHA-256
  if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 < "$1" | cut -d' ' -f1
  else openssl dgst -sha256 < "$1" | sed 's/^.* //'; fi
}
shastdin() { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1; elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | cut -d' ' -f1; else openssl dgst -sha256 | sed 's/^.* //'; fi; }
isgit() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# The files brought: "<path in the game>\t<source file>", in name order. A single file is index.html.
T=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/door-in-$$"); mkdir -p "$T"
trap 'rm -rf "$T"' EXIT
if [ -f "$SRC" ]; then
  SHAPE=file; PAGE="$SRC"
  printf 'index.html\t%s\n' "$SRC" > "$T/list"
else
  SHAPE=folder; PAGE="$SRC/index.html"
  ( cd "$SRC" && find . \( -name .git -o -name node_modules \) -prune -o -type f -print | sed 's|^\./||' | LC_ALL=C sort ) |
    while IFS= read -r f; do
      case "$f" in */.DS_Store|.DS_Store|*/Thumbs.db|Thumbs.db) printf 'skipped\t%s\ta system file\n' "$f" >> "$T/skipped"; continue ;; esac
      printf '%s\t%s/%s\n' "$f" "$SRC" "$f"
    done > "$T/list"
  [ -d "$SRC/.git" ] && printf 'skipped\t.git/\tits history stays in the original; the copy starts at the baseline tag\n' >> "$T/skipped"
  [ -d "$SRC/node_modules" ] && printf 'skipped\tnode_modules/\tinstalled packages, not the game\n' >> "$T/skipped"
fi

# ---- --verify: the tag's stored bytes against the source -------------------------------------
if [ "$MODE" = verify ]; then
  isgit || { printf 'refused\tnot a git project: there is no tag to check\n'; exit 3; }
  git rev-parse -q --verify "refs/tags/baseline/$NAME" >/dev/null || { printf 'refused\tno tag baseline/%s\n' "$NAME"; exit 3; }
  n=0; ok=0
  while IFS="$(printf '\t')" read -r rel file; do
    n=$((n + 1))
    if ! git cat-file -e "baseline/$NAME:prototypes/$NAME/$rel" 2>/dev/null; then printf 'verify\t%s\tmissing\n' "$rel"; continue; fi
    if [ "$(git cat-file blob "baseline/$NAME:prototypes/$NAME/$rel" | shastdin)" = "$(sha "$file")" ]; then
      printf 'verify\t%s\tsame\n' "$rel"; ok=$((ok + 1))
    else printf 'verify\t%s\tdiffers\n' "$rel"; fi
  done < "$T/list"
  printf 'verified\t%d\t%d\n' "$ok" "$n"
  [ "$ok" = "$n" ] && exit 0 || exit 3
fi

# ---- --after: provenance and the door record, beside the game --------------------------------
if [ "$MODE" = after ]; then
  D="prototypes/$NAME"
  [ -d "$D" ] || { printf 'refused\tno %s/\n' "$D"; exit 3; }
  mkdir -p "$D/assets" "$D/evidence" || exit 1
  if grep -q '^assets/provenance.yaml	' "$T/list"; then
    printf 'kept\t%s/assets/provenance.yaml\tthe game brought its own: not changed\n' "$D"
  elif [ ! -f "$D/assets/provenance.yaml" ]; then
    {
      echo "# Where each file came from, one entry per file. The door brought these files in as they"
      echo "# were, so each one's origin is unknown until you say: ai (with tool), you, cc0, licensed."
      echo "# - path: index.html         # relative to this game's folder"
      echo "#   sha256: <its hash>       # the bytes it came in with"
      echo "#   origin: unknown          # ai | bought | cc0 | you | outsourced | template | plugin | licensed | code | unknown"
      while IFS="$(printf '\t')" read -r rel file; do
        printf -- '- path: %s\n  sha256: %s\n  origin: unknown\n' "$rel" "$(sha "$file")"
      done < "$T/list"
    } > "$D/assets/provenance.yaml" || exit 1
    printf 'wrote\t%s/assets/provenance.yaml\n' "$D"
  else printf 'kept\t%s/assets/provenance.yaml\tthere already\n' "$D"
  fi
  # The same line as .git/info/attributes, now in the project's .gitattributes, so every clone
  # checks the game out with the bytes it came in with (info/attributes belongs to one clone).
  LINE="/$D/** -text -eol"
  if [ -f .gitattributes ] && tr -d '\r' < .gitattributes | grep -qxF "$LINE"; then printf 'kept\t.gitattributes\t%s\n' "$LINE"
  else
    { [ ! -s .gitattributes ] || [ -z "$(tail -c 1 .gitattributes)" ] || echo; echo "# $NAME, brought in by the door: kept byte for byte"; echo "$LINE"; } >> .gitattributes || exit 1
    printf 'wrote\t.gitattributes\t%s\n' "$LINE"
  fi
  {
    echo "# Brought in: $NAME"
    echo
    echo "- From: \`$SRC\` ($SHAPE$( [ "$SHAPE" = file ] && printf ', named %s' "$(basename "$SRC")")), $(date +%Y-%m-%d)"
    echo "- Baseline: the tag \`baseline/$NAME\`, holding only the game's files as they came in"
    echo "- The original was not changed. Its history, if it had one, stays with it."
    echo
    echo "| File | Bytes | SHA-256 |"
    echo "|---|---|---|"
    while IFS="$(printf '\t')" read -r rel file; do
      printf '| `%s` | %s | `%s` |\n' "$rel" "$(wc -c < "$file" | tr -d ' ')" "$(sha "$file")"
    done < "$T/list"
    if [ -s "$T/skipped" ]; then echo; echo "Left out:"; awk -F'\t' '{ print "- `" $2 "`: " $3 }' "$T/skipped"; fi
  } > "$D/evidence/door.md" || exit 1
  printf 'wrote\t%s/evidence/door.md\n' "$D"
  exit 0
fi

# ---- copy ------------------------------------------------------------------------------------
case "$SRC/" in "$ROOT"/*) WHERE=inside ;; *) WHERE=outside ;; esac
printf 'source\t%s\t%s\t%s\n' "$SRC" "$SHAPE" "$WHERE"
[ -s "$T/skipped" ] && cat "$T/skipped"

# What it is. A web project with its own build is /setup-engine web's; an engine or tool export
# goes to references/ as a reference for a remake (door-design.md section 10).
KIND=game; WHAT=""
if [ "$SHAPE" = folder ] && [ -f "$SRC/package.json" ]; then KIND=web_project
elif [ ! -f "$PAGE" ]; then KIND=not_a_game; WHAT="no index.html at the folder's top"
  # A folder whose game is one page with its own name (a one-shot beside its notes): name the
  # page, so the person can bring that file in. The folder is not taken as it is: its page would
  # have to be renamed, and the copy is byte for byte, names included.
  PAGES=$(find "$SRC" -maxdepth 1 -type f \( -iname '*.html' -o -iname '*.htm' \) 2>/dev/null \
    | sed 's|.*/||' | LC_ALL=C sort | awk 'NR > 1 { printf ", " } { printf "%s", $0 }')
else
  files=$(cut -f1 "$T/list")
  has() { printf '%s\n' "$files" | grep -Eq "$1"; }
  inpage() { grep -Eqi "$1" "$PAGE" 2>/dev/null; }
  if has '\.pck$' && has '\.wasm$'; then WHAT=Godot
  elif has '(^|/)Build/.*\.(data|framework\.js|loader\.js)(\.gz|\.br)?$|UnityLoader\.js$|\.unityweb$'; then WHAT=Unity
  elif has '(^|/)dmloader\.js$'; then WHAT=Defold
  elif has '(^|/)c3runtime\.js$' || inpage 'c3runtime'; then WHAT=Construct
  elif has '(^|/)gdjs/' || inpage 'gdjs\.'; then WHAT=GDevelop
  elif has '(^|/)(rmmz_|rpg_)[a-z_]*\.js$'; then WHAT="RPG Maker"
  elif inpage '<tw-storydata'; then WHAT=Twine
  elif inpage 'type="text/bitsy"|bitsy'"'"'s|var exportedGameData'; then WHAT=Bitsy
  elif inpage 'pico8_|_cartdat'; then WHAT=PICO-8
  fi
  if [ -n "$WHAT" ]; then KIND=export
  else
    # A game: a script, and a canvas, a frame loop or a loader, in the page or its local scripts.
    js=$( { cat "$PAGE"; cut -f2 "$T/list" | grep -E '\.m?js$' | while IFS= read -r f; do cat "$f"; done; } 2>/dev/null)
    if ! printf '%s' "$js" | grep -qi '<script'; then KIND=not_a_game; WHAT="the page has no script"
    elif ! printf '%s' "$js" | grep -Eq '<canvas|getContext|requestAnimationFrame|setInterval\('; then KIND=not_a_game; WHAT="no canvas and no frame loop in the page or its scripts"
    fi
  fi
fi
case "$KIND" in
  game) printf 'kind\tgame\n' ;;
  export) printf 'kind\texport\t%s\n' "$WHAT" ;;
  web_project) printf 'kind\tweb_project\n'; printf 'refused\ta package.json is at its top: a web project with its own build, which /setup-engine web records as it is\n'; exit 3 ;;
  not_a_game) printf 'kind\tnot_a_game\t%s\n' "$WHAT"
    if [ -n "${PAGES:-}" ]; then printf 'refused\tbring the page in, not its folder: %s; the page here: %s\n' "$WHAT" "$PAGES"
    else printf 'refused\tnothing here plays: %s\n' "$WHAT"; fi
    exit 3 ;;
esac

# The name: the page's <title>, else the file or folder name, as one-shot-new.sh accepts it.
mkname() { tr 'A-Z' 'a-z' | sed 's/&[a-z#0-9]*;/ /g; s/[^a-z0-9]\{1,\}/-/g; s/^-*//; s/-*$//' | cut -c1-40 | sed 's/-*$//'; }
if [ "$NAME_SET" = 1 ]; then
  case "$NAME" in ""|*[!a-z0-9-]*|-*) printf 'refused\tnot a folder name: %s (lower-case letters, digits and hyphens)\n' "$NAME"; exit 3 ;; esac
  FROM=given
else
  NAME=$(tr -d '\r' < "$PAGE" | tr '\n' ' ' | sed -n 's:.*<[Tt][Ii][Tt][Ll][Ee][^>]*>\([^<]*\)</[Tt][Ii][Tt][Ll][Ee]>.*:\1:p' | mkname); FROM=title
  if [ -z "$NAME" ]; then
    if [ "$SHAPE" = file ]; then NAME=$(basename "$SRC" | sed 's/\.[Hh][Tt][Mm][Ll]\{0,1\}$//' | mkname); FROM=file
    else NAME=$(basename "$SRC" | mkname); FROM=folder; fi
  fi
  [ -n "$NAME" ] || NAME=game
fi
BASE=prototypes; [ "$KIND" = export ] && BASE=references
if [ "$FROM" != given ]; then
  n=1; try=$NAME
  while [ -e "$BASE/$try" ] || { isgit && git rev-parse -q --verify "refs/tags/baseline/$try" >/dev/null; }; do n=$((n + 1)); try="$(printf '%s' "$NAME" | cut -c1-37)-$n"; done
  NAME=$try
elif [ -e "$BASE/$NAME" ]; then printf 'refused\t%s/%s/ is there already\n' "$BASE" "$NAME"; exit 3; fi
printf 'name\t%s\t%s\n' "$NAME" "$FROM"
DEST="$BASE/$NAME"
printf 'dest\t%s/\n' "$DEST"

nf=0; nb=0
while IFS="$(printf '\t')" read -r rel file; do
  b=$(wc -c < "$file" | tr -d ' '); h=$(sha "$file")
  printf 'file\t%s\t%s\t%s\n' "$rel" "$b" "$h"
  printf '%s\t%s\n' "$rel" "$h" >> "$T/hashes"
  [ "$b" -gt 52428800 ] && printf 'big\t%s\t%s\n' "$rel" "$((b / 1048576))"
  nf=$((nf + 1)); nb=$((nb + b))
done < "$T/list"
printf 'total\t%d\t%d\n' "$nf" "$nb"
[ "$DRY" = 1 ] && exit 0

# Git stores and checks out the game's bytes as they are: no line-ending change, ever (a line in
# .git/info/attributes, which belongs to this clone and is never committed).
if isgit && [ "$KIND" = game ]; then
  ATTR="$(git rev-parse --git-path info/attributes)"; LINE="/$DEST/** -text -eol"
  mkdir -p "$(dirname "$ATTR")"
  grep -qxF "$LINE" "$ATTR" 2>/dev/null || printf '%s\n' "$LINE" >> "$ATTR" || exit 1
  printf 'attributes\t.git/info/attributes\t%s\n' "$LINE"
fi
mkdir -p "$DEST" || exit 1
while IFS="$(printf '\t')" read -r rel file; do
  mkdir -p "$DEST/$(dirname "$rel")" && cp "$file" "$DEST/$rel" || { echo "door-in: could not copy $rel" >&2; exit 1; }
done < "$T/list"
bad=0
while IFS="$(printf '\t')" read -r rel h; do [ "$(sha "$DEST/$rel")" = "$h" ] || bad=$((bad + 1)); done < "$T/hashes"
if [ "$bad" = 0 ]; then printf 'copied\t%d\tsame\n' "$nf"; else printf 'copied\t%d\t%d differ\n' "$nf" "$bad"; exit 1; fi
exit 0
