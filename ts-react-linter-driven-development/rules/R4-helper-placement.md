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
After extraction, `Port`/`Ports`/`firstNamed`/`first` say nothing about Kubernetes
or Weka: juicy (range validation, collection queries), domain-generic, and imported
by a second page → rung 3, a shared `src/networking/` module. The feature keeps a
two-line storified policy function:

```typescript
const WEKA_API_PORT = 'weka-api'

export function managementPort(ports: Ports): Port | undefined {
  return ports.firstNamed(WEKA_API_PORT) ?? ports.first()
}
```

Only the domain-generic parts were promoted: the `WEKA_API_PORT` constant is feature
policy and stays in the feature. A shared module that knows one feature's port names
is not shared vocabulary — it is leaked policy.

The rung-1 contrast — a trivial helper that stays put:

```typescript
// One caller, no domain vocabulary, no rules of its own: stays non-exported.
function parseK3sArgument(arg: string): readonly [key: string, value: string] | undefined {
  const [key, ...rest] = arg.split('=')
  return rest.length === 0 ? undefined : [key, rest.join('=')]
}
```

There is no urge to test this directly — and that absence is the point: the promotion
signal (below) never fires. The rungs in TypeScript: rung 1 is a non-exported
function at module scope beside its only caller (never inside the component body,
where it is re-created every render), covered through the module's exports; rung 2
is the page folder's own module named for its vocabulary
(`pages/Cluster/managementPort.ts`, `pages/Cluster/hooks/`), imported by relative
path; rung 3 is a shared `src/<domain>/` module named for a vocabulary, reached
through the path alias, when a second page imports it. There is no `internal/`
convention — `export` is the wall, and a barrel `index.ts` that re-exports a
module's private names tears it down.
Extract Function (here, a custom hook) climbs the same ladder: beside its only
caller, then the page's `hooks/`, then `src/hooks/` only when two pages share it.

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

The rung paths in TypeScript: rung 2 is a module in the page folder, with exported
names (`pages/Cluster/managementPort.ts`). Rung 3 is a shared `src/<domain>/` module.

"Juicy" is an R1 score of 4 or more — `R1-primitive-obsession.md` is the scorecard's
only home.

### The promotion signal

**The urge to unit-test a helper directly is a signal to score the helper.** Never
act on that urge by testing privates, and never by exporting the helper into the
parent. The R1 score decides the home. With a score of 0–3, the helper stays
internal at rung 1, and its tests go through the parent's public API. With a
score of 4 or more, the helper deserves its own package: a real home where a test can
call its exported API with literal inputs. Use rung 2 by default, and rung 3 on the
trigger the ladder gives. A score of 4 or more gives the helper its own package,
with or without the urge.

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

1. **Is a symbol exported only so tests can reach it?**
   Detect: judgment
   Detection: for each newly `export`ed function, hook or type
   (`grep -rn "export " <file>` lists the candidates),
   `grep -rln "import .*\b<Symbol>\b.* from '" --include='*.ts' --include='*.tsx' --exclude-dir=node_modules . | grep -v '\.test\.'`
   — count non-test importers outside its defining module.
   Violation: zero production importers while `*.test.ts`/`*.test.tsx` files import
   it — it was exported for tests; demote (rung 1) or promote (rung 2/3).
   `export function parseRetention` whose only importer is `parseRetention.test.ts`
   is the shape.

2. **Are module-private helpers tested directly?**
   Detect-grep: `__test|for test|@internal|^export \{|vi\.spyOn\(` files=all
   Detection: a non-exported name cannot be imported, so the reach leaves a trace:
   a re-export or a `__testing` bag added at the bottom of the module, a barrel
   `index.ts` that re-exports what the module kept private, and a `vi.spyOn` in a
   test on a module's internals through its namespace import — read what each
   `export {` block and each spy names.
   Violation: any direct test of a private helper. The urge is a signal to score
   the helper on R1's scorecard. A score of 0–3 keeps it private: delete the direct
   test and cover the helper through the parent's public API (rung 1). A
   score of 4 or more gives the helper its own module (rung 2 or 3). The re-export is
   a convention the test runs through, and that is why the question is asked.

3. **Does a new shared module have a role name?**
   Detect-path: `(^|/)(util[^/]*|helpers|helper|common|shared|misc|lib)/|(^|/)(utils|helpers|common|constants)\.tsx?$`
   Detection: any scope path under a role-named directory, or a module of that
   name; a barrel `hooks/index.ts` that collects every hook is the same dumping
   ground with an `index` and is read by hand.
   Violation: any hit — `utils/strings.ts`, `utils/time.ts` and `common/constants.ts`
   are the TypeScript spelling of the role-named package; modules are named for a
   domain vocabulary, never a role.

4. **Is a new shared module a single noun rather than a vocabulary?**
   Detect: judgment
   Detection: `grep -cE '^export (interface|type|class|function|const) ' src/<name>/*.ts`
   and ask whether plausible domain siblings exist under the name.
   Violation: a module named after its one type (`src/kubeport/`) with no room for
   siblings — fold into a vocabulary module (`src/networking/`) or keep at rung 1/2.
   A rung-2 module nested under its feature is not judged by this question.

5. **Did feature policy leak into a shared module?**
   Detect: judgment
   Detection: grep the shared module for feature-owned literals and constants, e.g.
   `grep -rn "'weka-" <shared module>/`; a feature literal in a shared constants
   module (`common/constants.ts` holding `SNAPSHOTS_PAGE_SIZE`) is the same leak.
   Violation: any feature-specific literal or preference decision inside a
   domain-generic module — policy stays in the feature (Stage 2 of
   `R1-primitive-obsession.md`).

6. **Does a changed function envy another type's data?**
   Detect: judgment
   Detection: for each changed function or component, count property accesses per
   value: `grep -oE '\b<param>\.[a-zA-Z_]+' <function body> | sort | uniq -c` for its
   most-touched parameter or prop versus the same count for its own data (its
   state, its module's types). A parameter that is a `Record`, an array or a `Map`
   is accessed by `[`, `.get(`, `in`, `.length` and `for … of` rather than by
   property; count those the same way. A component reaching into another page's
   data shape — `pages/Alerts/AlertRow.tsx` walking
   `device.network.interfaces[0].addresses` from the Devices page's type — is the
   React form.
   Violation: accesses on one foreign value outnumber accesses on the function's
   own data and the foreign type is yours to extend — Move Method to the Envied
   Type (a function beside that type, or a selector on its hook), then re-place via
   the ladder. A component that merely *reads* a DTO once to render it at the
   boundary is not envy.
