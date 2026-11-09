# engine-row.awk — print one engine's row, or one cell of it, from the engine
# table .claude/engines/engines.tsv. The one reader every file that needs an
# engine's folders or commands shares, so none keeps a copy of the table:
#
#   awk -F'\t' -v engine="Godot" -v col=code_root -f .claude/scripts/engine-row.awk .claude/engines/engines.tsv
#
#   col     a column name from the header row (code_root, test_root,
#           asset_root, run, build, test, smoke); its cell is printed, and an
#           empty cell (`-`) prints nothing. Empty col prints the whole row,
#           tab-separated, dashes kept. An unknown column prints nothing.
#   engine  the engine.name value. It matches a row in any case, and any name
#           starting with "unreal" is the Unreal row, so "Unreal Engine" resolves
#           as the old `unreal*` cases did. No match
#           prints nothing: the caller treats the engine as unset or unknown.
#
# Run with -F'\t': an IFS read in bash merges empty fields, awk does not. CR
# line ends are stripped. BWK awk safe: no gawk extensions.

function lc(s) { return tolower(s) }
BEGIN { want = lc(engine); sub(/^[ \t]+/, "", want); sub(/[ \t]+$/, "", want) }
{ gsub(/\r/, "") }
NR == 1 { for (i = 1; i <= NF; i++) if ($i == col) c = i; next }
/^#/ || $0 == "" { next }
want == "" { exit }
{
  row = lc($1)
  if (want != row && !(row == "unreal" && index(want, "unreal") == 1)) next
  if (col == "") { print; exit }
  if (c && $c != "-" && $c != "") print $c
  exit
}
