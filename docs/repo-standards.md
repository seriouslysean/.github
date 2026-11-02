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
- The root `README.md` has one sentence on what it is, a "Get started" block (install and the check command), links into `docs/` with a line on each, and a license line last. No copied tables or counts that go stale. Keep it short; past about 60 lines, look for what can move to `docs/`.
- Track work in GitHub Issues, not Markdown backlogs or idea files. A plan file for a build in progress says when it gets deleted.
- Keep one home for release notes: GitHub release notes by default, or `docs/changelog.md` with `## X.Y.Z - YYYY-MM-DD` headings. Say which in `docs/` or `AGENTS.md`. Apps and sites don't need one.
- A repo uses the shared contributing guide, security policy and templates unless it needs its own. A local copy says only what is different and why, and never contradicts squash merging.

## Commands

- Every repo with code has one check command: an executable `scripts/check` with no file extension. It runs everything CI runs, prints one short `ok` or `FAIL` line per step, shows full output only for failures, and exits nonzero if any step failed.
- In Node repos, `scripts/check` calls the package.json scripts. Use these names where the repo has the job: `dev`, `build`, `lint`, `lint:fix`, `format`, `format:check`, `typecheck`, `test`, `test:e2e`. Never `type-check`.
- Install with `npm ci`, never `npm install`. OpenClaw plugin repos use `npm ci --ignore-scripts`.
- Keep scripts in lowercase `scripts/`. Don't add a second task runner. An existing Makefile or justfile calls `scripts/check`.
- Git hooks are optional. They call `scripts/check` or a named part of it, and CI runs everything a hook runs. Keep hooks in a committed place (`.githooks/` or `lefthook.yml`) and say how to turn them on. Don't add a new hook tool without a reason.
- Xcode apps: `scripts/check` is the full local check, macOS build and tests included. CI runs a named portable part of it on Linux, like `scripts/check --portable`.

## Agent instructions

- `AGENTS.md` at the root is the one source of agent instructions. `CLAUDE.md` starts with `@AGENTS.md` and may add lines only Claude needs, never a copy of `AGENTS.md` rules. A `CLAUDE.md` symlink changes to the import when the repo is next touched. Other agent files only point to `AGENTS.md`.
- `AGENTS.md` names the install command and the command that must pass before a pull request, and says where things live.
- It links [CONTRIBUTING.md](../CONTRIBUTING.md) instead of copying the branch and pull request steps, and lists only what this repo does differently, with the reason.
- If it tells agents to commit or post, it says which account they act as.
- It holds only what an agent can't learn from the code. No personal names, dated incident notes or emoji headings. Longer reference goes in `docs/`.
- Tools and MCP servers that agents run are pinned to an exact version, never `@latest`.

## Settings for active repos

- **Merging:** squash only. Set the default commit subject to the PR title and the message body to the PR description. Delete branches after merging.
- **Off:** Projects, wiki, merge commits and rebase merging.
- **On:** Issues, auto-merge for public repos and "Always suggest updating pull request branches."
- **Actions:** set the workflow token to read-only by default. Grant extra access through `permissions:` only where needed. Pin actions to full commit SHAs, with versions in comments.
- **Public repo security:** secret scanning, push protection and private vulnerability reporting on.
- **Dependabot:** alerts on, with weekly grouped version updates for Actions and supported packages.

## Checks

- Every repo with code has one workflow, `.github/workflows/ci.yml`, named `CI`. Its jobs are `lint`, `typecheck` (typed code), `test` and `build` (anything that ships), plus `e2e` where there are end-to-end tests. A repo whose checks are one script runs it as one job named `test`.
- A job never sets a `name:` that differs from its id. Required checks and other workflows key on these names.
- Jobs call the repo's own scripts instead of repeating tool commands and flags.
- Run on pull requests and on pushes to `main`. Add `workflow_dispatch` when people or other workflows start it by hand, and never remove it without checking what starts it. A job-level `if:` must allow every trigger the workflow has.
- Set `permissions: contents: read` at the top. A job that needs more asks for it itself.
- Every job sets `timeout-minutes`, based on how long it really takes, with room to spare. Jobs that call a reusable workflow are exempt.
- Pull request runs share a concurrency group per workflow and pull request (`${{ github.workflow }}-${{ github.head_ref }}`) and cancel older runs. Other runs get their own group (`${{ github.run_id }}`), so a run on `main` is never replaced.
- Every `actions/checkout` sets `persist-credentials: false` unless the job pushes.
- Use one Linux runner, `ubuntu-latest`, in every Linux job. macOS jobs pin a version, like `macos-15`.
- Use each framework's own tools the way it expects, like `astro check`, `tsc`, SwiftLint, ruff, shellcheck or gofmt.
- JavaScript and TypeScript lint with oxlint and format with oxfmt, replacing ESLint and Prettier. Commit `.oxlintrc.json` with warnings denied and `.oxfmtrc.json`. `format:check` runs in the `lint` job. Keep Prettier only for a file type oxfmt can't format yet, named in `AGENTS.md`.
- TypeScript repos have a `typecheck` script: `tsc --noEmit` in strict mode, or `astro check` plus `tsc -p tsconfig.tests.json --noEmit` in Astro sites.
- Unit tests use Vitest; `node:test` is fine in repos with no dependencies. End-to-end tests use Playwright. A repo with no tests yet has a smoke test: the build works and one file loads.
- Node is 24 or newer. `.nvmrc` pins the major (like `24`), and `engines.node`, if set, is a `>=` floor on that major. `actions/setup-node` reads `.nvmrc`, sets `check-latest: true` so CI gets patch releases the runner image hasn't cached yet, and caches npm.
- Renaming a workflow: required checks match job names, not workflow names, so only update what listens for the old workflow name (`workflow_run` triggers, docs), in the same pull request.
- Renaming a job that a ruleset requires takes two pull requests, because a required check that stops reporting blocks every pull request with "Waiting for status to be reported":
  1. Keep the old job and add the renamed one beside it, with anything that listens for it accepting both names. Merge.
  2. Once the new name has run on `main` (GitHub only offers checks that passed in the last seven days), add it to the ruleset, check that a new pull request shows both passing, then remove the old name.
  3. Delete the old job and every reference to its name. Merge, then compare the ruleset with `ci.yml`.

