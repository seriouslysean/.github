# .github

Shared files for this organization's repositories: the PR and issue templates, `CONTRIBUTING.md` and `SECURITY.md`, which repos without their own copy inherit. It also holds the org profile, the repo standards, the testing rules, the shared Dependabot workflow and the ruleset files.

## What's here

| Path | What it is |
|---|---|
| `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` | Default templates |
| `.github/workflows/dependabot-auto-merge.yml` | The shared Dependabot auto-merge workflow |
| `docs/repo-standards.md` | How repos are named, set up and kept tidy |
| `docs/testing.md` | The testing rules |
| `rulesets/` | Ruleset files and `apply.py`, which applies one to a repo |
| `profile/` | The organization profile |

## Mirror

[seriouslysean/.github](https://github.com/seriouslysean/.github) is an exact mirror of this repo, because GitHub gives a `.github` repo's default files only to repos with the same owner. Change files here only. After each merge, push this repo's `main` to the mirror as a fast-forward:

```sh
git push https://github.com/seriouslysean/.github.git origin/main:refs/heads/main
```

A refused push means the mirror drifted; find out why before doing anything else. A user account's profile comes from its own profile repo, so `profile/` does nothing in the mirror.

## Links

- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)
- [Repo standards](docs/repo-standards.md)
- [Testing](docs/testing.md)
