- **Promote to feature sub-package (rung 2)**: a juicy helper type that no second package
  imports, with or without a test above it → move it into a rung-2 package or
  module, export it there, test its public API directly.
- **Split the pure leaf out of an I/O package**: a juicy pure private type sits in
  a package that does I/O (network, files, environment variables). Only tests through
  that I/O reach it. Move it to a rung-2 package or module and export it there. Give
  it leaf unit tests (rung 0 of `R7-test-placement.md`) with 100% coverage and a
  mutation run. Move only that type and the code it calls. A private function that
  only the I/O code calls is not part of the leaf: it stays private in the parent.
  The I/O code stays in the parent and calls the leaf. This applies also
  when the leaf is {{.Unexported}}.
