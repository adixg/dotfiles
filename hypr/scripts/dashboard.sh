#!/usr/bin/env bash
# Build (or re-attach to) the "wall" tmux dashboard.
#
# Panes are launched as the pane command directly rather than with send-keys,
# which targets whichever pane happens to be active and can land keystrokes in
# the wrong one.
#
# Layout:   btop across the top
#           gping bottom-left, asciiquarium bottom-right
#
# Swap the bottom-right pane by changing FILLER below. Anything that redraws
# to fit its pane works: asciiquarium, cmatrix, cava, "vnstat -l",
# "journalctl -f", "watch -n5 sensors".
#
# Detach with prefix-d; the session keeps running with no display attached,
# so it survives logout and can be re-attached over Tailscale.

SESSION=wall
PING_TARGET=${PING_TARGET:-1.1.1.1}
FILLER=${FILLER:-asciiquarium}

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session  -d -s "$SESSION" -n dash btop
    tmux split-window -v -l 40% -t "$SESSION:dash" gping "$PING_TARGET"
    tmux split-window -h -l 50% -t "$SESSION:dash" $FILLER
    tmux select-pane  -t "$SESSION:dash".0
fi

exec tmux attach -t "$SESSION"
