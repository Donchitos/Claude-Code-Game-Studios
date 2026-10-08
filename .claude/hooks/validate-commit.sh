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

# Claude Code PreToolUse hook: Validates git commit commands
# Receives JSON on stdin with tool_input.command
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }

INPUT=$(cat)

# Most Bash and PowerShell calls do not mention git at all. Leave before any
# parsing: this hook runs on every one of them, and the parse is most of its
# cost (the early exit is the shell start-up alone).
# Tested only after the "tool_input" key: matching the whole payload also
# tests cwd and transcript_path, so a project path containing "GitHub" or
# "digital" never took this exit and paid the full parse on every call.
case "$INPUT" in *'"tool_input"'*[Gg][Ii][Tt]*) ;; *) exit 0 ;; esac

# Parse command -- use jq if available, fall back to grep. The fallback's string
# body is (\\.|[^"\\])* so an escaped quote (-m \"msg\") does not end it early.
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    # LC_ALL=C: in a UTF-8 locale an emoji in the command makes this grep match
    # nothing, and an empty COMMAND skips every check below.
    COMMAND=$(echo "$INPUT" | LC_ALL=C grep -oE '"command"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 | LC_ALL=C sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
    # The grep leaves the JSON escapes in place; decode them once, here, and
    # never jq's output. \\ goes first, through a placeholder: decoded after \r,
    # the path C:\\Users\\me\\review lost the `r` of `review` (a segment
    # starting t or n became a tab or a line break), the -C check below found
    # no repository, and the commit went unchecked. A \" left escaped ended a
    # quoted branch name in a stray backslash; a \t or \r left escaped never
    # closed a tab-indented `<<-EOF` or a CRLF here-doc, dropping every command
    # after it.
    COMMAND=$(printf '%s\n' "$COMMAND" \
      | LC_ALL=C awk '{ gsub(/\\\\/, "\002"); gsub(/\\r/, ""); gsub(/\\t/, "\t"); gsub(/\\n/, "\n"); gsub(/\\"/, "\""); print }' \
      | tr '\002' '\\')
fi

# Print the first segment of $2 that runs `git $1`, anywhere in the command.
# Anchoring on ^git let every chained form through unchecked:
# `git add -A && git commit`, `git -C . commit`, `cd x && git commit`,
# `GIT_DIR=.git git commit`, a commit on a second line. Segments split on
# && || ; & | ( ) backticks and quotes, and on newlines. Before a segment's
# `git`, VAR=value words, `env`/`sudo`/`doas`/`xargs`/`nice`/`timeout` with
# their flags (a flag's value and timeout's duration included), shell keywords
# (`if`, `do`, `{`, `time`, ...) and a path, either slash (`/usr/bin/git`,
# `C:\Git\cmd\git.exe`) are allowed, and a QUOTED path to git ("C:\Program
# Files\Git\cmd\git.exe") is read as plain `git`; after it, git's own options
# (-C <dir>, -c <k=v>, --git-dir <dir> and the other long options that take a
# separate value, -p, --flag[=v]). A quoted value of git's own options --
# `-C "my repo"`, `--git-dir ".git"`, `-c user.name="A B"`, `--work-tree="."`,
# `-C "$(pwd)"` -- is unquoted first and its spaces and shell operators carried
# as \001, or the split cut `git` off from its subcommand and the commit went
# unchecked; an unquoted `$(pwd)` with no space in it is one word, too. Only
# when it follows `git`: a shell's own `bash -c "git commit"` was unquoted the
# same way, which glued the inner command into one word and skipped the check,
# and the quote after `=` in `grep "key=" f && git commit -m "x"` closes a
# string rather than opening a value. All splitting is awk: BSD sed writes a
# literal `n` for `\n`, so on macOS a sed split missed every chained form.
# Over-splitting only costs a check that finds nothing staged; under-splitting
# is the bypass. Kept identical in validate-push.sh.
#
# `git` itself is matched case-insensitively (`Git`, `GIT`) and a bare quoted
# `"git"` or `'git'` (no path) reads as plain `git` too, the same as a quoted
# path ending in it. `stdbuf`, `winpty` and `command -p` join `env`/`sudo`/...
# as prefixes that take flags. A line ending in a lone `\` is joined with the
# next before any of this runs, so `git \` then `commit` on the next line is
# still one command; `1<<y` inside `$((...))` is left-shift, not a here-doc
# opener, even though it matches `<<` the same as a real one. A quoted WORD
# with no shell-meaningful character inside it (a quoted branch name, `"main"`)
# is unquoted in place rather than read as a delimiter; a quoted string that
# DOES contain one is left for the here-doc/command handling above.
#
# A here-document body is text, not commands: a commit message, a file being
# written. Read as commands, a message quoting `git push origin main` warned
# about a push, and `cat > notes.md <<EOF` mentioning git commit blocked on
# staged data. So the body is dropped -- UNLESS its line runs an interpreter
# (bash <<EOF, python - <<EOF), whose here-doc IS commands: dropping that
# would be the bypass. `<<<` is a here-string, not a here-doc. An interpreter
# may carry a path (`/bin/bash <<EOF`). The delimiter is the whole word, or the
# whole quoted string (`<<'END-NOTES'`), and a `<<` inside a quoted string
# (`echo "a<<b"`) opens nothing -- `$(cat <<EOF` inside one still does. Either
# mistake left a here-doc that never closed and dropped every later line, a
# real commit included. A PowerShell single-quote here-string (`@'` ... `'@`)
# is the same kind of text and is dropped the same way; the double-quote form
# (`@"` ... `"@`) is left alone, because PowerShell itself expands `$(...)`
# inside it, and that content is still live.
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

# Only process git commit commands
COMMIT_SEG=$(git_segment commit "$COMMAND") || exit 0

# `git -C <dir> commit` commits whatever repository <dir> is in. Only this
# project's staged files are ours to check; another repository is not. Leave
# only when <dir> PROVABLY is another repository: a <dir> rev-parse cannot
# resolve here -- `"$CLAUDE_PROJECT_DIR"`, `~/x`, `"$(pwd)"`, all unexpanded in
# the command text -- is this project as often as not, and skipping it let the
# commit through unchecked.
#
# COMMIT_SEG can hold more than one line -- a chained `git -C other commit &&
# git commit` -- and this early exit must not fire on the strength of the
# FIRST one alone: that let a real commit of THIS repo, chained after a
# provably-elsewhere one, through unchecked. So it only applies when exactly
# one commit invocation was found; a chain of several falls through to the
# normal staged-file checks below, which are already scoped to this repo.
if [ "$(printf '%s\n' "$COMMIT_SEG" | grep -c .)" = 1 ]; then
GIT_OPTS=${COMMIT_SEG%%[[:space:]]commit*}
case "$GIT_OPTS" in
    *-C*)
        C_DIR=$(printf '%s' "$GIT_OPTS" | sed -nE 's/.*[[:space:]]-C[[:space:]]+([^[:space:]]+).*/\1/p' | tr '\001' ' ')
        if [ -n "$C_DIR" ] && _C_TOP=$(git -C "$C_DIR" rev-parse --show-toplevel 2>/dev/null) && [ -n "$_C_TOP" ]; then
            _OUR_TOP=$(git rev-parse --show-toplevel 2>/dev/null)
            [ "$_C_TOP" != "$_OUR_TOP" ] && [ ! "$_C_TOP" -ef "$_OUR_TOP" ] && exit 0
        fi ;;
