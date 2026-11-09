#!/bin/bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured),
#      unless cwd is itself named .claude: a stray .claude/.claude/ would
#      make .claude/ a root, and the hooks would write .claude/production/
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment),
#      unless it names a .claude folder, for the same reason as rule 2
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || { [ -d ".claude" ] && [ "${PWD##*/}" != ".claude" ]; }; then
  CCGS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ] && case "${CLAUDE_PROJECT_DIR%/}" in */.claude|*\\.claude) false ;; *) true ;; esac; then
  CCGS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code PreToolUse hook: Validates git push commands, and the git and
# release actions that ask first
# Warns on pushes to protected branches, and on git tag, git merge, gh release,
# butler push and steamcmd +run_app_build (the deploy steps /hotfix and
# /team-release describe; which segments count is
# `.claude/scripts/write-guard.sh git`, the helper twin) -- as hook JSON on
# stdout, the only channel the user or Claude sees on exit 0.
# It warns and never blocks: every path exits 0 (the normal permission flow
# still applies).
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git push origin main" } }

INPUT=$(cat)

# Most Bash and PowerShell calls do not mention git or a release tool at all.
# Leave before any parsing: this hook runs on every one of them, and the parse
# is most of its cost (the early exit is the shell start-up alone).
# Tested only after the "tool_input" key: matching the whole payload also
# tests cwd and transcript_path, so a project path containing "GitHub" or
# "digital" never took this exit and paid the full parse on every call. `gh`
# must start a word, or "through " and "high " paid it too. Only git push, tag
# and merge are checked, so one of them must follow "git": `git status`,
# `.gitignore` and `.github` leave here too.
case "$INPUT" in
  *'"tool_input"'*[Gg][Ii][Tt]*[Pp][Uu][Ss][Hh]*|*'"tool_input"'*[Gg][Ii][Tt]*[Tt][Aa][Gg]*|*'"tool_input"'*[Gg][Ii][Tt]*[Mm][Ee][Rr][Gg][Ee]*|*'"tool_input"'*butler*|*'"tool_input"'*steamcmd*|*'"tool_input"'*[!A-Za-z0-9_.-]gh[\ .]*) ;;
  *) exit 0 ;;
esac

