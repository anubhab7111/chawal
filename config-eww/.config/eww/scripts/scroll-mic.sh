#!/usr/bin/env bash
# $1 is the direction eww's `:onscroll` hands us: "up" or "down". PAMIXER: tests.
PAMIXER="${PAMIXER:-pamixer}"
case "$1" in
    up) "$PAMIXER" --default-source -i 5 ;;
    down) "$PAMIXER" --default-source -d 5 ;;
esac
