```go
// ❌ exported from the feature package only so the test can reach it
func ParseK3sArgument(arg string) (key, value string, ok bool)

// ✅ rung 1: one caller, no vocabulary of its own; unexported where it is used,
//    tested through the public API that calls it
func parseK3sArgument(arg string) (key, value string, ok bool)

// ✅ rung 3: generic networking vocabulary with three callers → its own package
package networking
func ParsePrefixes(raw string) (Prefixes, error)
```

> **In Go:** the `"weka-api"` port name is feature policy and stays in the feature;
> `Port`, `Ports` and `FirstNamed` are networking vocabulary and move to
> `internal/pkg/networking`. A shared package that knows one feature's constants is
> leaked policy, not shared vocabulary.
