Package Structure:
[feature]/
  ├── __init__.py      # the public surface: what a consumer imports
  ├── [type].py        # each of the feature's API types in its own module
  ├── [helper]/        # a juicy helper that no second package imports: a sub-package (R4 rung 2)
  │   └── __init__.py
  ├── service.py
  └── handler.py
