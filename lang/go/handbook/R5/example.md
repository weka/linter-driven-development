```text
❌ by layer                      ✅ by feature, roles inside
internal/domain/rotator.go       internal/rotator/rotator.go
internal/services/rotator.go     internal/rotator/parser.go
internal/handlers/rotator.go     internal/rotator/handler.go
internal/models/rotation.go      internal/rotator/rotation.go
```

> **In Go:** role names live in file names inside the slice, and a type of the
> feature's API with logic gets its own file named after the type. A juicy helper
> that the feature keeps unexported goes to a nested package (R4). Slices live under `internal/` unless
> another module is meant to import them.
