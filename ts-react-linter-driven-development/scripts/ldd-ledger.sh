#!/usr/bin/env bash
# Deferral ledger of the ts-react-linter-driven-development plugin.
#
# Keeps the deferred work of a branch in a file. The file stays when Claude
# Code compacts the conversation, and when a linked worktree is removed. Every
# closing report prints `show`. The agent runs `clear` only when the user asks
# for it.
#
# Usage:  bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh add finding [<text>...]
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh add prep [<text>...]
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh add mutation-not-run [<text>...]
#           with no text argument, add reads the text from a pipe, a heredoc or a
#           file on stdin; any other stdin is bad usage
#           add prints the row; it does not write a row that is already there
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh show
#           prints "Deferred:" and one line per row, or "Deferred: none"
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh clear
# Rows:   - finding · <text>
#         - prep · <text>
#         - mutation-not-run · <text>
# File:   $(git rev-parse --path-format=absolute --git-common-dir)/ldd/<branch>.md,
#         one file for each branch; in the branch name `%` becomes `%25`, then `/`
#         becomes `%2F`; a detached HEAD uses `HEAD`
# Lock:   add and clear take the directory <file>.lock in turns; the script never
#         removes a lock that it did not take
# Exit:   0 done · 1 a read or write of the file failed, or the lock stayed taken
#         for 5 seconds · 2 bad usage, or no git repository

set -euo pipefail

usage() { sed -n '/^# Usage:/,/^# Exit:/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
fail() { echo "ldd-ledger: $*" >&2; exit 1; }

# A writer that sends no end of input in 5 seconds is bad usage. The limit is
# for all of the input, not for each line. The clock check also catches
# bash 3.2, whose read -t gives no timeout status.
read_stdin() {
  local line left deadline=$((SECONDS + 5))
  text=""
  while left=$((deadline - SECONDS)); (( left > 0 )) && IFS= read -r -t "$left" line; do
    text+="$line"$'\n'
  done
  (( SECONDS < deadline )) || { echo "ldd-ledger: no end of input on stdin in 5 seconds" >&2; usage; }
  text+="$line"
}

common=$(git rev-parse --path-format=absolute --git-common-dir) \
  || { echo "ldd-ledger: not inside a git repository" >&2; exit 2; }
branch=$(git symbolic-ref --short -q HEAD) || branch=HEAD
branch=${branch//\%/%25}
ledger="$common/ldd/${branch//\//%2F}.md"
lock="$ledger.lock"

# mkdir is atomic, and macOS has no flock.
take_lock() {
  local tries=0
  mkdir -p -- "$(dirname -- "$ledger")" || fail "cannot create the directory of $ledger"
  while ! mkdir -- "$lock" 2>/dev/null; do
    if [[ ! -e "$lock" ]]; then
      mkdir -- "$lock" && break
      fail "cannot create the lock $lock"
    fi
    (( tries++ < 50 )) || fail "the lock $lock stayed taken for 5 seconds; when no add or clear runs, remove it: rmdir -- $(printf '%q' "$lock")"
    sleep 0.1
  done
  trap 'rmdir -- "$lock" 2>/dev/null || true' EXIT
}

cmd="${1:-}"
case "$cmd" in
  add)
    (( $# >= 2 )) || usage
    kind="$2"
    case "$kind" in
      finding|prep|mutation-not-run)
        head="- $kind · "
        shift 2
        ;;
      *) echo "ldd-ledger: bad kind: $kind" >&2; usage ;;
    esac
    if (( $# > 0 )); then
      text=$(printf '%s ' "$@")
    else
      [[ -p /dev/stdin || -f /dev/stdin ]] || usage
      read_stdin
    fi
    text=$(printf '%s' "$text" | tr '\n\r\t' '   ' | sed 's/  */ /g; s/^ //; s/ $//')
    [[ -n "$text" ]] || { echo "ldd-ledger: the text is empty" >&2; usage; }
    row="$head$text"
    take_lock
    if [[ -e "$ledger" ]]; then
      found=0
      grep -qxF -- "$row" "$ledger" || found=$?
      case "$found" in
        0) printf '%s\n' "$row"; exit 0 ;;
        1) ;;
        *) fail "cannot read $ledger" ;;
      esac
    fi
    printf '%s\n' "$row" >> "$ledger" || fail "cannot write $ledger"
    printf '%s\n' "$row"
    ;;
  show)
    (( $# == 1 )) || usage
    rows=""
    if [[ -e "$ledger" ]]; then
      rows=$(cat -- "$ledger") || fail "cannot read $ledger"
    fi
    if [[ -n "$rows" ]]; then
      printf 'Deferred:\n%s\n' "$rows"
    else
      echo "Deferred: none"
    fi
    ;;
  clear)
    (( $# == 1 )) || usage
    take_lock
    rm -f -- "$ledger" || fail "cannot remove $ledger"
    ;;
  *) usage ;;
esac
