#!/usr/bin/env bash
# Emits {"brightness": N} for eww's `deflisten`.
#
# The real level is sampled in the background (sysfs doesn't reliably raise
# inotify events, so it polls); this loop *eases* the number eww sees toward
# it, so the gauge fill glides instead of jumping. Small moves (<= 3%, e.g.
# dragging the slider) snap straight through so the fill never lags the pointer.
state="$(mktemp)"
bg=""
cleanup() {
    rm -f "$state"
    # Only our own sampler -- never the process group, which would take the
    # eww daemon down with it.
    [ -n "$bg" ] && { pkill -P "$bg" 2>/dev/null; kill "$bg" 2>/dev/null; }
}
trap cleanup EXIT

(
    while :; do
        brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%' >"$state"
        sleep 0.2
    done
) &
bg=$!

# Sleep without forking: a read with a timeout on a fd nothing writes to.
exec 9<> <(:)
tick() { read -r -t "$1" -u 9 || true; }

shown=""      # fixed-point, percent * 100
last=""
while :; do
    read -r tv <"$state" 2>/dev/null
    [ -z "$tv" ] && { tick 0.05; continue; }
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
    if (( shown == goal )); then tick 0.08; else tick 0.02; fi
done
