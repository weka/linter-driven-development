Testing is complete when ALL of the following are true:

- [ ] All unit tests in pkg_test package testing public API only
- [ ] Table-driven tests use named struct fields
- [ ] No wantErr bool - success and error cases in separate test functions
- [ ] Cyclomatic complexity = 1 inside t.Run() (no if/else, no switch)
- [ ] Leaf types have 100% coverage
- [ ] I/O types have 100% coverage, each handled error path included; a branch that no real fake can reach has a comment that says why
- [ ] Integration tests cover component seams
- [ ] System tests in tests/ folder with appropriate dependency level
- [ ] No time.Sleep (using channels/waitgroups)
- [ ] Tests pass and linter approves