esac
fi

# Resolve a Python interpreter ONCE for every batched check below. Both the
# blocking JSON scan and the advisory design scan must not spawn one process per
# item; they spawn one each, and share this lookup.
# Run it, do not just find it: the Windows Store `python` placeholder passes
# `command -v` and then prints an install hint instead of running anything.
# And ask for Python 3: a Python 2 first on PATH runs `import sys` fine, then
# fails every check below (they read sys.stdin.buffer), and valid data blocked.
_VC_PY=""
for _c in python python3 py; do
    if command -v "$_c" >/dev/null 2>&1 && "$_c" -c 'import sys; sys.exit(sys.version_info[0] < 3)' >/dev/null 2>&1; then
        _VC_PY="$_c"; break
    fi
done

# Get the files this commit will record, and where each committed copy lives.
# A plain commit records the INDEX. `-a` / `--all` (or a cluster such as -am)
# also commits every modified tracked file, and `git commit <path>` commits the
# named paths' WORKING copies, staged or not -- both read from the working tree
# (WT_FILES). core.quotePath=false: without it a non-ASCII path comes back
# quoted ("assets/data/caf\303\251.json") and no pattern below matched it.
_GIT="git -c core.quotePath=false"
COMMIT_ARGS=" ${COMMIT_SEG#*[[:space:]]commit}"
INDEX_FILES=$($_GIT diff --cached --name-only 2>/dev/null)
WT_FILES=""
if printf '%s' "$COMMIT_ARGS" | grep -qE '[[:space:]](-[ABDEGHIJKLMNOPQRTUVWXYZbdefghijklnopqrsvwxyz]*a[A-Za-z]*|--all)([[:space:]]|$)'; then
    WT_FILES=$($_GIT diff --name-only 2>/dev/null)
