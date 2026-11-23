**MANDATORY** after creating new types or extracting functions:
1. List created types: `grep -RnE "^type[[:space:]]+\w+" --include="*.go" .`
2. Missing tests for any of them → STOP and invoke @testing.
3. Coverage: `go test -cover ./...` — leaf types must show 100% (R7). I/O types must
   show 100% in the run that includes their integration tests.
