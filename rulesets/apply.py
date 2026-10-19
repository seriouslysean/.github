"""Create or update the default-branch ruleset on a repo from default-branch.json.

  python3 apply.py <owner/repo> [--check NAME ...] [--apply]

Without --apply it prints the body and what it would do. Each --check adds a required
status check from GitHub Actions (not strict). Needs a gh login that can admin the repo.
"""
import json, subprocess, sys
from pathlib import Path

args = sys.argv[1:]
repo = args.pop(0)
apply = "--apply" in args
checks = [args[i + 1] for i, a in enumerate(args) if a == "--check"]

body = json.loads((Path(__file__).parent / "default-branch.json").read_text())
if checks:
    body["rules"].append({"type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": False, "do_not_enforce_on_create": False,
        "required_status_checks": [{"context": c, "integration_id": 15368} for c in checks]}})

def gh(*a, stdin=None):
    r = subprocess.run(["gh", *a], capture_output=True, text=True, input=stdin, env={"GH_PAGER": "cat", **__import__("os").environ})
    if r.returncode:
        sys.exit(f"gh {' '.join(a)}: {r.stderr.strip()}")
    return r.stdout

existing = [r for r in json.loads(gh("api", f"repos/{repo}/rulesets")) if r["name"] == body["name"]]
verb, path = ("PUT", f"repos/{repo}/rulesets/{existing[0]['id']}") if existing else ("POST", f"repos/{repo}/rulesets")
print(f"{repo}: {verb} {path}; checks: {checks or 'none'}")
if apply:
    out = json.loads(gh("api", "-X", verb, path, "--input", "-", stdin=json.dumps(body)))
    print(f"  ruleset {out['id']} {out['enforcement']}")
else:
    print(json.dumps(body, indent=1))
