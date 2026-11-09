# R4 — Helper Visibility & Placement

## Principle

Every extraction raises a second question: where does the helper live? Two axes
decide the answer. One is juiciness: the scorecard in `R1-primitive-obsession.md`
(cite it, never re-derive it). The other is scope: does a second package import it?
There are three rungs: internal in place, a sub-package nested under the
feature, and a shared domain package when a second package imports it. Never test
privates, and never export a helper into its parent package just so a test can reach
it.

## Why

Wrong placement rots in both directions. Helpers exported into the parent package for
testability pollute its API — callers see symbols that exist only for tests, and the
package's real surface becomes unreadable. Juicy helpers buried as internal code
either go untested or push the team into testing privates, breaking the
public-API-only discipline (`R7-test-placement.md`). And role-named dumping grounds
(`util`, `helpers`, `common`) accrete unrelated code that nobody can find, name, or
own. Placement is what lets extraction deliver its promise: isolated, literal-input
unit tests against a legitimate public API.

## Canonical example

From the Port case (`R1-primitive-obsession.md` carries the full three-stage study).
After extraction, `Port`/`Ports`/`firstNamed`/`first` say nothing about Kubernetes or
Weka: juicy (range validation, collection queries), domain-generic, and imported by a
second feature → rung 3, a shared `networking` package. The feature keeps a two-line
storified policy method:

```text
kubeService.managementPort():
    return self.ports.firstNamed(managementPortName) or self.ports.first()
```

Only the domain-generic parts were promoted: the `"weka-api"` constant is feature
policy and stays in the feature. A shared package that knows one feature's port names
is not shared vocabulary — it is leaked policy.

The rung-1 contrast — a trivial helper that stays put:

```text
# Trivial: one caller, no domain vocabulary, no rules of its own.
# Stays internal; covered through the parent's public API.
parseArgument(arg):
    key, sep, value = arg.partition("=")
    if sep is empty: return absent
    return (key, value)
```

There is no urge to test this directly — and that absence is the point: the promotion
signal (below) never fires.

## Design guidance

### The placement ladder

1. **Trivial helper** (R1 score 0–3) → internal, same package, tested only
   through the parent's public API.
2. **Juicy, and no second package imports it** → a package nested under the feature
   package, or a module with public names inside the feature package. The feature
   needs no minimum size for it. See `R5-vertical-slice.md`.
3. **Juicy, and a second package imports it** → a top-level shared package. Extend
   the domain package that fits it, or create one.
   Granularity: a package is a domain *vocabulary* (`networking`), not a single noun
   (`kubeport`), never a role (`util`/`helpers`/`common`).

The rung paths: rung 2 is a sub-package, sub-module or namespace under the feature,
with public names. Rung 3 is a shared package under the source root.

"Juicy" is an R1 score of 4 or more — `R1-primitive-obsession.md` is the scorecard's
only home.

### The promotion signal

**The urge to unit-test a helper directly means it deserves its own package.** Never
act on that urge by testing privates, and never by exporting the helper into the
parent. The urge is data: it says that the helper has enough behavior to be a unit
of its own. Give it a real home where a test can call its exported API with literal
inputs. Use rung 2 by default, and rung 3 on the trigger the ladder gives. An R1 score
of 4 or more is the same signal, with or without the urge.

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
  imports, tested through awkward big-object setups → move it into a rung-2 package or
  module, export it there, test its public API directly.
- **Split the pure leaf out of an I/O package**: a juicy pure function or type sits in
  a package that does I/O (network, files, environment variables). Only tests through
  that I/O reach it. Move it to a rung-2 package or module and export it there. Give
  it leaf unit tests (rung 0 of `R7-test-placement.md`) with 100% coverage and a
  mutation run. The I/O code stays in the parent and calls it. This applies also
  when the leaf is internal.
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

Build each search over the language's source files (`detected-language source`); "test files"
means the files the repository's test runner picks up (`*<test-file suffix>`, a `tests/`
directory, or whatever the repository uses).

1. **Is a symbol public only so tests can reach it?**
   Detect: judgment
   Detection: for each newly public function/type, search the non-test source files
   for references outside its defining file — count them.
   Violation: zero production call sites outside the package or module while test
   references exist — it was made public for tests; demote (rung 1) or promote
   (rung 2/3).

2. **Are internal helpers tested directly?**
   Detect: judgment
   Detection: find test files that can reach non-public symbols (an in-package test,
   an import of a private module, a test that reaches past the public surface), then
   search those files for calls to the package's non-public functions.
   Violation: any direct test of a private helper — that urge is the promotion
   signal; give the helper its own package instead.

3. **Does a new shared package have a role name?**
   Detect-path: `(^|/)(util|utils|helpers|helper|common|shared|misc)(/|\.[a-z]+$)`
   Detection: list the shared-library directories and match their names against
   `util`, `utils`, `helpers`, `helper`, `common`, `shared`, `misc`.
   Violation: any hit — packages are named for a domain vocabulary, never a role.

4. **Is a new shared package a single noun rather than a vocabulary?**
   Detect: judgment
   Detection: count the public types the new package declares and ask whether
   plausible domain siblings exist under the name.
   Violation: a package named after its one type (`kubeport`) with no room for
   siblings — fold into a vocabulary package (`networking`) or keep at rung 1/2.
   A rung-2 package nested under its feature is not judged by this question.

5. **Did feature policy leak into a shared package?**
   Detect: judgment
   Detection: search the shared package for feature-owned literals and constants
   (a product or feature name inside a string literal, say `"weka-`).
   Violation: any feature-specific literal or preference decision inside a
   domain-generic package — policy stays in the feature (Stage 2 of
   `R1-primitive-obsession.md`).

6. **Does a changed function envy another type's data?**
   Detect: judgment
   Detection: for each changed function/method, count field/method accesses per
   value (occurrences of `<receiver>.` versus occurrences of `<parameter>.` in the
   body), for the receiver and for its most-touched parameter or field. A parameter
   that is a built-in container is accessed by index, lookup, membership test and
   loop rather than by field; count those the same way.
   Violation: accesses on one foreign value outnumber accesses on the receiver (or
   on all local data, for a free function) and the foreign type is yours to extend —
   Move Method to the Envied Type, then re-place via the ladder. A function that
   merely *reads* a foreign DTO once to adapt it at a boundary is not envy.
