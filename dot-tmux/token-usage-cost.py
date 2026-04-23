#!/usr/bin/env python3

"""Tmux status widget for rolling 24-hour opencode spend.

Reads per-message cost directly from the opencode SQLite DB. OpenRouter (and
other providers opencode supports) return exact USD cost in every inference
response via OpenRouter's Usage Accounting; opencode persists that value as
`data.cost` on each assistant message. No network calls, no pricing tables.
"""

from __future__ import annotations

import sqlite3
import sys
import time
from pathlib import Path

WINDOW_HOURS = 24
DB_PATH = Path.home() / ".local/share/opencode/opencode.db"

COLOR_GREEN = "#3EFFDC"
COLOR_YELLOW = "#FFDA7B"
COLOR_RED = "#FF4A4A"


def recent_spend_usd() -> float:
    if not DB_PATH.exists():
        return 0.0

    cutoff_ms = int((time.time() - WINDOW_HOURS * 60 * 60) * 1000)
    query = """
        SELECT COALESCE(SUM(CAST(json_extract(data, '$.cost') AS REAL)), 0)
        FROM message
        WHERE json_extract(data, '$.role') = 'assistant'
          AND time_created >= ?
    """

    conn = sqlite3.connect(f"file:{DB_PATH}?mode=ro", uri=True)
    try:
        (total,) = conn.execute(query, (cutoff_ms,)).fetchone()
    finally:
        conn.close()

    return float(total or 0.0)


def select_color(total_cost: float) -> str:
    if total_cost >= 45:
        return COLOR_RED
    if total_cost >= 10:
        return COLOR_YELLOW
    return COLOR_GREEN


def format_total(total_cost: float) -> str:
    return f"${total_cost:.2f}/{WINDOW_HOURS}h"


def main() -> int:
    try:
        total_cost = recent_spend_usd()
    except Exception:
        return 0

    if total_cost <= 0:
        return 0

    color = select_color(total_cost)
    display = format_total(total_cost)
    sys.stdout.write(f"#[fg={color}]💸 {display}#[fg=default] | ")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
