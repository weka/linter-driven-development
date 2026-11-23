1. **Verify Go project**: `go.mod` in root or parent directories.
2. **Discover commands** (README.md, CLAUDE.md, Makefile, Taskfile.yaml, in that
   order): test + lint commands, and the mutation target when one exists (`mutate`,
   `gremlins`). Fallbacks: `go test ./...`, `golangci-lint run --fix`; none for
   mutation — a missing tool gets the hand check and a ledger row that names
   `/{{.CmdPrefix}}-setup` (`../../rules/R7-test-placement.md`, Mutation mechanics).
