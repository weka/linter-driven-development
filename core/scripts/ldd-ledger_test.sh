#!/usr/bin/env bash
# Fixture matrix for ldd-ledger.sh — the deferral ledger's own conformance test.
#
# Each case builds a throwaway repository under a temp dir, runs the script in
# it and asserts the exit code and the lines it prints. No case reads or writes
# the ledger of the checkout that runs the test.
#
# Usage:  bash scripts/ldd-ledger_test.sh [path/to/ldd-ledger.sh]
#         (default: the sibling ldd-ledger.sh)
# Exit:   0 all cases pass · 1 any failure (details on stdout)

set -u
unset GIT_DIR GIT_WORK_TREE

HERE=$(cd "$(dirname "$0")" && pwd)
LEDGER="${1:-$HERE/ldd-ledger.sh}"
[[ -f "$LEDGER" ]] || { echo "no such script: $LEDGER" >&2; exit 2; }
LEDGER=$(cd "$(dirname "$LEDGER")" && pwd)/$(basename "$LEDGER")

pass=0 failed=0
CASE="" OUT="" CODE=0 TMP=""

begin() { CASE="$1"; TMP=$(mktemp -d); }
finish() { rm -rf "$TMP"; }
ok()  { pass=$((pass + 1)); echo "PASS  $CASE"; }
bad() { failed=$((failed + 1)); echo "FAIL  $CASE — $1"; echo "      exit=$CODE"; printf '%s\n' "$OUT" | sed 's/^/      | /'; }

new_repo() { # <dir> — a repository with one commit
  mkdir -p "$1"
  (cd "$1" && git init -q && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init)
}
run() { # <dir> <args...> — runs the script in <dir>, stdout and stderr together
  local dir="$1"; shift
  OUT=$(cd "$dir" && bash "$LEDGER" "$@" 2>&1); CODE=$?
}

# ---------- cases ----------

begin "show in a fresh repository prints Deferred: none"
new_repo "$TMP/r"
run "$TMP/r" show
if (( CODE == 0 )) && [[ "$OUT" == "Deferred: none" ]]; then ok; else bad "expected exactly 'Deferred: none'"; fi
finish

begin "add then show prints the row under Deferred:"
new_repo "$TMP/r"
run "$TMP/r" add finding user "R1 Q4 internal/x:12 — Extract Leaf Type"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 0 && CODE == 0 )) \
  && [[ "$(printf '%s\n' "$OUT" | sed -n 1p)" == "Deferred:" ]] \
  && [[ "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')" == "2" ]] \
  && printf '%s\n' "$OUT" | sed -n 2p | grep -qF "finding" \
  && printf '%s\n' "$OUT" | sed -n 2p | grep -qF "user" \
  && printf '%s\n' "$OUT" | sed -n 2p | grep -qF "R1 Q4 internal/x:12 — Extract Leaf Type"; then ok
else bad "expected 'Deferred:' and one row with kind, who and text (add exit=$add_code)"; fi
finish

begin "each kind and who is accepted, one row per add"
new_repo "$TMP/r"
run "$TMP/r" add finding no-user-answer "first"; c1=$CODE
run "$TMP/r" add prep no-user-answer "second"; c2=$CODE
run "$TMP/r" add mutation-not-run user "third"; c3=$CODE
run "$TMP/r" show
if (( c1 == 0 && c2 == 0 && c3 == 0 && CODE == 0 )) \
  && [[ "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')" == "4" ]] \
  && printf '%s\n' "$OUT" | grep -qF "mutation-not-run"; then ok
else bad "expected three rows (exits $c1 $c2 $c3)"; fi
finish

begin "text with spaces, a percent sign and a newline stays one row"
new_repo "$TMP/r"
run "$TMP/r" add finding user "50% of" "the leaf
is untested"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 0 )) && [[ "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')" == "2" ]] \
  && printf '%s\n' "$OUT" | grep -qF "50% of the leaf is untested"; then ok
else bad "expected one row with the joined text"; fi
finish

begin "add from a subdirectory writes the same ledger"
new_repo "$TMP/r"
mkdir -p "$TMP/r/a/b"
run "$TMP/r/a/b" add prep no-user-answer "deep"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 0 )) && printf '%s\n' "$OUT" | grep -qF "deep" \
  && [[ ! -e "$TMP/r/a/b/ldd" && ! -e "$TMP/r/a/b/.git" ]]; then ok
else bad "expected the row in the repository ledger"; fi
finish

begin "a git worktree checkout has its own ledger under the main .git"
new_repo "$TMP/r"
(cd "$TMP/r" && git worktree add -q "$TMP/wt" 2>/dev/null)
run "$TMP/wt" add finding user "in the worktree"
add_code=$CODE
run "$TMP/wt" show
wt_out=$OUT wt_code=$CODE
run "$TMP/r" show
if (( add_code == 0 && wt_code == 0 )) \
  && printf '%s\n' "$wt_out" | grep -qF "in the worktree" \
  && [[ "$OUT" == "Deferred: none" ]] \
  && [[ -f "$TMP/wt/.git" && ! -e "$TMP/wt/ldd" ]] \
  && ls "$TMP/r/.git/worktrees/"*/ldd/ledger.md >/dev/null 2>&1; then ok
else OUT="worktree: $wt_out | main: $OUT"; bad "expected the row in .git/worktrees/<name>/ldd/ledger.md only"; fi
finish

begin "clear empties the ledger"
new_repo "$TMP/r"
run "$TMP/r" add finding user "to clear"
run "$TMP/r" clear
clear_code=$CODE
run "$TMP/r" show
if (( clear_code == 0 && CODE == 0 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else bad "expected exactly 'Deferred: none' after clear (clear exit=$clear_code)"; fi
finish

begin "a bad kind exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add bogus user "text"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else CODE=$add_code; bad "expected exit 2 and no row"; fi
finish

begin "a bad who exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add finding agent "text"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else CODE=$add_code; bad "expected exit 2 and no row"; fi
finish

begin "add with no text exits 2"
new_repo "$TMP/r"
run "$TMP/r" add finding user
if (( CODE == 2 )); then ok; else bad "expected exit 2"; fi
finish

begin "an unknown command exits 2"
new_repo "$TMP/r"
run "$TMP/r" list
if (( CODE == 2 )); then ok; else bad "expected exit 2"; fi
finish

begin "outside a git repository exits 2"
mkdir -p "$TMP/plain"
OUT=$(cd "$TMP/plain" && GIT_CEILING_DIRECTORIES="$TMP" bash "$LEDGER" show 2>&1); CODE=$?
if (( CODE == 2 )); then ok; else bad "expected exit 2"; fi
finish

echo
echo "ldd-ledger: $pass passed, $failed failed"
(( failed == 0 ))
