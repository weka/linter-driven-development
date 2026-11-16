**The refinement (mandatory):** a refutation is never a bare "no". Name the need the
proposal was groping toward, then meet it more cheaply — better naming when the need
is clarity; private fields + accessors when the real need is controlled mutation
rather than validation or logic; a telling variable name when the proposal wraps a
flat container of primitives that lives inside one function and crosses no boundary
(R1, "Containers of primitives", tier 1). A nested container never takes that
alternative: the inner shape is a type with no name, and a variable name cannot
name it. A test-only door to a private name is never the cheaper alternative. A door
is an export, alias, re-export or hook that exists only so a test can reach a private
name. For a private leaf with R1 score 0–3, the cheaper alternative is a test through
the public entry of its parent. At a score of 4 or more, the leaf gets its own
sub-package folder, with `__init__.py`, under the feature. Tests call its exported API
directly. The case file you read is the template for what a correct refutation looks
like.
