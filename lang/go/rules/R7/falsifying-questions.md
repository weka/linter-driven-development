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
   owns (or should own) — move the test down a rung, extracting the leaf if needed. When the leaf is a
   private type, it is Q4's finding: the fix moves the type to its own package (R4),
   not only the test.

4. **Does a private leaf or a new public behavior have no direct test?**
   Detect-grep: `^type [a-z]`
   Detection: the hits are the unexported types of the
   scope's non-test files.
   Score each hit with R1's scorecard. Read the scorecard in the same Bash call as
   the hits: `sed -n '/^### Juiciness scoring/,/^### The over-abstraction trap/p'`
   over `R1-primitive-obsession.md` in this rule file's directory. A hit with a score
   of 3 or less is not a finding. Old unexported types in a touched file are in scope. A private
   function is not a hit: it is fine where it is.
   An in-package test that calls a hit is a Q2 finding, not a direct test.
   For each new public method on a leaf type, run
   `grep -rn '<Method>' --include='*_test.go' .` and look for a direct test.
   When the budget ends before every hit is scored, use the partial receipt:
   `R7 Q4: <judged> of <hits> hit(s) judged → <findings> finding(s)`. The
   `not reached:` line then names the three directories with the most hits that
   were not scored, each as `R7 Q4: /{{.CmdPrefix}}-review <dir>`.
   Violation: a new public method of a leaf type with no direct test. Also, an unexported type with a score of 4 or
   more and no direct test. This applies in any package. A test above it does not
   count. The usual test above it builds a server, files or a database.
   Fix a public method: add the rung-0 test. The orchestrator test keeps only the seam.
   Fix an unexported leaf in a package that does I/O: use R4's "Split the pure leaf out of an
   I/O package". Fix one in any other package: use "Promote to feature sub-package
   (rung 2)". Then add the rung-0 test.

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
   inside such a package with Q4. Do not skip it. Code that does I/O gets no
   mutation run, no `did not execute` line and no finding. `gremlins` not on `PATH`: propose
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
   `R7 Q7: mutation run did not execute — <leaf>`. A hand check does not replace the tool: when the
   language has a mutation tool and it did not run, the line and the
   `mutation-not-run` ledger row are written, also after a hand check. Only a language
   with no mutation tool takes the hand check alone, with no such line.
   On a whole-repository review this question is not judged: a mutation run or a
   hand check over every leaf does not fit a hunter's budget. The receipt reads
   `R7 Q7: <hits> hit(s) → per-leaf, not judged`, R7's tally takes the partial form,
   and the `not reached:` line names the three leaf directories with the most hits,
   each as the review that judges it: `R7 Q7: /{{.CmdPrefix}}-review <dir>`. On a
   scoped review the question is judged in full.
   Violation: any `LIVED` or `NOT COVERED` line on a leaf package that is not
   recorded as an equivalent mutant — a missing table row or dead logic; name the mutant (file,
   line, mutation) and the row that would kill it.
