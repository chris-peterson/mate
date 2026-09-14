---
name: feature
disable-model-invocation: true
description: Add a capability to an existing codebase — gather the constraints that prevent false starts, implement one feature at a time against the repo's existing patterns, verify each against real feedback, then consolidate before merge.
argument-hint: "[what to build]"
---

# Feature

Add capability to an existing, working codebase: confirm the constraints that decide the shape of the change, implement one feature at a time following the patterns already there, verify each against the feedback loop that can actually catch its failures, then consolidate the divergence that multi-feature work leaves behind.

**Skip this skill when** the work is a defect whose cause isn't known yet (that's `/fix`), when the project has no existing patterns to follow (greenfield work maximizes autonomy instead of constraining it), when the change is a one-line or mechanical edit, or when the task is research and the deliverable is an answer rather than code.

## Before starting

Ask for whatever is missing rather than guessing. **Project format, build system, and deployment target are the most commonly omitted and the most expensive to discover** — without them the default is modern conventions for all three, and a legacy codebase punishes each wrong default with a failed iteration.

- **Domain** — what the project does, who uses it, its key technologies.
- **Feature requirements as concrete behavior.** "Display the error with stderr, command, and log path, then prompt retry/continue/abort" is a specification; "add error handling" buys a generic try/catch. Ask for the concrete form before implementing; a session started without it spends its first iterations discovering what it should have been handed.
- **Existing patterns to follow** — name the interfaces, types, and conventions, or the file that demonstrates them.
- **Project format** — packages.config vs PackageReference, monorepo vs polyrepo.
- **Build system and deployment target** — where this ships and how.
- **API contracts** — the Swagger/OpenAPI URL, when the feature touches an external API. Read it rather than guessing at endpoints.
- **Validation strategy** — how the feature gets verified: tests, a live run, CI, a deploy.

Three questions that only apply sometimes, and each is cheap next to what it prevents:

- **Fast-moving ecosystem?** (build tooling, packaging, infrastructure, agent conventions) Research before implementing. Cross-reference official docs against the project's issue tracker — outdated advice dominates search results and official READMEs go stale. State the current best practice and why, so the user can validate it before it's built.

  When the feature's *existence* depends on the research — "if a standard exists, enforce it" — four moves keep the answer honest:

  - **Ask the falsifiable question, not for the feature.** "Does a standard exist for X?" can come back no; "add a check that enforces X" cannot. A negative is shippable: a deferred requirement citing the evidence, with a named trigger that would reopen it.
  - **Name the feature shape for each outcome before the evidence lands.** Two or three branches keyed to what the research might find. Backgrounded research then costs no wall-clock, and a negative result arrives as a decision rather than a dead end.
  - **Separate a format claim from a location or behavior claim.** "There's a spec for what goes inside a skill directory" and "there's a spec for where it lives" are different facts, and usually only one of them can justify what you're about to build.
  - **Re-derive the load-bearing claim yourself.** A research fan-out's own adversarial verification runs inside the apparatus that produced the claim. Identify the single fact that would reverse the decision and check its primary source directly.
- **Multi-feature batch?** List the features, say which depend on which, and frame delivery as one at a time up front rather than promising everything in the first commit.
- **Cross-repo rollout?** Ask whether the consumer population is uniform (everyone on `latest`/`main`) or mixed/pinned. Uniform supports a single-path swap; mixed needs a transitional dual state. This is one binary question that decides whether the rollout is one MR per repo or three.

## Phase 1 — Setup and context (5-15 min)

