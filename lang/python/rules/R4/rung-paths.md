The rung paths in Python: rung 2 is a sub-package (a folder with `__init__.py`)
nested in the feature package, with public names (`alerts/vectorenv/__init__.py`).
Rung 3 is a top-level package under the source root, only when a second package
imports the helper. It is never a separate distributable package.
