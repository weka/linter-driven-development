# R4 — Helper Visibility & Placement

## Principle

Every extraction raises a second question: where does the helper live? Two axes
decide the answer. One is juiciness: the scorecard in `R1-primitive-obsession.md`
(cite it, never re-derive it). The other is scope: does a second package import it?
There are three rungs: {{.Unexported}} in place, a sub-package nested under the
feature, and a shared domain package when a second package imports it. Never test
privates, and never export a helper into its parent package just so a test can reach
it.

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
   through the parent's public API.
{{include "rules/R4/ladder-rung-2.md"}}
3. **Juicy, and a second package imports it** → a top-level shared package. Extend
   the domain package that fits it, or create one.
   Granularity: a package is a domain *vocabulary* (`networking`), not a single noun
   (`kubeport`), never a role (`util`/`helpers`/`common`).

{{include "rules/R4/rung-paths.md"}}

"Juicy" is an R1 score of 4 or more — `R1-primitive-obsession.md` is the scorecard's
only home.

### The promotion signal

**The urge to unit-test a helper directly is a signal to score the helper.** Never
act on that urge by testing privates, and never by exporting the helper into the
parent. The R1 score decides the home. With a score of 0–3, the helper stays
{{.Unexported}} at rung 1, and its tests go through the parent's public API. With a
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
{{include "rules/R4/promote-rung-2.md"}}
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

{{include "rules/R4/falsifying-questions.md"}}
