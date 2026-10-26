#!/usr/bin/env bash
# scripts/check-pr-body.test.sh — synthetic-body tests for scripts/check-pr-body.sh.
# A stub `gh` on PATH serves repo files from a temp tree, laid out as
# <tree>/<owner>/<repo>/<ref>/<path> (ref "default" for the default branch); a missing
# file answers 404 as gh does, matching case as the contents API does. The real default template is this repo's own.
#   bash scripts/check-pr-body.test.sh
# Exit: 0 if all cases pass; 1 listing how many failed.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="$ROOT/scripts/check-pr-body.sh"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/check-pr-body-test.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT

mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
# gh api -X GET -H <header> repos/<owner>/<repo>/contents/<path> [-f ref=<ref>]
if [ -n "${GH_STUB_FAIL:-}" ]; then echo 'gh: Server Error (HTTP 500)' >&2; exit 1; fi
ref=default
for arg; do
  case $arg in
    repos/*) url=$arg ;;
    ref=*) ref=${arg#ref=} ;;
  esac
done
rest=${url#repos/}
owner=${rest%%/*} rest=${rest#*/}
repo=${rest%%/*} rest=${rest#*/contents/}
path=$rest
file="$GH_STUB_TREE/$owner/$repo/$ref/$path"
if [ -f "$file" ] && ls "${file%/*}" | grep -Fxq -- "${file##*/}"; then cat "$file"; else echo 'gh: Not Found (HTTP 404)' >&2; exit 1; fi
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH" GH_STUB_TREE="$tmp/tree"
unset GITHUB_ACTIONS GH_STUB_FAIL

# put <owner/repo> <ref> <path>: stdin becomes that file.
put() { mkdir -p "$(dirname "$tmp/tree/$1/$2/$3")" && cat >"$tmp/tree/$1/$2/$3"; }
put drizzt/.github default .github/pull_request_template.md <"$ROOT/.github/pull_request_template.md"

echo "== test-check-pr-body =="
failures=0
check() {
  if [[ $2 == "$3" ]]; then
    printf '  PASS %s\n' "$1"
  else
    printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}
contains() {
  case "$2" in
    *"$3"*) check "$1" present present ;;
    *) check "$1" "contains $3" "$2" ;;
  esac
}
# run <body> <owner/repo> [ref]
run() {
  out=$(printf '%s' "$1" | bash "$checker" "$2" "${3:-main}" 2>&1)
  rc=$?
}

default=$'## What changed\nA change.\n\n## Why\nA need.\n\nCloses #4\n\n## How you checked it\nTests.\n'

# The default template, from <owner>/.github.
run "$default" drizzt/icewind
check "a body with every default heading passes" 0 "$rc"
contains "it names the default template" "$out" "drizzt/.github/.github/pull_request_template.md"
run "$(cat "$ROOT/.github/pull_request_template.md")" drizzt/icewind
check "the default template itself passes" 0 "$rc"
run "${default/'## Why'/Why}" drizzt/icewind
check "a missing heading fails" 1 "$rc"
contains "the missing heading is named" "$out" "missing headings from drizzt/.github/.github/pull_request_template.md: ## Why"
run "${default/'## Why'/'## Whyever'}" drizzt/icewind
check "a heading must match exactly" 1 "$rc"
run "${default/'## Why'/'### Why'}" drizzt/icewind
check "a deeper heading does not count" 1 "$rc"
run "## Why  "$'\n'"${default/'## Why'/}" drizzt/icewind
check "trailing space on a body heading is ignored" 0 "$rc"
run "$(printf '%s' "$default" | sed 's/$/\r/')" drizzt/icewind
check "a CRLF body passes" 0 "$rc"
run "" drizzt/icewind
check "an empty body fails" 1 "$rc"
contains "an empty body names all three headings" "$out" ": ## What changed, ## Why, ## How you checked it"

# The repo's own template, at the base ref, from each place GitHub reads it.
for path in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md \
  pull_request_template.md PULL_REQUEST_TEMPLATE.md \
  docs/pull_request_template.md docs/PULL_REQUEST_TEMPLATE.md; do
  rm -rf "$tmp/tree/drizzt/mithral"
  printf '## Summary\n\n<!-- ## Hidden -->\n\n## Notes \n' | put drizzt/mithral main "$path"
  run $'## Summary\nx\n\n## Notes\ny' drizzt/mithral
  check "the repo's template at $path is used" 0 "$rc"
  contains "it names $path" "$out" "drizzt/mithral/$path"
  run "$default" drizzt/mithral
  check "the default does not apply over $path" 1 "$rc"
done
rm -rf "$tmp/tree/drizzt/mithral"
printf '## First\n' | put drizzt/mithral main .github/pull_request_template.md
printf '## Second\n' | put drizzt/mithral main docs/pull_request_template.md
run $'## First' drizzt/mithral
check "the first place in GitHub's order wins" 0 "$rc"
printf '<!--\n## Hidden\n-->\n## Shown <!-- note --> \n' | put drizzt/mithral main .github/pull_request_template.md
run $'## Shown' drizzt/mithral
check "headings inside comments are skipped, inline comments stripped" 0 "$rc"
printf '## Old\n' | put drizzt/mithral v1 .github/pull_request_template.md
run $'## Old' drizzt/mithral v1
check "the template is read at the given base ref" 0 "$rc"
run $'## Old' drizzt/mithral
check "another ref reads its own template" 1 "$rc"
contains "another ref names its own template" "$out" "drizzt/mithral/.github/pull_request_template.md"
printf '## Odd\n' | put drizzt/mithral 'feat&x=1' .github/pull_request_template.md
run $'## Odd' drizzt/mithral 'feat&x=1'
check "a ref with query characters reaches gh whole" 0 "$rc"

