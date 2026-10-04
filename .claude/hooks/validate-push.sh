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
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || [ -d ".claude" ]; then
  CCGS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  CCGS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code PreToolUse hook: Validates git push commands
# Warns on pushes to protected branches -- as hook JSON on stdout, the only
# channel the user or Claude sees on exit 0.
# Exit 0 = allow (the normal permission flow still applies), Exit 2 = block
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git push origin main" } }

INPUT=$(cat)

# Most Bash and PowerShell calls do not mention git at all. Leave before any
# parsing: this hook runs on every one of them, and the parse is most of its
# cost (~350 ms a call measured; the early exit is the shell start-up alone).
# Tested only after the "tool_input" key: matching the whole payload also
# tests cwd and transcript_path, so a project path containing "GitHub" or
# "digital" never took this exit and paid the full parse on every call.
case "$INPUT" in *'"tool_input"'*[Gg][Ii][Tt]*) ;; *) exit 0 ;; esac

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

# Print the first segment of $2 that runs `git $1`, anywhere in the command.
# An ^git anchor missed every chained push (`git add . && git push`).
# Kept identical in validate-commit.sh, which explains the splitting.
git_segment() {
    printf '%s\n' "$2" \
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
        }' \
      | grep -E "^[[:space:]]*((if|then|else|elif|do|while|until|time|exec|command|nohup|!|[{])[[:space:]]+|(env|sudo|doas|xargs|nice|timeout|stdbuf|winpty|command)([[:space:]]+-[A-Za-z0-9-]+(=[^[:space:]]*)?([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+([0-9][0-9.]*[smhd]?[[:space:]]+)?|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*([^[:space:]]*[/\\])?[Gg][Ii][Tt](\.exe)?([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|--(git-dir|work-tree|namespace|super-prefix|config-env|attr-source)[[:space:]]+[^[:space:]]+|-[A-Za-z]|--[A-Za-z-]+(=[^[:space:]]+)?))*[[:space:]]+$1([[:space:]]|\$)"
}

# Only process git push commands
PUSH_SEG=$(git_segment push "$COMMAND") || exit 0

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
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$MSG" "$MSG"
    # To block instead, replace the printf above with:
    # echo "BLOCKED: Run tests before pushing to $MATCHED_BRANCH" >&2
    # exit 2
fi

exit 0
