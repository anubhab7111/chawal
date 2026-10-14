#!/usr/bin/env bash
# Emits {"brightness": N} once immediately, then again whenever the
# backlight level changes (sysfs doesn't reliably raise inotify events, so
# this polls cheaply and only prints on change), for eww's `deflisten`.
last=""
while :; do
    cur="$(brightnessctl -m 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%')"
    if [ -n "$cur" ] && [ "$cur" != "$last" ]; then
        printf '{"brightness": %s}\n' "$cur"
        last="$cur"
    fi
    sleep 0.25
done
