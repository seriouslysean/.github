#!/usr/bin/env bash
# scripts/check-pr-body.sh — a PR body carries every heading of the repo's PR template.
# The same script runs in CI (the pr-body workflow, at its pinned commit) and locally,
# before `gh pr create` or `gh pr edit`, so CI is a backstop rather than the first pass.
#   check-pr-body.sh <owner/repo> <base ref> <body.md
# The template is the repo's own at the base ref, from the places GitHub reads a single
# PR template, else <owner>/.github's default. In the pr-body workflow that default is read at
# the commit the caller pinned: WORKFLOW_REPO and WORKFLOW_SHA (job.workflow_repository and
# job.workflow_sha) name the called workflow, and apply when WORKFLOW_REPO is <owner>/.github.
# Without them, as in a local run, it is read from the default branch.
# If the repo has scripts/checks/check-pr-body.sh at the base ref, that runs too, with the
# same body on stdin.
# Reads through one `gh api graphql` query: GH_TOKEN in CI, the gh login locally.
# Exit: 0 the body passes; 1 a finding; 2 a usage or read error.
set -euo pipefail
umask 077
export LC_ALL=C

if [ "$#" -ne 2 ] || ! [[ $1 =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] ||
  [[ $1 =~ (^|/)\.\.?(/|$) ]] || [ -z "$2" ]; then
  echo 'usage: check-pr-body.sh <owner/repo> <base ref> <body.md' >&2
  exit 2
fi
repo=$1 ref=$2
default_repo="${repo%%/*}/.github"
extra=scripts/checks/check-pr-body.sh

# The ref for the fallback template: the pinned commit when this runs from the shared
# workflow of <owner>/.github, else empty (the default branch).
default_ref=
if [ -n "${WORKFLOW_SHA:-}" ] && [ "$(printf %s "${WORKFLOW_REPO:-}" | tr '[:upper:]' '[:lower:]')" = "$(printf %s "$default_repo" | tr '[:upper:]' '[:lower:]')" ]; then
  if ! [[ $WORKFLOW_SHA =~ ^[0-9a-f]{40}$ ]]; then
    echo 'WORKFLOW_SHA is not a full commit SHA' >&2
    exit 2
  fi
  default_ref=$WORKFLOW_SHA
fi

tmp=$(mktemp -d "${TMPDIR:-/tmp}/check-pr-body.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT

error() {
  if [ "${GITHUB_ACTIONS:-}" = true ]; then echo "::error::$1"; else echo "FAIL $1"; fi
}

# The places GitHub reads a single PR template from, in its order. Git paths are
# case-sensitive, so both spellings are listed.
paths=(.github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md
  pull_request_template.md PULL_REQUEST_TEMPLATE.md
  docs/pull_request_template.md docs/PULL_REQUEST_TEMPLATE.md)

# One GraphQL query reads every candidate template and the extra check at the base ref, and
# the default template, so a check costs one API call. A missing file is null, not an error;
# a missing repo is an error, so if the owner has no .github the repo is read alone.
# Each file found prints as "<key><tab><base64 text>".
blob='... on Blob { text }'
# GraphQL and jq variables, not shell ones.
# shellcheck disable=SC2016
query='query($owner: String!, $name: String!, $e0: String!, $e1: String!, $e2: String!, $e3: String!, $e4: String!, $e5: String!, $ex: String!'
fields=''
for i in 0 1 2 3 4 5; do fields="$fields p$i: object(expression: \$e$i) { $blob }"; done
fields="$fields x: object(expression: \$ex) { $blob }"
# shellcheck disable=SC2016
picks='(.data.repo // {}) as $r | (("p0", "p1", "p2", "p3", "p4", "p5", "x") as $k | $r[$k].text // empty | "\($k)\t" + @base64)'
args=(-f owner="${repo%%/*}" -f name="${repo#*/}" -f ex="$ref:$extra")
for i in 0 1 2 3 4 5; do args+=(-f "e$i=$ref:${paths[$i]}"); done
if ! gh api graphql "${args[@]}" -f fname=.github -f ef="${default_ref:-HEAD}:.github/pull_request_template.md" \
  -f query="$query, \$fname: String!, \$ef: String!) { repo: repository(owner: \$owner, name: \$name) { $fields } fallback: repository(owner: \$owner, name: \$fname) { t: object(expression: \$ef) { $blob } } }" \
  --jq "$picks, (.data.fallback.t.text // empty | \"fallback\\t\" + @base64)" >"$tmp/files" 2>/dev/null &&
  ! gh api graphql "${args[@]}" -f query="$query) { repo: repository(owner: \$owner, name: \$name) { $fields } }" \
    --jq "$picks" >"$tmp/files" 2>"$tmp/gh-error"; then
  cat "$tmp/gh-error" >&2
  error "could not read $repo"
  exit 2
fi

# file <key> <out>: 0 and the text when the query found that file, else 1.
file() {
  local line
  line=$(grep -m1 "^$1	" "$tmp/files") || return 1
  printf '%s' "${line#*	}" | base64 --decode >"$2"
}

# Bodies edited in the web UI arrive with CRLF line endings.
tr -d '\r' >"$tmp/body.md"

source=
for i in 0 1 2 3 4 5; do
  if file "p$i" "$tmp/template.md"; then
    source="$repo/${paths[$i]}"
    break
  fi
done
if [ -z "$source" ]; then
  file fallback "$tmp/template.md" || {
    error "no PR template in $repo or $default_repo"
    exit 2
  }
  source="$default_repo/.github/pull_request_template.md"
fi

# Headings outside HTML comments, trailing space trimmed.
tr -d '\r' <"$tmp/template.md" | awk '
  {
    line = $0; out = ""
    while (1) {
      if (incomment) {
        i = index(line, "-->"); if (!i) { line = ""; break }
        line = substr(line, i + 3); incomment = 0
      }
      i = index(line, "<!--"); if (!i) { out = out line; break }
      out = out substr(line, 1, i - 1); line = substr(line, i + 4); incomment = 1
    }
    sub(/[ \t]+$/, "", out)
    if (out ~ /^#+[ \t]/) print out
  }' >"$tmp/headings"
sed 's/[[:space:]]*$//' "$tmp/body.md" >"$tmp/body-trimmed"

failed=0
missing=
while IFS= read -r heading; do
  [ -n "$heading" ] || continue
  grep -Fxq -- "$heading" "$tmp/body-trimmed" || missing="$missing, $heading"
done <"$tmp/headings"
if [ -n "$missing" ]; then
  error "PR body is missing headings from $source: ${missing#, }"
  failed=1
else
  echo "ok   PR body carries every heading of $source"
fi

# The repo's script reads only the body: it gets no GitHub token.
if file x "$tmp/extra.sh"; then
  if ! env -u GH_TOKEN -u GITHUB_TOKEN bash "$tmp/extra.sh" <"$tmp/body.md"; then
    error "PR body fails $repo/$extra"
    failed=1
  fi
fi

exit "$failed"
