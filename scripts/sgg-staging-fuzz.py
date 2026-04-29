#!/Users/bryan/.local/share/sgg-staging-test/.venv/bin/python
"""Simpler Grants Gov — staging API fuzz / exercise script.

Hits the public Common Grants endpoints on staging with a sampled cross-product
of filters, sorts, and pagination to surface non-2xx responses. Results are
written to ./staging_failures.csv in the current working directory.

Invocation:
    sgg-staging-fuzz                      # via shell function (zsh)
    ~/code/dotfiles/scripts/sgg-staging-fuzz.py

Environment:
    API_KEY   Overrides the secret file. If unset, the script reads
              ~/.secrets/simpler-grants-staging-api-key (raw value, one line).
    BASE_URL  Defaults to https://api.staging.simpler.grants.gov.

Environment setup:
    ~/.local/share/sgg-staging-test/.venv must exist with `requests` installed.
    Bootstrap with: scripts/sgg-staging-fuzz-setup.sh
"""

import csv
import json
import os
import random
import sys
import time
from datetime import datetime, timedelta
from itertools import product
from pathlib import Path
from typing import Any

import requests

BASE_URL = os.environ.get("BASE_URL", "https://api.staging.simpler.grants.gov")
API_KEY = os.environ.get("API_KEY", "")
OUTPUT_FILE = "staging_failures.csv"

# Fall back to the ~/.secrets/ convention (one file per secret, raw value).
# Env var wins so callers can still override per-invocation.
if not API_KEY:
    secret_path = Path.home() / ".secrets" / "simpler-grants-staging-api-key"
    if secret_path.is_file():
        API_KEY = secret_path.read_text().strip()

if not API_KEY:
    print(
        "ERROR: API_KEY not set. Either export API_KEY, or place the key at "
        "~/.secrets/simpler-grants-staging-api-key (raw value, one line).",
        file=sys.stderr,
    )
    sys.exit(1)

HEADERS = {
    "X-API-Key": API_KEY,
    "Content-Type": "application/json",
}

STATUS_COMBOS = [
    None,
    {"operator": "in", "value": ["forecasted"]},
    {"operator": "in", "value": ["open"]},
    {"operator": "in", "value": ["closed"]},
    {"operator": "in", "value": ["forecasted", "open"]},
    {"operator": "notIn", "value": ["closed"]},
]

today = datetime.today().date()
DATE_RANGE_COMBOS = [
    None,
    {
        "operator": "between",
        "value": {"min": str(today), "max": str(today + timedelta(days=90))},
    },
    {
        "operator": "between",
        "value": {"min": str(today - timedelta(days=365)), "max": str(today)},
    },
    {
        "operator": "outside",
        "value": {"min": str(today - timedelta(days=30)), "max": str(today + timedelta(days=30))},
    },
]

FUNDING_RANGE_COMBOS = [
    None,
    {
        "operator": "between",
        "value": {
            "min": {"amount": "0", "currency": "USD"},
            "max": {"amount": "100000", "currency": "USD"},
        },
    },
    {
        "operator": "between",
        "value": {
            "min": {"amount": "100000", "currency": "USD"},
            "max": {"amount": "1000000", "currency": "USD"},
        },
    },
]

SORT_COMBOS = [
    {"sortBy": "lastModifiedAt", "sortOrder": "desc"},
    {"sortBy": "lastModifiedAt", "sortOrder": "asc"},
    {"sortBy": "title", "sortOrder": "asc"},
    {"sortBy": "keyDates.closeDate", "sortOrder": "asc"},
    {"sortBy": "funding.maxAwardAmount", "sortOrder": "desc"},
    {"sortBy": "funding.totalAmountAvailable", "sortOrder": "desc"},
]

SEARCH_QUERIES = [None, "housing", "education", "health", "infrastructure", ""]

