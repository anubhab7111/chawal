#!/usr/bin/env bash
# $1 is the direction eww's `:onscroll` hands us: "up" or "down".
case "$1" in
    up) pamixer -i 5 ;;
    down) pamixer -d 5 ;;
esac
