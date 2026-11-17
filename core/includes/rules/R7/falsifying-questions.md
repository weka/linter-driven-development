Test files are the ones the repository's test runner picks up (`*{{.TestGlob}}`, a
`tests/` directory, or whatever the repository uses); build each search over them.

1. **Does any test case body contain a conditional?**
   Detect-grep: `\b[Ww]ant_?[Ee]rr(or)?\b|\b[Ee]xpect_?[Ee]rr(or)?\b|\b[Ss]hould_?[Ff]ail\b` files=test
   Detection: search the test files for `if`/`switch`/`match` inside a test function
   or a parametrized case, and for a success-or-error flag in a case table
   (`expectError`, `shouldFail`, `raises` as a boolean column).
   Violation: any conditional inside a case, or a boolean expect-error field —
   success and error cases are fused; split the functions.

2. **Does any test reach past the public surface?**
   Detect: judgment
   Detection: find test files that import or declare themselves inside the package
   under test rather than importing it as a consumer would (an in-package test, an
   import of a private module or an {{.Unexported}} name).
   Violation: a test that can reach privates — move it to the consumer's side and
   test the public API.

3. **Does a test construct a big object to exercise a leaf behavior?**
   Detect: judgment
   Detection: read each new/changed test — compare the setup (fixtures, services,
   servers) against the assertion's subject; count setup lines vs. the one predicate
   actually checked.
   Violation: heavyweight construction whose assertions target logic a leaf type
   owns (or should own) — move the test down a rung, extracting the leaf if needed. When the leaf is a
   private type, it is Q4's finding: the fix moves the type to its own package (R4),
   not only the test. A private function that the moved type does not
   call stays where it is, pure or not: the test above covers it.

4. **Does a private leaf or a new public behavior have no direct test?**
   Detect: judgment
   Detection: for each new public method on a leaf type, search the test files for
   its name — is it exercised directly, or only through an orchestrator's test?
   Then search the changed source for {{.Unexported}} types. Score each one with R1's scorecard. Read the scorecard in the same Bash call
   as the search: `sed -n '/^### Juiciness scoring/,/^### The over-abstraction trap/p'` over
   `R1-primitive-obsession.md` in this rule file's directory. Do not judge or report
   a helper with a score of 3 or less. A test that calls an {{.Unexported}} name is a
   Q2 finding, not a direct test. Old {{.Unexported}} types in a touched file are in
   scope. A private function is not a finding: it is fine where it is.
   Violation: leaf behavior with no direct test, in any package or module. This
   applies to a public method of a leaf type and to an {{.Unexported}} type
   with a score of 4 or more. The usual test above it builds a server, files, a
   database or a rendered tree. Fix a public method: add the rung-0 test; the
   orchestrator test keeps only the seam. Fix an {{.Unexported}} leaf in a package that
   does I/O with R4's "Split the pure leaf out of an I/O package". Fix one in a package
   with no I/O with "Promote to feature sub-package (rung 2)". Move only the type and
   the code that it calls. Name the type alone in the finding. A private function that
   only the I/O code calls stays private in the parent. Then add the rung-0 test.

5. **Does a test assert on a fake's internals rather than observable behavior?**
   Detect-grep: `[Aa]ssert(_?[Cc]alled|_?[Ee]xpectations|_?[Aa]ny_?[Cc]all|_?[Hh]as_?[Cc]alls)|\.call_count|\.mock_calls|\.calls\b` files=test
   Detection: search the test files for the mocking library's verification calls
   (`assertExpectations`, `assertCalled`, `assert_called_with`, `.calls`); also flag
   assertions reading fields of a test double instead of querying the system under
   test.
   Violation: the test verifies the double — assert on real state via the public API
   (and the double itself is likely an R6 finding).

6. **Does any test sleep to synchronize?**
   Detect-grep: `\b[Ss]leep\(` files=test
   Detection: search the test files for the language's sleep call (`time.Sleep`,
   `time.sleep`, `setTimeout`, `Thread.sleep`).
   Violation: any hit — replace with an event, channel or wait primitive with a
   timeout.

7. **Does a mutant survive a leaf type's tests?**
   Detect-grep: `(<=?|>=?) *('.'|-?[0-9]+)|\b[Ll]en\([^)]*\) *(<=?|>=?|==|!=)`
   Detection: for each new or changed leaf type, run the repository's mutation
   testing tool over that leaf's package only (the mechanics bullet names the tool
   and the command) and read its list of survivors; skip orchestrators, the top
   rung and any package that does I/O. Judge a private type inside such a package
   with Q4. Do not skip it. A private function there gets no run and no finding. Code that does I/O gets no
   mutation run, no `did not execute` line and no finding. A tool the language has but the machine
   lacks is proposed for install as the mechanics bullet says, never skipped and
   never counted as a pass. Without any tool, list the leaf's comparisons
   and boolean conditions, check the table for a row at each boundary value and on
   each side of each condition, and hand-flip any operator whose rows are missing
   (`<` to `<=`, `>` to `>=`, a condition negated), run the leaf's tests, revert.
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
   Violation: any survivor on a leaf type that is not recorded as equivalent — a
   missing table row or dead logic; name the mutant (file, line, operator) and the
   row that would kill it.
