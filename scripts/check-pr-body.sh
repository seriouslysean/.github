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
# Reads through `gh api`: GH_TOKEN in CI, the gh login locally.
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

# fetch <repo> <path> <ref> <out>: 0 read, 1 not there (404). Any other error stops the
# check rather than check against the wrong template. An empty ref reads the default
# branch; gh encodes the ref into the query.
fetch() {
  local args=(-X GET -H 'Accept: application/vnd.github.raw' "repos/$1/contents/$2")
  [ -z "$3" ] || args+=(-f "ref=$3")
  if gh api "${args[@]}" >"$4" 2>"$tmp/gh-error"; then
    return 0
  fi
  grep -q '(HTTP 404)' "$tmp/gh-error" && return 1
  cat "$tmp/gh-error" >&2
  error "could not read $1/$2"
  exit 2
}

# Bodies edited in the web UI arrive with CRLF line endings.
tr -d '\r' >"$tmp/body.md"

# The places GitHub reads a single PR template from. The contents API is
# case-sensitive, so both spellings are tried.
source=
for path in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md \
  pull_request_template.md PULL_REQUEST_TEMPLATE.md \
  docs/pull_request_template.md docs/PULL_REQUEST_TEMPLATE.md; do
  if fetch "$repo" "$path" "$ref" "$tmp/template.md"; then
    source="$repo/$path"
    break
  fi
done
if [ -z "$source" ]; then
  fetch "$default_repo" .github/pull_request_template.md "$default_ref" "$tmp/template.md" || {
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
if fetch "$repo" "$extra" "$ref" "$tmp/extra.sh"; then
  if ! env -u GH_TOKEN -u GITHUB_TOKEN bash "$tmp/extra.sh" <"$tmp/body.md"; then
    error "PR body fails $repo/$extra"
    failed=1
  fi
fi

exit "$failed"
