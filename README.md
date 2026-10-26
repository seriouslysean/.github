# .github

Shared community files for this account's repositories: the PR and issue templates, `CONTRIBUTING.md` and `SECURITY.md`, which repos without their own copy inherit. It also holds the reusable PR body check, the ruleset files and the repo standards.

## What's here

| Path | What it is |
|---|---|
| `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` | Default templates |
| `.github/workflows/pr-body.yml`, `scripts/check-pr-body.sh` | The PR body check repos call from a workflow |
| `rulesets/` | Ruleset files and `apply.py`, which applies one to a repo |
| `docs/repo-standards.md` | How repos here are named, set up and kept tidy |

## Get started

Check your changes the way CI does. You need [ShellCheck](https://www.shellcheck.net/) and [shfmt](https://github.com/mvdan/sh):

```sh
shellcheck scripts/*.sh
shfmt -d -i 2 -ci scripts/
bash scripts/check-pr-body.test.sh
```

Check a PR body before posting it: `bash scripts/check-pr-body.sh owner/repo main <pr.md`.

## Links

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Repo standards](docs/repo-standards.md)
