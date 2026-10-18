#!/usr/bin/env bash
# Dragging the slider is an explicit "set the volume" gesture, so unmute too
# (otherwise a drag away from 0% while muted would look like a no-op).
vol="$(printf '%.0f' "$1")"
pamixer --unmute
pamixer --set-volume "$vol"
