1. **Is any package or module named after a layer or role?**
   Detect-path: `(^|/)(util[^/]*|helpers|common|shared|misc|domain|services|handlers|models|repositories)/|(^|/)(utils|helpers|common|models|services|handlers)\.py$`
   Detection: any scope path under a layer- or role-named directory, or a module of
   that name. Python has no `package` line; a layer package announces itself in the
   docstring of its `__init__.py`, so read those too.
   Violation: any hit — the package describes a role, not a domain.

2. **Is one feature's code spread across ≥2 layer directories?**
   Detect: judgment
   Detection: for each feature noun in the diff,
   `grep -rli '<feature>' --include='*.py' . | xargs -n1 dirname | sort -u` — count
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
   Violation: `<feature>/service.py` alongside `services/<feature>_service.py` —
   the never-mix rule; finish the feature's migration in this change or don't start
   it.

5. **Is a mixed-architecture repo missing its migration plan?**
   Detect: judgment
   Detection: layer directories exist alongside slices, and
   `ls docs/architecture/vertical-slice-migration.md` fails.
   Violation: mixed state with no documented strategy/progress — add the template
   above.

6. **Is any module over the file-length limit?**
   Detect-script: ldd-lint file-length
   Detection: the gap linter counts the code lines of each Python module in the
   scope. ruff has no file-length rule: the limit is pylint's `max-module-lines`
   where the repository sets it, else {{.FileMaxLines}} code lines. When the
   repository's linter holds the rule, the row count is 0 and the `ldd-lint:` line
   names the rule: the linter's own report is the lead, and the limit is its to
   enforce.
   Violation: a module over the limit standing in for the whole slice, or a
   `# pylint: disable=too-many-lines` silencing the limit (the suppression row
   carries directives) — split it by role inside the package.

7. **Is any package over the file-count limit?**
   Detect-script: ldd-lint package-size --over-limit
   Detection: the gap linter counts the Python modules of each directory in the
   scope, leaving out test and generated files and `__init__.py`. The limit is
   `package_max_files` in `.ldd-lint.yaml`, else {{.PackageMaxFiles}} files.
   Violation: a directory at or over the limit — decompose it into sub-packages with
   the refactoring skill's package-decomposition procedure. The warning zone is not a
   review finding.
