# Verification

Which feedback loop catches which failure, and the verification shapes that a
passing test suite cannot stand in for.

## Match the instrument to the feature

| Feature shape | Instrument | What only this catches |
|---------------|-----------|------------------------|
| Type changes, interface modifications, nullable conversions | Unit tests | Regressions in call sites the change didn't touch |
| A tool wrapping an external process (ffmpeg, a CLI, hardware) | A live run with real inputs | Library loading, metadata accuracy, UI layout instability |
| A tool-serving system (MCP, an HTTP API) | The actual protocol, not the unit seam | Output formatting, missing fields, tool descriptions |
| Infrastructure (Docker, nginx, CI, publish) | The full pipeline | Signature matching, env-specific config, proxy routing |
| Anything that emits an artifact (package, binary, config) | Inspect the artifact | What went wrong, where logs only say why |
| Anything with a rendered surface | A screenshot or a person | Every render-contract bug a green suite ships |

Two traps in the first column. A test project can pass with a simpler
configuration than production uses, which makes it a weaker oracle than it
looks. And live testing is not a later, heavier version of unit testing — it is
a *different* oracle, so run it during implementation rather than after.

## Validate outputs, not process logs

When a build emits thousands of log lines, go to the artifact first: the package
contents, the generated file, the PDB metadata. Extract it and read it directly.
Logs explain *why* something went wrong; the output tells you *what* went wrong,
and reading them in that order collapses a diagnosis that otherwise scrolls.

## Visual verification

For anything with a rendered surface — a docs site, a dashboard, a status bar, a
badge — use the Playwright plugin (`@anthropic-ai/claude-code-plugin-playwright`).
Its `waitForSelector` plus a structured screenshot call is one tool call per
check.

Driving `Google Chrome --headless --screenshot=…` from Bash instead is a
token-cost trap: cache-busting needs a fresh `--user-data-dir` per run,
`--virtual-time-budget` is unreliable for client-rendered routes (docsify hash
routing completes asynchronously), and full-page captures truncate past
~3500px. A single session can burn ~25 rounds at 5-10s each before anyone
notices the cost.

**`--dump-dom` is the diagnostic** when a screenshot disagrees with expectation:
an element present in the DOM but invisible means the bug is JS/CSS, not the
capture pipeline.

Add the preview command (`docsify serve docs`, or the project's equivalent) to
the Bash allowlist up front so server starts don't prompt mid-session.

## Both-branch verification for convergent changes

A "reconcile on every deploy" change — tag convergence, drift correction, any
apply-every-time logic — has two code paths: the resource already exists (the
**converge** path) and the resource is fresh (the **create** path). An
obviously-correct diff can leave one of them broken, and the diff will not show
it.

Verify both. The converge path usually exercises naturally on a redeploy. Force
the path you can't reach passively by **manipulating live state** — delete the
resource so the next deploy has to recreate it — rather than trusting that the
untouched branch still works. The live deploy, and the actual resource state
after it, is the oracle; a reading of the code paths is not.

Budget such a change by how many live deploy cycles the verification needs, not
by diff size. A 12-line convergence change can be hours of work whose product is
confidence rather than authorship.

## Scenario matrix as an acceptance harness

When a feature wraps a tool with its own resolution rules — Terraform variable
precedence, shell glob and merge order, CI variable availability — its
correctness lives in the runtime, not in the source, so unit tests give false
confidence.

Build a separate scenario repo where **each directory is one case** (default,
override, precedence, fallback, …) and run the whole matrix in the real
environment. The matrix is the spec; the run is the judge. Two force
multipliers:

1. **Verify the load-bearing mechanism by running a probe**, not by reciting the
   docs — a plausible-sounding mechanism cited as fact is how a rumor becomes
   the premise of the next decision. The observed precedence or merge order
   then drives both the implementation and the matrix.
2. **Fold the run anchors into the change request** as a self-contained proof
   section, not an ephemeral rendered artifact a later reviewer can't open.

Defer regenerating fixtures until the design settles — regenerating on every
refinement invites a stale scenario slipping through.

## A remote pipeline can be the build environment

When there's no local toolchain (full-framework on a non-Windows host, a
platform-specific SDK), don't simulate the build: push and poll the pipeline
(`glab ci status`, the job APIs) with `run_in_background`, so the multi-minute
waits never block a turn. The build and test verbs become `git` and the forge
CLI rather than a local runner — and the same pipeline doubles as the acceptance
harness above.

## When the consumer ships a validator, test against its rejections

A feature that encodes someone else's contract — a schema for a manifest another
tool reads, a config a platform parses — has an oracle better than your own tests:
the consumer's validator. Your suite proves the constraints are self-consistent.
Both agree on well-formed input, so run the malformed cases through both, one at a
time, and compare what each refuses. That's where a transcribed contract turns out
to be a superset of the real one.

Two companions, cheap and worth doing in the same pass:

- **Plant the bad input in a real entry**, not just a unit fixture, and confirm the
  build refuses it with the file and field named. A gate asserted in prose is a
  gate nobody has seen fire.
- **Break a guard whose input set is currently empty.** A test over "every
  published entry" passes vacuously until the first one exists, which makes it
  indistinguishable from a working guard. Falsify it once so its failure message
  is known to work.

Worked example: a marketplace schema plus eleven tests, all green, disagreed with
`claude plugin validate --strict` on hostname case. Planting an uncompilable regex
in a live registry entry proved the build gate; breaking the documented sample
proved the drift guard.

## Prove a pre-existing failure rather than reasoning about it

Before claiming a failure predates the change, `git stash -u`, re-run exactly
those tests against the unmodified base, and compare. An identical reproduction
is what earns the "not mine" claim; a test name that looks unrelated is not.

## Construct the degraded input rather than reasoning about it

The happy path is the one in front of you, so a claim about what happens when
the input is *wrong* gets asserted from the API's shape instead of exercised —
and that claim is usually the reason no guard was written. Build the broken case
and run it. Three shapes the result takes, each with a claim that came back
that way:

- **Backwards.** `&&` chaining looked fine for running build-then-push under a
  role-assuming wrapper. The `&&` binds in the *caller's* shell, so only the
  first command gets the role, silently.
- **True only under a condition nobody stated.** A heredoc does work through a
  YAML block scalar — at one indentation. Mis-indent it and the shell eats the
  rest of the job, runs a stray command, and exits 0.
- **Confirmed.** `exec "$@"` is injection-safe; metacharacters, `$( )` and pipes
  all arrive as literal argv. Running it is what makes that a fact rather than
  a belief.

A form whose most natural mis-use fails at exit 0 doesn't belong in a README,
and constructing the degraded input is what tells you which forms those are.
"When the consumer ships a validator" above carries two worked instances:
planting bad input in a real entry, and falsifying a guard whose input set is
still empty.

## Use the pattern before documenting it

Where a feature ships a pattern other people are meant to copy, use it in the
project's own code before the README describes it.

One wrapper carried its own open/close pattern in its body before the README
covered it, which surfaced a defect: a per-region auth call had become a *child*
process, so the credentials it set up died with the child, and every command
after it ran on whatever the parent already had. It had been that way for two
releases.
