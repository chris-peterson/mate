---
name: fix
description: Diagnose a bug whose cause isn't known yet — root-cause it, prove it with a failing test, then sweep for the same bug class. Triggers on a stack trace, a CI failure, "why is this failing", "works locally but fails in CI".
argument-hint: "[what's failing]"
---

# Fix

Drive a bug from symptom to shipped fix: confirm the defect is real and current, find the mechanism, prove it with a failing test, verify in the environment that actually failed, then sweep for the same bug class before shipping.

**Skip this skill when** the correction is already known and mechanical (a typo, a rename, a lint error with an obvious fix), when the work is a feature or a refactor rather than a defect, or when there is no error signal to reason from — a vague performance concern or a broad quality complaint is investigative work, not debugging.

## Before starting

Ask for whatever is missing rather than guessing. Framework version, system architecture, and execution-context constraints are the most commonly omitted and the most expensive to discover through failed iterations.

- **The actual failure artifact** — the CI job trace for a CI bug, the container's output for a container bug. Diagnosing a remote failure from a local build log burns the session on wrong leads.
- **Environment** — framework/SDK version, OS, architecture, containerized vs native.
- **Execution context** — where the failing command runs, and whether the code sits in `async void`, a thread-pool callback, or an unhandled exception handler. Catch-pattern choices depend on this.
- **What changed** — recent commits, dependency updates, config changes.
- **Report provenance** — when it was observed, on what version. A report is a snapshot; the defect may already be fixed.

Work in the target repo's own working directory. Cross-cwd debugging multiplies tool calls, trips permission prompts, and confuses skills whose target detection assumes cwd ≈ git root. In the wrong cwd, say so and ask for a restart rather than working around it.

**On a first contribution to an unfamiliar repo, get a clean build and a green run of the suite you'll extend *before* writing the failing test.** The toolchain pin and the package feed are the two that bite: a `global.json` / `.tool-versions` / lockfile pin the machine doesn't satisfy, and a private feed that 401s on a package the build needs. Run the repo's own bootstrap script (`Start-PSBootstrap`, `bootstrap.sh`, `make setup`) rather than improvising. Discovering either one *between* writing the RED test and running it is the expensive position: the gate that proves the diagnosis is blocked on unrelated infrastructure while the test design is still in flight.

