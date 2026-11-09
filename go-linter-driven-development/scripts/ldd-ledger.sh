#!/usr/bin/env bash
# Deferral ledger of the go-linter-driven-development plugin.
#
# Keeps the list of deferred work in a file, so the list survives context
# compaction. Every closing report prints `show`. Only the user runs `clear`.
#
# Usage:  bash scripts/ldd-ledger.sh add <kind> <who> <text>...
#           kind: finding | prep | mutation-not-run
#           who:  user | no-user-answer
#         bash scripts/ldd-ledger.sh show
#           prints "Deferred:" and one line per row, or "Deferred: none"
#         bash scripts/ldd-ledger.sh clear
# File:   $(git rev-parse --git-path ldd/ledger.md) — one file per checkout,
#         also in a `git worktree add` checkout
# Exit:   0 done · 2 bad usage, or not inside a git repository

set -u

usage() { sed -n '/^# Usage:/,/^# Exit:/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

ledger=$(git rev-parse --git-path ldd/ledger.md 2>/dev/null) \
  || { echo "ldd-ledger: not inside a git repository" >&2; exit 2; }

cmd="${1:-}"
case "$cmd" in
  add)
    (( $# >= 4 )) || usage
    kind="$2" who="$3"
    case "$kind" in finding|prep|mutation-not-run) ;; *) echo "ldd-ledger: bad kind: $kind" >&2; usage ;; esac
    case "$who" in user|no-user-answer) ;; *) echo "ldd-ledger: bad who: $who" >&2; usage ;; esac
    shift 3
    text=$(printf '%s ' "$@" | tr '\n\r' '  ' | sed 's/  */ /g; s/^ //; s/ $//')
    [[ -n "$text" ]] || usage
    mkdir -p "$(dirname "$ledger")"
    printf -- '- %s · %s · %s\n' "$kind" "$who" "$text" >> "$ledger"
    ;;
  show)
    (( $# == 1 )) || usage
    if [[ -s "$ledger" ]]; then
      echo "Deferred:"
      cat "$ledger"
    else
      echo "Deferred: none"
    fi
    ;;
  clear)
    (( $# == 1 )) || usage
    rm -f "$ledger"
    ;;
  *) usage ;;
esac
