#!/usr/bin/env python3

"""Tmux status widget for rolling 4-hour model spend."""

from __future__ import annotations

import json
import os
import sqlite3
import sys
import tempfile
import time
import urllib.request
from decimal import Decimal, InvalidOperation
from pathlib import Path

WINDOW_HOURS = 4
PRICE_CACHE_TTL_SECONDS = 24 * 60 * 60
PRICING_URL = "https://openrouter.ai/api/v1/models"
DB_PATH = Path.home() / ".local/share/opencode/opencode.db"
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir())
PRICE_CACHE_PATH = RUNTIME_DIR / "tmux-token-usage-cost-prices.json"

COLOR_GREEN = "#3EFFDC"
COLOR_YELLOW = "#FFDA7B"
COLOR_RED = "#FF4A4A"


def load_price_cache() -> dict[str, dict[str, Decimal]]:
    cached = read_cached_prices(enforce_ttl=True)
    if cached is not None:
        return cached

    try:
        prices = fetch_prices()
    except Exception:
        stale = read_cached_prices(enforce_ttl=False)
        if stale is not None:
            return stale
        raise

    write_cached_prices(prices)
    return prices


def read_cached_prices(*, enforce_ttl: bool) -> dict[str, dict[str, Decimal]] | None:
    if not PRICE_CACHE_PATH.exists():
        return None

    age = time.time() - PRICE_CACHE_PATH.stat().st_mtime
    if enforce_ttl and age > PRICE_CACHE_TTL_SECONDS:
        return None

    try:
        payload = json.loads(PRICE_CACHE_PATH.read_text())
    except (json.JSONDecodeError, OSError):
        return None

    return deserialize_prices(payload)


def write_cached_prices(prices: dict[str, dict[str, Decimal]]) -> None:
    payload = {
        "fetched_at": int(time.time()),
        "prices": {
            model_id: {key: str(value) for key, value in values.items()}
            for model_id, values in prices.items()
        },
    }

    tmp_path = PRICE_CACHE_PATH.with_suffix(".tmp")
    tmp_path.write_text(json.dumps(payload, separators=(",", ":")))
    tmp_path.replace(PRICE_CACHE_PATH)


def deserialize_prices(payload: dict) -> dict[str, dict[str, Decimal]]:
    prices: dict[str, dict[str, Decimal]] = {}
    raw_prices = payload.get("prices", {})
    if not isinstance(raw_prices, dict):
        return prices

    for model_id, values in raw_prices.items():
        if not isinstance(values, dict):
            continue
        parsed: dict[str, Decimal] = {}
        for key in ("prompt", "completion", "input_cache_read", "input_cache_write"):
            try:
                parsed[key] = Decimal(str(values.get(key, "0")))
            except (InvalidOperation, TypeError):
                parsed[key] = Decimal("0")
        prices[model_id] = parsed
    return prices


def fetch_prices() -> dict[str, dict[str, Decimal]]:
    request = urllib.request.Request(
        PRICING_URL,
        headers={
            "Accept": "application/json",
            "User-Agent": "dotfiles-token-usage-cost/1.0",
        },
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)

    prices: dict[str, dict[str, Decimal]] = {}
    for item in payload.get("data", []):
        model_id = item.get("id")
        pricing = item.get("pricing") or {}
        if not model_id or not isinstance(pricing, dict):
            continue

        parsed: dict[str, Decimal] = {}
        for key in ("prompt", "completion", "input_cache_read", "input_cache_write"):
            try:
                parsed[key] = Decimal(str(pricing.get(key, "0")))
            except (InvalidOperation, TypeError):
                parsed[key] = Decimal("0")
        prices[model_id] = parsed

    return prices


def anthropic_dot_version(model: str) -> str | None:
    prefixes = ("claude-opus-", "claude-sonnet-", "claude-haiku-")
    for prefix in prefixes:
        if not model.startswith(prefix):
            continue
        suffix = model.removeprefix(prefix)
        parts = suffix.split("-")
        if len(parts) >= 2 and parts[0].isdigit() and parts[1].isdigit():
            dotted = f"{parts[0]}.{parts[1]}"
            remainder = "-".join(parts[2:])
            return f"{prefix}{dotted}" + (f"-{remainder}" if remainder else "")
    return None


