- **Mutation mechanics**: `gremlins unleash --timeout-coefficient 50 ./path/to/leaf` (go-gremlins, a Go mutation
  tester that swaps comparison operators, negates conditions, flips arithmetic and
  removes statements) over the leaf package, after `go test` is green there and after
  each fix; its report's `LIVED` lines are the survivors to triage, `KILLED` the rows
  that hold. In CI, `--threshold-efficacy` with the same `--timeout-coefficient` on that package only, never on `./...`, so
  orchestrator packages are not mutated. When `gremlins` is not on `PATH`, propose a
  `mutate` target beside `test` and `lint` in the repository's Taskfile or Makefile
  that runs `go install github.com/go-gremlins/gremlins/cmd/gremlins@latest` and then
  `gremlins unleash --timeout-coefficient 50 ./<leaf>`; with no task runner, propose that `go install` line for
  the developer to run. Ask first, never install silently, and never substitute a
  different invocation. The flag is necessary: gremlins gives each mutant a timeout of
  three times the duration of the coverage run, and on a fast host a mutant's own
  compile takes longer. When the repository runs gremlins without the flag, propose
  this `.gremlins.yaml` at the module root, two lines: `unleash:`, then
  `  timeout-coefficient: 50` indented under it. One line is not valid YAML, and
  gremlins ignores an invalid file with no message.
  A `Timed out:` count above 0 makes the run inconclusive: run the leaf once more with
  `--timeout-coefficient 100`. A mutant that times out in both runs makes the code
  loop with no end, for example `i--` in a `for` loop: the tests detect it, so count
  it as killed. A mutant that timed out in one run only takes its status from the
  other run. `LIVED` and `NOT COVERED` lines are findings in every run.
  A loop mutant waits its full timeout, so run gremlins in the background or give the
  call a time limit of 10 minutes. A call that a time limit stops gives no result:
  run it again in the background.
  The run did not execute when there is no summary line, when every count is 0, or
  when neither run killed a mutant and every `KILLED`, `LIVED` or `TIMED OUT` mutant
  timed out in both runs.
  gremlins never mutates an equality
  (`==`, `!=`) or a literal constant, so it cannot ask for the row where an element
  sorts below the needle or the row on the far side of a limit; the hand check's row
  at each boundary and one past it covers those two on purpose, not by accident.
  A mutation run targets only a pure logic leaf. A pure logic leaf does no I/O
  (network, files, environment variables, clock), and its tests call it with literal
  inputs. Never run the tool over a package or module that does I/O. When a package
  holds a juicy pure type and I/O code, move that type and the code it calls to its
  own leaf first (R4). A private function that only the I/O code calls stays.
  The actor that tried the tool writes each run that did not execute to the deferral
  ledger, also when it did a hand check instead, and reads the exit code. That actor is the testing skill, or the main agent
  when it runs the tool itself on `/{{.CmdPrefix}}-quickfix`. The call:

```bash
bash <this rule file's directory>/../scripts/ldd-ledger.sh add mutation-not-run <<'ROW'
<leaf> — <why the run did not execute>
ROW
```

