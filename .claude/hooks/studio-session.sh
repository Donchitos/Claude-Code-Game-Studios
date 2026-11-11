#!/bin/bash
# Hook helper: studio-session.sh — Dont-Know-Studios session-start notices.
# Sourced by session-start.sh in place of update-check.sh; see STUDIO.md.
#
#   studio_session_notice
#     Prints at most one line:
#       - in the studio template repo itself: that games are not built here,
#         and to run /new-game;
#       - in a game: that a newer studio release is out, when the cached newest
#         studio release is newer than STUDIO_VERSION in .claude/studio.conf.
#     Starts a background refresh of that cache when it is missing or a day
#     old. Never touches the network itself and never waits.
#
#   bash studio-session.sh refresh
#     Asks GitHub for the newest studio release and writes the cache.
#   bash studio-session.sh notice
#     Prints the notice line by hand.
#
# Why a separate file from update-check.sh: that one announces upstream
# (Donchitos) releases and holds the upstream framework version, which
# set-stage.sh writes into project.yaml. Games take studio releases, never
# upstream ones directly, so the studio notice replaces it; keeping it a
# separate, studio-owned file means upstream merges never conflict here.
#
# The update notice is off when `updates.check: false` (project.local.yaml
# first, then project.yaml) or when CI is set — the same switch as
# update-check.sh. The template-repo line is never off: it is the guard.
#
# Cross-platform: Windows Git Bash, macOS bash 3.2, Linux. Needs curl or wget
# for the refresh only.

case "${BASH_SOURCE[0]}" in
  /*|[A-Za-z]:*) _STUDIO_SESSION_SELF="${BASH_SOURCE[0]}" ;;
  *)             _STUDIO_SESSION_SELF="$PWD/${BASH_SOURCE[0]}" ;;
esac

_studio_root() {
  local d="${_STUDIO_SESSION_SELF%/*}"   # .claude/hooks
  d="${d%/*}"                             # .claude
  printf '%s' "${d%/*}"
}

_studio_conf_get() {
  local conf
  conf="$(_studio_root)/.claude/studio.conf"
  [ -f "$conf" ] || return 0
  awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); sub(/[ \t\r]+$/, ""); print; exit }' "$conf"
}

_studio_cache() {
  # Per user, outside every project, and per studio repo: a plain upstream
  # project on the same machine keeps its own cache (update-check.sh's).
  local repo
  repo=$(_studio_conf_get STUDIO_REPO | tr '[:upper:]/' '[:lower:]_')
  printf '%s' "${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-game-studios/studio-${repo:-unknown}-latest-release"
}

_studio_now() {
  if [ -n "${EPOCHSECONDS:-}" ]; then printf '%s' "$EPOCHSECONDS"; else date +%s; fi
}

# 0 when x.y.z $1 is newer than $2. Plain numbers only.
# shellcheck disable=SC2034  # a1..b3 are read through eval
_studio_newer() {
  local a="${1%%-*}" b="${2%%-*}" i x y
  local IFS=.
  set -- $a; local a1="${1:-0}" a2="${2:-0}" a3="${3:-0}"
  set -- $b; local b1="${1:-0}" b2="${2:-0}" b3="${3:-0}"
  for i in 1 2 3; do
    eval "x=\$a$i; y=\$b$i"
    case "$x$y" in *[!0-9]*|'') return 1 ;; esac
    [ "$x" -gt "$y" ] && return 0
    [ "$x" -lt "$y" ] && return 1
  done
  return 1
}

# 0 unless updates.check is false, or CI is set.
_studio_updates_enabled() {
  local f v root
  root=$(_studio_root)
  [ -n "${CI:-}" ] && return 1
  for f in "$root/project.local.yaml" "$root/project.yaml"; do
    [ -f "$f" ] || continue
    v=$(awk '
      /^updates:[[:space:]]*(#.*)?$/ { inu=1; next }
      /^[^[:space:]#]/               { inu=0 }
      inu && /^[[:space:]]+check:/ {
        sub(/^[[:space:]]*check:[[:space:]]*/, "")
        sub(/[[:space:]]*#.*$/, "")
        gsub(/["'"'"'[:space:]]/, "")
        print; exit
      }' "$f" 2>/dev/null)
    case "$v" in
      false) return 1 ;;
      true)  return 0 ;;
    esac
  done
  return 0
}

