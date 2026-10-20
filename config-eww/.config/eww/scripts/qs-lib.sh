#!/usr/bin/env bash
# qs-lib.sh: the pieces the quick-settings scripts share. Source it, do not run it.
#
#   qs_pend ID ON SUB TTL_MS
#
# Show a click at once: record the state the click asked for in $RUN/pend/ID,
# lay it over the state that is on screen ($RUN/state.json, see qs-state), write
# the cache back and push it to eww. The entry ends when the real state agrees
# or after TTL_MS. A control that is missing or disabled is left alone (the
# change itself is the caller's job). The caller sets CFG, RUN and EWW first.
#
# The panel object holds the six toggles under "rows" and the power profile and
# theme under "power" / "theme", so the patch differs per control: power sets the
# profile, theme sets the name, and a toggle patches its row.

qs_pend() { # ID ON SUB TTL_MS
    local id=$1 on=$2 sub=$3 ttl=$4
    local cur now out pend state
    mkdir -p "$RUN/pend"

    cur=$(cat "$RUN/state.json" 2>/dev/null)
    [ -n "$cur" ] || cur=$("$CFG/scripts/qs-state") || return 1 # a click before any poll
    now=$(date +%s%3N)

    # line 1: the pending entry; line 2: the state with the control changed
    out=$(jq -c --arg id "$id" --argjson on "$on" --arg sub "$sub" \
        --argjson now "$now" --argjson ttl "$ttl" '
        def enabled:
            if $id == "theme" then true
            elif $id == "power" then .power.enabled
            else ([.rows[][] | select(.id == $id)][0].enabled) end;
        if (enabled | not) then empty else
            ({on: $on, sub: $sub, exp: ($now + $ttl)}) as $p
            | $p, (if $id == "power" then .power.profile = $sub
                   elif $id == "theme" then .theme = ($sub | ascii_downcase)
                   else .rows |= map(map(if .id == $id
                                         then . + {on: $on, sub: $sub} else . end))
                   end)
        end' <<<"$cur")
    [ -n "$out" ] || return 0

    pend=${out%%$'\n'*}
    state=${out#*$'\n'}
    printf '%s\n' "$pend" >"$RUN/pend/$id"
    printf '%s\n' "$state" >"$RUN/state.json.$$" && mv -f "$RUN/state.json.$$" "$RUN/state.json"
    "$EWW" --config "$CFG" update "qs_state=$state" >/dev/null 2>&1
    return 0
}
