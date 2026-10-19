# Repo standards

How repositories on this account are named, set up and kept tidy.

## Names

Follow any naming rules required by GitHub or the course, site or package you use. Otherwise:

- Use lowercase words with hyphens.
- End website names with `-site`: `splitleaf-site`.
- Start demos, examples and lessons with `learn-`: `learn-vue-3-usefetch`.

Name the local clone folder after the repo.

## Descriptions and topics

- **Description:** one short, factual sentence: "A/An <thing> for <purpose>." Framework names go in topics.
- **Topics:** 3–6 common, lowercase topics for the language, framework, platform or subject.

## Issues and pull requests

- Title commits and pull requests `type(scope): summary`. The scope is optional.
- Types:

  | Type | For | Issue first? |
  |---|---|---|
  | `feat` | new behavior | yes |
  | `fix` | a bug | yes |
  | `refactor` | same behavior, reshaped or faster | yes |
  | `docs` | docs only | no |
  | `chore` | everything else: dependencies, build, CI, tests only, settings, lint | no |

  These are a subset of the Conventional Commits types (commitlint's `config-conventional`). Use a scope to tell kinds of `chore` apart, like `chore(deps)` or `chore(ci)`.
- Branch from `main` as `<issue>-<slug>`, or `<type>/<slug>` when there's no issue.
- A pull request with no issue says why on the template's issue line, like `No issue: chore`.
- Use the issue and PR templates.
- Repos on GitHub, public or private, track issues in GitHub Issues. Cairn trackers are only for repos that live on this machine with no GitHub remote. Revisit once Cairn can sync with GitHub.
- Agents using `gh`: fill out the template and pass the completed file with `--body-file`.

## Labels

Use only GitHub's default labels and labels added by Dependabot.

## Docs

- Keep a short root `README.md`: what it is, how to start and links to `docs/`.
- Put other docs in `docs/`, with a lowercase `d`, wherever tools support it.
- Keep `LICENSE`, `AGENTS.md` and `CLAUDE.md` at the root. Other files belong there only when tools require it.
- Keep code-folder READMEs with their code.
- Put agent instructions in `AGENTS.md`. Make `CLAUDE.md` point to it.

## Settings for active repos

- **Merging:** squash only. Set the default commit subject to the PR title and the message body to the PR description. Delete branches after merging.
- **Off:** Projects, wiki, merge commits and rebase merging.
- **On:** Issues, auto-merge for public repos and "Always suggest updating pull request branches."
- **Actions:** set the workflow token to read-only by default. Grant extra access through `permissions:` only where needed. Pin actions to full commit SHAs, with versions in comments.
- **Public repo security:** secret scanning, push protection and private vulnerability reporting on.
- **Dependabot:** alerts on, with weekly grouped version updates for Actions and supported packages.

## Checks

- Every repo with code runs the same CI jobs on pull requests: `lint`, `typecheck` (typed code), `test`, and `build` (anything that ships).
- Use each framework's own tools the way it expects, like `astro check`, `tsc`, SwiftLint, ruff, shellcheck or gofmt.
- End-to-end tests use Playwright.
- Every job sets `timeout-minutes`, sized to the job: about 5 for bot jobs, 10–15 for lint, typecheck and test, 30 for build and E2E.
- A new push cancels that pull request's older runs.

## Branch protection

- Every public repo gets one ruleset on the default branch, from `rulesets/default-branch.json`: pull request required with 0 approvals, squash only, no force pushes, no deleting the branch. Repo admins can bypass.
- Add the repo's CI jobs as required status checks, not strict. Do it once `ci.yml` exists, so a green check means the real jobs ran.
- Apply it with `python3 rulesets/apply.py <owner/repo> [--check NAME ...] [--apply]`. Without `--apply` it only prints.
- Private repos on the Free plan can't have rulesets or protection. Public repos can.
- Auto-merge waits only on required checks. A repo with the ruleset but no required checks merges as soon as a pull request exists, so a workflow that merges must wait for CI itself.

## Licenses

Use MIT for code. Posts, photos, game assets and other non-code content keep their own rights. Note these exceptions in `README.md`.

## Outside sources

Follow the rules of the courses, sites and packages you use, including what you may publish.

## Archiving

Archive repos that are finished but worth keeping:

1. Close open issues and pull requests.
2. Disable workflows and Dependabot. Delete `.github/dependabot.yml`.
3. Delete webhooks, secrets, variables, deploy keys and extra environments.
4. Keep or unpublish the Pages site. Remove unused custom domains from Pages settings, any `CNAME` file and DNS records you control. Remove stale homepage links.
5. Archive the repo.

To change an archived repo, unarchive it, make the change and archive it again. Delete repos with nothing worth keeping.

Do not keep forks.
