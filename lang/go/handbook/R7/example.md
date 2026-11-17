```go
// ❌ one table, a flag, and a branch inside t.Run
func TestParsePort(t *testing.T) {
    tests := []struct {
        name    string
        in      int32
        wantErr bool
    }{ /* ... */ }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := networking.ParsePort("x", tt.in)
            if tt.wantErr {
                require.Error(t, err)
            } else {
                require.NoError(t, err)
            }
        })
    }
}

// ✅ success and error tables apart, named fields, complexity 1 per case
func TestParsePort_Success(t *testing.T) { /* rows that parse */ }

func TestParsePort_Error(t *testing.T) {
    tests := []struct {
        name string
        in   int32
    }{
        {name: "zero", in: 0},
        {name: "above range", in: 70000},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := networking.ParsePort("x", tt.in)
            require.Error(t, err)
        })
    }
}
```

> **In Go:** every table row uses named struct fields, because the linter reorders
> fields. No `time.Sleep`: synchronize on a channel or a `sync.WaitGroup`.
> Orchestrators are tested by wiring their real collaborators over `httptest`, an
> embedded database or a temp directory. Leaf packages, and only they, also run
> under `gremlins unleash --timeout-coefficient 50`: a `LIVED` mutant is a missing row
> or dead logic. After a `TIMED OUT` mutant, run the leaf again with
> `--timeout-coefficient 100`. A mutant that times out in both runs counts as killed
> only in the condition or the post statement of a `for` header, where it makes the
> loop run with no end. Anywhere else it is unresolved.
