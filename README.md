# mate

**mate** plugins to combine capabilities.

![Claude Code](https://img.shields.io/badge/Claude%20Code-%23D97757.svg?logo=claudecode&logoColor=white)
![GitHub top language](https://img.shields.io/github/languages/top/chris-peterson/mate)
![GitHub Release](https://img.shields.io/github/v/release/chris-peterson/mate?sort=semver&display_name=release&logo=github&label=latest)

An event hub for the bridge.ai plugins: reacts to what each one announces, and
names what to run next.

**[Docs →](https://chris-peterson.github.io/mate/#/)**

```bash
claude plugin marketplace add chris-peterson/claude-marketplace
claude plugin install mate@chris-peterson
```

| Skill | For |
|---|---|
| `/mate:fix` | a defect whose cause isn't known yet — root cause, a test that fails for the reason the bug exists, then a sweep for the same bug class |
| `/mate:feature` | a capability an existing codebase doesn't have — the constraints, the repo's own patterns, verification against real feedback |

On entering a phase, a hook emits one line naming the phase after it. That line
is a suggestion; you type the next command, or you don't. Nothing in mate
invokes the next phase on its own.

## Composes with

`/tack:start` → **`/mate:fix`** or **`/mate:feature`** → `/anchor:commit` →
`/anchor:prepare-review` → `/anchor:review` → `/anchor:merge` →
`/anchor:release` → `/tack:end`

[tack](https://github.com/chris-peterson/tack) supplies the envelope the work
opens and closes in; [anchor](https://github.com/chris-peterson/anchor) supplies
the commit, change-request, merge, and release phases. Both are optional. A bare
`mate` install runs both skills start to finish, and each step that names a
sibling says what to do when it isn't installed —
[Composing with the siblings](https://chris-peterson.github.io/mate/#/guides/composing-with-siblings)
is the full contract.

## Development

See [AGENTS.md](./AGENTS.md).

## License

MIT
