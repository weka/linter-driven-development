**MANDATORY** after creating new types or extracting functions, hooks or components:
1. List what was created — types, functions, hooks and components alike: `grep -rnE "^export (default )?(async )?(interface|type|class|enum|function|const|let)[[:space:]]+\w+" --include='*.ts' --include='*.tsx' --exclude-dir=node_modules .`
2. Missing tests for any of them → STOP and invoke @testing. Before a move,
   characterization tests through the public API (`renderWithProviders` + MSW,
   never a `vi.mock` of the module being moved); `npx vitest run <dir>` after each step.
3. Coverage: `npx vitest run --coverage` (or the repository's coverage command) — leaf
   types must show 100% (R7). I/O types must show 100% in the run that includes their
   integration tests, except a branch that no real fake can reach and that has a
   comment that says why.
