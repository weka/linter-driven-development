Package Structure:
[feature]/
  ├── [type].go        # each juicy type of the feature's API in its own file
  ├── [helper]/        # a juicy helper the feature keeps unexported: a nested package (R4 rung 2)
  │   └── [helper].go
  ├── service.go
  └── handler.go
