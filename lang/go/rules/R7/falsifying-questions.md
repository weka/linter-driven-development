1. **Does any `t.Run` body contain a conditional?**
   Detect-grep: `\bwantErr\b|^\s*(} else )?if (tt|tc|c|tst|test)\.|^\s*switch (tt|tc|c|test)\.` files=test
   Detection: a `wantErr` field, or a conditional on the table case inside a `t.Run`
   body.
   Violation: any conditional inside a case, or a `wantErr bool` field — success and
   error cases are fused; split the functions.

2. **Is any test in the internal package?**
   Detect-grep: `^package [a-z][a-z0-9]*$` files=test
   Detection: a test file's `package` line without the `_test` suffix.
   Violation: a test package without the `_test` suffix — it can reach privates;
   move to `pkg_test` and test the public API.

3. **Does a test construct a big object to exercise a leaf behavior?**
   Detect: judgment
   Detection: read each new/changed test — compare the setup (fixtures, services,
   servers) against the assertion's subject; count setup lines vs. the one predicate
   actually checked.
   Violation: heavyweight construction whose assertions target logic a leaf type
   owns (or should own) — move the test down a rung, extracting the leaf if needed.

4. **Does a new behavior's test sit above the lowest rung that contains it?**
   Detect: judgment
   Detection: for each new public method on a leaf type,
   `grep -rn '<Method>' --include='*_test.go' .` — is it exercised directly, or only
   through an orchestrator's test? Then list the new or changed unexported functions,
   methods and types: `grep -nE '^func (\([^)]*\) )?[a-z]|^type [a-z]'` in the changed
   files. Score each one with R1's scorecard. Read the scorecard in the same Bash call
   as the grep: `sed -n '/^### Juiciness scoring/,/^### The over-abstraction trap/p'` over
   `R1-primitive-obsession.md` in this rule file's directory. Do not judge or report
   a helper with a score of 3 or less. An in-package test that calls it is a Q2
   finding, not a direct test.
   Violation: leaf behavior with no direct test, reached only from above. This
   applies to a public method of a leaf type and to an unexported function, method or
   type with a score of 4 or more. The usual test above it builds a server, files or
   a database. Fix a public method: add the rung-0 test; the orchestrator test keeps
   only the seam. Fix an unexported leaf in a package that does I/O with R4's "Split
   the pure leaf out of an I/O package". Fix one in a package with no I/O with
   "Promote to feature sub-package (rung 2)". Then add the rung-0 test.

5. **Does a test assert on a fake's internals rather than observable behavior?**
   Detect-grep: `AssertExpectations|AssertCalled|\.calls\b` files=test
   Detection: also flag assertions reading fields of a test double instead of querying the
   system under test.
   Violation: the test verifies the double — assert on real state via the public API
   (and the double itself is likely an R6 finding).

6. **Does any test sleep to synchronize?**
   Detect-grep: `time\.Sleep` files=test
   Violation: any hit — replace with channels/wait groups.

7. **Does a mutant survive a leaf type's tests?**
   Detect-grep: `(<=?|>=?) *('.'|-?[0-9]+|[a-zA-Z_.]*[Ll]en\b)|\b[Ll]en\([^)]*\) *(<=?|>=?|==|!=)` exclude-path=(^|/)cmd/,(^|/)main\.go$,(^|/)handlers/
   Detection: for each new or changed leaf package,
   `gremlins unleash ./path/to/leaf | grep -E '^[[:space:]]*(LIVED|NOT COVERED|TIMED OUT)|Killed:|Not covered:|Timed out:'`;
   skip orchestrators, the top rung and any package that does I/O. Judge a pure leaf
   inside such a package with Q4. Do not skip it. `gremlins` not on `PATH`: propose
   the install the mechanics bullet describes before hunting; an empty `LIVED` list from
   a run that did not execute, or whose mutants all timed out, is not a pass. A
   `NOT COVERED` mutant is a finding, the same as a `LIVED` one: a missing test row.
   The run did not execute only when there is no summary line, or when every count
   (`Killed:`, `Lived:`, `Timed out:`, `Not covered:`) is 0. In a
   read-only review, where no tests may run, take the hand check instead: list the
   leaf's comparisons and boolean conditions, check the table for a row at each
   boundary value and on each side of each condition, and name the row that is
   missing.
   When the tool run did not execute for a leaf, the receipt says so on its own line:
   `R7 Q7: mutation run did not execute — <leaf>`. A hand check alone runs no tool
   and writes no such line.
   On a whole-repository review this question is not judged: a mutation run or a
   hand check over every leaf does not fit a hunter's budget. The receipt reads
   `R7 Q7: <hits> hit(s) → per-leaf, not judged`, R7's tally takes the partial form,
   and the `not reached:` line names the three leaf directories with the most hits,
   each as the review that judges it: `R7 Q7: /{{.CmdPrefix}}-review <dir>`. On a
   scoped review the question is judged in full.
   Violation: any `LIVED` or `NOT COVERED` line on a leaf package that is not
   recorded as an equivalent mutant — a missing table row or dead logic; name the mutant (file,
   line, mutation) and the row that would kill it.
