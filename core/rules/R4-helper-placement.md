# R4 — Helper Visibility & Placement

## Principle

Every extraction raises a second question: where does the helper live? The answer is
decided by two axes — juiciness (the scorecard in `R1-primitive-obsession.md`; cite
it, never re-derive it) and scope (feature-specific versus domain-generic). Three
rungs: {{.Unexported}} in place, a sub-package nested under the feature, and a shared
domain package when a second package imports it. Never test privates, and never
export a helper into its parent package just so a test can reach it.

## Why

Wrong placement rots in both directions. Helpers exported into the parent package for
testability pollute its API — callers see symbols that exist only for tests, and the
package's real surface becomes unreadable. Juicy helpers buried as {{.Unexported}} code
either go untested or push the team into testing privates, breaking the
public-API-only discipline (`R7-test-placement.md`). And role-named dumping grounds
(`util`, `helpers`, `common`) accrete unrelated code that nobody can find, name, or
own. Placement is what lets extraction deliver its promise: isolated, literal-input
unit tests against a legitimate public API.

## Canonical example

{{include "rules/R4/canonical-example.md"}}

## Design guidance

### The placement ladder

1. **Trivial helper** (R1 score 0–3) → {{.Unexported}}, same package, tested only
   through the parent's public API. A helper (function or type) with a score of 4 or
   more stays here only with a reason written in the design.
2. **Juicy + feature-scoped** → a package nested under the feature package
   (`internal/<feature>/<leaf>`), or a module with public names inside the feature
   package. This is the default home of a juicy helper. The feature needs no
   minimum size for it. See `R5-vertical-slice.md`.
3. **Juicy + domain-generic, and a second package imports it** → a top-level shared
   package: `internal/pkg/<domain>` (default) or `pkg/<domain>` (public).
   Granularity: a package is a domain *vocabulary* (`networking`), not a single noun
   (`kubeport`), never a role (`util`/`helpers`/`common`).

"Juicy" is an R1 score of 4 or more — `R1-primitive-obsession.md` is the scorecard's
only home.

### The promotion signal

**The urge to unit-test a helper directly means it deserves its own package.** Never
act on that urge by testing privates, and never by exporting the helper into the
parent. The urge is data: it says the helper has enough behavior to be a unit of its
own — so give it a real home where its exported API is legitimately testable with
literal inputs: rung 2 by default, rung 3 when a second package imports it. An R1
score of 4 or more is the same signal, with or without the urge.

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
- **Promote to feature sub-package (rung 2)**: a juicy, feature-scoped helper being
  tested through awkward big-object setups → move it into a package nested under the
  feature package, export it there, test its public API directly.
- **Split the pure leaf out of an I/O package**: a juicy pure function or type in a
  package that does I/O (network, files, environment variables), tested only through
  that I/O → move it to a rung-2 package nested under the feature and export it
  there. Give it rung-0 tests with 100% coverage and a mutation run
  (`R7-test-placement.md`). The I/O code stays in the parent and calls it. This
  applies also when the leaf is {{.Unexported}}.
- **Promote to domain package (rung 3)**: a juicy, domain-generic helper that a
  second package imports → create or extend `internal/pkg/<domain>`; move the generic
  types; leave feature policy home as a thin storified method (see Stage 2 of
  `R1-primitive-obsession.md`'s canonical example).
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

{{include "rules/R4/falsifying-questions.md"}}
