# Feature-session patterns

What has repeatedly worked, and what has repeatedly failed, across past
feature sessions. Consult while working — most entries decide a specific
fork rather than describing a phase.

## Working style

### Backseat driving

The user directs; the agent implements every line. The user stays in architect
mode and spends their effort on prompt text instead of code, so vague prompts
produce vague output and specific ones produce specific output.

**Works for:** integration work (CI/CD, multi-file coordination); boilerplate-
heavy tasks (scripts, config, docs); unfamiliar territory where the agent has
the patterns and the user has the intent; well-defined features on settled
architecture.

**Doesn't work for:** debugging, where the user reasons through it themselves;
novel or creative solutions with no existing pattern to draw from, where the
result drifts; code simple enough that typing it is faster than describing it;
exploration where the user doesn't yet know what the solution looks like.

When the user writes more prompt text than the resulting code, the pattern is
working. It also compounds — later sessions move faster as the user's prompts
sharpen and the codebase's conventions become known.

### State the goal, not the steps

"Add API compat testing" is a complete instruction. Don't wait for "write a bash
script that downloads NuGet packages and runs apicompat" — figure out the *how*
and surface the trade-off, not the request for permission.

### Show, don't tell

Existing codebase patterns are better context than descriptions of them. Read
the interfaces and type conventions directly rather than asking the user to
narrate them. Where an external API is involved, connect to the live definition
(Swagger/OpenAPI) rather than guessing at endpoints.

### Do it now, start rough

Implement incrementally: basic first, capabilities added iteratively. A preview
starts as confirm/abort and gains editing later; error handling starts basic and
gains command display and log paths. Get to functional code fast — the first
functional iteration is often surprisingly complete.

### Surface additional opportunities

While implementing, watch for automation the user hadn't considered — deriving a
value that was going to be typed, pivoting to a better fit than the original
approach. Propose it explicitly rather than silently expanding scope.

### Delegate the tedium

MSBuild XML, zsh completion, regex, YAML indentation, CI config: formats where
humans make constant mechanical errors and the mechanical tax for an agent is
essentially zero. For GitLab CI this includes `!reference [.shared, rules]`
directives, `extends:` chains, and dropdown variable definitions (`value:` +
`options:` + `description:`).

## Deciding with the user

### Two-option design sign-off

When a design choice has a clear top two, present exactly two alternatives with
a one-sentence trade-off each rather than asking an open-ended "how should I do
this?". The user replies with a single character and implementation begins.

Reserve it for genuine choices: when there's one reasonable answer, just propose
it; when there are five, pick the top two and ignore the rest. The user's reply
is often a *third* option hybridizing the two anchors — that's the framing
working, not failing.

### Front-loaded scope contract

For a multi-commit feature session, four single-select `AskUserQuestion`s at the
start (each 2-4 options with concrete trade-offs) can drive the whole
implementation without revisits. It requires real options with distinguishable
trade-offs — and when one genuine answer is "skip this entirely", surface that
as an option rather than letting the framing implicitly endorse "yes,
somewhere".

### Collapse planned artifacts mid-build

An issue decomposes work into N artifacts *before* the design is explored; that
count is a hypothesis, not a spec. When the user asks "why N?" — "why a separate
read-only skill?", "is a distinct bootstrap skill obvious, or a `--init` mode?"
— treat it as a prompt to collapse, not to defend. In one session three such
questions turned a planned three-skill-plus-flag decomposition into two skills,
one deletion, and one new mode: smaller, and one fewer future drift surface. The
compression is cheapest while the pieces are still fluid. Resolve each fork with
a single `AskUserQuestion`, and expect the answer to be a hybrid.

## Shaping the API

### Split the verb from the noun

When a new capability is the operational counterpart of an existing command
(file↔find, create↔select) and the same word's singular and plural mean
*different* operations, ship two focused commands rather than one command with a
`--mode` flag. anchor's `/issues` (find and rank the next issue) scoped the
plural to *selection* and reframed `/issue` toward *filing* one — the English
pair carries the semantics for free. This is **compose, don't duplicate** at the
command-naming layer.

Declare the topology in the *opening prompt* — cheaper than building one
overloaded skill and refactoring it into two — and give the two faces one
requirement-ID prefix in the spec, since they're two views of one capability.
Don't force the split when the capability genuinely is one operation with
parameters.

### Fast path as a separate subcommand

