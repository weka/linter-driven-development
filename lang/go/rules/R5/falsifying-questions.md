1. **Is any package or module named after a layer or role?**
   Detect-path: `(^|/)(util[^/]*|helpers|common|shared|misc|domain|services|handlers|models|repositories)/`
   Detection: any scope path under a layer- or role-named directory; a Go package is
   named after its directory, so the `package` line says the same.
   Violation: any hit — the package describes a role, not a domain.

2. **Is one feature's code spread across ≥2 layer directories?**
   Detect: judgment
   Detection: for each feature noun in the diff,
   `grep -rln '<feature>' --include='*.go' . | xargs -n1 dirname | sort -u` — count
   distinct layer-named directories.
   Violation: the same feature living in `handlers/` and `services/` (etc.) — it is
   horizontally scattered.

3. **Does the diff add a new file into a layer directory instead of a slice?**
   Detect: judgment
   Detection: the diff's added files (`new file mode` in the patch) — check each new
   path's directory against the layer names above.
   Violation: new feature code placed in a layer directory — new code is always
   sliced, even mid-migration.

4. **Do both shapes coexist for one feature?**
   Detect: judgment
   Detection: `ls <feature>/ services/ handlers/ 2>/dev/null | grep -i <feature>`
   Violation: `<feature>/service.go` alongside `services/<feature>_service.go` —
   the never-mix rule; finish the feature's migration in this change or don't start
   it.

5. **Is a mixed-architecture repo missing its migration plan?**
   Detect: judgment
   Detection: layer directories exist alongside slices, and
   `ls docs/architecture/vertical-slice-migration.md` fails.
   Violation: mixed state with no documented strategy/progress — add the template
   above.

6. **Is any file over the file-length limit?**
   Detect-script: ldd-lint file-length --measure-held
   Detection: the gap linter counts the lines of each Go file in the scope. The
   limit is revive's `file-length-limit` where the repository sets it, else
   {{.FileMaxLines}} code lines. Where the repository's linter holds the rule, the row is measured
   against that rule's limit and names the rule. The linter stays the enforcer.
   Violation: a file over the limit standing in for the whole slice, or a `//nolint`
   silencing the limit (the suppression row carries directives) — split the feature's
   API types by role (file-per-type) inside the package. Move a juicy helper to a
   nested package (rung 2 of `R4-helper-placement.md`).

7. **Is any package over the file-count limit?**
   Detect-script: ldd-lint package-size --over-limit
   Detection: the gap linter counts the Go files of each directory in the scope,
   leaving out test and generated files. The limit is `package_max_files` in
   `.ldd-lint.yaml`, else {{.PackageMaxFiles}} files.
   Violation: a directory at or over the limit — decompose it into sub-packages with
   the refactoring skill's package-decomposition procedure. The warning zone is not a
   review finding.
