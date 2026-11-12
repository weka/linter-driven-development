# R4 — Helper Visibility & Placement

## Principle

Every extraction raises a second question: where does the helper live? Two axes
decide the answer. One is juiciness: the scorecard in `R1-primitive-obsession.md`
(cite it, never re-derive it). The other is scope: does a second package import it?
There are three rungs: underscore-prefixed in place, a sub-package nested under the
feature, and a shared domain package when a second package imports it. Never test
privates, and never export a helper into its parent package just so a test can reach
it. The ladder places helpers: code the feature would otherwise keep underscore-prefixed. A
type that is part of the feature package's public API stays in that package, whatever
its R1 score.
When a rung-2 helper builds that type, the helper's package can define it. The
feature package then re-exports it.

## Why

Wrong placement rots in both directions. Helpers exported into the parent package for
testability pollute its API — callers see symbols that exist only for tests, and the
package's real surface becomes unreadable. Juicy helpers buried as underscore-prefixed code
either go untested or push the team into testing privates, breaking the
public-API-only discipline (`R7-test-placement.md`). And role-named dumping grounds
(`util`, `helpers`, `common`) accrete unrelated code that nobody can find, name, or
own. Placement is what lets extraction deliver its promise: isolated, literal-input
unit tests against a legitimate public API.

## Canonical example

From the Port case (`R1-primitive-obsession.md` carries the full three-stage study).
After extraction, `Port`/`Ports`/`first_named`/`first` say nothing about Kubernetes
or Weka: juicy (range validation, collection queries), domain-generic, and imported
by a second feature → rung 3, a shared `networking` package. The feature keeps a
two-line storified policy method:

```python
def management_port(self) -> networking.Port | None:
    return self.ports.first_named(WEKA_API_PORT) or self.ports.first()
```

Only the domain-generic parts were promoted: the `WEKA_API_PORT` constant is feature
policy and stays in the feature. A shared package that knows one feature's port names
is not shared vocabulary — it is leaked policy.

The rung-1 contrast — a trivial helper that stays put:

```python
def _parse_k3s_argument(arg: str) -> tuple[str, str] | None:
    """One caller, no domain vocabulary, no rules of its own: stays private."""
    key, sep, value = arg.partition("=")
    return (key, value) if sep else None
```

Its R1 score is 0–3, so it stays at rung 1, and its tests go through the public API
that calls it. An urge to test it directly does not change that (the promotion
signal, below). The rungs in Python: rung 1 is a leading-underscore name
in the same module, covered through the module's public API; rung 2 is a sub-package
(a folder with `__init__.py`) nested in the feature package, with public names
(`alerts/vectorenv/__init__.py`); rung 3 is a top-level package under the project's
source root, named for a domain vocabulary, when a second package imports it.
There is no `internal/` convention — the underscore and `__all__` carry visibility.

## Design guidance

### The placement ladder

1. **Trivial helper** (R1 score 0–3) → underscore-prefixed, same package, tested only
   through the parent's public API.
2. **Juicy, and no second package imports it** → a sub-package (a folder with
   `__init__.py`) nested in the feature package, with public names. The feature
   needs no minimum size for it. See `R5-vertical-slice.md`.
3. **Juicy, and a second package imports it** → a top-level shared package. Extend
   the domain package that fits it, or create one.
   Granularity: a package is a domain *vocabulary* (`networking`), not a single noun
   (`kubeport`), never a role (`util`/`helpers`/`common`).

The rung paths in Python: rung 2 is a sub-package (a folder with `__init__.py`)
nested in the feature package, with public names (`alerts/vectorenv/__init__.py`).
Rung 3 is a top-level package under the source root, only when a second package
imports the helper. It is never a separate distributable package.

"Juicy" is an R1 score of 4 or more — `R1-primitive-obsession.md` is the scorecard's
only home.

### The promotion signal

**The urge to unit-test a helper directly is a signal to score the helper.** Never
act on that urge by testing privates, and never by exporting the helper into the
parent. The R1 score decides the home. With a score of 0–3, the helper stays
underscore-prefixed at rung 1, and its tests go through the parent's public API. With a
score of 4 or more, with or without the urge, the helper deserves its own package: a
real home where a test can call its exported API with literal inputs. Use rung 2 by
default, and rung 3 on the trigger the ladder gives.

### The reuse objection

"Nobody else uses it, so it can't justify a package." Wrong premise: reuse is not the
only justification for extraction — isolated testability and readability count on
their own. And the pollution worry it hides is solved by *placement*, not by inlining
the logic back: a helper in its own package pollutes nothing. Reuse decides only
between rung 2 and rung 3.

### Granularity

Name shared packages after a domain vocabulary with room for siblings: `networking`
can grow `Port`, `Ports`, addresses, CIDRs. A single-noun package (`kubeport`) is a
vocabulary of one — fold it into the vocabulary it belongs to. A role name (`util`,
`helpers`, `common`) describes no domain at all and is never acceptable. A rung-2
package nested under its feature can hold a single type.

## Fix pattern

- **Demote (rung 1)**: a helper exported from its parent only so tests can reach it →
  unexport it, delete the direct tests, cover it through the parent's public API.
- **Promote to feature sub-package (rung 2)**: a juicy helper that no second package
  imports, tested through awkward big-object setups → move it into a rung-2
  sub-package, export it there, test its public API directly.
- **Split the pure leaf out of an I/O package**: a juicy pure function or type sits in
  a package that does I/O (network, files, environment variables). Only tests through
  that I/O reach it. Move it to a rung-2 sub-package and export it there. Give
  it leaf unit tests (rung 0 of `R7-test-placement.md`) with 100% coverage and a
  mutation run. The I/O code stays in the parent and calls it. This applies also
  when the leaf is underscore-prefixed.
