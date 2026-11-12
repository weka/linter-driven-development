Package Structure:
[feature]/
  ├── [type]{{.SrcExt}}      # each juicy type of the feature's API in its own file
  ├── [helper]/       # a juicy helper the feature keeps out of its API (R4 rung 2)
  ├── service{{.SrcExt}}
  └── handler{{.SrcExt}}