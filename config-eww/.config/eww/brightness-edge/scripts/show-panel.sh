#!/usr/bin/env bash
# Open the panel window collapsed, then flip `panel_open` once it is mapped
# so the revealer actually animates the slide-in.
CFG="$1"
eww --config "$CFG" open brightness-panel >/dev/null 2>&1
sleep 0.04
eww --config "$CFG" update panel_open=true
