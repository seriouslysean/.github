"""Create or update a ruleset on a repo from a ruleset file in this folder.

  python3 apply.py <owner/repo> [--file FILE] [--id ID] [--check NAME ...] [--apply]

FILE is a name in this folder (default default-branch.json; tags-releases.json is the release
tag rule), or a path when it contains a slash. The live ruleset to update is the one with --id, else the one with the
file's name; with neither it creates one. Pass the id of a live ruleset named differently
(like `main`) to migrate it to the shared file instead of adding a second one beside it.
Without --apply it prints the body and what it would do. Each --check adds a required status
check from GitHub Actions (not strict) and applies to branch rulesets only. The update replaces
the live rules, so when the live ruleset requires checks it refuses unless --check names them
all; it prints any it would drop. Needs a gh login that can admin the repo.
"""
import argparse, json, os, subprocess, sys
from pathlib import Path

ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("repo")
ap.add_argument("--file", default="default-branch.json")
ap.add_argument("--id", type=int)
ap.add_argument("--check", action="append", default=[])
ap.add_argument("--apply", action="store_true")
opts = ap.parse_args()
repo, checks = opts.repo, opts.check

here = Path(__file__).parent
path = Path(opts.file) if "/" in opts.file else here / opts.file
body = json.loads(path.read_text())
if checks:
    if body["target"] != "branch":
        sys.exit("--check applies to branch rulesets only")
    body["rules"].append({"type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": False, "do_not_enforce_on_create": False,
        "required_status_checks": [{"context": c, "integration_id": 15368} for c in checks]}})

def gh(*a, stdin=None):
    r = subprocess.run(["gh", *a], capture_output=True, text=True, input=stdin, env={"GH_PAGER": "cat", **os.environ})
    if r.returncode:
        sys.exit(f"gh {' '.join(a)}: {r.stderr.strip()}")
    return r.stdout

live = json.loads(gh("api", f"repos/{repo}/rulesets"))
if opts.id is not None:
    existing = [r for r in live if r["id"] == opts.id]
    if not existing:
        sys.exit(f"{repo}: no ruleset with id {opts.id}")
    if existing[0].get("target", body["target"]) != body["target"]:
        sys.exit(f"{repo}: ruleset {opts.id} targets {existing[0]['target']}, the file targets {body['target']}")
else:
    existing = [r for r in live if r["name"] == body["name"]]
verb, url = ("PUT", f"repos/{repo}/rulesets/{existing[0]['id']}") if existing else ("POST", f"repos/{repo}/rulesets")
print(f"{repo}: {verb} {url} from {path.name}; checks: {checks or 'none'}")
if existing and existing[0]["name"] != body["name"]:
    print(f"  renames live ruleset '{existing[0]['name']}' to '{body['name']}'")
if existing:
    # The list omits rules; read the live ruleset so a PUT doesn't drop its required checks.
    live_rules = json.loads(gh("api", url)).get("rules", [])
    live_checks = sorted({c["context"] for r in live_rules if r["type"] == "required_status_checks"
                          for c in r["parameters"]["required_status_checks"]})
    dropped = [c for c in live_checks if c not in checks]
    if dropped:
        print(f"  drops live required checks: {', '.join(dropped)}")
        if not checks:
            sys.exit(f"{repo}: the live ruleset requires checks; pass each to keep with --check")
if opts.apply:
    out = json.loads(gh("api", "-X", verb, url, "--input", "-", stdin=json.dumps(body)))
    print(f"  ruleset {out['id']} {out['enforcement']}")
else:
    print(json.dumps(body, indent=1))
