#!/usr/bin/env bash
# $1 is the direction eww's `:onscroll` hands us: "up" or "down".
case "$1" in
    up) brightnessctl set +5% >/dev/null ;;
    down) brightnessctl set 5%- >/dev/null ;;
esac