# The repo's extra check, at the base ref.
cat <<'EOF' | put drizzt/guenhwyvar main scripts/checks/check-pr-body.sh
grep -q '^Fixes #[0-9]' || { echo 'FAIL no closing reference'; exit 1; }
echo 'ok   extra'
EOF
run "Fixes #1"$'\n'"$default" drizzt/guenhwyvar
check "the extra check runs and passes" 0 "$rc"
contains "the extra check's output shows" "$out" "ok   extra"
run "$default" drizzt/guenhwyvar
check "a failing extra check fails the body" 1 "$rc"
contains "the extra check's finding shows" "$out" "FAIL no closing reference"
contains "the extra check is named" "$out" "fails drizzt/guenhwyvar/scripts/checks/check-pr-body.sh"
run "Fixes #1"$'\n'"${default/'## Why'/}" drizzt/guenhwyvar
check "headings and extra check both report" 1 "$rc"
contains "the missing heading still shows beside the extra check" "$out" "missing headings"
run "$default" drizzt/guenhwyvar v2
check "no extra check at another ref means only headings" 0 "$rc"
case $out in
  *"ok   extra"*) check "the extra check does not run at that ref" absent present ;;
  *) check "the extra check does not run at that ref" absent absent ;;
esac
cat <<'EOF' | put drizzt/guenhwyvar crlf scripts/checks/check-pr-body.sh
[ "$(tr -dc '\r' | wc -c)" -eq 0 ]
EOF
run "$(printf '%s' "$default" | sed 's/$/\r/')" drizzt/guenhwyvar crlf
check "the extra check gets the body without CR" 0 "$rc"

cat <<'EOF' | put drizzt/guenhwyvar token scripts/checks/check-pr-body.sh
[ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]
EOF
GH_TOKEN=secret GITHUB_TOKEN=secret run "$default" drizzt/guenhwyvar token
check "the extra check gets no GitHub token" 0 "$rc"

# The fallback template at the commit the caller pinned (WORKFLOW_REPO, WORKFLOW_SHA).
pin=0123456789abcdef0123456789abcdef01234567
printf '## Pinned\n' | put artemis/.github "$pin" .github/pull_request_template.md
printf '## Moved\n' | put artemis/.github default .github/pull_request_template.md
WORKFLOW_REPO=artemis/.github WORKFLOW_SHA=$pin run $'## Pinned' artemis/icewind
check "the fallback template is read at the pinned commit" 0 "$rc"
WORKFLOW_REPO=artemis/.github WORKFLOW_SHA=$pin run $'## Moved' artemis/icewind
check "a template change on the default branch does not reach a pinned caller" 1 "$rc"
WORKFLOW_REPO=Artemis/.github WORKFLOW_SHA=$pin run $'## Pinned' artemis/icewind
check "the workflow repo matches the owner's .github ignoring case" 0 "$rc"
run $'## Moved' artemis/icewind
check "without a pin the default branch is read" 0 "$rc"
WORKFLOW_REPO=other/.github WORKFLOW_SHA=$pin run $'## Moved' artemis/icewind
check "a pin from another owner's workflow does not apply" 0 "$rc"
WORKFLOW_REPO=artemis/.github WORKFLOW_SHA=main run $'## Moved' artemis/icewind
check "a pin that is not a full SHA is a usage error" 2 "$rc"
WORKFLOW_REPO=artemis/.github WORKFLOW_SHA=0123456789abcdef0123456789abcdef01234568 run $'## Pinned' artemis/icewind
check "a pinned commit without the template is an error" 2 "$rc"
rm -rf "$tmp/tree/artemis"

# Errors and output modes.
run "$default" drizzt
check "a repo without an owner is a usage error" 2 "$rc"
run "$default" ../..
check "a dot path as the repo is a usage error" 2 "$rc"
run "$default" drizzt/..
check "a dot repo name is a usage error" 2 "$rc"
run "$default" drizzt/.github
check "a repo named .github is allowed" 0 "$rc"
out=$(printf '' | bash "$checker" drizzt/icewind 2>&1)
check "a missing base ref is a usage error" 2 "$?"
GH_STUB_FAIL=1 run "$default" drizzt/icewind
check "a read error other than 404 stops the check" 2 "$rc"
contains "the read error is named" "$out" "could not read drizzt/icewind/.github/pull_request_template.md"
run "$default" artemis/icewind
check "no template anywhere is a read error" 2 "$rc"
GITHUB_ACTIONS=true run "" drizzt/icewind
contains "in Actions a finding is an error annotation" "$out" "::error::PR body is missing headings"
run "" drizzt/icewind
contains "locally a finding is a FAIL line" "$out" "FAIL PR body is missing headings"

if [[ $failures -ne 0 ]]; then
  echo "$failures check(s) failed"
  exit 1
fi
