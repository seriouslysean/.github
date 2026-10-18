# Contributing

Thanks for helping out! Every change starts with an issue, even a small one.

1. **Find or open an issue.** Use the bug or feature template. For docs or cleanup, a blank issue with what, why and a short checklist is fine.
2. **Branch from `main`.** Name it after the issue, like `14-menu-closes-early`. Fork first if you can't push here.
3. **Make the change and check it.** A bug fix gets a test that fails without it. Run the tests and lint, and update docs if something works differently.
4. **Open a pull request.** Fill in the template and add `Closes #14`.
5. **Title it `type: summary`,** like `fix: keep the menu open`. Pull requests are squash-merged, so the title and description become the commit.

**Labels:** GitHub's built-in ones only, like `bug`, `enhancement` and `documentation`.

**Privacy:** keep secrets and private details out of code, issues and pull requests. Use paths relative to the repo.

**Using `gh`:** `--body` and `--body-file` skip the templates, so fill in the template yourself and pass it with `--body-file`, adding labels with `--label`. If a repo has no templates of its own, they're in [seriouslysean/.github](https://github.com/seriouslysean/.github).

**Standards:** how repos here are named, set up and documented is in [docs/repo-standards.md](https://github.com/seriouslysean/.github/blob/main/docs/repo-standards.md).

Found a security problem? See [SECURITY.md](SECURITY.md) instead of opening an issue or pull request.
