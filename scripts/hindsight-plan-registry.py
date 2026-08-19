#!/usr/bin/env python3
"""Register exact Git plan artifacts in Hindsight, and audit the registry.

Git — not Hindsight — is the exact artifact transport. `register` upserts a
*reference* document (deterministic document_id, source repo/path, exact
commit SHA, target banks, status, execution_authorized flag) so agents can
recall that a plan exists, then read the exact file from Git before acting.
`audit` is read-only and reports drift; an explicit `register` run repairs it.

Usage:
  hindsight-plan-registry.py register --plan PATH --banks BANK[,BANK...]
      [--status current|superseded] [--summary TEXT] [--authorize]
  hindsight-plan-registry.py audit --banks BANK[,BANK...]
      [--expected REPO_PATH:PLAN_RELPATH ...]

Connection comes from ~/.hindsight/coding-agent.json (apiUrl + apiToken),
the same machine-local config the coding-agent integration uses.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

CONFIG_PATH = Path.home() / ".hindsight" / "coding-agent.json"
MARKER = "PLAN-REGISTRY v1"


def load_connection() -> tuple[str, str]:
    cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    api_url = cfg["apiUrl"].rstrip("/")
    token = cfg.get("apiToken", "")
    return api_url, token


def api(method: str, path: str, body: dict | None = None, timeout: int = 600):
    api_url, token = load_connection()
    request = urllib.request.Request(
        api_url + path,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method=method,
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        raw = response.read()
        return json.loads(raw) if raw else {}


def git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(repo), *args], check=True, capture_output=True, text=True
    ).stdout.strip()


def plan_identity(plan_path: Path) -> dict:
    plan_path = plan_path.resolve()
    repo_root = Path(git(plan_path.parent, "rev-parse", "--show-toplevel"))
    rel = plan_path.relative_to(repo_root).as_posix()
    if git(repo_root, "status", "--porcelain", "--", rel):
        raise SystemExit(f"ERROR: {rel} has uncommitted changes — commit and push the exact file first")
    commit = git(repo_root, "log", "-1", "--format=%H", "--", rel)
    if not commit:
        raise SystemExit(f"ERROR: {rel} has no committed history")
    blob = git(repo_root, "rev-parse", f"{commit}:{rel}")
    try:
        pushed = bool(git(repo_root, "branch", "-r", "--contains", commit))
    except subprocess.CalledProcessError:
        pushed = False
    return {
        "plan_id": f"plan-registry::{repo_root.name}::{rel}",
        "repo": repo_root.name,
        "repo_root": str(repo_root),
        "path": rel,
        "commit": commit,
        "blob": blob,
        "pushed": pushed,
    }


def cmd_register(args: argparse.Namespace) -> int:
    ident = plan_identity(Path(args.plan))
    if not ident["pushed"]:
        raise SystemExit(f"ERROR: commit {ident['commit'][:12]} is not on the upstream branch — push first")
    banks = [b.strip() for b in args.banks.split(",") if b.strip()]
    record = {
        "plan_id": ident["plan_id"],
        "repo": ident["repo"],
        "repo_root": ident["repo_root"],
        "path": ident["path"],
        "commit": ident["commit"],
        "blob": ident["blob"],
        "banks": banks,
        "status": args.status,
        "execution_authorized": bool(args.authorize),
        "registered_at": datetime.now(timezone.utc).isoformat(),
        "summary": args.summary or "",
    }
    content = "\n".join([
        MARKER,
        json.dumps(record, sort_keys=True),
        "This is a reference to an exact Git artifact. Read the file at the recorded",
        "repo/path/commit before acting on it. This summary is not the plan and",
        "confers no execution permission.",
    ])
    item = {
        "content": content,
        "document_id": ident["plan_id"],
        "update_mode": "replace",
        "metadata": {k: str(v) for k, v in record.items() if k != "summary"},
        "tags": ["plan-registry", f"plan-status:{args.status}"],
    }
    for bank in banks:
        api("PUT", f"/v1/default/banks/{bank}", {"name": bank})
        # async: extraction may queue behind other local-LLM work; the
        # document itself is stored immediately and upserts by document_id.
        api("POST", f"/v1/default/banks/{bank}/memories", {"items": [item], "async": True})
        print(f"registered {ident['plan_id']} @ {ident['commit'][:12]} -> bank {bank} (status={args.status})")
    return 0


def registry_documents(bank: str) -> list[dict]:
    # The list endpoint omits document text, so fetch each doc in full —
    # parse_record needs the body to read the embedded JSON record.
    listing = api("GET", f"/v1/default/banks/{bank}/documents?tags=plan-registry&limit=500")
    out = []
    for stub in listing.get("items", listing.get("documents", [])):
        did = stub.get("id")
        if not did:
            continue
        out.append(api("GET", f"/v1/default/banks/{bank}/documents/{urllib.parse.quote(str(did), safe='')}"))
    return out


def parse_record(document: dict) -> dict | None:
    text = document.get("text") or document.get("original_text") or document.get("content") or ""
    if MARKER not in text:
        meta = document.get("metadata") or {}
        return meta if meta.get("plan_id") else None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                return None
    return None


def cmd_audit(args: argparse.Namespace) -> int:
    banks = [b.strip() for b in args.banks.split(",") if b.strip()]
    findings: list[str] = []
    seen: dict[str, set[str]] = {}
    for bank in banks:
        try:
            documents = registry_documents(bank)
        except urllib.error.HTTPError as error:
            findings.append(f"[{bank}] cannot list documents: HTTP {error.code}")
            continue
        for document in documents:
            record = parse_record(document)
            if not record:
                findings.append(f"[{bank}] unparseable plan-registry document {document.get('id')}")
                continue
            plan_id = record["plan_id"]
            seen.setdefault(plan_id, set()).add(bank)
            repo_root = Path(record.get("repo_root", ""))
            rel, commit = record["path"], record["commit"]
            if not repo_root.is_dir():
                findings.append(f"[{bank}] {plan_id}: repo root missing at {repo_root}")
                continue
            try:
                git(repo_root, "cat-file", "-e", commit)
            except subprocess.CalledProcessError:
                findings.append(f"[{bank}] {plan_id}: registered commit {commit[:12]} missing from Git")
                continue
            if not (repo_root / rel).exists():
                findings.append(f"[{bank}] {plan_id}: committed plan file missing at HEAD ({rel})")
            head_commit = git(repo_root, "log", "-1", "--format=%H", "--", rel)
            if head_commit and head_commit != commit and str(record.get("status")) == "current":
                findings.append(
                    f"[{bank}] {plan_id}: Hindsight SHA {commit[:12]} behind Git {head_commit[:12]} — re-register"
                )
            wanted = record.get("banks") or []
            if isinstance(wanted, str):
                wanted = json.loads(wanted.replace("'", '"')) if wanted.startswith("[") else [wanted]
            if wanted and bank not in wanted:
                findings.append(f"[{bank}] {plan_id}: registered in bank not named by its own record ({wanted})")
    for expectation in args.expected or []:
        repo_path, _, rel = expectation.partition(":")
        plan_id = f"plan-registry::{Path(repo_path).name}::{rel}"
        if plan_id not in seen:
            findings.append(f"[expected] committed plan missing from Hindsight: {plan_id}")
    if findings:
        print("PLAN REGISTRY AUDIT: DRIFT FOUND")
        for finding in findings:
            print(" -", finding)
        return 1
    print(f"PLAN REGISTRY AUDIT: clean ({sum(len(b) for b in seen.values())} registrations across {len(banks)} banks)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    p_register = sub.add_parser("register")
    p_register.add_argument("--plan", required=True)
    p_register.add_argument("--banks", required=True)
    p_register.add_argument("--status", default="current", choices=["current", "superseded"])
    p_register.add_argument("--summary", default="")
    p_register.add_argument("--authorize", action="store_true",
                            help="Mark execution_authorized=true (requires Bryan's explicit authorization)")
    p_register.set_defaults(func=cmd_register)
    p_audit = sub.add_parser("audit")
    p_audit.add_argument("--banks", required=True)
    p_audit.add_argument("--expected", nargs="*", default=[],
                         help="REPO_PATH:PLAN_RELPATH pairs that must be registered")
    p_audit.set_defaults(func=cmd_audit)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