studio_session_notice() {
  local root role repo version cache latest="" checked=0 line now
  root=$(_studio_root)
  repo=$(_studio_conf_get STUDIO_REPO)
  [ -n "$repo" ] || return 0

  if [ -f "$root/.claude/scripts/studio-check.sh" ]; then
    role=$(bash "$root/.claude/scripts/studio-check.sh" --root "$root" 2>/dev/null | awk -F'\t' '$1 == "role" { print $2; exit }')
  fi
  if [ "$role" = template ]; then
    echo "Studio template: this checkout is $repo itself, which every game is cloned from. Games are never built here — to start one, run /new-game (it gives the game its own repo). Maintaining the template? Ignore this line."
    return 0
  fi

  _studio_updates_enabled || return 0
  version=$(_studio_conf_get STUDIO_VERSION)
  cache=$(_studio_cache)
  if [ -f "$cache" ]; then
    while IFS= read -r line; do
      case "$line" in
        latest=*)  latest="${line#latest=}" ;;
        checked=*) checked="${line#checked=}" ;;
      esac
    done < "$cache"
  fi
  case "$checked" in ''|*[!0-9]*) checked=0 ;; esac

  now=$(_studio_now)
  if { [ $((now - checked)) -ge 86400 ] || [ "$checked" -gt "$now" ]; } && [ -f "$_STUDIO_SESSION_SELF" ]; then
    ( bash "$_STUDIO_SESSION_SELF" refresh </dev/null >/dev/null 2>&1 & ) >/dev/null 2>&1
  fi

  if [ -n "$latest" ] && [ -n "$version" ] && _studio_newer "$latest" "$version"; then
    echo "Update: studio template $latest is out (this project has $version). What changed: https://github.com/$repo/releases/latest — the repo's open 'template-update' issue has the merge steps (STUDIO.md, 'Taking a studio update'). To stop this notice: /project-settings --local updates.check=false"
  fi
  return 0
}

# Ask GitHub, write the cache. A failed answer keeps the last known release and
# still stamps the time, so an offline machine asks once a day.
studio_session_refresh() {
  local cache dir body="" tag="" err="" old="" line tmp repo prefix url
  repo=$(_studio_conf_get STUDIO_REPO)
  prefix=$(_studio_conf_get STUDIO_TAG_PREFIX)
  [ -n "$repo" ] || return 0
  cache=$(_studio_cache); dir="${cache%/*}"
  mkdir -p "$dir" 2>/dev/null || return 0
  url="https://api.github.com/repos/$repo/releases/latest"
  if command -v curl >/dev/null 2>&1; then
    body=$(curl -fsSL --max-time 10 -H 'Accept: application/vnd.github+json' "$url" 2>/dev/null) || err="request failed"
  elif command -v wget >/dev/null 2>&1; then
    body=$(wget -q -t 1 -T 5 -O - "$url" 2>/dev/null) || err="request failed"
  else
    err="neither curl nor wget found"
  fi
  if [ -z "$err" ]; then
    tag=$(printf '%s' "$body" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
          | sed 's/.*"\([^"]*\)"$/\1/')
    case "$tag" in
      "$prefix"*) tag="${tag#"$prefix"}" ;;
      *) err="newest release is not a studio release: ${tag:-none}"; tag="" ;;
    esac
    case "$tag" in
      '') ;;
      [0-9]*.[0-9]*.[0-9]*) case "$tag" in *[!0-9.]*) err="unexpected tag: $tag"; tag="" ;; esac ;;
      *) err="unexpected tag: $tag"; tag="" ;;
    esac
  fi
  if [ -z "$tag" ] && [ -f "$cache" ]; then
    while IFS= read -r line; do
      case "$line" in latest=*) old="${line#latest=}" ;; esac
    done < "$cache"
    tag="$old"
  fi
  tmp="$cache.$$"
  {
    echo "checked=$(_studio_now)"
    echo "latest=$tag"
    if [ -n "$err" ]; then echo "error=$err"; fi
  } > "$tmp" 2>/dev/null && mv -f "$tmp" "$cache" 2>/dev/null
  rm -f "$tmp" 2>/dev/null
  return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    refresh) studio_session_refresh ;;
    notice)  studio_session_notice ;;
    *) echo "usage: bash studio-session.sh refresh|notice" >&2; exit 2 ;;
  esac
fi
