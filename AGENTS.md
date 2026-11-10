## Documentation
Docs live in docs/ — start at docs/index.md, the map of all repo docs.
Before adding or editing anything under docs/, read docs/conventions.md
(frontmatter, link rules, what never to do).
When you change how the evals or the plugin work, update the doc that describes it
and its index line. Check your work: bash scripts/check-docs.sh

Before you open a pull request that changes plugin text or a shared script, pick the eval scope
in docs/eval-baseline.md ("Choosing the eval scope for a change"). Run it and write the result in the PR.
