#!/usr/bin/env bash
# Clamp to 1% so dragging the slider to the bottom can't black out the panel.
pct="$(printf '%.0f' "$1")"
(( pct < 1 )) && pct=1
brightnessctl set "${pct}%" >/dev/null