fi
# Pathspecs after the `commit` word. ANY pathspec takes working copies -- `.`,
# `-- .`, a folder, a glob, `:/` -- not only a literal assets/ path, and a
# message or an -F file is not one. So Python tokenises the command as a shell
# would (shlex; COMMIT_SEG was split at quotes and cannot say where `-m "a b"`
# ends) and git expands the pathspecs. Without Python only literal data paths
# are found, and the data check below blocks on them anyway.
#
# The tokeniser also reads an -a the grep above cannot see: COMMIT_ARGS stops
# at the first quote, so `git commit -m "x" -a` and `--all` committed every
# modified tracked file unchecked. `-a` counts in a short-option cluster only
# before a letter that takes a value (`-am x` is -a; `-ma` is the message "a").
#
# A path-limited commit (`git commit -m x src/player.gd`, no -i/--include)
# records ONLY those paths -- `git commit --dry-run` lists nothing else -- so a
# broken file staged for later must not block it. The tokeniser says so on its
# first line (CCGS-ONLY), and only when it read every commit in the command:
# one inside `bash -c "..."` or a here-doc is a single word or plain text to it.
#
# A relative pathspec resolves where the commit runs, and this hook runs at the
# project root: after a `cd`, under -C, or in a session sitting in a subfolder,
# `cd assets && git commit -m x data/item.json` named nothing here and the file
# went unchecked. There, and whenever a pathspec names no tracked file, every
# modified tracked file is checked (`:/`), and the index with it.
#
# A `git add` (or `git stage`) earlier in the same command stages its files
# after this hook has read the index, so `git add -A && git commit` committed a
# new broken data file unchecked. Each add before a commit is read too, and
# what it will stage -- modified tracked files, and untracked ones unless it is
# -u (ignored ones only with -f) -- is checked as working copies. A dry run
# (-n) stages nothing, an add after the commit is for a later one, a
# path-limited commit still records only its own paths, and after a cd or -C
# an add's pathspecs are read as the whole tree, as above.
if [ -n "$_VC_PY" ]; then
    if command -v jq >/dev/null 2>&1; then
        _VC_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
    else
        _VC_CWD=$(echo "$INPUT" | LC_ALL=C grep -oE '"cwd"[[:space:]]*:[[:space:]]*"(\\.|[^"\\])*"' | head -1 \
          | LC_ALL=C sed 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//; s/\\\\/\\/g')
    fi
    _VC_AWAY=0
    [ -n "$_VC_CWD" ] && [ ! "$_VC_CWD" -ef . ] && _VC_AWAY=1
    _VC_TOK=$(printf '%s\n' "$COMMAND" | "$_VC_PY" -c '
import re, shlex, subprocess, sys
OPS = set(";&|()<>")
GIT_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix", "--config-env", "--attr-source"}
REDIR = re.compile(r"^[<>]+&?$|^&>+$")  # >, >>, >&, <, <<, &>: a redirection operator
COMMIT_ARG = {"--message", "--file", "--reuse-message", "--reedit-message", "--fixup", "--squash",
              "--author", "--date", "--template", "--cleanup", "--trailer", "--pathspec-from-file"}
def words(line):
    try:
        lx = shlex.shlex(line, posix=True, punctuation_chars=True)
        lx.whitespace_split = True
        lx.commenters = ""
        return list(lx)
    except ValueError:  # an unclosed quote: the line continues a string
        return line.split()
def git(*args):
    return subprocess.run(["git", "-c", "core.quotePath=false"] + list(args),
                          stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
def add(w, k):  # git add/stage from w[k] -> pathspecs, takes untracked, -f, -n, next k
    specs, rest, alln, upd, force, dry = [], False, False, False, False, False
    while k < len(w):
        a = w[k]
        if a.isdigit() and k + 1 < len(w) and w[k + 1][:1] in "<>":
            k += 1
            continue
        if REDIR.match(a):
            k += 2
            continue
        if a and set(a) <= OPS:
            break
        if rest or not a.startswith("-") or a == "-":
            specs.append(a)
        elif a == "--":
            rest = True
        elif a.startswith("--"):
            alln = alln or a in ("--all", "--no-ignore-removal")
            upd, force, dry = upd or a == "--update", force or a == "--force", dry or a == "--dry-run"
            if a.startswith("--pathspec-from-file"):
                specs.append(":/")  # paths only git reads
        else:  # no short option of git add takes a value: -Av is -A -v
            alln, upd, force, dry = alln or "A" in a, upd or "u" in a, force or "f" in a, dry or "n" in a
        k += 1
    if not specs and (alln or upd):
        specs = [":/"]  # -A and -u with no pathspec take the whole tree
    return specs, alln or not upd, force, dry, k
text = sys.stdin.buffer.read().decode("utf-8", "replace")
away = sys.argv[1] == "1" or re.search(r"(^|[^\w.-])(cd|pushd|popd)(\s|[;&|)]|$)", text, re.M) is not None
specs, commits, only = [], 0, True
adds, pending = [], []  # what each git add stages: before a commit, not yet
for line in text.splitlines():
    w, i = words(line), 0
    while i < len(w):
        if w[i].replace("\\", "/").rsplit("/", 1)[-1].lower() not in ("git", "git.exe"):
            i += 1
            continue
        j = i + 1
        while j < len(w) and w[j].startswith("-"):
            away = away or w[j] in ("-C", "--git-dir", "--work-tree") or w[j].startswith(("--git-dir=", "--work-tree="))
            j += 2 if w[j] in GIT_ARG else 1
        if j < len(w) and w[j] in ("add", "stage"):
            s, new, force, dry, i = add(w, j + 1)
            if not dry:
                pending.append((s, new, force))
            continue
        if j >= len(w) or w[j] != "commit":
            i = j
            continue
        commits += 1
        adds, pending = adds + pending, []
        k, rest, mine, index = j + 1, False, [], False
        while k < len(w):
            a = w[k]
            if a.isdigit() and k + 1 < len(w) and w[k + 1][:1] in "<>":
                k += 1  # 2>&1, 2> err.txt: a file descriptor, not a pathspec
                continue
            if REDIR.match(a):
                k += 2  # the redirection and its target; the commit goes on after it
                continue
            if a and set(a) <= OPS:
                break  # the next command
            if rest or not a.startswith("-") or a == "-":
                mine.append(a)
            elif a == "--":
                rest = True
            elif a.startswith("--"):
                if a == "--all" or a.startswith("--pathspec-from-file"):
                    mine.append(":/")  # every tracked change, or paths only git reads
                index = index or a in ("--all", "--include", "--patch", "--interactive") \
                    or a.startswith("--pathspec-from-file")
                if a in COMMIT_ARG:
                    k += 1  # --message <msg>: the value is not a pathspec
            else:
                for n, ch in enumerate(a[1:], 1):  # -am: -a, then -m <msg>
                    if ch in "mFCct":
                        if n == len(a) - 1:
                            k += 1
                        break
                    if ch in "uS":
                        break  # -uno, -S<key>: the rest is its value
                    if ch == "a":
                        mine.append(":/")
                    index = index or ch in "aip"
            k += 1
        specs += mine
        only = only and bool(mine) and not index
        i = k
if specs and not away:
    away = git("ls-files", "--error-unmatch", "--", *specs).returncode != 0
if specs and away:
    specs.append(":/")
    only = False
only = only and commits > 0 and len(re.findall(r"(?<![\w.-])commit(?![\w-])", text)) == commits
out = git("diff", "--name-only", "HEAD", "--", *specs) if only else None
if out is None or out.returncode != 0:  # not path-limited, or no HEAD yet
    only = False
    out = git("diff", "--name-only", "--", *specs) if specs else None
more = b""
for s, new, force in ([] if only else adds):
    s = [":/"] if away else s
    more += git("diff", "--name-only", "--", *s).stdout
    if new:
        more += git("ls-files", "--others", "--full-name", *([] if force else ["--exclude-standard"]), "--", *s).stdout
sys.stdout.buffer.write((b"CCGS-ONLY\n" if only else b"CCGS-INDEX\n") + (out.stdout if out else b"") + more)
' "$_VC_AWAY" 2>/dev/null)
    case "$_VC_TOK" in CCGS-ONLY*) INDEX_FILES="" ;; esac
    WT_FILES=$(printf '%s\n%s' "$WT_FILES" "$(printf '%s\n' "$_VC_TOK" | tail -n +2)")
else
    _AFTER=$(printf '%s' "$COMMAND" | LC_ALL=C awk '
        !f && match($0, /(^|[^A-Za-z0-9_.-])commit([ \t]|$)/) { f = 1; print substr($0, RSTART + RLENGTH); next }
        f { print }')
    for _p in $(printf '%s' "$_AFTER" | LC_ALL=C grep -oE '(assets|Assets|Content)/[^[:space:]"'"'"';|&)]*'); do
        WT_FILES=$(printf '%s\n%s' "$WT_FILES" "$($_GIT diff --name-only -- "$_p" 2>/dev/null)")
    done
    # No tokeniser to read a `git add`'s paths: take every change and new file.
    if git_segment add "$COMMAND" >/dev/null || git_segment stage "$COMMAND" >/dev/null; then
        WT_FILES=$(printf '%s\n%s\n%s' "$WT_FILES" "$($_GIT diff --name-only 2>/dev/null)" \
          "$($_GIT ls-files --others --exclude-standard --full-name 2>/dev/null)")
    fi
fi
WT_FILES=$(printf '%s\n' "$WT_FILES" | grep -v '^$' | sort -u)
# A project in a subfolder of a larger repository (game/ in a monorepo): git
# names every path above from the repository's top level, and every check below
# matches from the PROJECT root (^assets/, ^design/gdd/, the code root) and
# reads files relative to it. Unconverted, nothing matched and the commit went
# through unchecked. Keep this project's paths with the prefix dropped; files
# outside the project are not ours to check. "" at the top level.
_VC_PREFIX=$(git rev-parse --show-prefix 2>/dev/null)
if [ -n "$_VC_PREFIX" ]; then
    INDEX_FILES=$(printf '%s\n' "$INDEX_FILES" | LC_ALL=C awk -v p="$_VC_PREFIX" 'index($0, p) == 1 { print substr($0, length(p) + 1) }')
    WT_FILES=$(printf '%s\n' "$WT_FILES" | LC_ALL=C awk -v p="$_VC_PREFIX" 'index($0, p) == 1 { print substr($0, length(p) + 1) }')
fi
STAGED=$(printf '%s\n%s\n' "$INDEX_FILES" "$WT_FILES" | grep -v '^$' | sort -u)
if [ -z "$STAGED" ]; then
    exit 0
fi

WARNINGS=""

# Section findings are collected through a file, not a variable: the loops below
# run inside pipelines, and a subshell cannot assign to WARNINGS in the parent.
# The scratch file must actually be WRITABLE, and that has to be tested rather
# than assumed. `mktemp` and the `${TMPDIR:-/tmp}` fallback beside it both aim
# at /tmp, which does not exist or is not writable in several environments this
# hook runs in -- notably sandboxed Windows shells. When the redirect failed,
# `[ -s "$TMP_DESIGN" ]` was false, the design-section scan emitted nothing, and
# the hook exited 0: a check that could not run, reporting clean.
#
# So: try mktemp, then TMPDIR, then the repo own .git directory (writable by
# definition -- `git diff --cached` has already succeeded against it), and PROVE
# each candidate by writing to it. If none works, TMP_DESIGN stays empty and the
# scan announces that it did not run instead of skipping in silence.
TMP_DESIGN=""
for _cand in "$(mktemp 2>/dev/null)" "${TMPDIR:+$TMPDIR/ccgs-commit-$$}" \
             "$(git rev-parse --git-dir 2>/dev/null)/ccgs-commit-$$"; do
    [ -z "$_cand" ] && continue
    if : > "$_cand" 2>/dev/null; then TMP_DESIGN="$_cand"; break; fi
done
trap '[ -n "$TMP_DESIGN" ] && rm -f "$TMP_DESIGN"' EXIT

# ---------------------------------------------------------------------------
# BLOCKING CHECK FIRST. Everything below this block is advisory:
# it appends to $WARNINGS and the hook still exits 0. This block is the only one
# that can exit 2, and exit 2 is the entire reason the hook is registered.
#
# Running it after the design-section scan, and validating one file per
# `python -m json.tool` invocation -- one interpreter spawn each -- would get the
# hook killed by its 15s timeout on a large commit before it reaches a corrupt
# file, so whether a bad file is caught would depend on where its NAME SORTS: a
# corrupt file sorting first is blocked, one sorting last lets the commit through.
#
# Two independent fixes, because either alone is a mitigation rather than a
# guarantee:
#   (a) ORDER. The blocking check runs before any advisory work, so a starved
#       hook has already done the part that matters.
#   (b) COST. One interpreter validates every staged JSON file, so the check is
#       constant in file count instead of linear. The one-subprocess-per-item
#       shape has caused this same starvation more than once; batching is the
#       only fix that holds.
#
# Making it merely faster is not enough -- the cost stays linear and the hook
# starves again at a larger file count. Batch it, or it returns.
#
# WHERE DATA LIVES is engine-specific, like the code root: Godot keeps it in
# assets/data/, Unity under Assets/ (Assets/Data/, Assets/Game/Data/), Unreal
# under Content/. Anchored to ^assets/data/ alone, this -- the hook's only
# blocking check -- never fired on Unity or Unreal. It stays inside the asset
# roots so an editor's JSON-with-comments (.vscode/settings.json) never blocks.
# ---------------------------------------------------------------------------
DATA_FILES=$(echo "$STAGED" | grep -E '^(assets|Assets|Content)/(.*/)?[Dd]ata/.*\.[Jj][Ss][Oo][Nn]$')
if [ -n "$DATA_FILES" ]; then
    PYTHON_CMD="$_VC_PY"
    if [ -n "$PYTHON_CMD" ]; then
        # One spawn, all files. The file list arrives on stdin so an unbounded
        # number of paths cannot overflow the argument limit.
        # The first output line is a sentinel. Without it the validator did not
        # run -- a crash, or an interpreter that is not Python -- and an empty
        # list of bad files would read as "all valid".
        # Each line is "W<tab>path" (commit takes the working copy) or
        # "I<tab>path" (commit takes the staged copy). Index copies are read
        # through ONE `git cat-file --batch`, not a `git show` per file.
        JSON_OUT=$(LC_ALL=C awk -v OFS='\t' 'NR == FNR { if ($0 != "") wt[$0] = 1; next }
                     $0 != "" { print (($0 in wt) ? "W" : "I"), $0 }' \
                     <(printf '%s\n' "$WT_FILES") <(printf '%s\n' "$DATA_FILES") \
                   | CCGS_VC_PREFIX="$_VC_PREFIX" "$PYTHON_CMD" -c '
import json, sys, os, subprocess
bad, lfs_unread = [], []
# Bytes in, decoded as UTF-8: a Windows console code page would mangle a
# non-ASCII path before it reached os.path or git.
items = [l.split("\t", 1) for l in sys.stdin.buffer.read().decode("utf-8").splitlines() if "\t" in l]
staged = [p for mode, p in items if mode == "I"]
# Paths are project-relative; the index names them from the repository top.
prefix = os.environ.get("CCGS_VC_PREFIX", "")
blobs = {}
if staged:
    out = subprocess.run(["git", "cat-file", "--batch"], stdout=subprocess.PIPE,
                         input="".join(":" + prefix + p + "\n" for p in staged).encode("utf-8")).stdout
    pos = 0
    for p in staged:
        end = out.index(b"\n", pos)
        head = out[pos:end].split()
        pos = end + 1
        if len(head) == 3 and head[1] == b"blob":
            size = int(head[2])
            blobs[p] = out[pos:pos + size]
            pos += size + 1
for mode, p in items:
    try:
        if mode == "I":
            if p not in blobs:
                continue  # removed from the index: nothing of it is committed
            data = blobs[p]
            if data.startswith(b"version https://git-lfs.github.com/spec/"):
                # A Git LFS pointer: git add stored the file in LFS and staged
                # this stub, which is never JSON. The working copy is the file
                # it stored. With no working copy there is nothing to read --
                # say so, do not block a valid file or pass it in silence.
                if not os.path.isfile(p):
                    lfs_unread.append(p)
                    continue
                with open(p, "rb") as fh:
                    data = fh.read()
        else:
            if not os.path.isfile(p):
                continue
            with open(p, "rb") as fh:
                data = fh.read()
        json.loads(data.decode("utf-8-sig"))
    except Exception:
        bad.append(p)
# Bytes, not text. Python text-mode stdout on Windows rewrites \n as \r\n,
# putting a CR inside every path but the last. Invisible in a terminal and in
# a line-by-line diff -- only a byte comparison against the pre-batch
# implementation surfaced it. get_yaml_key writes bytes for the same reason.
# One line per file: "B<tab>path" not valid JSON, "S<tab>path" an LFS pointer
# with no working copy to read.
sys.stdout.buffer.write(("CCGS-JSON-CHECKED\n" + "".join("B\t" + p + "\n" for p in bad)
                         + "".join("S\t" + p + "\n" for p in lfs_unread)).encode("utf-8"))
' 2>/dev/null)
        if [ "$(printf '%s\n' "$JSON_OUT" | head -1)" != "CCGS-JSON-CHECKED" ]; then
            echo "BLOCKED: $(printf '%s\n' "$DATA_FILES" | grep -c .) staged data file(s) could not be validated -- the JSON check did not run under '$PYTHON_CMD'. Check that it is a working Python 3 and commit again." >&2
            exit 2
        fi
        BAD_JSON=$(printf '%s\n' "$JSON_OUT" | tail -n +2 | LC_ALL=C awk -F'\t' '$1 == "B" { print $2 }')
        LFS_UNREAD=$(printf '%s\n' "$JSON_OUT" | tail -n +2 | LC_ALL=C awk -F'\t' '$1 == "S" { print $2 }')
        if [ -n "$LFS_UNREAD" ]; then
            WARNINGS="$WARNINGS\nSKIPPED: $(printf '%s\n' "$LFS_UNREAD" | grep -c .) staged data file(s) are Git LFS pointers with no working copy, so the JSON check did NOT read them: $(printf '%s' "$LFS_UNREAD" | tr '\n' ' ')"
        fi
        if [ -n "$BAD_JSON" ]; then
            # Every offender at once. The per-file loop reported only the first
            # and exited, so a commit with several bad files took several
            # round-trips to clean up.
            echo "$BAD_JSON" | while IFS= read -r bad; do
                [ -n "$bad" ] && echo "BLOCKED: $bad is not valid JSON" >&2
            done
            exit 2
        fi
    else
        # Block, do not warn. Stderr from a hook that exits 0 goes to the debug
        # log only -- Claude never sees it -- so the old warning let unvalidated
        # data through in silence. A check that cannot run must not pass.
        echo "BLOCKED: $(printf '%s\n' "$DATA_FILES" | grep -c .) staged data file(s) could not be validated -- no Python 3 interpreter found (tried python, python3, py). CCGS needs Python for its config reads too; install it and commit again." >&2
        exit 2
    fi
fi

# Check design documents for the sections REQUIRED AT THIS PROJECT'S TIER.
#
# Demanding all 8 sections unconditionally would contradict
# .claude/docs/coding-standards.md and workflow-modes.md: the required count is
# a function of `modes.workflow` -- 8 at `full`, 5 (+ conditional Formulas) at
# `standard`, and no GDD requirement at all at `minimal`. A jam project on the
# recommended `minimal` tier was being warned about six sections its own
# configuration says it does not need, which trains the user to ignore the hook.
# Source the config helper ONCE, ahead of every consumer below. It was
# previously sourced inside the design-doc branch, so the code scans further
# down -- which now need resolve_code_root -- could not reach it on a commit
# that staged no GDD.
# Detect success by asking whether the function EXISTS, not by the source's exit
# status. A sourced file returns the status of its last statement, which here is
# incidental -- gating on it left _VC_HELPER at 0 on a perfectly good source, the
# workflow tier silently stayed at its "standard" fallback, and the GDD section
# check stopped scaling with the tier.
_VC_HELPER=0
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh 2>/dev/null || true
    command -v resolve_setting >/dev/null 2>&1 && _VC_HELPER=1
fi

# design/gdd/ also holds governance and registry files that are not system
# GDDs and have none of these sections, so they warned on every commit (#133).
# Skip the names not_a_system_gdd() skips in gdd-structure-check.sh and
# review-scope.sh; keep the three lists the same.
DESIGN_FILES=$(echo "$STAGED" | grep -E '^design/gdd/' \
  | grep -vE '/(game-concept|systems-index|game-pillars|gdd-cross-review-[^/]*|gameplay-tags|fixture-swap-ledger|entity-registry|sound-bible)\.md$')
if [ -n "$DESIGN_FILES" ]; then
    WORKFLOW="standard"
    if [ "$_VC_HELPER" = 1 ]; then
        W=$(resolve_setting modes.workflow 2>/dev/null | cut -f1)
        [ -n "$W" ] && WORKFLOW="$W"
    fi

    # "Detailed" (not "Detailed Rules") because the canonical heading has a
    # documented alias, "Detailed Design" -- workflow-modes.md says not to treat
    # one as missing when the other is present.
    case "$WORKFLOW" in
        minimal) REQUIRED="" ;;
        full)    REQUIRED="Overview|Player Fantasy|Detailed|Formulas|Edge Cases|Dependencies|Tuning Knobs|Acceptance Criteria" ;;
        *)       REQUIRED="Overview|Detailed|Edge Cases|Dependencies|Acceptance Criteria" ;;
    esac

    if [ -n "$REQUIRED" ] && [ -z "$_VC_PY" ]; then
        # A skipped step announces itself (obligation 3, as below). Handing the
        # scan to a `python` that is not there printed nothing, which read as a
        # GDD with every section its tier requires.
        WARNINGS="$WARNINGS\nSKIPPED: no Python 3 interpreter found (tried python, python3, py), so the GDD section check did NOT run on the staged design doc(s)."
    elif [ -n "$REQUIRED" ]; then
        # One pass for every file x section pair.
        #
        # A nested shell loop -- for each staged design doc, `echo |
        # tr | while read` then one `grep -qi` per required section -- does not
        # scale. At workflow=full that is 8 greps per file, and each is a
        # process, so an ordinary project of about 50 GDDs would use nearly all
        # of this hook's 15s budget on the ADVISORY half alone.
        #
        # Matching is unchanged on purpose: case-insensitive SUBSTRING anywhere
        # in the file, exactly what `grep -qi "$section"` did. It is looser than
        # a heading check, and tightening it here would silently change which
        # documents warn -- a behaviour change smuggled inside a performance
        # fix. If that wants tightening it should be its own change with its
        # own test.
        printf '%s\n' "$DESIGN_FILES" | "$_VC_PY" -c '
import sys, os
argv = sys.argv
required = [x for x in argv[1].split("|") if x]
workflow = argv[2]
out = []
for line in sys.stdin.read().splitlines():
    path = line.strip()
    if not path or not path.endswith(".md") or not os.path.isfile(path):
        continue
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            body = fh.read().lower()
    except OSError:
        continue
    for section in required:
        if section.lower() not in body:
            out.append("DESIGN: %s missing section required at workflow=%s: %s"
                       % (path, workflow, section))
if out:
    # Bytes, not text -- see the CRLF note in the JSON scan above.
    sys.stdout.buffer.write(("\n".join(out) + "\n").encode("utf-8"))
' "$REQUIRED" "$WORKFLOW" > "$TMP_DESIGN" 2>/dev/null
        if [ -z "$TMP_DESIGN" ]; then
            # Obligation 3 of .claude/rules/skill-authoring.md: a skipped step
            # announces itself. Silence here is indistinguishable from a GDD
            # that already has every section its tier requires.
            WARNINGS="$WARNINGS\nSKIPPED: no writable scratch location, so the GDD section check did NOT run on the staged design doc(s)."
        elif [ -s "$TMP_DESIGN" ]; then
            WARNINGS="$WARNINGS\n$(cat "$TMP_DESIGN")"
        fi
    fi
fi

# Check for hardcoded gameplay values in gameplay code
# Uses grep -E (POSIX extended) instead of grep -P (Perl) for cross-platform compatibility
#
# Batched through xargs. Run one `grep` per staged file -- a process each,
# ~60ms on Windows -- and 400 staged gameplay files blow a 15s budget on their
# own. `xargs` packs as many
# paths into each grep as ARG_MAX allows, so the spawn count is bounded by total
# path length rather than by file count.
#
# `-l` not `-q`: with many files per invocation the exit status can no longer
# say WHICH matched, and the warning names the file. It stays a test, not a
# report -- `-l` prints only names, never matched lines, which is what the -q
# comment here was guarding against.
#
# NUL-delimited, NOT `-d '\n'`: both `-d` and `-r` are GNU-only extensions.
# BSD xargs (macOS) rejects `-d`, and because this pipeline ends in
# `2>/dev/null || true` the rejection is SILENT -- the check returns empty and
# reports nothing found, which is indistinguishable from a clean scan. README
# claims these hooks run on macOS, so a silent no-op there is a false pass.
# `-0` exists in both GNU and BSD xargs. `-r` is dropped, not replaced: both
# callers below reach xargs only inside `if [ -n ... ]`, so the empty-input case
# it guarded cannot occur. `|| true` stays -- grep exits 1 on no match, which is
# the normal case and not an error.
# --- resolve the code root before either scan below ------------------------
#
# Both scans used to be hardcoded to `^src/gameplay/` and `^src/`. Per
# .claude/docs/directory-structure.md, `src/` is the GODOT row of the code-root
# table -- Unity compiles only `Assets/`, Unreal builds only from `Source/`. So
# on two of the three supported engines both greps matched nothing on every
# commit, both checks silently did not run, and the hook exited 0. A scan that
# cannot run and a scan that found nothing produced the identical artifact.
#
# The `/gameplay/` narrowing is dropped rather than translated: it describes a
# Godot source layout and has no Unity or Unreal equivalent, so keeping it would
# leave the check Godot-only by a second route. The hardcoded-value scan instead
# widens to the whole code root and is bounded by source-code EXTENSION, which
# is what actually keeps it precise -- without it, a Unity commit would drag
# `.meta`, `.asset` and `.prefab` YAML (all full of `speed: 5`) into a scan
# meant for code, and a hook that cries wolf gets muted rather than fixed.
CODE_ROOT=""; CODE_ROOT_SRC="unset"
if [ "$_VC_HELPER" = 1 ]; then
    _CR=$(resolve_code_root 2>/dev/null)
    CODE_ROOT=$(printf '%s' "$_CR" | cut -f1)
    CODE_ROOT_SRC=$(printf '%s' "$_CR" | cut -f2)
fi

# Obligation 3 of .claude/rules/skill-authoring.md -- a skipped step announces
# itself. Only fires when source code is actually being committed, so a
# docs-only or config-only commit stays quiet and the notice keeps its meaning.
if [ -z "$CODE_ROOT" ]; then
    if echo "$STAGED" | grep -qiE '\.(gd|cs|cpp|cc|hpp|h|c|py|js|ts|rs|java|kt|lua|gdshader|shader|hlsl)$'; then
        WARNINGS="$WARNINGS\nSKIPPED: source files are staged but no code root could be resolved (engine.name unset, and the tree does not name one unambiguously). The hardcoded-value and TODO-owner scans did NOT run. Run /setup-engine, or set engine.name in project.yaml."
    fi
fi

CODE_FILES=""
[ -n "$CODE_ROOT" ] && CODE_FILES=$(echo "$STAGED" \
    | grep -E "^${CODE_ROOT}/" \
    | grep -iE '\.(gd|cs|cpp|cc|hpp|h|c|py|js|ts|rs|java|kt|lua)$')
if [ -n "$CODE_FILES" ]; then
    HARDCODED=$(printf '%s\n' "$CODE_FILES" | tr '\n' '\0' \
        | xargs -0 grep -lE '(damage|health|speed|rate|chance|cost|duration)[[:space:]]*[:=][[:space:]]*[0-9]+' 2>/dev/null || true)
    if [ -n "$HARDCODED" ]; then
        while IFS= read -r file; do
            [ -n "$file" ] && WARNINGS="$WARNINGS\nCODE: $file may contain hardcoded gameplay values. Use data files."
        done <<< "$HARDCODED"
    fi
fi

# Check for TODO/FIXME without assignee -- uses grep -E instead of grep -P
# Same code root as the scan above. Not extension-bounded: an unowned TODO is
# worth flagging in a shader or a build script too, and this scan greps for a
# literal marker rather than a numeric pattern, so it does not misfire on
# serialized asset YAML the way the hardcoded-value scan would.
SRC_FILES=""
[ -n "$CODE_ROOT" ] && SRC_FILES=$(echo "$STAGED" | grep -E "^${CODE_ROOT}/")
if [ -n "$SRC_FILES" ]; then
    UNOWNED=$(printf '%s\n' "$SRC_FILES" | tr '\n' '\0' \
        | xargs -0 grep -lE '(TODO|FIXME|HACK)[^(]' 2>/dev/null || true)
    if [ -n "$UNOWNED" ]; then
        while IFS= read -r file; do
            [ -n "$file" ] && WARNINGS="$WARNINGS\nSTYLE: $file has TODO/FIXME without owner tag. Use TODO(name) format."
        done <<< "$UNOWNED"
    fi
fi

# Warnings allow the commit. They go out as hook JSON: stderr on exit 0 reaches
# the debug log only, so neither the user nor Claude ever saw them. stderr stays
# as the fallback for a tree whose helper did not load.
if [ -n "$WARNINGS" ]; then
    _VC_MSG=$(printf '%b' "=== Commit Validation Warnings ===$WARNINGS\n================================")
    if command -v hook_warn >/dev/null 2>&1; then
        hook_warn PreToolUse "$_VC_MSG"
    else
        printf '%s\n' "$_VC_MSG" >&2
    fi
fi

exit 0
