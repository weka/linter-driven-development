- **Promote to feature sub-package (rung 2)**: a juicy helper type that no second package
  imports, with or without a test above it → move it into a nested rung-2
  package, export it there, test its exported API directly.
- **Split the pure leaf out of an I/O package**: a juicy pure private type sits in
  a package that does I/O (network, files, environment variables). Only tests through
  that I/O reach it. Move it to a nested rung-2 package and export it there. Give
  it leaf unit tests (rung 0 of `R7-test-placement.md`) with 100% coverage and a
  mutation run. The I/O code stays in the parent and calls it. This applies also
  when the leaf is unexported.
