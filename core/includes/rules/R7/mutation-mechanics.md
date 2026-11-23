- **Mutation mechanics**: the repository's mutation testing tool, configured once
  and pointed at leaf packages only; run it after the leaf's tests are green and
  after each fix that kills a survivor; a threshold in CI, where the repository has
  one, is set per leaf package, never module-wide. The tool is installed the way the
  repository installs its other tools: a target in the task runner the repository
  already has (Taskfile, Makefile) installs a pinned version and runs it over one
  leaf package; where there is no task runner, the developer runs the local install
  command. `/{{.CmdPrefix}}-setup` recommends this install. When the tool is not installed at the time of a check, do not install it and do
  not propose it: do the hand check, and write the `mutation-not-run` row with the
  cause `not installed; run /{{.CmdPrefix}}-setup`.
  Never read a run that did not execute as a pass.
  When the language has no maintained mutation tool, or the tool is not installed,
  the check is done by hand and stays cheap because a
  leaf is small: for every comparison in the leaf the table holds a row at the
  boundary value and one just past it, for every boolean condition a row on each
  side, and a suspected gap is confirmed by flipping the operator, running the
  leaf's tests, and putting it back — green tests mean a survivor.
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