CUSTOM_FILTER_COMBOS: list[dict | None] = [
    None,
    {"agency": {"operator": "eq", "value": "HHS"}},
    {"agency": {"operator": "neq", "value": "DOD"}},
    {"funding_instrument": {"operator": "eq", "value": "grant"}},
    {"funding_instrument": {"operator": "eq", "value": "cooperative_agreement"}},
    {"title": {"operator": "like", "value": "rural"}},
    {"title": {"operator": "notLike", "value": "pilot"}},
    {"description": {"operator": "like", "value": "broadband"}},
    {"category": {"operator": "in", "value": ["health", "education"]}},
    {"category": {"operator": "notIn", "value": ["defense"]}},
    {"applicant_type": {"operator": "in", "value": ["state", "local"]}},
    {"applicant_type": {"operator": "in", "value": ["nonprofit", "individual"]}},
    {"applicant_type": {"operator": "notIn", "value": ["for_profit"]}},
    {"estimated_award_count": {"operator": "gt", "value": 0}},
    {"estimated_award_count": {"operator": "gte", "value": 10}},
    {"estimated_award_count": {"operator": "lt", "value": 100}},
    {"estimated_award_count": {"operator": "lte", "value": 50}},
    {"estimated_award_count": {"operator": "between", "value": {"min": 1, "max": 20}}},
    {"estimated_award_count": {"operator": "outside", "value": {"min": 0, "max": 5}}},
    {"open_date": {"operator": "gte", "value": str(today - timedelta(days=180))}},
    {"open_date": {"operator": "lte", "value": str(today)}},
    {
        "agency": {"operator": "in", "value": ["HHS", "USDA", "DOE"]},
        "category": {"operator": "in", "value": ["health"]},
    },
    {
        "funding_instrument": {"operator": "eq", "value": "grant"},
        "applicant_type": {"operator": "in", "value": ["state", "local", "tribal"]},
    },
    {
        "agency": {"operator": "eq", "value": "EPA"},
        "estimated_award_count": {"operator": "gte", "value": 1},
        "title": {"operator": "like", "value": "water"},
    },
    {"unknown_field": {"operator": "eq", "value": "unknown_value"}},
    {"nonexistent_filter": {"operator": "in", "value": ["a", "b"]}},
    {"made_up_field": {"operator": "between", "value": {"min": 0, "max": 100}}},
    {"unknown_field": {"operator": "like", "value": "test"}, "another_unknown": {"operator": "eq", "value": "val"}},
    {"empty_string_value": {"operator": "eq", "value": ""}},
    {"numeric_string": {"operator": "eq", "value": "0"}},
]

PAGINATION_COMBOS = [
    {"page": 1, "pageSize": 10},
    {"page": 1, "pageSize": 25},
    {"page": 2, "pageSize": 25},
    {"page": 1, "pageSize": 100},
    {"page": 999, "pageSize": 10},
]


def build_search_body(
    search: str | None,
    status: dict | None,
    close_date: dict | None,
    funding: dict | None,
    custom_filters: dict | None,
    sorting: dict,
    pagination: dict,
) -> dict:
    filters: dict[str, Any] = {}
    if status:
        filters["status"] = status
    if close_date:
        filters["closeDateRange"] = close_date
    if funding:
        filters["totalFundingAvailableRange"] = funding
    if custom_filters:
        filters["customFilters"] = custom_filters

    body: dict[str, Any] = {
        "sorting": sorting,
        "pagination": pagination,
    }
    if filters:
        body["filters"] = filters
    if search is not None:
        body["search"] = search

    return body


all_requests: list[dict] = []
failures: list[dict] = []
total = 0

FIELDNAMES = ["route", "method", "status_code", "success", "custom_filters", "payload", "response_body"]


def record(
    route: str,
    method: str,
    payload: Any,
    response: requests.Response,
    custom_filters: dict | None = None,
) -> None:
    global total
    total += 1
    status = response.status_code
    is_ok = 200 <= status < 300
    marker = "." if is_ok else "F"
    print(marker, end="", flush=True)
    entry = {
        "route": route,
        "method": method,
        "status_code": status,
        "success": is_ok,
        "custom_filters": json.dumps(custom_filters) if custom_filters is not None else "",
        "payload": json.dumps(payload),
        "response_body": response.text[:500],
    }
    all_requests.append(entry)
    if not is_ok:
        failures.append(entry)


def get(path: str, params: dict | None = None) -> None:
    url = f"{BASE_URL}{path}"
    r = requests.get(url, headers=HEADERS, params=params, timeout=30)
    record(path, "GET", params, r)


