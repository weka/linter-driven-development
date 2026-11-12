### Before — feature scattered across layers

```
project/
├── domain/
│   └── rotator{{.SrcExt}}
├── services/
│   └── rotator_service{{.SrcExt}}
├── repository/
│   └── rotator_repository{{.SrcExt}}
└── handlers/
    └── rotator_handler{{.SrcExt}}
```

Changing rotation policy touches four directories; the `services` package's API is
the union of every feature's service; `domain` and `services` are role names that
describe no domain at all.

### After — one slice, roles inside

```
project/
└── rotator/
    ├── rotator{{.SrcExt}}       # domain type
    ├── parser{{.SrcExt}}        # role: parsing
    ├── handler{{.SrcExt}}       # role: HTTP
    ├── repository{{.SrcExt}}    # role: persistence
    └── rotator{{.TestGlob}}
```

The whole feature is one `ls`. Each type of the feature's API with logic sits in its own
file named after the type, and a juicy helper goes to rung 2 of
`R4-helper-placement.md`; the package name is the feature's domain word, and file names carry the
roles. The directory is a package, module or namespace — whatever the language calls
one unit of code with its own public surface.
