- **Promote to feature sub-package (rung 2)**: a juicy helper that no second package
  imports, tested through awkward big-object setups → move it into a rung-2 package or
  module, export it there, test its public API directly.
- **Split the pure leaf out of an I/O package**: a juicy pure function or type sits in
  a package that does I/O (network, files, environment variables). Only tests through
  that I/O reach it. Move it to a rung-2 package or module and export it there. Give
  it leaf unit tests (rung 0 of `R7-test-placement.md`) with 100% coverage and a
  mutation run. The I/O code stays in the parent and calls it. This applies also
  when the leaf is {{.Unexported}}.
  A leaf that builds and returns an API type is that type's constructor. Do not move it.
  Make it public beside the type. Give it the same tests and the same mutation run.