def price_candidates(provider: str, model: str) -> list[str]:
    full_id = f"{provider}/{model}"
    candidates = [full_id, model]

    if provider == "opencode":
        candidates.extend([f"openai/{model}", model])
        dotted = anthropic_dot_version(model)
        if dotted:
            candidates.extend([f"anthropic/{dotted}", dotted])

    if provider == "anthropic":
        dotted = anthropic_dot_version(model)
        if dotted:
            candidates.extend([f"anthropic/{dotted}", dotted])

    if provider == "openai":
        candidates.extend([f"openai/{model}", model])

    deduped: list[str] = []
    seen = set()
    for candidate in candidates:
        if candidate and candidate not in seen:
            seen.add(candidate)
            deduped.append(candidate)
    return deduped


def recent_usage_rows() -> list[dict[str, int | str]]:
    if not DB_PATH.exists():
        return []

    cutoff = int((time.time() - WINDOW_HOURS * 60 * 60) * 1000)
    query = """
        SELECT
            COALESCE(json_extract(data, '$.providerID'), '') AS provider,
            COALESCE(json_extract(data, '$.modelID'), '') AS model,
            SUM(COALESCE(json_extract(data, '$.tokens.input'), 0)) AS input_tokens,
            SUM(COALESCE(json_extract(data, '$.tokens.output'), 0)) AS output_tokens,
            SUM(COALESCE(json_extract(data, '$.tokens.reasoning'), 0)) AS reasoning_tokens,
            SUM(COALESCE(json_extract(data, '$.tokens.cache.read'), 0)) AS cache_read_tokens,
            SUM(COALESCE(json_extract(data, '$.tokens.cache.write'), 0)) AS cache_write_tokens
        FROM message
        WHERE json_extract(data, '$.role') = 'assistant'
          AND time_created >= ?
          AND json_extract(data, '$.modelID') IS NOT NULL
        GROUP BY provider, model
    """

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(query, (cutoff,)).fetchall()
    finally:
        conn.close()

    return [dict(row) for row in rows]


def calculate_cost(
    usage_rows: list[dict[str, int | str]],
    prices: dict[str, dict[str, Decimal]],
) -> tuple[Decimal, list[str]]:
    total = Decimal("0")
    unresolved: list[str] = []

    for row in usage_rows:
        provider = str(row["provider"])
        model = str(row["model"])
        price = None
        for candidate in price_candidates(provider, model):
            price = prices.get(candidate)
            if price is not None:
                break

        if price is None:
            unresolved.append(f"{provider}/{model}" if provider else model)
            continue

        input_tokens = Decimal(int(row["input_tokens"]))
        output_tokens = Decimal(int(row["output_tokens"]))
        reasoning_tokens = Decimal(int(row["reasoning_tokens"]))
        cache_read_tokens = Decimal(int(row["cache_read_tokens"]))
        cache_write_tokens = Decimal(int(row["cache_write_tokens"]))

        prompt_cost = input_tokens * price.get("prompt", Decimal("0"))
        completion_cost = (output_tokens + reasoning_tokens) * price.get("completion", Decimal("0"))
        cache_read_cost = cache_read_tokens * price.get("input_cache_read", Decimal("0"))
        cache_write_cost = cache_write_tokens * price.get("input_cache_write", price.get("prompt", Decimal("0")))
        total += prompt_cost + completion_cost + cache_read_cost + cache_write_cost

    return total, unresolved


def select_color(total_cost: Decimal) -> str:
    if total_cost >= Decimal("25"):
        return COLOR_RED
    if total_cost >= Decimal("10"):
        return COLOR_YELLOW
    return COLOR_GREEN


def format_total(total_cost: Decimal, approximate: bool) -> str:
    quantized = total_cost.quantize(Decimal("0.01"))
    prefix = "~" if approximate else ""
    return f"{prefix}${quantized}/4h"


def main() -> int:
    try:
        prices = load_price_cache()
        usage_rows = recent_usage_rows()
    except Exception:
        return 0

    total_cost, unresolved = calculate_cost(usage_rows, prices)
    color = select_color(total_cost)
    display = format_total(total_cost, approximate=bool(unresolved))
    sys.stdout.write(f"#[fg={color}]💸 {display}#[fg=default] | ")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
