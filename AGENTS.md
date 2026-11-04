# AGENTS.md

Shared templates, community files, standards and ruleset files. See [README.md](README.md) for the layout.

## Git and PR flow

Follow [CONTRIBUTING.md](CONTRIBUTING.md), including its section on agents and accounts.

## Things to know

- Rulesets are applied by the owner, who has admin. `rulesets/apply.py` prints without `--apply`; never pass `--apply`.
- Docs are plain and short. `docs/repo-standards.md` is the reference for repo rules.
- seriouslysean/.github mirrors this repo. Never open a PR there. After each merge here, fast-forward its `main` as [README.md](README.md#mirror) says.
