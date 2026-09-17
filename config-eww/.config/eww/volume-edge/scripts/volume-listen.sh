#!/usr/bin/env bash
# Emits {"volume": N, "muted": true|false} once immediately, then again on
# every sink volume/mute change, for eww's `deflisten` to pick up live.
emit() {
    printf '{"volume": %s, "muted": %s}\n' "$(pamixer --get-volume)" "$(pamixer --get-mute)"
}

emit
pactl subscribe 2>/dev/null | while read -r line; do
    case "$line" in
        *"on sink"*) emit ;;
    esac
done
