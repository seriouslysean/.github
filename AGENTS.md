# AGENTS.md

Shared templates, community files, the reusable PR body check and ruleset files. See [README.md](README.md) for the layout.

## Before a PR

Run what `.github/workflows/ci.yml` runs:

```sh
shellcheck scripts/*.sh
shfmt -d -i 2 -ci scripts/
bash scripts/check-pr-body.test.sh
```

## Git and PR flow

Follow [CONTRIBUTING.md](CONTRIBUTING.md), including its section on agents and accounts. Check each PR body with `scripts/check-pr-body.sh` before posting.

## Things to know

- Callers pin `pr-body.yml` by commit, so a change here reaches a repo only when it bumps its pin.
- Rulesets are applied by the owner, who has admin. `rulesets/apply.py` prints without `--apply`; never pass `--apply`.
- Docs are plain and short. `docs/repo-standards.md` is the reference for repo rules.
