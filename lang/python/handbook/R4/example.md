```python
# ❌ imported by the test through its private name, so it stays where it should not
from app.k3s._args import _parse_k3s_argument

# ✅ rung 1: one caller, no vocabulary of its own;
#    covered through the public API that calls it
def _parse_k3s_argument(arg: str) -> tuple[str, str] | None: ...

# ✅ rung 3: networking vocabulary with several callers → its own package,
#    named for the domain
from app.networking import Port, Ports
```

> **In Python:** the leading underscore is a convention, not a wall, so a test *can*
> import `_parse_row`. That it can is not a reason it should: the urge is a placement
> signal. With an R1 score of 0–3 the helper stays private and the test goes through
> the public API; with 4 or more it wants its own sub-package with public names. Rung
> 2 is a sub-package (a folder with `__init__.py`) nested in the feature package
> (`alerts/vectorenv/__init__.py`); rung 3 a top-level package under the source
> root, when a second package imports it. There is no `internal/`; the underscore
> and `__all__` carry visibility.
