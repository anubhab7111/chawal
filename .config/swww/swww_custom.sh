#!/bin/sh

# Usage: ./wallrotate.sh /path/to/wallpapers [interval]
# Default interval = 600s (10 mins)

DEFAULT_INTERVAL=600

if [ $# -lt 1 ] || [ ! -d "$1" ]; then
	printf "Usage:\n\t\e[1m%s\e[0m \e[4mDIRECTORY\e[0m [\e[4mINTERVAL\e[0m]\n" "$0"
	printf "\n\tChanges the wallpaper to a randomly chosen image in DIRECTORY every\n\tINTERVAL seconds (or every %d seconds if unspecified).\n" "$DEFAULT_INTERVAL"
	exit 1
fi

DIR="$1"
INTERVAL="${2:-$DEFAULT_INTERVAL}"

export SWWW_TRANSITION_FPS="${SWWW_TRANSITION_FPS:-60}"
export SWWW_TRANSITION_STEP="${SWWW_TRANSITION_STEP:-2}"
RESIZE_TYPE="stretch"

while true; do
	IMG=$(find "$DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n 1)
	if [ -n "$IMG" ]; then
		swww img --resize="$RESIZE_TYPE" "$IMG"
	fi
	sleep "$INTERVAL"
done

