#!/usr/bin/env bash
# Dragging the mic slider is an explicit "I want this level", so unmute too.
# PAMIXER: tests.
PAMIXER="${PAMIXER:-pamixer}"
vol="$(printf '%.0f' "$1")"
"$PAMIXER" --default-source --unmute
"$PAMIXER" --default-source --set-volume "$vol"
