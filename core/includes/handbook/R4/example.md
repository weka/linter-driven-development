```text
# ❌ made public by the feature package only so the test can reach it
public parseK3sArgument(arg)       # one caller, in this package

# ✅ rung 1: one caller, no vocabulary of its own; hidden where it is used,
#    tested through the public API that calls it
parseK3sArgument(arg)              # private to the feature

# ✅ rung 3: networking vocabulary with three callers → its own package, named for the domain
public networking.parsePrefixes(raw)  # with the Prefixes type beside it
```

> **Spelling:** rung 1 is the language's private form: a lower-case or underscored
> name, a symbol the module does not export, a file-local declaration. Rung 2 is a
> sub-package, sub-module or namespace under the feature, with public names that the
> feature's public surface does not expose; rung 3 a
> shared package under the source root, when a second package imports it. A test that
> has to reach a private name, through a friend module, a reflection helper or a
> test-only export, is a placement signal, never a reason to add the seam. The
> `"weka-api"` port name is feature policy and stays in the feature; `Port`, `Ports`
> and `firstNamed` are networking vocabulary and move.
