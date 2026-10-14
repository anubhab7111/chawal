#!/usr/bin/env bash
# Emits {"volume": N, "muted": true|false} for eww's `deflisten`.
#
# The real level is tracked in the background (once now, then on every sink
# change); this loop *eases* the number eww sees toward it, so the gauge fill
# glides instead of jumping. Small moves (<= 3%, e.g. dragging the slider)
# snap straight through so the fill never lags behind the pointer.
state="$(mktemp)"
bg=""
cleanup() {
    rm -f "$state"
    # Only our own sampler (and its pactl child) -- never the process group,
    # which would take the eww daemon down with it.
    [ -n "$bg" ] && { pkill -P "$bg" 2>/dev/null; kill "$bg" 2>/dev/null; }
}
trap cleanup EXIT

sample() {
    printf '%s %s\n' "$(pamixer --get-volume)" "$(pamixer --get-mute)" >"$state"
}

(
    sample
    pactl subscribe 2>/dev/null | while read -r line; do
        case "$line" in
            *"on sink"*) sample ;;
        esac
    done
) &
bg=$!

# Sleep without forking: a read with a timeout on a fd nothing writes to.
exec 9<> <(:)
tick() { read -r -t "$1" -u 9 || true; }

shown=""      # fixed-point, percent * 100
last=""
while :; do
    read -r tv muted <"$state" 2>/dev/null || { tick 0.05; continue; }
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
    cur="$out $muted"
    if [ "$cur" != "$last" ]; then
        printf '{"volume": %s, "muted": %s}\n' "$out" "$muted"
        last="$cur"
    fi
    if (( shown == goal )); then tick 0.08; else tick 0.02; fi
done
