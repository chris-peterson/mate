# Bug Types

A symptom catalog. Match the reported symptom to a section, gather the context it names, and start from that section's angle rather than from a generic read of the code.

## Framework / SDK upgrade

**Symptom:** works on the old version, breaks on the new one.

Gather the exact version numbers on both sides, the release notes or breaking-changes page, and the behavioral difference. The version pair is the whole diagnosis surface — without it the search space is the entire framework.

```
We upgraded from .NET 8 to .NET 9 and tests started crashing. Here's the error:
[error]

I suspect the SDK behavior changed. Can you:
1. Check .NET 9 release notes for breaking changes
2. Explain what changed and why it breaks our code
3. Suggest a fix that works with .NET 9
```

## Environment-specific

**Symptom:** works locally, fails in CI / staging / prod.

Gather OS, architecture, container-vs-native, configuration differences, dependency versions per environment, and timing differences — CI is often slower, so timers and timeouts behave differently there.

```
Tests pass locally (macOS ARM64) but crash in CI (Ubuntu x64). Error:
[error]

Environment differences:
- Local: macOS 14.7, ARM64, .NET SDK 9.0.100
- CI: Ubuntu 24.04, x64, .NET SDK 9.0.101

What platform-specific issue could cause this?
```

## Cross-repository

**Symptom:** the bug manifests in one codebase, the root cause lives in a shared library or dependency.

Escalate context progressively. Start with the app exhibiting the bug plus the library where the cause likely sits; if that stalls, add a *working* app that does not exhibit the bug, which gives a diff to reason about.

```
Swagger toolbar buttons make successful HTTP requests but nothing happens in the UI.

Two repos are relevant:
- This service (adpsitemaps-service) — where the bug manifests
- The shared library (aspnetcore) — where the toolbar code lives
```

### When no live branch carries the call site

Stop before drafting the fix again and ask what the reachable branch *can* carry. In a project that releases from a private repo, the public `release/*` branches are pushes for the drop and get deleted afterwards, so an affected line can have no branch at all — check whether a branch holds commits beyond its released tag, because one that is *exactly* the tag has nothing on it.

The durable artifact is then usually a **test on the default branch**: one that passes today and fails the moment the defect is ported forward. It needs no product change, targets a branch that exists, and is a shape maintainers merge. Post the finished patch itself on the issue thread, one labelled diff per affected line, each stating its base and whether it was actually built.

## Infrastructure / configuration history

**Symptom:** the question is "when did this stop working, and why?" rather than a stack trace — a stale-looking config reference, a service behaving unexpectedly, no certainty it ever worked in this environment.

Gather the repo where the *configuration* lives (not the app repo), the specific resource names, and which environments matter.

```
In the [repo] repo, trace the full git lifecycle for each of the following [services/configs].
For each: (1) did the file ever exist in [environment path]? (2) if so, what commit added it
and when? (3) what commit removed it and when? (4) which environments have it today?
Report as a table with columns: Item | Status | Since | Age | Exists In.

Items: [list]
```

Front-loading the complete list and the desired output format collapses several back-and-forth rounds into one response. **Run this in a concurrent session** — forensics is self-contained, needs no knowledge of why the investigation started, and keeps the primary context clean. One forensic pass traced 5 services across ~90 months of history in 21 minutes this way.

## Alerts / automation that never fired

**Symptom:** a rule, alert, webhook, or scheduled job exists but has never produced output, and the silence went unnoticed until the thing it watched changed state.

Two independent failure modes, frequently both present:

1. **Wrong event semantics.** Does the chosen event fire in the scenario that matters? A failure alarm stays silent when the process succeeds, by design — so downstream action following a *successful* automated step never triggers off a failure event. Check the provider docs for what the event signals and when in the lifecycle it fires.
2. **The pattern never matches.** Declarative matchers — EventBridge patterns, alert routing rules, label selectors — are not validated against real event schemas. A filter naming a field the event doesn't carry matches nothing, forever, silently. Diff the deployed pattern against the documented event shape field by field.

Gather the deployed rule definition itself (not a description of it), the outcome expected to trigger it, and the provider documentation for the event source. A certificate-renewal alert that never fired had both modes at once.

## Safety gates that fail open

**Symptom:** a pipeline or deploy completed successfully having skipped a check meant to gate it — a test job, an approval, a validation step — and nothing errored. The gate didn't fail; it was absent.

**The mechanism is two reasonable choices composing into a hole:** the consumer references the gate *optionally* (`needs: {optional: true}`, a soft dependency, a skip-if-missing lookup), and the gate itself is made not to exist on some trigger paths (a `rules:` clause, `when: never`, a conditional definition). On any path where the second removes the job and the first tolerates its absence, the gate vanishes silently. Audit every trigger path where a safety job's rules resolve to no-job, not just the paths where it runs.

**Why these surface now.** The hole usually sits on a path humans rarely walk — an `api`-source CI exemption is invisible while the API path belongs exclusively to automation. The moment a skill starts driving that path routinely, the latent hole becomes reachable on an ordinary errand. Treat automation-only code paths as untested until proven otherwise, and diff the resolved job set of an automation-triggered pipeline against a human-triggered one before trusting it.

**Suspect an overloaded discriminator.** When the exemption keys on something like `$CI_PIPELINE_SOURCE == 'api'`, check whether that one value means two different things. When one signal serves two intents that have diverged, stop conflating them rather than stacking on another condition.

**Find the exemption's original reason before removing it.** A `when: never` that looks obviously wrong was usually deliberate. `git blame` the rule and confirm the justification is obsolete — engage why the guard exists rather than keeping or removing it on appearance.

## Intermittent / flaky

**Symptom:** sometimes works, sometimes fails.

Gather the frequency (1 in 10? random?), any pattern (time of day, load, test order), and whether threading or async code is involved. Ask specifically about race conditions, shared state, and non-deterministic ordering — then force reproduction with the timing probes in `techniques.md` rather than waiting for the flake to recur.
