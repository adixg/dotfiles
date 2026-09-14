#!/usr/bin/env bash
# Start hyprsunset at the temperature appropriate for the current time.
#
# The hyprsunset-warm/-day systemd timers only fire at the boundary instants,
# and hyprsunset always starts at its 6000K default. Without this, restarting
# during the evening leaves the display cold until the next boundary - after a
# reboot at 22:00 the screen would stay at 6000K until 20:00 the following day.
#
# Keep WARM/DAY and the hours below in sync with:
#   systemd/user/hyprsunset-warm.service  (temperature)
#   systemd/user/hyprsunset-warm.timer    (WARM_HOUR)
#   systemd/user/hyprsunset-day.timer     (DAY_HOUR)

WARM=3000
DAY=6000
WARM_HOUR=20
DAY_HOUR=5

hour=$(date +%-H)

if (( hour >= WARM_HOUR || hour < DAY_HOUR )); then
    exec hyprsunset -t "$WARM"
else
    exec hyprsunset -t "$DAY"
fi
