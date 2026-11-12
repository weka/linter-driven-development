2. **Juicy, and no second package imports it** → a package nested under the feature
   package, with exported names. A file of the feature package is not enough: each
   exported name in it is part of the feature's API. The feature needs no minimum
   size for it. See `R5-vertical-slice.md`.
   The constructor of an API type is not a helper and does not move.