**Before implementing:** where [tack](https://github.com/chris-peterson/tack) is installed and no route resolves for the session, say so and let the user type `/tack:start [url]` — it opens the envelope (the linked thread read in full, a branch, a route) that `/tack:end` later closes. Where it isn't, do the same work by hand: read the linked thread in full and cut a branch named for the feature before touching anything.

Confirm the inputs above, then honor the constraints that prevent false starts. For CI, build, or orchestration config, **check the variable-availability docs for the context the variable sits in**, not just that the variable exists: a variable available in a job may expand to empty in `workflow:name`, `rules:if`, or a trigger job, and the failure is cosmetic-but-confusing rather than loud.

When the feature already exists somewhere else, the reference implementation's git history is an executable spec — `git log --grep` plus `git show` on the *introducing* commit yields the exact format, enum values, and verification deltas to mirror, with unrelated history stripped out.

## Phase 2 — First working implementation (15-60 min)

Get to working code. Functional results come early; polish is a later phase and a longer one.

1. **Mirror the repo before introducing anything new.** Read the existing interfaces, types, and conventions and extend them. Name new types consistently with the ones already there. With a newer or thinly-documented SDK, expect 2-3 build-fix cycles discovering the real API shape — that's the cost of the territory, not a failure.
2. **One feature at a time, each leaving the tree buildable and tested.** Run the tests after each. Features implemented in sequence are how parallel code paths (sequential vs concurrent, old vs new) silently drift apart; verifying each one catches the drift while it's a one-line fix.
3. **Prefer the concrete type over the workaround.** A nullable `int?` carries "auto-detect if unspecified" better than `int` plus `bool wasExplicit`. Share types between parallel paths instead of duplicating logic. Design a concurrent structure for N workers from the start even when N is 1.
4. **Apply design corrections immediately and propagate them.** The user is the architect. A brief correction — "falsey values should opt out", "push the fix to the API boundary" — is the highest-signal input in the session and often redirects the whole implementation. Applying it while the code is still fluid beats refactoring it in later.
5. **Order the part you can't verify last.** When one component of a feature depends on behavior you have no way to observe — another tool's runtime, a service you don't have credentials for — sequence it after everything that works by construction and state the claim as unverified where a reader will meet it. The feature then degrades cleanly instead of failing as a unit, and nobody downstream inherits an assertion nothing tested.
6. **Pull toward simplicity when iterations spiral.** If the third approach is more complex than the second, stop and ask what the simplest thing that could work is. `jsondecode(jsonencode(...))` round-trips, regex post-processing, and nested try/catch layers are the tells that complexity is being added rather than subtracted.

Never wrap the requested approach in a fallback that degrades to a simpler path; if the primary fails, surface the error loudly instead. The feature then looks like it works while the fallback is what's running, so every test after that point evaluates the wrong thing.

## Phase 3 — Refine against real feedback (30 min to hours)

Pick the feedback loop that can actually catch this feature's failures — unit tests, a live run, the real protocol, a full CI/deploy cycle, or inspecting the emitted artifact. `references/verification.md` maps feature shapes to instruments, covers both-branch verification for convergent changes and visual verification for anything with a rendered surface, and says how to construct the degraded input instead of reasoning about it.

- **Expect most iteration to be polish, not function.** Functional correctness typically arrives around iteration 5-6; console output, error messages, progress indicators, and docs take many more. Budget for it, and agree with the user on what "good enough" means before starting — polish iterations otherwise continue indefinitely.
- **Treat each real-world issue as immediate input.** Runtime errors, unexpected metadata, layout instability: act on each as it surfaces rather than batching. Observing actual output beats specifying UX up front.
- **Treat manual testing as discovery, not just verification.** It routinely surfaces bugs and gaps automated tests miss, which is why a one-feature session often ships three features plus fixes.
- **Where the feature ships a pattern others are meant to copy, use it in the project's own code first.** Using it is what finds the bug, while nobody has copied it yet; `references/verification.md` has the defect that ordering caught.
- **When a test for the new feature fails, fix the code.** The test is a fixed acceptance target; a shrinking assertion or a loosened threshold ships the feature unverified behind a green suite.
- **Reset to zero when the session balloons.** When failed approaches and scope expansion make the branch hard to reason about, stash to a side branch and re-derive the minimum viable change from baseline. That's cheaper than pruning an overgrown branch.

## Phase 4 — Consolidate (15-30 min)

Multi-feature and long-session work leaves divergence behind. Run this scan deliberately *before* merge, surface each finding with a one-line rationale, then fix:

- **Type proliferation** — separate features inventing parallel types for one concept (`RipResult` / `EncodeOutcome` / `EncodeResult` where one `ProcessResult` would do).
- **Path divergence** — do the sequential and concurrent, or old and new, paths still share types and logic?
- **Naming conflicts** — internal types colliding with public-facing ones.
- **Concurrency design** — were shared resources built for N workers, or retrofitted onto a single-worker model?

Then do the cleanup pass: orphaned code, debug scaffolding, and generated build output that should be `.gitignore`d rather than tracked. Adding without removing is the default, and nobody asks for the cleanup — offer it.

## Phase 5 — Ship it through the pipeline (variable)

Local build success does not predict deployment success. Constraints that only surface on a real publish or deploy — signature matching, environment-specific config, reverse-proxy routing — can cost as much as the original implementation, and infrastructure compounds scope: "add an MCP server" reaches the Dockerfile, the nginx config, the CI pipeline, and the entrypoint script, each with its own iteration cycle.

| Phase | Typical time |
|-------|--------------|
| Setup and context | 5-15 min |
| First working implementation | 15-60 min |
| Refinement | 30 min - hours |
| Consolidation | 15-30 min |
| Infrastructure and deploy | 30-60+ min |

Long sessions accumulate context faster than they look like they do, and idle gaps — waiting on CI, reviewing, interruptions — burn it without adding anything. When the session approaches that threshold, say so and propose splitting the work or persisting the decisions to CLAUDE.md before continuing.

**Make the result observable before reporting it.** Give the user a command they can paste and the output it actually produced, rather than a prose summary. Name what the session leaves behind, too: a background server, a scratch directory, a file written outside the tree.

Where tack is installed, the close is **`/tack:end`** — it reads what actually landed (a draft CR with green checks is a stall, not a finish), records the deliverable against the route, decides whether the session earned a retro, and reports the commands still owed rather than running them. Where it isn't, close by hand: a draft CR with green checks is still a stall, so say what landed, what is still owed, and whether the session earned a retro.

## Working style: the user directs, you implement

Backseat driving is the interaction style this work rewards — the user stays in architect mode and writes prompts instead of code, and vague prompts produce vague output while specific ones produce specific output. It fits integration work, boilerplate-heavy tasks, tedious-syntax formats (MSBuild XML, zsh completion, regex, YAML, CI config), and settled architectures. It fits badly when the user is still exploring what the solution should be, or when the code is simple enough that typing it is faster than describing it.

## Reference files

- **`references/verification.md`** — which feedback loop catches which failure, both-branch verification for idempotent/convergent changes, visual verification, validating artifacts rather than logs, constructing the degraded input, and using a pattern before documenting it.
- **`references/patterns.md`** — the accumulated what-works / what-doesn't catalog from past feature sessions: design sign-off shapes, command-topology decisions, scope control, and the failure modes that recur.

## Related

Phase 4's scan turns on a changeset's own divergence the habit of fixing what you find everywhere it fits. Claims about *why* a chosen approach is correct — a precedence order, a rendering behavior, a variable's availability — need a probe rather than a recollection; the cheapest decisive probe usually beats reading source.

The [feature-dev plugin](https://claude.com/plugins/feature-dev) covers the same ground as a guided seven-phase workflow with dedicated exploration, architecture, and review agents. Reach for it when the preference is step-by-step interactive structure over this skill's phases.