## Branch protection

- Every public repo gets one ruleset on the default branch, from `rulesets/default-branch.json`: pull request required with 0 approvals, squash only, no force pushes, no deleting the branch. Repo admins can bypass.
- Add the repo's CI jobs as required status checks, not strict. Do it once `ci.yml` exists, so a green check means the real jobs ran. A job left out needs a one-line reason.
- Apply it with `python3 rulesets/apply.py <owner/repo> [--check NAME ...] [--apply]`. Without `--apply` it only prints.
- Private repos on the Free plan can't have rulesets or protection. Public repos can.
- Auto-merge waits only on required checks. A repo with the ruleset but no required checks merges as soon as a pull request exists, so a workflow that merges must wait for CI itself.

## Dependabot

- Every active repo with workflows or package files has `.github/dependabot.yml`: `github-actions` at `/`, plus one entry per package ecosystem at the folder of its manifest.
- Each entry runs weekly, uses commit prefix `chore` with the scope, and has one group named after the ecosystem for minor and patch updates. Major updates are not grouped.
- Ignore an update only when it can't be taken yet, with a comment saying why and when to remove it.
- Dependabot auto-merge is an `automerge` job in `ci.yml`, GitHub's documented pattern: it reads the update type with `dependabot/fetch-metadata`, never merges majors, and merges with `gh pr merge --squash --match-head-commit <sha>` so a newer push can't merge untested. Its `needs:` lists every other job in the workflow, or it merges before they finish.

## Releases and deploys

- Each repo is either versioned (released by tag) or continuous (deployed from `main`, no tags). `AGENTS.md` says which.
- A release is an annotated `vX.Y.Z` tag on a commit already on `main`, with a GitHub release and generated notes. Fix a bad release with a new version. A repo's first release needs the owner's OK.
- Versioned repos turn on immutable releases in the repo settings, so a published release's tag and assets can't change. Releases only go forward: a bad one stays, and a new version replaces it.
- A version change arrives in a pull request. Agents never push a version bump or tag to `main`; a workflow cuts the release from `main` and retries a missing release even when the tag exists. A repo whose own docs give a release process with an owner approval step follows that instead.
- OpenClaw plugin repos: `openclaw.build`, `openclaw.compat` and the `openclaw` peer range all name the OpenClaw version the plugin was last tested on, and a test fails when they disagree. The `openclaw` devDependency is what CI typechecks and may be newer. When the plugin is tested on a newer OpenClaw, all of them move together.
- Keep the version in one file. If a second copy can't be avoided, the check command fails when they disagree.
- No workflow pushes to `main`. A workflow that changes content opens a pull request, unless the owner grants that push a named ruleset bypass. Exception: wordbug and wordbun take only words on `main`, so their rulesets keep no-force-push and no-delete but drop the pull request and required check rules, and Add Word pushes the word straight to `main`. Code changes reach them from occasional-wotd.
- Deploy workflows are separate from `ci.yml`, use concurrency group `pages` without canceling, and say in a comment whether they wait for CI. Deploying on every push is fine only when `main` gets nothing but pull requests that passed a required check. Otherwise the deploy runs on `workflow_run` only when CI succeeded, and checks out the commit CI tested (`${{ github.event.workflow_run.head_sha }}`).

## Hygiene

- `.gitignore` covers `.env` and `.env.*` (keeping `.env.example`), `.DS_Store` and `.claude/settings.local.json`.
- A repo that reads environment variables commits `.env.example` with every key and blank secrets.
- No tracked symlink points outside the repo.
- A repo whose rules forbid personal data has a check that enforces it.

## Licenses

Every repo has a license file at the root named exactly `LICENSE`. Public repos use MIT. Private and proprietary repos say "All rights reserved" and name the owner as the rights holder. Posts, photos, game assets and other non-code content keep their own rights; note these exceptions in `README.md`.

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
