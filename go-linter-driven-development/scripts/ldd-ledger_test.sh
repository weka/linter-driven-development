#!/usr/bin/env bash
# Tests of ldd-ledger.sh. Each case makes a temporary repository, runs the
# script in it, and checks the exit code and the output. No case reads or
# writes the ledger of the checkout that runs the test.
#
# Usage:  bash scripts/ldd-ledger_test.sh [path/to/ldd-ledger.sh]
#         (default: the sibling ldd-ledger.sh)
# Exit:   0 all cases pass · 1 any failure (details on stdout)

set -u
unset GIT_DIR GIT_WORK_TREE
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

HERE=$(cd "$(dirname "$0")" && pwd)
LEDGER="${1:-$HERE/ldd-ledger.sh}"
[[ -f "$LEDGER" ]] || { echo "no such script: $LEDGER" >&2; exit 2; }
LEDGER=$(cd "$(dirname "$LEDGER")" && pwd)/$(basename "$LEDGER")

pass=0 failed=0
CASE="" OUT="" CODE=0 TMP=""

begin() { CASE="$1"; TMP=$(mktemp -d); }
finish() { chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"; }
ok()  { pass=$((pass + 1)); echo "PASS  $CASE"; }
skip() { echo "SKIP  $CASE — $1"; }
bad() { failed=$((failed + 1)); echo "FAIL  $CASE — $1"; echo "      exit=$CODE"; printf '%s\n' "$OUT" | sed 's/^/      | /'; }

new_repo() {
  mkdir -p "$1" || { echo "setup failed: mkdir $1"; exit 1; }
  (cd "$1" && git init -q -b main \
    && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init) \
    || { echo "setup failed: git init in $1"; exit 1; }
}
git_in() {
  (cd "$1" && shift && git "$@") || { echo "setup failed: git ${*:2} in $1"; exit 1; }
}
# Runs the script in <dir> with stdout and stderr together. Stdin is the
# caller's: a case passes a heredoc, every other case gets /dev/null.
run_stdin() {
  local dir="$1"; shift
  OUT=$(cd "$dir" && bash "$LEDGER" "$@" 2>&1); CODE=$?
}
run() { run_stdin "$@" </dev/null; }
rows() { printf '%s\n' "$OUT" | sed -n '2,$p'; }

begin "show in a fresh repository prints Deferred: none"
new_repo "$TMP/r"
run "$TMP/r" show
if (( CODE == 0 )) && [[ "$OUT" == "Deferred: none" ]]; then ok; else bad "expected exactly 'Deferred: none'"; fi
finish

begin "each kind writes its exact row, and add prints it"
new_repo "$TMP/r"
run "$TMP/r" add finding user "R1 Q4 internal/x:12 — Extract Leaf Type"; c1=$CODE o1=$OUT
run "$TMP/r" add finding no-user-answer "second"; c2=$CODE o2=$OUT
run "$TMP/r" add prep "Split the pure leaf — bounded L"; c3=$CODE o3=$OUT
run "$TMP/r" add mutation-not-run "internal/x/leaf — gremlins not on PATH"; c4=$CODE o4=$OUT
run "$TMP/r" show
want="Deferred:
- finding · user · R1 Q4 internal/x:12 — Extract Leaf Type
- finding · no-user-answer · second
- prep · Split the pure leaf — bounded L
- mutation-not-run · internal/x/leaf — gremlins not on PATH"
if (( c1 == 0 && c2 == 0 && c3 == 0 && c4 == 0 && CODE == 0 )) && [[ "$OUT" == "$want" ]] \
  && [[ "$o1" == "- finding · user · R1 Q4 internal/x:12 — Extract Leaf Type" ]] \
  && [[ "$o3" == "- prep · Split the pure leaf — bounded L" ]] \
  && [[ "$o4" == "- mutation-not-run · internal/x/leaf — gremlins not on PATH" ]]; then ok
else bad "expected four exact rows (exits $c1 $c2 $c3 $c4; add output: $o1 | $o2 | $o3 | $o4)"; fi
finish

begin "a who on a prep or mutation-not-run row exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add prep no-user-answer "text"; c1=$CODE
run "$TMP/r" add mutation-not-run user "text"; c2=$CODE
run "$TMP/r" show
if (( c1 == 2 && c2 == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else bad "expected exit 2 from both and no row (exits $c1 $c2)"; fi
finish

begin "the same row added twice is one row, and the second add prints it"
new_repo "$TMP/r"
run "$TMP/r" add finding user "twice"
run "$TMP/r" add finding user "twice"; c2=$CODE o2=$OUT
run "$TMP/r" show
if (( c2 == 0 )) && [[ "$o2" == "- finding · user · twice" ]] \
  && [[ "$(rows)" == "- finding · user · twice" ]]; then ok
else bad "expected one row (second add exit=$c2, output: $o2)"; fi
finish

begin "text from a quoted heredoc stays literal and runs nothing"
new_repo "$TMP/r"
run_stdin "$TMP/r" add finding user <<'ROW'
it's $(touch pwned); echo x > made.txt `touch tick`
ROW
add_code=$CODE add_out=$OUT
run "$TMP/r" show
if (( add_code == 0 )) \
  && [[ "$(rows)" == "- finding · user · it's \$(touch pwned); echo x > made.txt \`touch tick\`" ]] \
  && [[ ! -e "$TMP/r/pwned" && ! -e "$TMP/r/made.txt" && ! -e "$TMP/r/tick" ]]; then ok
else bad "expected the literal text and no new file (add exit=$add_code, output: $add_out)"; fi
finish

begin "text with spaces, a percent sign, a tab and a newline stays one row"
new_repo "$TMP/r"
run "$TMP/r" add finding user "50% of" "the leaf
is	untested"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 0 )) && [[ "$(rows)" == "- finding · user · 50% of the leaf is untested" ]]; then ok
else bad "expected one row with the joined text"; fi
finish

begin "text of spaces or tabs only exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add finding user "   "; c1=$CODE
run "$TMP/r" add finding user "	"; c4=$CODE
run "$TMP/r" add prep "	 	"; c2=$CODE
run_stdin "$TMP/r" add mutation-not-run <<'ROW'

ROW
c3=$CODE
run "$TMP/r" show
if (( c1 == 2 && c2 == 2 && c3 == 2 && c4 == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else bad "expected exit 2 from each and no row (exits $c1 $c4 $c2 $c3)"; fi
finish

begin "add with no text and empty stdin exits 2"
new_repo "$TMP/r"
run "$TMP/r" add finding user; c1=$CODE
run "$TMP/r" add prep
if (( c1 == 2 && CODE == 2 )); then ok; else bad "expected exit 2 from both (finding exit=$c1)"; fi
finish

begin "add reads the text from a file on stdin"
new_repo "$TMP/r"
printf 'from a file\n' > "$TMP/row.txt"
run_stdin "$TMP/r" add prep < "$TMP/row.txt"
if (( CODE == 0 )) && [[ "$OUT" == "- prep · from a file" ]]; then ok
else bad "expected '- prep · from a file'"; fi
finish

begin "add with no text and stdin from an open socket exits 2 at once"
new_repo "$TMP/r"
sock=$(cd "$TMP/r" && python3 -I -c '
import socket, subprocess, sys
a, b = socket.socketpair()
try:
    r = subprocess.run(["bash", sys.argv[1], "add", "prep"], stdin=a, capture_output=True, timeout=10)
    print(r.returncode)
except subprocess.TimeoutExpired:
    print("timeout")
' "$LEDGER")
run "$TMP/r" show
if [[ "$sock" == "2" ]] && [[ "$OUT" == "Deferred: none" ]]; then ok
else bad "expected exit 2 and no row (add with a socket stdin: $sock)"; fi
finish

begin "a new row that is part of an old row is a new row"
new_repo "$TMP/r"
run "$TMP/r" add prep "split the leaf out"
run "$TMP/r" add prep "split the leaf"; c2=$CODE
run "$TMP/r" show
if (( c2 == 0 )) && [[ "$(rows)" == "- prep · split the leaf out
- prep · split the leaf" ]]; then ok
else bad "expected two rows (second add exit=$c2)"; fi
finish

begin "leading and trailing spaces are trimmed"
new_repo "$TMP/r"
run "$TMP/r" add prep "   lead and trail   "
add_code=$CODE add_out=$OUT
if (( add_code == 0 )) && [[ "$add_out" == "- prep · lead and trail" ]]; then ok
else bad "expected '- prep · lead and trail'"; fi
finish

begin "add finding with no who exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add finding; c1=$CODE
run "$TMP/r" add finding "R1 Q4 text with no who"; c2=$CODE
run "$TMP/r" show
if (( c1 == 2 && c2 == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else bad "expected exit 2 from both and no row (exits $c1 $c2)"; fi
finish

begin "add from a subdirectory writes the same ledger"
new_repo "$TMP/r"
mkdir -p "$TMP/r/a/b"
run "$TMP/r/a/b" add prep "deep"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 0 )) && printf '%s\n' "$OUT" | grep -qF "deep" \
  && [[ ! -e "$TMP/r/a/b/ldd" && ! -e "$TMP/r/a/b/.git" ]]; then ok
else bad "expected the row in the repository ledger"; fi
finish

begin "each branch has its own ledger"
new_repo "$TMP/r"
run "$TMP/r" add finding user "on main"
git_in "$TMP/r" checkout -q -b feature/x
run "$TMP/r" show; fresh=$OUT
run "$TMP/r" add finding user "on feature"
run "$TMP/r" show; feature=$OUT
git_in "$TMP/r" checkout -q main
run "$TMP/r" show
if [[ "$fresh" == "Deferred: none" ]] \
  && [[ "$feature" == "Deferred:
- finding · user · on feature" ]] \
  && [[ "$OUT" == "Deferred:
- finding · user · on main" ]] \
  && [[ -f "$TMP/r/.git/ldd/feature%2Fx.md" && -f "$TMP/r/.git/ldd/main.md" ]] \
  && [[ "$(find "$TMP/r/.git/ldd" -type f | wc -l | tr -d ' ')" == "2" ]]; then ok
else OUT="new branch: $fresh | feature: $feature | main: $OUT"; bad "expected ldd/main.md and ldd/feature%2Fx.md only"; fi
finish

begin "feat/x and feat%2Fx have separate ledgers"
new_repo "$TMP/r"
git_in "$TMP/r" checkout -q -b feat/x
run "$TMP/r" add prep "slash"
git_in "$TMP/r" checkout -q -b 'feat%2Fx'
run "$TMP/r" add prep "percent"
run "$TMP/r" show; percent=$OUT
git_in "$TMP/r" checkout -q feat/x
run "$TMP/r" show
if [[ "$OUT" == "Deferred:
- prep · slash" ]] && [[ "$percent" == "Deferred:
- prep · percent" ]] \
  && [[ -f "$TMP/r/.git/ldd/feat%2Fx.md" && -f "$TMP/r/.git/ldd/feat%252Fx.md" ]]; then ok
else OUT="feat/x: $OUT | feat%2Fx: $percent"; bad "expected two files, one row each"; fi
finish

begin "a detached HEAD and a branch named detached have separate ledgers"
new_repo "$TMP/r"
git_in "$TMP/r" checkout -q -b detached
run "$TMP/r" add prep "on the branch"
git_in "$TMP/r" checkout -q --detach
run "$TMP/r" show; head_fresh=$OUT
run "$TMP/r" add prep "on the head"
add_code=$CODE
git_in "$TMP/r" checkout -q detached
run "$TMP/r" show
if (( add_code == 0 )) && [[ "$head_fresh" == "Deferred: none" ]] \
  && [[ "$OUT" == "Deferred:
- prep · on the branch" ]] \
  && [[ -f "$TMP/r/.git/ldd/HEAD.md" && -f "$TMP/r/.git/ldd/detached.md" ]]; then ok
else OUT="detached HEAD before add: $head_fresh | branch detached: $OUT"; bad "expected ldd/HEAD.md and ldd/detached.md, one row each"; fi
finish

begin "a row added in a linked worktree stays after the worktree is removed"
new_repo "$TMP/r"
git_in "$TMP/r" worktree add -q -b topic "$TMP/wt"
run "$TMP/wt" add finding user "in the worktree"
add_code=$CODE
run "$TMP/r" show; main_out=$OUT
git_in "$TMP/r" worktree remove "$TMP/wt"
git_in "$TMP/r" checkout -q topic
run "$TMP/r" show
if (( add_code == 0 )) && [[ "$main_out" == "Deferred: none" ]] \
  && [[ "$OUT" == "Deferred:
- finding · user · in the worktree" ]] \
  && [[ ! -e "$TMP/wt" && -f "$TMP/r/.git/ldd/topic.md" ]]; then ok
else OUT="main before: $main_out | topic after removal: $OUT"; bad "expected the row in .git/ldd/topic.md after the worktree is gone"; fi
finish

begin "a write failure exits 1, writes no row, and show stays true"
if (( $(id -u) == 0 )); then skip "root ignores file modes"; else
new_repo "$TMP/r"
run "$TMP/r" add finding user "kept"
dir=$(dirname "$(find "$TMP/r/.git/ldd" -type f)")
chmod a-w "$dir" "$dir"/*.md
run "$TMP/r" add finding user "lost"
add_code=$CODE add_out=$OUT
run "$TMP/r" show
if (( add_code == 1 )) && printf '%s\n' "$add_out" | grep -q '^ldd-ledger: ' \
  && [[ "$OUT" == "Deferred:
- finding · user · kept" ]]; then ok
else OUT="add: $add_out | show: $OUT"; CODE=$add_code; bad "expected exit 1 with an ldd-ledger: line and the one old row"; fi
fi
finish

begin "show of an unreadable ledger exits 1 and prints nothing to stdout"
if (( $(id -u) == 0 )); then skip "root ignores file modes"; else
new_repo "$TMP/r"
run "$TMP/r" add finding user "hidden"
chmod a-r "$(find "$TMP/r/.git/ldd" -type f)"
stdout=$(cd "$TMP/r" && bash "$LEDGER" show 2>/dev/null </dev/null); CODE=$?
stderr=$(cd "$TMP/r" && bash "$LEDGER" show 2>&1 >/dev/null </dev/null)
OUT="stdout: $stdout | stderr: $stderr"
if (( CODE == 1 )) && [[ -z "$stdout" ]] && [[ "$stderr" == *"ldd-ledger: "* ]]; then ok
else bad "expected exit 1, an empty stdout and an ldd-ledger: line"; fi
fi
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

begin "clear on an empty ledger exits 0"
new_repo "$TMP/r"
run "$TMP/r" clear
if (( CODE == 0 )) && [[ -z "$OUT" ]]; then ok; else bad "expected exit 0 and no output"; fi
finish

begin "a bad kind exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add bogus user "text"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else CODE=$add_code; bad "expected exit 2 and no row"; fi
finish

begin "a bad who on a finding exits 2 and writes no row"
new_repo "$TMP/r"
run "$TMP/r" add finding agent "text"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 2 )) && [[ "$OUT" == "Deferred: none" ]]; then ok
else CODE=$add_code; bad "expected exit 2 and no row"; fi
finish

begin "text that starts with a dash stays literal"
new_repo "$TMP/r"
run "$TMP/r" add finding user "-n --flag text"
add_code=$CODE
run "$TMP/r" show
if (( add_code == 0 )) && [[ "$(rows)" == "- finding · user · -n --flag text" ]]; then ok
else bad "expected the dash text in the row (add exit=$add_code)"; fi
finish

begin "show or clear with an extra argument exits 2"
new_repo "$TMP/r"
run "$TMP/r" show extra; show_code=$CODE
run "$TMP/r" clear extra
if (( show_code == 2 && CODE == 2 )); then ok
else bad "expected exit 2 from both (show exit=$show_code)"; fi
finish

begin "an unknown command exits 2"
new_repo "$TMP/r"
run "$TMP/r" list
if (( CODE == 2 )); then ok; else bad "expected exit 2"; fi
finish

begin "outside a git repository exits 2"
mkdir -p "$TMP/plain"
OUT=$(cd "$TMP/plain" && GIT_CEILING_DIRECTORIES="$TMP" bash "$LEDGER" show 2>&1 </dev/null); CODE=$?
if (( CODE == 2 )); then ok; else bad "expected exit 2"; fi
finish

echo
echo "ldd-ledger: $pass passed, $failed failed"
(( failed == 0 ))
