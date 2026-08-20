#!/usr/bin/env python3
"""Collect minimal state for Bryan's recurring weekly orientation invitation."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

HOME = Path.home()
SECOND_BRAIN = HOME / "second-brain"
PACIFIC = ZoneInfo("America/Los_Angeles")


def next_monday(day):
    current_monday = day - timedelta(days=day.weekday())
    return current_monday + timedelta(days=7)


def main() -> int:
    now = datetime.now(PACIFIC)
    week_start = next_monday(now.date())
    next_hub = SECOND_BRAIN / "Journal" / f"{week_start.isoformat()}-weekly-plan.md"
    payload = {
        "generatedAt": now.isoformat(),
        "timezone": "America/Los_Angeles",
        "checkIn": {
            "nextWeekStart": week_start.isoformat(),
            "nextWeekHubPath": str(next_hub),
            "nextWeekHubExists": next_hub.is_file(),
            "alreadyCompleted": next_hub.is_file(),
        },
    }
    json.dump(payload, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