def post(path: str, body: dict, custom_filters: dict | None = None) -> None:
    url = f"{BASE_URL}{path}"
    r = requests.post(url, headers=HEADERS, json=body, timeout=30)
    record(path, "POST", body, r, custom_filters=custom_filters)


def test_list_opportunities() -> None:
    print("\n\n--- GET /common-grants/opportunities ---")
    for pagination in PAGINATION_COMBOS:
        params = {"page": pagination["page"], "pageSize": pagination["pageSize"]}
        get("/common-grants/opportunities", params=params)
        time.sleep(1.0)


def test_get_opportunity_details(sample_size: int = 20) -> None:
    print("\n\n--- GET /common-grants/opportunities/<id> ---")

    r = requests.get(
        f"{BASE_URL}/common-grants/opportunities",
        headers=HEADERS,
        params={"page": 1, "pageSize": 1},
        timeout=30,
    )
    if r.status_code != 200:
        print(f"\nCould not fetch IDs for detail tests (status {r.status_code})")
        return

    total_items = r.json().get("paginationInfo", {}).get("totalResults", 0)
    page_size = 25
    total_pages = max(1, (total_items + page_size - 1) // page_size)

    ids: list[str] = []
    pages_tried: set[int] = set()
    while len(ids) < sample_size and len(pages_tried) < total_pages:
        page = random.randint(1, total_pages)
        if page in pages_tried:
            continue
        pages_tried.add(page)
        pr = requests.get(
            f"{BASE_URL}/common-grants/opportunities",
            headers=HEADERS,
            params={"page": page, "pageSize": page_size},
            timeout=30,
        )
        if pr.status_code == 200:
            for item in pr.json().get("items", []):
                opp_id = item.get("id") or item.get("oppId")
                if opp_id:
                    ids.append(opp_id)

    ids = random.sample(ids, min(sample_size, len(ids)))
    print(f"  sampled {len(ids)} IDs from {len(pages_tried)} random pages")

    for opp_id in ids:
        get(f"/common-grants/opportunities/{opp_id}")
        time.sleep(1.0)

    for bad_id in [
        "00000000-0000-0000-0000-000000000000",
        "not-a-uuid",
    ]:
        r = requests.get(
            f"{BASE_URL}/common-grants/opportunities/{bad_id}",
            headers=HEADERS,
            timeout=30,
        )
        record(f"/common-grants/opportunities/{bad_id}", "GET", None, r)


def test_search_opportunities() -> None:
    print("\n\n--- POST /common-grants/opportunities/search ---")

    combos = list(
        product(
            SEARCH_QUERIES,
            STATUS_COMBOS,
            DATE_RANGE_COMBOS,
            FUNDING_RANGE_COMBOS,
            CUSTOM_FILTER_COMBOS,
            SORT_COMBOS,
            PAGINATION_COMBOS,
        )
    )

    max_requests = 300
    step = max(1, len(combos) // max_requests)
    sampled = combos[::step][:max_requests]

    print(f"  total combos: {len(combos)}, running: {len(sampled)}")

    for search, status, close_date, funding, custom_filters, sorting, pagination in sampled:
        body = build_search_body(search, status, close_date, funding, custom_filters, sorting, pagination)
        post("/common-grants/opportunities/search", body, custom_filters=custom_filters)
        time.sleep(1.0)


def write_results() -> None:
    with open(OUTPUT_FILE, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(all_requests)
    print(f"\nAll results written to {OUTPUT_FILE} ({len(failures)} failures / {total} total)")


if __name__ == "__main__":
    print(f"Target: {BASE_URL}")
    print("Running against staging — capturing non-2xx responses\n")

    test_list_opportunities()
    test_get_opportunity_details()
    test_search_opportunities()

    print(f"\n\nDone. {total} requests | {len(failures)} failures")

    if failures:
        print("\nFailed requests:")
        for f in failures:
            print(f"  [{f['status_code']}] {f['method']} {f['route']}")
            if f["custom_filters"]:
                print(f"    custom_filters: {f['custom_filters']}")
            print(f"    payload: {f['payload'][:200]}")
            print(f"    response: {f['response_body'][:200]}")

    write_results()