- **Promote to domain package (rung 3)**: a juicy helper that a second package
  imports → create or extend the shared domain package; move the generic types; leave feature policy home as a thin
  storified method (see Stage 2 of `R1-primitive-obsession.md`'s canonical example).
- **Split policy from vocabulary during promotion**: feature constants and preference
  logic stay in the feature; only the domain-generic types and queries move.
- **Move Method to the Envied Type** (Fowler: Feature Envy → Move Function): a
  function that reads another type's data more than its own belongs on that type —
  move it there, then place the enriched type on the ladder as usual. If the envied
  type is foreign (another module's DTO) or a built-in container (a map of strings
  the function keeps looking things up in), wrap it first
  (`R1-primitive-obsession.md`, Name the Container) and hang the behavior on the
  wrapper.
- **A message chain is a placement signal, not a wrapper order** (Fowler: Message
  Chains). Before "fixing" `order.Customer().Address().City()` by adding a
  `CustomerCity()` forwarder, ask what the caller *does* with the endpoint (Tell,
  Don't Ask — `../maxims.md`): a decision or computation → that behavior moves onto
  the chain's owner (Move Method to the Envied Type, above), where the chain
  collapses into a one-hop walk of the type's own composition — which was never the
  problem. Only data egress at a boundary (rendering, serialization, wire mapping)
  legitimately keeps the chain, and there it lives as a one-shot mapping inside the
  adapter, not scattered through domain code.
- **A type speaks for its parts only when it has something to add** (Fowler: Middle
  Man). A method whose entire body is `return o.x.Method()` — no decision, no
  combination, no invariant — is R1's ceremony verdict applied per method: the
  indirection owns nothing, so it goes. A type whose surface is mostly such forwards
  is a worse copy of its field's API — delete the forwards and hand callers the part
  (`o.Customer()`), keeping only delegations that carry a rule (`ShippingAddress()`
  choosing gift recipient over buyer earns its place; `CustomerEmail()` does not).
  The accelerant: embedding or inheriting a domain type manufactures this smell in
  one line by promoting the entire foreign API onto the outer type — embed or inherit
  for genuine is-a, never to save typing `o.customer.`.
- Multi-rule extraction sequencing: `../skills/refactoring/reference.md`. Forward
  design of the promoted package: @code-designing.

## Falsifying questions

Answer each with evidence (`file:line`, command output) — never a bare verdict.

1. **Is a symbol public only so tests can reach it?**
   Detect: judgment
   Detection: for each newly public function/class (no leading underscore, or newly
   listed in `__all__`),
   `grep -rn '<Symbol>' --include='*.py' . | grep -v 'test_\|_test.py\|conftest'` —
   count non-test references outside its defining module.
   Violation: zero production call sites outside its defining module while test
   files reference it — it was made public for tests; demote (rung 1) or promote
   (rung 2/3).

2. **Are `_private` helpers tested directly?**
   Detect-grep: `import _[a-z]|from [a-z_.]+ import .*\b_[a-z_]+|\._[a-z_]+\(` files=test
   Detection: an import of a `_private` name, or a call through `obj._helper(...)` in a test
   body. `monkeypatch.setattr(mod, "_helper", ...)` is the same reach with a
   different verb.
   Violation: any direct test of a private helper. The urge is a signal to score
   the helper on R1's scorecard. A score of 0–3 keeps it private: delete the direct
   test and cover the helper through the parent's public API (rung 1). A
   score of 4 or more gives the helper its own package: a sub-package of the feature
   (rung 2), or a top-level package (rung 3). The underscore is a convention, not a
   wall: the test runs, and that is why the question is asked.

3. **Does a new shared package have a role name?**
   Detect-path: `(^|/)(util|utils|helpers|helper|common|shared|misc)(\.py|/__init__\.py)$`
   Detection: any scope path that is a role-named module or package.
   Violation: any hit — `utils.py` and `common.py` are the Python spelling of the
   role-named package; modules are named for a domain vocabulary, never a role.

4. **Is a new shared package a single noun rather than a vocabulary?**
   Detect: judgment
   Detection: `grep -cE '^class [A-Z]' <package>/*.py` and ask whether plausible
   domain siblings exist under the name.
   Violation: a package named after its one type (`kubeport/`) with no room for
   siblings — fold into a vocabulary package (`networking/`) or keep at rung 1/2.
   A rung-2 sub-package nested under its feature is not judged by this question.

5. **Did feature policy leak into a shared package?**
   Detect: judgment
   Detection: grep the shared package for feature-owned literals and constants, e.g.
   `grep -rn '"weka-' <shared package>/`.
   Violation: any feature-specific literal or preference decision inside a
   domain-generic package — policy stays in the feature (Stage 2 of
   `R1-primitive-obsession.md`).

6. **Does a changed function envy another type's data?**
   Detect: judgment
   Detection: for each changed function/method, count attribute accesses per value:
   `grep -oE '\bself\.[a-zA-Z_]+' <func body> | sort | uniq -c` versus the same
   count for its most-touched parameter (`grep -oE '\b<param>\.[a-zA-Z_]+'`). A
   parameter that is a `dict`, `list` or `tuple` is accessed by `[`, `.get(`, `in`,
   `len(` and `for … in` rather than by attribute; count those the same way.
   Violation: accesses on one foreign value outnumber accesses on `self` (or on all
   local data, for a free function) and the foreign type is yours to extend — Move
   Method to the Envied Type, then re-place via the ladder. A function that merely
   *reads* a foreign DTO once to adapt it at a boundary is not envy.