**Before diagnosing:** where [tack](https://github.com/chris-peterson/tack) is installed and no route resolves for the session, say so and let the user type `/tack:start [url]` — it opens the envelope (the linked thread read in full, a branch, a route) that `/tack:end` later closes. Where it isn't, do the same work by hand: cut a branch named for the defect, and fetch the linked thread's description and every comment in one call — a `#note_<id>` / `#issuecomment-<id>` fragment is a scroll position, not a scope boundary.

## Phase 1 — Establish the bug is real and current (5-10 min)

Cheap gates, before any diagnosis. Each one can end the session outright.

1. **Confirm the defect still exists on the latest default branch.** `git fetch` and reproduce there, not in whatever is checked out. Do this per repo when suspect code spans repos — staleness is per-repo. A non-fast-forward rejection at push time is the late warning: read `HEAD..origin/<branch>` before forcing through.
   - **Where servicing branches exist, survey every live line and released tag for the call site before choosing a target branch**, and treat the issue's stated versions as a hypothesis — `git log -S "<expression>"` against each ref answers it in one pass. It can add a servicing line the issue never mentioned, and it can rule the default branch out entirely. Put what it found in the change-request description. `references/bug-types.md` covers the harder case: no live branch carries the call site at all.
2. **Search the upstream tracker when the suspect is external.** `gh search issues --repo <owner>/<repo> "<error fragment>"` or `glab issue list --repo <group>/<project> --search "<fragment>"`. A maintainer may have filed it already, with a workaround or a pending fix.
3. **When a prior attempt's change request closed with no review, read the repository timeline, not the CR.** `gh pr view` shows reviews, checks and a state; it cannot show what happened to the repo underneath. `gh api repos/<owner>/<repo>/issues/<n>/timeline` can: a `base_ref_deleted` immediately followed by `closed`, same actor, means routine branch churn took the PR as collateral, not that anyone rejected it. Establish that before re-deriving the fix or answering review comments that were never the reason.
4. **State back what the thread settled before proposing anything.** The user's own replies in it are decisions already made about scope, contract, and versioning.

Then **explain the error before proposing any fix**. One paragraph, plain language, mechanism first. Failing to write that paragraph means the context is still missing — go back and ask.

Treat a user's theory as one hypothesis among the mechanisms the symptom permits, not as the conclusion. When the user describes symptoms only, that is the higher-signal case: form an independent hypothesis from the wire before scanning the codebase.

## Phase 2 — Diagnose (5-15 min)

Reason about candidate mechanisms *before* reading files. A precise symptom — a POSIX errno, an exception class, a syscall — usually has a small enumerable set of causes, and eliminating them from the wire beats grep-driven exploration.

- **When the failing code hasn't changed, the environment is the suspect — diff around the code, not the code.** "Unchanged for weeks" is a signal, not a dead end. Check whether the image or dependency reference is pinned; if it floats, find the version running now versus what last passed and read that delta's release notes. An unpinned reference is a latent-bug detonator: the defect was dormant until the new version published. Pin it as part of the fix.
- **Build the causal chain** from trigger to symptom, each link verifiable by a log line, stack frame, syscall, or config value. Present it — the user spots a wrong link faster than it can be verified.
- **Treat a user correction as the highest-signal input.** Abandon the current hypothesis and restate the updated one in a sentence; don't reconcile the old path with the new information.
- **Read every state you reason from off the thing itself, not off the process meant to change it.** "This host runs the old build", "that job never ran", "the flag is still set" — a pipeline job state, a merge status, or a config default describes *intent*; the running system describes what is. Classifying a node from a deploy job showing `manual` cost three rounds of mechanism reasoning, when the node had been built from the other branch the day before and the branch's own description said so. Each mechanism derived after a wrong premise still looks independently reasonable.
- **Probe the live system when the mechanism turns on runtime behavior the source doesn't settle.** Competing theories all sound plausible; one read of the running system's actual state ends the debate. Reach for the probe before the third hypothesis, not after.
- **When the system under test also gates your tools, the probe is subject to it.** Debugging a hook, a linter, a permission layer, or a sandbox means your probe command runs through the live copy of the thing you're probing — so its refusal arrives in the same channel as the probe's result, and reads as one. Check the *shape* of the output before its content: a plain-text message where the component emits JSON, an error where it exits silently. A probe of a safety hook came back with what looked like a decision and was actually the installed hook denying the probe's own command line, twice, because the payload contained the string being tested. Reshape the probe (write the input to a file, run it via a script) rather than reading the refusal as data.
- **A hedge covers the sentence it sits in and nothing downstream.** Marking a mechanism "my read" or "inference rather than instrumented" and then recommending an edit on top of it still acts on an unverified claim. Either run the probe that would settle the premise, or state the recommendation as blocked on it.
- **Test at system boundaries** to isolate the broken layer. If `dotnet msbuild` fails but `dotnet exec MSBuild.dll` works, the bug is in argument forwarding. If `curl` works but the app fails, the bug is in request construction.
- **Find the regression commit, timeboxed to 15 minutes.** When the symptom names an exact string, `git log -S "<expression>" --all` beats bisect outright. If it doesn't converge, note that and move on — the test harness matters more than a perfect origin story.

`references/techniques.md` expands the last two as worked techniques, and covers verification-as-diagnosis for the live probe.

## Phase 3 — RED, GREEN, REFACTOR (10-30 min)

Expect the fix to take longer than the diagnosis. Fast diagnosis does not predict fast fix.

1. **RED — write a test that fails for the reason the bug exists.** Not a contrived failure; the actual broken path. Name it for the *condition* (`rejects_negative_quantity_in_split_shipment`), never the ticket. Inability to write a failing test means the root cause isn't isolated yet — return to Phase 2. **Announce RED in user-facing text and restate it in the wrap-up summary**, not just inline: the step takes seconds and scrolls away, and reviewers have repeatedly missed a discipline that was genuinely followed.
2. **GREEN — minimal change to satisfy the test.** The RED test is now a fixed target: change production code to meet it, never the reverse. A shrinking assertion, a loosened threshold, or a deleted case in the fix diff is **rewriting the test to pass** — it ships the bug unverified behind a green suite. After green, enumerate input variations; parameterized cases cost nothing.
   - **When the fix has to flip an assertion an earlier commit added, that commit is the scope of a separate audit.** List every test it touched and report each one's status after your run. Regressions from a hardening change are the common case: the existing tests encode the previous author's intent, so proving *which* of them you are and are not contradicting is as much of the work as the code. Say it in the change-request description, where a reviewer meets it before the diff.
   - **A test name states intent; only its fixture states coverage.** Before treating an existing suite as the thing that protects a behavior you're narrowing, read what its fixture actually varies. A suite named for cross-origin credential handling whose test server only ever redirects within one host and port pins the same-origin case and nothing else — and the gap is invisible from the names. What that reading turns up is often the case worth adding.
3. **REFACTOR — do not skip.** GREEN feels like done and orchestrators pull straight into commit and review. Pause for one sentence: "the code is green; is it now the cleanest form?" Check names, leftover diagnosis scaffolds, minimal shape. The later review pass catches test tidying, not production tidying.

Throughout: propose the minimal change first, keep configuration out of hardcoded values, and fix in the right layer — when a bug surfaces in one codebase but the cause is in a shared library, fixing the library protects every consumer. **When shared logic has multiple callers, list each call site and what semantics it wants before proposing a fix; if callers disagree, split intents into named modes rather than unifying them.** Justify any lint suppression with *why the linter is wrong* — a bare suppression invites the next contributor to "fix" it back.

Verify each iteration in the environment that actually fails. For CI-only bugs, drive the poll loop with `run_in_background` so the multi-minute waits stop being a babysitting tax; that affordability is what makes "verify every iteration for real" hold up. The same move pays on any slow local build-and-test loop: launch the build in the background, block on its output, and six rebuilds stop being a reason to skip one.

**Re-run through the same script every time, never a trimmed copy.** A shortened re-run that drops a setup step — publishing test tools, seeding fixtures, starting a stub server — fails the whole suite at `BeforeAll`, and a whole-suite failure right after a code change reads exactly like a regression from that change. One script, re-run, so red means the code.

**When the deliverable is a guard rather than a fix, RED means writing the defect.** A test added to a branch that doesn't have the bug passes on day one, which proves only that it doesn't false-positive. Simulate the defect (apply the change you expect to be ported forward), confirm exactly that test goes red and nothing else moves, then restore. Then **rebuild before the next run**: restoring the source leaves the compiled artifact still carrying the simulated defect, `git status` reads clean, and the next suite comes back red with the failure attributed to whatever you changed most recently.

## Phase 4 — Verify (5-10 min)

1. **Prove pre-existing failures on a clean tree; don't reason your way there from test names.** `git stash -u`, re-run exactly the failing tests against the unmodified base, compare. Identical reproduction earns the "zero new failures" claim.
2. **Verify the surface for any render-contract bug.** Tests verify code; only a person or a screenshot verifies surface. Badge formats, profile JSON, CSS variables, status-bar layouts and dashboard widgets ship broken with a fully green suite. Plan the surface check into the timeline.
3. **When the mechanism lives in a client, reproduce the delivery shape — the server-side assertion is a proxy.** A bug whose cause is browser, runtime, or driver behavior is only half-verified by the thing it talks to: `curl` returning `403` proves the server refuses, not that the attack the reporter demonstrated now fails. Stand up the actual shape — the sandboxed iframe, the mobile client, the old SDK version — and watch it fail, then watch the legitimate caller still succeed. Reasoning from the spec instead is right most of the time and silently wrong the once it matters; `references/techniques.md` has the worked case under Boundary testing.
4. **Sweep for the same bug class before shipping.** Identify the root antipattern rather than the symptom, then grep every file with similar logic — **including config, template, and render-contract files (`.json`, `.yaml`, `.toml`, `.template`)**, since those often carry the canonical value the code-side constant only backs up. **Sweep before grading severity**: the same wrong value can be dormant on one call path and a live bug on another, so impact assigned from the first site is provisional. **Validate the site list against raw source** before editing N files — a grep or parser summary is a hypothesis, and a parser that misreads nesting invents phantom sites. Decide each site explicitly: fix now, file a follow-up, or document why it's safe.
5. **When the fix *is* a check — a guard, a lint, a gate, an assertion — confirm Phase 3's simulate-and-restore actually ran.** A green run on its own is equally consistent with a compliant population and with a check that cannot report anything else. `references/techniques.md` has the ways a green result carries no information, and the bad-input fixture to ship alongside the check.
6. **Review the diff** for side effects and strip debug scaffolding.

## Phase 5 — Communicate (5 min)

Lead the commit message and change-request description with the **root cause**, not the symptom: "Payload validation skipped when Content-Length is 0" beats "Fix 500 error on POST". Include the causal chain and link the regression commit, release notes, and any source that informed the fix — links are the bridge between "trust me" and the evidence. The description must stand alone for a reviewer who reads nothing else.

**Fix the failure-mode sentence once the RED run settles it, then hold every document to it.** "Silently drops the value" and "writes the CLR default over your data" imply different severities and different version bumps; a later document contradicting the RED output means the reasoning drifted off the evidence.

**Don't inherit the reporter's evidence as your own.** A structured bug report arrives with its own probe output — byte counts, status codes, a transcript of the failing call. Those measurements belong to whoever ran them. Where the session verified only the *fixed* build, write that: "the exploit now fails", not "confirmed it succeeded before and fails now". Restating someone else's measurement in the first person is how a chain of confident "verified" claims ends up resting on nobody, and it costs nothing to attribute — the reporter's evidence is often the stronger half, and saying so is not a weaker claim.

Cross-reference the originating deliverable when the bug surfaced during other work, so reviewers see the calling context.

**Run the reproduction one last time and paste the command with what it printed**, so the reader can re-run it without asking what it was.

**Report the machine state the session leaves behind, separately from the diff.** A toolchain installed side-by-side, a package feed added to unblock a restore, a container left running: any of these can be required to build and still belong nowhere near the commit. Reverting the local workaround is right, and it restores the failure for the next session — so a clean tree is not the same as an unchanged machine. Name what was installed and what was reverted at the close.

Where tack is installed, the close is **`/tack:end`** — it reads what actually landed, records the fix against the route, decides whether the session earned a retro, and reports the commands still owed rather than running them. Where it isn't, close by hand: state what landed, what is still owed, and whether the session turned up anything worth writing down.

## When it isn't converging

**Three fixes and the same error means the model is wrong, not the fix.** Stop refining and question the assumption: wrong variable, wrong layer, or wrong error entirely. Say it plainly.

Watch specifically for **more sophisticated wrong fixes** — a more correct measurement, a more elegant abstraction, a more robust observer along the same axis. Cleanness isn't correctness; if the symptom doesn't move, iteration N+1 is the same approach in better packaging.

Past ~90 minutes with no resolution, surface that and propose a reset with refined context.

## Reference files

- **`references/bug-types.md`** — the symptom catalog: framework/SDK upgrades, environment-specific, cross-repo, infrastructure/config history, alerts that never fired, safety gates that fail open, intermittent/flaky. Each with the context to gather and a worked prompt.
- **`references/techniques.md`** — regression bisect and source-string search, verification-as-diagnosis, boundary testing, timing probes, the self-validating test, and proving a check can fail.
