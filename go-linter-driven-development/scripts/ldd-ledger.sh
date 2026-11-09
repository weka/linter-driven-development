#!/usr/bin/env bash
# Deferral ledger of the go-linter-driven-development plugin.
#
# Keeps the deferred work of a branch in a file. The file stays when Claude
# Code compacts the conversation. Every closing report prints `show`. The agent
# runs `clear` only when the user asks for it.
#
# Usage:  bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh add finding <user|no-user-answer> [<text>...]
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh add prep [<text>...]
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh add mutation-not-run [<text>...]
#           with no text argument, add reads the text from stdin
#           add prints the row; it does not write a row that is already there
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh show
#           prints "Deferred:" and one line per row, or "Deferred: none"
#         bash ${CLAUDE_PLUGIN_ROOT}/scripts/ldd-ledger.sh clear
# Rows:   - finding · <who> · <text>
#         - prep · <text>
#         - mutation-not-run · <text>
# File:   $(git rev-parse --git-path ldd/<branch>.md), one file for each branch;
#         a `/` in the branch name becomes `%2F`; a detached HEAD uses `detached`
# Exit:   0 done · 1 a read or write of the file failed · 2 bad usage, or no git repository

set -euo pipefail

usage() { sed -n '/^# Usage:/,/^# Exit:/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
fail() { echo "ldd-ledger: $*" >&2; exit 1; }

git rev-parse --git-dir >/dev/null \
  || { echo "ldd-ledger: not inside a git repository" >&2; exit 2; }
branch=$(git symbolic-ref --short -q HEAD) || branch=detached
ledger=$(git rev-parse --git-path "ldd/${branch//\//%2F}.md")

cmd="${1:-}"
case "$cmd" in
  add)
    (( $# >= 2 )) || usage
    kind="$2"
    case "$kind" in
      finding)
        (( $# >= 3 )) || usage
        case "$3" in user|no-user-answer) ;; *) echo "ldd-ledger: bad who: $3" >&2; usage ;; esac
        head="- finding · $3 · "
        shift 3
        ;;
      prep|mutation-not-run)
        case "${3:-}" in user|no-user-answer) echo "ldd-ledger: a $kind row takes no who" >&2; usage ;; esac
        head="- $kind · "
        shift 2
        ;;
      *) echo "ldd-ledger: bad kind: $kind" >&2; usage ;;
    esac
    if (( $# > 0 )); then
      text=$(printf '%s ' "$@")
    else
      [[ -t 0 ]] && usage
      text=$(cat)
    fi
    text=$(printf '%s' "$text" | tr '\n\r\t' '   ' | sed 's/  */ /g; s/^ //; s/ $//')
    [[ -n "$text" ]] || { echo "ldd-ledger: the text is empty" >&2; usage; }
    row="$head$text"
    if [[ -e "$ledger" ]]; then
      found=0
      grep -qxF -- "$row" "$ledger" || found=$?
      case "$found" in
        0) printf '%s\n' "$row"; exit 0 ;;
        1) ;;
        *) fail "cannot read $ledger" ;;
      esac
    fi
    mkdir -p -- "$(dirname -- "$ledger")" || fail "cannot create the directory of $ledger"
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
    rm -f -- "$ledger" || fail "cannot remove $ledger"
    ;;
  *) usage ;;
esac
