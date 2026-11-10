---
type: guide
description: how a baseline is recorded and compared: noise floor, regrade, the acceptance procedure for a plugin refactor, and the eval scope each kind of change needs
---
# Baselines and Comparison

## Recording one
Run the cheap tier two or three times per case and the medium tier once, with the
model pinned and one `OUT` directory for both tiers (`task <lang>:run` keeps scaffolds
and writes each tier to `OUT/<tier>`). Regrade once after calibration so every
`result.json` carries the current graders' verdict. Then promote the run:
`task <lang>:baseline OUT=<run dir> PLUGIN=<plugin dir>` creates
`baselines/<lang>-<plugin version>-<plugin sha>/` in the evals repository (`NAME=`
overrides the directory when the plugin and the fixture differ in language:
`generic-gomini-…`, `generic-pymini-…`) with the
verdicts, every trace in one local `traces.tar.zst`, the plugin pin in `plugin.json`,
and a README stub with the per-case table pre-filled. Finish the README with the
findings, the noise floor and every grader change made after the run, and commit.
The trace archive is not committed, because a trace can hold data from the machine
that ran it: put it at the same path in the private `weka/ldd-evals-traces`
repository. The traces make later calibration free; the scaffolds are not kept,
so graders that read the tree cannot be regraded from a clone.

The Go suite's current baseline measures plugin 2.13.2 at b56f79b, the close of the
token-budget stages, and lives in the evals repository at
[`baselines/go-2.13.2-b56f79b/`](https://github.com/weka/ldd-evals/tree/main/baselines/go-2.13.2-b56f79b);
its README compares it case by case with the earlier
[`baselines/go-2.11.0-c78b55f/`](https://github.com/weka/ldd-evals/tree/main/baselines/go-2.11.0-c78b55f),
carries the first spend section, and names the reading guide for the next comparison:
one grader on a scoped review is noise and the same grader missing in both runs is a
signal, the whole-repository review inside 104 to 109 of 114 is noise, a refactor case
needs a second run before a change of up to three graders is read, and any change on a
case that has never flipped is a signal. The generic
plugin's floor on the same fixture is
[`baselines/generic-gomini-0.1.0-109b0db/`](https://github.com/weka/ldd-evals/tree/main/baselines/generic-gomini-0.1.0-109b0db),
compared with it grader by grader. The Python suite's first baseline is that same
generic plugin over py-mini, and its README adds the parity report: per rule, recall
on py-mini against recall on go-mini under one plugin, so the rules with a large gap
are where the Python binding spends next; the binding's own first baseline is then
read against that floor.

## The noise floor
Graders that flip between runs of the same case, on the same plugin, are the noise
floor. In the current baseline: two graders flip on Case A's review, one each on
Cases B, C and F, three on Case E's and on the centerpiece's; in the medium tier,
run twice, one grader on Case D, the centerpiece and quickfix, three on Case E. The
whole-repo review is read on its grader count (90 of 111 against the earlier band of
91–94), because two of its three runs reviewed an empty scope. The practical reading
rules:

- A per-case change smaller than one flipping grader is noise.
- Compare the whole-repo review on its grader count (91 to 94 of 111), not on
  pass or fail.
- In baselines graded by a single-vote judge (every baseline up to go-2.10.0-5828c34)
  an llm judge flipping between a live run and a regrade of the same file is noise;
  the runner now votes two of three, so a flip in a later baseline is a finding.

## Comparing after a refactor
This is the acceptance procedure for the language-neutral core extraction, whose
promise is that the generated plugin behaves the same as the hand-written one:

1. Run the cheap tier once and the medium tier once against the generated plugin,
   same model, same graders, into a new run directory under `results/`.
2. Regrade both the baseline and the new run with the same graders if any grader
   changed in between.
3. Per case, compare pass counts and, for the whole-repo review, the grader count.
   No case may move by more than one flipping grader; art judges must pass on the
   same cases.
4. Anything outside that band is a real behavior change. With the plugin text
   byte-identical, the suspect is the generator, not the plugin.

## Choosing the eval scope for a change
A change to plugin text or to a shared script can need two kinds of check. The table below selects which ones apply:

- A full check: `review-full`, three runs, on the Go fixture, on both arms (main and the branch). It finds a change in hunter behavior that the text change causes.
- A narrow check: for each other binding that renders the changed text, run only the cases that hold the plants of the touched rules. Run the branch arm only, three runs, against the newest baseline of that language.

Tests cover what an eval cannot. A rule that works on one fixture does not need a full run on the other fixtures.

| What the change touches | Check |
|---|---|
| Shared script or generator, plugin text byte-identical | Shell tests and `task check`. No eval. |
| Core text that all bindings render (rule prose, agents, skills) | Full check on Go. Narrow check on Python and TypeScript. |
| Text under one `lang/<binding>/` directory | Narrow check on each binding that renders it. The generic binding renders the Go `examples/` includes, so a change there reaches Go and generic. |
| Language-specific script code (for example a suppression pattern) | Shell test for that binding. Narrow check only if a hunter reads its output. |
| Docs, changelog, README | No eval. |

Pick the narrow cases from the rule ids in the plugin text that changed. A case qualifies when `violations.yaml` of that language plants a violation of the rule. When no case qualifies, use `review-full`.

If the newest baseline of a language predates the last release of its plugin, run the main arm too. Then compare two live arms, not an old baseline.

Write the scope and the result in the pull request: the cases, the run counts and the grader counts per arm.

## Comparing after a behavior change
Each deliberate fix to the plugin names the cases it should flip. Re-run only those
cases, at their baseline run counts, and read the delta. One fix per pull request,
so a flip has one cause and a regression elsewhere has one suspect.

## Cost
Cheap tier about $66 for 23 runs; medium tier about $23 for 10 runs; a whole-repo
review is the expensive cheap case at $7 to $15 per run. Sessions that spawn
subagents in the background and then poll roughly double their cost; the
`segments` field in each result marks them. Where the tokens of a run go, and the
spend gate a cost-cutting change must pass beside the verdict comparison above, is
in [token-budget.md](token-budget.md).
