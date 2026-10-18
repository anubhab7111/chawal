#!/usr/bin/env bash
# Emits {"brightness": N} for eww's `deflisten`.
#
# The level is read with brightnessctl (sysfs doesn't reliably raise inotify
# events) and the number eww sees is *eased* toward it, so the gauge fill
# glides instead of jumping. Small moves (<= 3%, e.g. dragging the slider)
# snap straight through so the fill never lags the pointer.
#
# Idle cost: while the gauge is hidden (no $RUN/brightness.visible) this sleeps
# indefinitely; edge-ctl wakes it with SIGUSR1 right after creating that file.
# While visible it re-reads five times a second.
RUN="${EDGE_RUN:-${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/rice/edge}" # EDGE_RUN: tests
VIS="$RUN/brightness.visible"
mkdir -p "$RUN"
printf '%s' "$$" >"$RUN/brightness.listener"
trap 'rm -f "$RUN/brightness.listener"' EXIT
trap ':' USR1 # only here to interrupt the sleep below

# Sleep without forking: a read with a timeout on a fd nothing writes to.
exec 9<> <(:)
tick() { read -r -t "$1" -u 9 || true; }

sample() { tv=$(brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%'); }

shown=""      # fixed-point, percent * 100
last=""
since=99      # loop turns since the last read (animating turns skip most reads)
tv=""
while :; do
    if [ -z "$tv" ] || (( shown == goal )) || (( since >= 10 )); then
        sample
        since=0
    fi
    since=$(( since + 1 ))
    [ -z "$tv" ] && { tick 0.1; continue; }
    goal=$(( tv * 100 ))
    if [ -z "$shown" ]; then
        shown=$goal
    else
        delta=$(( goal - shown ))
        if (( delta > -300 && delta < 300 )); then
            shown=$goal
        else
            shown=$(( shown + delta * 35 / 100 ))
        fi
    fi
    out=$(( (shown + 50) / 100 ))
    if [ "$out" != "$last" ]; then
        printf '{"brightness": %s}\n' "$out"
        last="$out"
    fi
    if (( shown != goal )); then
        tick 0.02
    elif [ -e "$VIS" ]; then
        tick 0.2
    else
        tick 3600
    fi
done
