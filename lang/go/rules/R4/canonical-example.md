From the Port case (`R1-primitive-obsession.md` carries the full three-stage study).
After extraction, `Port`/`Ports`/`FirstNamed`/`First` say nothing about Kubernetes or
Weka: juicy (range validation, collection queries), domain-generic, and imported by a
second feature → rung 3, `internal/pkg/networking`. The feature keeps a four-line
storified policy method:

```go
func (s kubeService) managementPort() (networking.Port, bool) {
    if p, ok := s.ports.FirstNamed(kubeWekaAPIPort); ok { return p, true }
    return s.ports.First()
}
```

Only the domain-generic parts were promoted: the `"weka-api"` constant is feature
policy and stays in the feature. A shared package that knows one feature's port names
is not shared vocabulary — it is leaked policy.

The rung-1 contrast — a trivial helper that stays put:

```go
// Trivial: one caller, no domain vocabulary, no rules of its own.
// Stays unexported; covered through the parent's public API.
func parseK3SArgument(arg string) (key, value string, ok bool) {
    parts := strings.SplitN(arg, "=", 2)
    if len(parts) != 2 {
        return "", "", false
    }
    return parts[0], parts[1], true
}
```

Its R1 score is 0–3, so it stays at rung 1, and its tests go through the public API
that calls it. An urge to test it directly does not change that (the promotion
signal, below).