When adding a fast-path companion to an existing slow command, prefer
`tool fast-cmd` over `tool cmd --fast`. A separate subcommand shares no dispatch
or parsing code with the slow path, which eliminates future drift and makes the
"skip the expensive work" guarantee structural rather than conventional.

### The override belongs in a flag, not a middle positional

When a smart default (auto-derived value, computed fallback) replaces what was a
positional argument, the explicit override is now the exception — so it belongs
in a flag (`--label <text>`), not wedged back into the positional list. An
optional positional sitting *before* a required one (`cmd <a> [<b>] <c>`) forces
count-based disambiguation and reads badly.

The unlock when review challenges a signature is the author's own question
"what *is* the default?" — answering it usually shows which argument is rare
enough to be a flag. Engage the design on its merits rather than defending the
form that already passed tests: that a shape already exists, follows convention,
or has a precedent describes what is, and is not evidence it is right.

### Remove the escape hatch when fixing silent magic

When a change removes surprising behavior, the instinct is to preserve it behind
an opt-in flag (`--promote-if-empty`, `--legacy-behavior`). Resist. The flag
invites the same surprise to recur through scripts that opt in once and forget
why, and both code paths stay in everyone's head forever. The asymmetry favors
removal: a flag can be added back if a real use case appears, but a shipped API
contract is much harder to withdraw.

### Per-instance signal over per-stem heuristic

When a system classifies workloads by template, cluster, or AMI name (a
"stem-name regex") and the truth actually lives on the running instance, the
migration shape is reliable: add the per-instance signal to the data layer;
split the consuming pivots so the existing class and the new one go down
separate paths; demote the legacy heuristic to a visual-only signal (badge,
filter) rather than deleting it. Spec drift is the tell — if the spec says
"per-instance" and the code says "per-name", the spec is usually right and the
code is calcified.

## Keeping the change reviewable

### Spec as part of the diff

When a project has named requirement IDs (CLI-N, SES-N), update the spec
alongside the code in the same commit, not as a follow-up. Drift between spec
and code is cheap to introduce and expensive to find.

### Multi-agent review for invariant-introducing diffs

When a change introduces a new invariant — a function now promises "this URL is
in exactly one place", "this command would resolve your error" — single-pass
review tends to miss violations because one reviewer doesn't hold every angle at
once. Five parallel finder agents at xhigh effort (line-by-line, removed-
behavior, cross-file tracer, language-pitfall, wrapper/proxy) caught three real
correctness bugs in a diff whose tests had just passed, at roughly $30 of agent
context. The overhead earns itself specifically on newly-introduced invariants;
purely additive changes that restate no invariant don't need it.

### The review bottleneck

A session can produce hundreds of lines across many files. Surface the volume to
the user proactively so they can budget review time, rather than delivering it
as a surprise.

### Wiring indexes before the artifact set settles

On a session expected to add, rename, or remove several artifacts (skills,
modules, commands), don't update the README, sidebar, and index listings per
artifact as you go. A skill wired into three index files and then renamed after
a consolidation decision makes every one of those edits rework. Index updates
are the *last* edit, not a per-piece one.

## Recurring failure modes

- **Scope creep.** Multi-feature sessions invite "while we're here" expansions.
  One feature at a time, each verified before the next.
- **Over-engineering.** Build what's needed now. No extra parameters or error
  handling "just in case".
- **Deleting configuration without grepping the consumer side.** When scope
  options include "drop the env var / hook / callback / global default", grep
  the *consumer-facing* invocations (`dotnet test`, `npm run`, the real entry
  points) before presenting the choice. Implicit registration — env vars that
  activate behavior when no explicit flag is passed, hooks that register
  handlers globally — is invisible in the diff but load-bearing for some call
  patterns, and only a real consumer pipeline catches it.
- **Idle context burn.** Pauses for CI, code review, and unrelated
  interruptions consume the context window without adding anything, so
  compaction arrives earlier and takes debugging nuance with it. Persist
  decisions to CLAUDE.md so continuations don't lose them.
- **Undoing a probe with a whole-file restore.** Mid-refinement, a one-line
  `sed` gets planted to prove a guard fires, and `git checkout <path>` is the
  reflex for putting it back. That command reverts the *file* to `HEAD`, so in a
  file already holding the session's uncommitted work it discards all of it —
  a README lost its new schema sample and a whole authored section this way, and
  the test that would have caught the loss skipped quietly because the content it
  validates was gone. Reverse the probe by naming it (a `sed` undoing the same
  substitution, or restoring from the value in context) and keep whole-artifact
  restores for a file whose entire delta should go.