# Parse command -- use jq if available, fall back to grep. The fallback's string
# body is (\\.|[^"\\])* so an escaped quote does not end it early.
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    # LC_ALL=C: in a UTF-8 locale an emoji in the command makes this grep match
    # nothing, and an empty COMMAND skips the check below.
    COMMAND=$(echo "$INPUT" | LC_ALL=C grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 | LC_ALL=C sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
    # Decode the JSON escapes once, here, and never jq's output -- \\ first,
    # through a placeholder. validate-commit.sh explains each escape.
    COMMAND=$(printf '%s\n' "$COMMAND" \
      | LC_ALL=C awk '{ gsub(/\\\\/, "\002"); gsub(/\\r/, ""); gsub(/\\t/, "\t"); gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }' \
      | tr '\002' '\\')
fi

# Print $1 split into its command segments, one per line: here-doc bodies
# dropped, quoted git option values kept whole. Kept identical to
# command_segments in validate-commit.sh, which explains the splitting.
command_segments() {
    printf '%s\n' "$1" \
      | awk '{ while ($0 ~ /\\$/) { line = $0; sub(/\\$/, "", line); if ((getline nxt) > 0) { $0 = line nxt } else { $0 = line; break } } print }' \
      | awk '
          pd != "" { t = $0; sub(/\r$/, "", t); if (t ~ /^'"'"'@/) pd = ""; next }
          d != "" { t = $0; sub(/\r$/, "", t); if (tabs) sub(/^\t+/, "", t); if (t == d) d = ""; next }
          { print }
          match($0, /<<-?[ \t]*("[^"]*"|'"'"'[^'"'"']*'"'"'|\\?[A-Za-z_][^ \t\r;&|()<>"'"'"'\\]*)/) && substr($0, RSTART - 1, 1) != "<" \
            && substr($0, 1, RSTART - 1) !~ /\$\(\([^)]*$/ \
            && $0 !~ /(^|[^A-Za-z0-9_.-])(bash|sh|zsh|dash|ksh|fish|pwsh|powershell|python[0-9.]*|py|node|ruby|perl|php|eval|source)([ \t]|$)/ {
              t = substr($0, RSTART, RLENGTH); q = ""
              for (i = 1; i < RSTART; i++) {
                  c = substr($0, i, 1)
                  if (q == "") { if (c == "\"" || c == "'"'"'") q = c }
                  else if (c == q || (q == "\"" && c == "$" && substr($0, i + 1, 1) == "(")) q = ""
              }
              if (q == "") { d = t; tabs = (d ~ /^<<-/); sub(/^<<-?[ \t]*/, "", d); gsub(/[\\"'"'"']/, "", d) }
          }
          # A PowerShell single-quote here-string body (opened by @ then a
          # single quote, closed by a single quote then @) is literal text,
          # the same as a bash here-doc -- UNLESS it is the double-quote form,
          # which PowerShell itself expands $(...) inside, so that form is
          # left unmarked and flows through unchanged.
          $0 ~ /@'"'"'[ \t]*\r?$/ { pd = "x" }' \
      | awk '{
          s = $0; out = ""
          gsub(/"([^"]*[\/\\])?[Gg][Ii][Tt](\.exe)?"/, "git", s); gsub(/'"'"'([^'"'"']*[\/\\])?[Gg][Ii][Tt](\.exe)?'"'"'/, "git", s)
          gsub(/\$\([^ \t;&|()`"'"'"']*\)|`[^ \t;&|()`"'"'"']*`/, "$_", s)
          while (match(s, /(-[Cc]|--(git-dir|work-tree|namespace|super-prefix|config-env|attr-source))[ \t]+("[^"]*"|'"'"'[^'"'"']*'"'"')|=("[^"]*"|'"'"'[^'"'"']*'"'"')/)) {
              p = out substr(s, 1, RSTART - 1); a = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
              if (a ~ /^=/) {
                  f = "="; ok = p ~ /(^|[ \t;&|(){`"'"'"'])([^ \t;&|(){`"'"'"']*[\/\\])?[Gg][Ii][Tt](\.exe)?([ \t]+[^ \t;&|(){`"'"'"']+)+$/
              } else {
                  f = a; sub(/[ \t]+["'"'"'].*$/, " ", f)
                  ok = p ~ /(^|[ \t;&|(){`"'"'"'])([^ \t;&|(){`"'"'"']*[\/\\])?[Gg][Ii][Tt](\.exe)?([ \t]+[^ \t;&|(){`"'"'"']+)*[ \t]+$/
              }
              if (!ok) { out = p substr(a, 1, 1); s = substr(a, 2) s; continue }
              v = a; sub(/^[^"'"'"']*["'"'"']/, "", v); v = substr(v, 1, length(v) - 1); gsub(/[ \t;&|()`]/, "\001", v)
              out = p f v
          }
          s = out s
          # A quoted WORD with nothing inside it a shell would split on (a
          # quoted branch name, a quoted refspec) is unquoted the same way
          # rather than read as a delimiter -- a bare `"` or `'"'"'` used to
          # split the line here, dropping the quoted text (and everything
          # after it on that line) from what the classifier below ever saw.
          # A quoted string that DOES contain such characters is left alone:
          # it may be a whole command (`bash -c "git commit"`) meant to fall
          # on its own line for re-inspection, or a commit message, and either
          # reading is unchanged from before.
          out = ""
          while (match(s, /"[^" \t;&|()`]*"|'"'"'[^'"'"' \t;&|()`]*'"'"'/)) {
              p = out substr(s, 1, RSTART - 1); a = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
              out = p substr(a, 2, length(a) - 2)
          }
          s = out s
          gsub(/&&|\|\|/, "\n", s); gsub(/[;&|()`"'"'"']/, "\n", s); print s
        }'
}

# Print the first segment of $2 that runs `git $1`, anywhere in the command.
# An ^git anchor missed every chained push (`git add . && git push`). Kept
# identical in validate-commit.sh.
git_segment() {
    command_segments "$2" \
      | grep -E "^[[:space:]]*((if|then|else|elif|do|while|until|time|exec|command|nohup|!|[{])[[:space:]]+|(env|sudo|doas|xargs|nice|timeout|stdbuf|winpty|command)([[:space:]]+-[A-Za-z0-9-]+(=[^[:space:]]*)?([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+([0-9][0-9.]*[smhd]?[[:space:]]+)?|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*([^[:space:]]*[/\\])?[Gg][Ii][Tt](\.exe)?([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|--(git-dir|work-tree|namespace|super-prefix|config-env|attr-source)[[:space:]]+[^[:space:]]+|-[A-Za-z]|--[A-Za-z-]+(=[^[:space:]]+)?))*[[:space:]]+$1([[:space:]]|\$)"
}

# Print $1 with the text inside each quoted argument masked (every character
# but a newline becomes _), so a command named inside one -- `grep -rn "git tag
# v1"`, `git log --grep "git merge"`, a commit message -- is not read as that
# command. command_segments splits at quotes, which is right for the commit
# checks (a quoted string may be a whole command) but put quoted text on a line
# of its own here. Left as written: a quoted git path ("C:/.../git.exe" is the
# command), the string a shell runs (bash -c "...", eval "..."), here-doc
# delimiters and bodies (command_segments drops a body unless a shell reads it).
# An unclosed quote masks nothing after it.
mask_quoted() {
    printf '%s\n' "$1" | LC_ALL=C awk '
        { s = s (NR > 1 ? "\n" : "") $0 }
        END {
            n = length(s); i = 1; out = ""; nh = 0; sq = sprintf("%c", 39)
            while (i <= n) {
                c = substr(s, i, 1)
                if (c == "\\") { out = out substr(s, i, 2); i += 2; continue }
                if (c == "\n" && nh > 0) {
                    # Here-doc bodies, in order, each to its delimiter line.
                    out = out c; i++
                    for (k = 1; k <= nh; k++) {
                        while (i <= n) {
                            j = index(substr(s, i), "\n"); line = (j > 0) ? substr(s, i, j - 1) : substr(s, i)
                            out = out line (j > 0 ? "\n" : ""); i += (j > 0) ? j : length(line)
                            t = line; sub(/\r$/, "", t); if (htab[k]) sub(/^\t+/, "", t)
                            if (t == hd[k] || j == 0) break
                        }
                    }
                    nh = 0; continue
                }
                if (c == "<" && substr(s, i, 2) == "<<" && substr(s, i + 2, 1) != "<" && (i == 1 || substr(s, i - 1, 1) != "<")) {
                    j = i + 2; tabs = 0
                    if (substr(s, j, 1) == "-") { tabs = 1; j++ }
                    while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
                    q = substr(s, j, 1); w = ""
                    if (q == "\"" || q == sq) {
                        e = index(substr(s, j + 1), q)
                        if (e > 0) { w = substr(s, j + 1, e - 1); j = j + e + 1 }
                    } else {
                        if (q == "\\") j++
                        while (j <= n && substr(s, j, 1) !~ /[ \t\n;&|()<>"\\]/ && substr(s, j, 1) != sq) { w = w substr(s, j, 1); j++ }
                    }
                    if (w != "") { hd[++nh] = w; htab[nh] = tabs }
                    out = out substr(s, i, j - i); i = j; continue
                }
                if (c == "\"" || c == sq) {
                    # The closing quote; a backslash escapes inside double quotes only.
                    j = i + 1
                    while (j <= n && substr(s, j, 1) != c) j += (c == "\"" && substr(s, j, 1) == "\\") ? 2 : 1
                    if (j > n) { out = out substr(s, i); break }
                    body = substr(s, i + 1, j - i - 1)
                    pre = out; sub(/.*[\n;&|(]/, "", pre)
                    if (body !~ /^([^"]*[\/\\])?[Gg][Ii][Tt](\.[Ee][Xx][Ee])?$/ \
                        && pre !~ /(^|[ \t\/\\])((ba|z|da|k)?sh|pwsh|powershell)(\.exe)?([ \t]+-[A-Za-z]+)*[ \t]+-[A-Za-z]*[Cc]([Oo][Mm][Mm][Aa][Nn][Dd])?[ \t]+$/ \
                        && pre !~ /(^|[ \t])eval[ \t]+$/)
                        gsub(/[^\n]/, "_", body)
                    out = out c body c; i = j + 1; continue
                }
                out = out c; i++
            }
            printf "%s\n", out
        }'
}

# The git and release actions that ask first: the tag and merge segments as
# git_segment finds them (prefixes and git's own options understood), and the
# segments that run a release tool, read from the command with its quoted
# arguments masked. write-guard.sh says which of them act (`git tag -l` lists,
# `git merge --abort` undoes; neither asks).
ACT_CMD=$(mask_quoted "$COMMAND" 2>/dev/null) || ACT_CMD="$COMMAND"
[ -n "$ACT_CMD" ] || ACT_CMD="$COMMAND"
ACT_SEGS=$( { git_segment '(tag|merge)' "$ACT_CMD"
              command_segments "$ACT_CMD" | grep -E '(^|[[:space:]/\\])(gh|butler|steamcmd)(\.exe|\.sh)?[[:space:]]'; } 2>/dev/null )
ACT_MSG=""
if [ -n "$ACT_SEGS" ]; then
    if [ -f .claude/scripts/write-guard.sh ]; then
        ACTIONS=$(printf '%s\n' "$ACT_SEGS" | bash .claude/scripts/write-guard.sh --root . git 2>/dev/null \
          | awk -F '\t' '$1 == "GIT_ACTION" && !seen[$2]++ {
              w = ($2 == "tag") ? "git tag" : ($2 == "merge") ? "git merge" : ($2 == "release") ? "gh release" \
                : ($2 == "deploy-itch") ? "butler push" : "steamcmd +run_app_build"
              l = l (l == "" ? "" : ", ") w } END { print l }')
        [ -n "$ACTIONS" ] && ACT_MSG="This command runs $ACTIONS. Tagging, merging and deploying ask first (/hotfix, /team-release): go ahead only if the user approved this step."
    else
        ACT_MSG="Git action check skipped: .claude/scripts/write-guard.sh is missing, so tag, merge and deploy steps were not checked."
    fi
fi

PUSH_SEG=$(git_segment push "$COMMAND")
if [ -z "$PUSH_SEG" ]; then
    [ -n "$ACT_MSG" ] && printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$ACT_MSG" "$ACT_MSG"
    exit 0
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
MATCHED_BRANCH=""

# Check if pushing to a protected branch: main, master, or any release/*
# branch (the trunk model's only other protected line -- no GitFlow develop).
for branch in main master; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
        MATCHED_BRANCH="$branch"
        break
    fi
    # Also check if pushing to a protected branch explicitly: as its own word,
    # or as a refspec's destination (HEAD:main, feature:main, +main,
    # refs/heads/main). `main:feature` pushes TO feature and stays quiet.
    if echo "$PUSH_SEG" | grep -qE "([[:space:]+:]|refs/heads/)${branch}([[:space:]]|$)"; then
        MATCHED_BRANCH="$branch"
        break
    fi
done

# release/* is a name pattern, not a fixed branch, so it needs its own checks:
# pushing FROM a release/* branch (a bare `git push`), or explicitly TO one.
if [ -z "$MATCHED_BRANCH" ]; then
    case "$CURRENT_BRANCH" in
        release/*) MATCHED_BRANCH="$CURRENT_BRANCH" ;;
    esac
fi
if [ -z "$MATCHED_BRANCH" ] && echo "$PUSH_SEG" | grep -qE "([[:space:]+:]|refs/heads/)release/[^[:space:]:]+([[:space:]]|$)"; then
    MATCHED_BRANCH=$(echo "$PUSH_SEG" | grep -oE "release/[^[:space:]:]+" | head -1)
fi

if [ -n "$MATCHED_BRANCH" ]; then
    # Allow the push, but warn where it is seen. stderr on exit 0 goes to the
    # debug log only, so this warning reached neither the user nor Claude.
    # systemMessage is shown to the user; additionalContext reaches Claude next
    # to the tool result. No permissionDecision: "allow" would skip the user's
    # permission prompt. MATCHED_BRANCH is no longer a fixed name -- for
    # release/* it is the current branch or text taken from the command, and
    # git allows a literal `"` or `\` in a branch name, so it must be escaped
    # before it goes into the JSON string below.
    SAFE_BRANCH=$(printf '%s' "$MATCHED_BRANCH" | sed 's/\\/\\\\/g; s/"/\\"/g')
    MSG="Push to protected branch '$SAFE_BRANCH' detected. Reminder: Ensure build passes, unit tests pass, and no open bugs the release gate blocks (S1; S1-S3 at workflow: full)."
    [ -n "$ACT_MSG" ] && MSG="$MSG $ACT_MSG"
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$MSG" "$MSG"
    # To block instead, replace the printf above with:
    # echo "BLOCKED: Run tests before pushing to $MATCHED_BRANCH" >&2
    # exit 2
elif [ -n "$ACT_MSG" ]; then
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$ACT_MSG" "$ACT_MSG"
fi

exit 0
