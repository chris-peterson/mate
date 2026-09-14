# Techniques

The diagnostic moves worth reaching for by name, each with the case that established it.

## Find the introducing commit

**Prefer source-string search when the symptom names a string.** An exact error message, a cast operator, a unique expression — `git log -S "<exact-expression>" --all` returns the introducing commit directly, no bisect. A regression hunt found a broken cast in seconds with `git log -S "[hashtable] (,$GitlabVars)"`, and got the *why* alongside it: a PSScriptAnalyzer rule.

**Otherwise bisect, timeboxed to 15 minutes.** `git bisect` or manual history inspection collapses "something is broken" into "this diff broke it", and the diff usually carries the reason — a refactor that missed an edge case, a dependency bump with changed behavior, a config change with unintended scope. The commit routinely makes the fix obvious on sight: a `-State` default changed from empty to `all`. Past 15 minutes without convergence, or where the behavior was always wrong, stop — the test harness is worth more than a perfect origin story.

Link whatever is found in the change request so reviewers see the whole causal chain.

## Make RED provable, and visible

**Visible.** RED can take seconds and scrolls away. Announce it ("Step 1/3: confirming RED — running tests…"), report the failure summary ("6 failures, all matching the reported error"), and **restate it in the phase or wrap-up summary** where a reviewer arriving later actually looks: `RED confirmed (N tests fail against current code) → GREEN (all pass with the fix)`. Real-but-invisible is the recurring failure — on one fix the discipline *was* followed and two independent parties still missed it.

**Provable retroactively.** When asked "if you comment out the fix, do the new tests fail?", answer with evidence. Restore only the production file to its pre-fix state, run the new tests, watch the intended cases fail, then restore:

```bash
git show HEAD~1:<file> > <file>
# run the new tests — they should fail
git checkout HEAD -- <file>
# re-run — green
```

The tests stay in place; only the fix rolls back. Done once on demand, it turns a fix-now review comment into a settled verification in about 30 seconds.

**Label honestly.** Revert-and-confirm proves the tests are load-bearing. It does not make the work tests-first if the fix and tests were written together. Both are legitimate — say which one happened.

## Verification-as-diagnosis

Before committing to a fix, propose a quick test that confirms the root cause. Look for configuration that can be commented out, a flag to toggle, a code path to short-circuit. A confirmed hypothesis makes the fix zero-risk, and 30 seconds of verification always costs less than a wrong fix.

- **"X isn't running" is usually false — prove it with a 4-line debug log.** Hooks, callbacks, hot-path code, and event handlers are generally firing; they write somewhere unexpected, see different state, or arrive in a different order. The log shim costs one edit to add and one to remove. Disprove "isn't running" before designing around it.
- **Once the mechanism is understood, instrument to count the affected population.** Which inputs hit this state, and how many? That is the question the fix actually turns on — guard-and-continue versus hard-fail — and enumerating the cases routinely exposes an adjacent latent bug. Counting AMIs with a null launch-permission collection returned "11 of several hundred", low enough to justify a guard, and the enumeration surfaced a third pre-existing bug on the way.
- **"No integration exists" / "X has never worked" — exercise it directly first.** The framing implies a missing code path, but the path often exists and simply never fires because the data it consumes is rarely populated. Seed the data, invoke the entry point, see what comes out. A reported-missing integration once worked within minutes of being called directly; the real gap was the data layer.
- **When upstream describes a change's scope, verify by experiment rather than re-reading the description.** Upstream writes from its own perspective — what changed — not from yours: what now breaks, and where. One upstream commit framed the change as a consequence of running as an unprivileged user, but `docker run --user 0:0 --cap-drop=ALL …` reproduced the same `EPERM`: UID was incidental, the missing capability was the trigger.

## Boundary testing

When layers are chained — CI, Docker, SDK, framework, application code — test each boundary in isolation and let systematic subtraction find the broken one.

- Strip layers one at a time. `dotnet msbuild /p:Foo=bar` failing while `dotnet exec MSBuild.dll /p:Foo=bar` works puts the bug in argument forwarding, not MSBuild.
- For API bugs, bypass the app and call the endpoint with `curl`. Working `curl` puts the bug in request construction; failing `curl` puts it in the API or the credentials.
- For container bugs, mount the repo into the container and run the exact CI command.
- **For binary distribution channels, test each channel separately.** The same upstream version obtained different ways can differ: file capabilities survive `COPY --from=<image>` but not a zip download. One case isolated exactly this — `COPY --from=hashicorp/vault` propagated `setcap cap_ipc_lock=+ep` while the releases-server zip did not.

The more layers between the observer and the failure, the more this pays.

## Timing probes

Manipulate the interval instead of guessing at it.

- **Shorten to expose.** A timer or polling interval that never fires locally because tests finish too fast will reproduce immediately at 1 second. A bug that only appears in 14-second CI runs becomes reproducible anywhere.
- **Crank concurrency to expose races.** A test that fails occasionally with 2 parallel workers turns into a near-certain reproduction at 20.

Applies to any bug involving timers, timeouts, polling, races, or async work where the failure depends on duration or concurrency.

## The self-validating test

When a bug ships alongside a green suite, suspect a test that **supplies the very input whose real-world value is the question**. A test that sets an environment variable itself and then asserts the code read it validates the code's assumption, not the contract — it shares the bug's wrong premise, so it stays green while the feature is dead.

**Spot it** by reading the test that *should* have caught the bug and asking where the input comes from. If the test injects the value — sets the env var, stubs the config key, hardcodes the field name — rather than exercising the real source, it cannot detect a mismatch between the code's belief and reality.

**Fix it** by pointing the test at the real contract. A unit test that set `CLAUDE_SESSION_ID` and asserted the pin captured it stayed green while the code read a variable the harness never populates; asserting the real harness variable is what makes the suite defend the contract instead of the code's mistake about it.

A test that asserts its own premise is claiming verification without verifying. Suspect it for any bug that coexists with passing tests over environment variables, config keys, feature flags, or API field names.

## Prove the check can fail

A check reporting green across every input is equally consistent with a population that complies and with a check that cannot report anything else.

**Name the input that would make it fail, then feed it that input and watch it fail.** If you can't name one, it isn't a check yet. Ship the failing fixture alongside the check, or the first real violation is also the first run of the branch that handles it.

Three ways a green result carries no information:

- **Blind by construction.** Ask which components the check exercises and whether the suspect is among them before treating a pass as a discriminator. A `--dry-run` that passed twice proved nothing about a failure caused by the repo's own `pre-commit` hook, because dry runs don't execute hooks.
- **A checker that shares its repair's blind spot certifies nothing.** If the audit and the fix model the file the same way, the audit confirms the fix ran and says nothing about whether it was right.
- **A negative search result is a claim about your query as much as the data.** A grep for a JSON key written with a space after the colon could never match — the writer emits no space — so its empty result carried nothing. Show the positive form exists in the data before reading an absence as a finding.

**Verify fixture attribution by perturbation, not by re-reading.** Rebuild the failing case, fix *only* the intended violation, and confirm the check flips to pass. A fixture that differs from its compliant twin in two ways can return `fail` for the wrong reason, and that failure looks exactly like a negative proof.
