#!/bin/bash

# Waybar custom media module script
# Uses playerctl to get currently playing media info

MAX_LENGTH=40

get_media_info() {
    player_status=$(playerctl status 2>/dev/null)

    if [[ "$player_status" == "Playing" || "$player_status" == "Paused" ]]; then
        artist=$(playerctl metadata artist 2>/dev/null)
        title=$(playerctl metadata title 2>/dev/null)

        if [[ -n "$title" ]]; then
            if [[ -n "$artist" ]]; then
                media_text="$artist - $title"
            else
                media_text="$title"
            fi

            # Truncate if too long
            if [[ ${#media_text} -gt $MAX_LENGTH ]]; then
                media_text="${media_text:0:$MAX_LENGTH}..."
            fi

            if [[ "$player_status" == "Playing" ]]; then
                icon="󰏤"
                status_text="Playing"
            else
                icon="󰐊"
                status_text="Paused"
            fi

            # JSON output for waybar
            printf '{"text": "%s %s", "tooltip": "%s\\n%s", "class": "%s"}\n' \
                "$icon" "$media_text" "$status_text: $artist - $title" \
                "$(playerctl metadata --format '{{playerName}}')" \
                "$player_status"
        else
            echo '{"text": "", "tooltip": "", "class": "stopped"}'
        fi
    else
        echo '{"text": "", "tooltip": "", "class": "stopped"}'
    fi
}

get_media_info
