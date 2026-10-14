#!/usr/bin/env bash
# Waybar custom/media module: one long-running playerctl follower instead
# of polling. `playerctl --follow` re-prints the format line whenever the
# player's status or metadata changes (and an empty line once no player is
# left); each line is turned into Waybar JSON by jq, which takes care of
# escaping quotes, backslashes and control characters in titles.
#
# Fields are split on the ASCII unit separator rather than tabs: tabs are
# IFS whitespace, so an empty artist field would collapse into its neighbour.

MAX_LENGTH=40
SEP=$'\x1f'

coproc FOLLOW {
    exec playerctl --follow metadata \
        --format "{{status}}${SEP}{{playerName}}${SEP}{{artist}}${SEP}{{title}}" 2>/dev/null
}
follower=$FOLLOW_PID
# Keep our own copy of the read end: bash closes the coproc's fds as soon as
# it exits, which would drop any lines still buffered in the pipe.
exec {in}<&"${FOLLOW[0]}"

# Waybar only signals this script, so take the follower down with it.
trap 'kill "$follower" 2>/dev/null' EXIT
trap 'exit 0' TERM INT HUP

while IFS="$SEP" read -r status player artist title <&"$in"; do
    # A failed write means Waybar has gone away: stop instead of lingering.
    jq -cn --arg status "$status" --arg player "$player" \
        --arg artist "$artist" --arg title "$title" --argjson max "$MAX_LENGTH" '
        if ($status == "Playing" or $status == "Paused") and $title != "" then
            (if $artist != "" then "\($artist) - \($title)" else $title end) as $media
            | {
                text: "\(if $status == "Playing" then "󰏤" else "󰐊" end) \(
                    if ($media | length) > $max then $media[:$max] + "..." else $media end)",
                tooltip: "\($status): \($media)\n\($player)",
                class: $status
              }
        else
            {text: "", tooltip: "", class: "stopped"}
        end' || exit 0
done
