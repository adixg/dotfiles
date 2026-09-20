#!/usr/bin/env python3
"""Format waybar-ai-usage output for the retro Waybar layout."""

import json
import re
import subprocess
import sys


# waybar-ai-usage's format_eta emits "6d18h" (>=24h), "4h57m" (>=1h) and
# "19m30s" (<1h). Every field is optional so the same pattern parses all three.
DURATION = re.compile(
    r"(?:(?P<days>\d+)d)?(?:(?P<hours>\d+)h)?"
    r"(?:(?P<minutes>\d+)m)?(?:(?P<seconds>\d+)s)?"
)

# The 5-hour reset is wrapped in these in the format strings below, so it can
# be formatted differently from everything else. Matching on the "5h" text
# instead is not possible: the bar label itself is the literal "5h".
FIVE_HOUR = re.compile("⟦(.*?)⟧")


def total_hours(value: str) -> float | None:
    match = DURATION.fullmatch(value.strip())
    if not match or not match.group(0):
        return None
    return (
        int(match.group("days") or 0) * 24
        + int(match.group("hours") or 0)
        + int(match.group("minutes") or 0) / 60
        + int(match.group("seconds") or 0) / 3600
    )


def five_hour(value: str) -> str:
    """Time until the 5-hour window resets, always as d.dh (e.g. 4.6h)."""
    hours = total_hours(value)
    if hours is None:
        return value.replace("Not started", "N/A")
    return f"{hours:.1f}h"


def decimal_hours(match: re.Match[str]) -> str:
    """Anything else (the weekly reset): whole hours, one decimal if needed."""
    hours = total_hours(match.group(0))
    if hours.is_integer():
        return f"{int(hours)}h"
    return f"{hours:.1f}h"


def clean(value: str) -> str:
    value = value.replace("Not started", "N/A")
    # split() with one capture group alternates: plain text, 5h reset, text, ...
    parts = FIVE_HOUR.split(value)
    return "".join(
        five_hour(part)
        if index % 2
        else DURATION.sub(
            lambda match: decimal_hours(match) if match.group(0) else "", part
        )
        for index, part in enumerate(parts)
    )


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"claude", "codex"}:
        print("usage: ai-usage.py claude|codex", file=sys.stderr)
        return 2

    provider = sys.argv[1]
    label = "Claude" if provider == "claude" else "Codex"
    format_text = (
        "{icon_plain} 5h {5h_pct}% · {icon_plain} W {7d_pct}% · "
        "{time_icon_plain} ⟦{5h_reset}⟧"
    )
    tooltip = (
        f"{label} usage\\n"
        "5-hour: {5h_pct}% · resets in ⟦{5h_reset}⟧\\n"
        "Weekly: {7d_pct}% · resets in {7d_reset}"
    )
    result = subprocess.run(
        [
            f"/usr/bin/{provider}-usage",
            "--waybar",
            "--format",
            format_text,
            "--tooltip-format",
            tooltip,
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    output = result.stdout.strip()
    if not output:
        return result.returncode

    try:
        payload = json.loads(output)
        payload["text"] = clean(payload.get("text", ""))
        payload["tooltip"] = clean(payload.get("tooltip", ""))
        print(json.dumps(payload))
    except json.JSONDecodeError:
        print(output)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
