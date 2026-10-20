#!/usr/bin/env bash
# Tests for the instant quick-settings toggles (qs-opt, qs-flip, qs-state) against stub backends.
# Everything lives in a temp sandbox: no real toggle, eww daemon or runtime dir is touched.
W=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd) # the repo root
SRC=$W/config-eww/.config/eww/scripts
T=$(dirname "$(readlink -f "$0")")                       # this test dir
S=$(mktemp -d)
mkdir -p "$S/cfg/scripts" "$S/bin" "$S/run"
cp "$SRC/qs-state" "$SRC/qs-opt" "$SRC/qs-lib.sh" "$SRC/qs-flip" "$S/cfg/scripts/"
cp "$T/stub-rice-toggle" "$S/bin/rice-toggle"; cp "$T/stub-eww" "$S/eww"
chmod +x "$S/bin/rice-toggle" "$S/eww" "$S"/cfg/scripts/*

export RICE_BIN=$S/bin QS_RUN=$S/run EWW=$S/eww STUB_STATE=$S/state STUB_LOG=$S/stub.log STUB_EWW_LOG=$S/eww.log
QSR=$S/cfg/scripts/qs-state QSF=$S/cfg/scripts/qs-flip QSO=$S/cfg/scripts/qs-opt

fresh() { # reset the sandbox state: wifi on, bluetooth on, dnd off, night on, caffeine off, game off, power performance, theme Mocha
    rm -rf "$S/run" "$S/eww.log" "$S/stub.log" "$S/state.tmp"; mkdir -p "$S/run"
    : >"$S/eww.log"; : >"$S/stub.log"
    cat >"$S/state" <<'EOF'
[{"id":"wifi","icon":"w","label":"Wi-Fi","on":true,"enabled":true,"sub":"Home"},
 {"id":"bluetooth","icon":"b","label":"Bluetooth","on":true,"enabled":true,"sub":"On"},
 {"id":"dnd","icon":"d","label":"DND","on":false,"enabled":true,"sub":"Off"},
 {"id":"night","icon":"n","label":"Night","on":true,"enabled":true,"sub":"On"},
 {"id":"caffeine","icon":"c","label":"Caffeine","on":false,"enabled":true,"sub":"Off"},
 {"id":"game","icon":"g","label":"Game","on":false,"enabled":true,"sub":"Off"},
 {"id":"power","icon":"p","label":"Power","on":true,"enabled":true,"sub":"performance"},
 {"id":"theme","icon":"t","label":"Theme","on":false,"enabled":true,"sub":"Mocha"}]
EOF
    unset FLIP_FAIL QS_PEND_MS
}
ms() { echo $(( $(date +%s%N) / 1000000 )); }
tile() { # JSON state, id, field
    jq -r --arg id "$2" --arg f "$3" '
        if $id == "power" then
            {on: (.power.profile != "balanced"), sub: .power.profile, enabled: .power.enabled}[$f]
        elif $id == "theme" then
            {on: (.theme == "latte"),
             sub: (if .theme == "latte" then "Latte" else "Mocha" end), enabled: true}[$f]
        else ([.rows[][] | select(.id == $id)][0] | .[$f]) end' <<<"$1"
}
last_update() { tail -1 "$S/eww.log" | cut -d' ' -f3-; }
n_updates() { grep -c . "$S/eww.log"; }
pend_count() { find "$S/run/pend" -mindepth 1 -maxdepth 1 | wc -l; }

pass=0; fail=0
ok() { # description, then a command whose success is the check
    local d=$1; shift
    if "$@"; then pass=$((pass + 1)); printf '  ok    %s\n' "$d"; else fail=$((fail + 1)); printf '  FAIL  %s\n' "$d"; fi
}
eq() { [ "$1" = "$2" ]; }
lt() { [ "$1" -lt "$2" ]; }

echo "T1  a click shows at once; the real change follows; the real state wins"
fresh; "$QSR" >/dev/null           # the panel is open: rows cached
t0=$(date +%s%N); "$QSF" wifi & fp=$!
for _ in $(seq 200); do [ -s "$S/eww.log" ] && break; sleep 0.002; done
first_ns=$(head -1 "$S/eww.log" | cut -d' ' -f1)
first=$(head -1 "$S/eww.log" | cut -d' ' -f3-)
lat=$(( (first_ns - t0) / 1000000 ))
echo "      first on-screen update after ${lat} ms (the change itself takes 500 ms)"
ok "first update arrives in under 80 ms"            lt "$lat" 80
ok "it shows wifi switched off"                      eq "$(tile "$first" wifi on)" false
ok "it shows the tile text for off"                  eq "$(tile "$first" wifi sub)" Off
ok "nothing else on screen changed (bluetooth on)"   eq "$(tile "$first" bluetooth on)" true
wait $fp
fin=$(last_update)
ok "after the change: wifi really off"               eq "$(jq -r '.[0].on' "$S/state")" false
ok "the last update is the real state, wifi off"     eq "$(tile "$fin" wifi on)" false
ok "pending entry cleared once state agrees"         eq "$(pend_count)" 0

echo "T2  a poll that runs during the change does not flip the tile back"
fresh; "$QSR" >/dev/null
"$QSF" dnd & fp=$!
sleep 0.15                                          # the change (500 ms) is under way, the real state is still off
poll=$("$QSR")
ok "poll mid-change still shows dnd on (the click)"  eq "$(tile "$poll" dnd on)" true
wait $fp
poll=$("$QSR")
ok "poll after the change shows dnd on (real)"       eq "$(tile "$poll" dnd on)" true
ok "and the pending entry is gone"                   eq "$(pend_count)" 0

echo "T3  a change that does not happen shows its real state again"
fresh; export FLIP_FAIL=1 QS_PEND_MS=700; "$QSR" >/dev/null
"$QSF" night; fin=$(last_update)                     # the change failed (no state change); entry still pending
ok "right after the failed change the click still shows (pending)" eq "$(tile "$fin" night on)" false
sleep 0.8
poll=$("$QSR")
ok "after the entry runs out the real state is back (night on)" eq "$(tile "$poll" night on)" true
ok "entry removed"                                   eq "$(pend_count)" 0
unset FLIP_FAIL QS_PEND_MS

echo "T4  two quick clicks on one tile are applied in order and end where they started"
fresh; export FLIP_DELAY=0.3; "$QSR" >/dev/null
"$QSF" caffeine & a=$!
sleep 0.05
"$QSF" caffeine & b=$!
sleep 0.1
mid=$(jq -r '.[0] | .on' <<<"[$(last_update | jq -c '[.rows[][] | select(.id == "caffeine")][0]')]")
ok "after click 2 the screen shows caffeine off again (optimistic)" eq "$mid" false
wait $a $b
ok "real state ended off (flipped twice)"            eq "$(jq -r '[.[] | select(.id == "caffeine")][0].on' "$S/state")" false
ok "the final update shows off"                      eq "$(tile "$(last_update)" caffeine on)" false
starts=$(grep -c flip-start "$S/stub.log"); ends=$(grep -c flip-end "$S/stub.log")
ok "both changes ran ($starts started, $ends finished)" eq "$starts-$ends" 2-2
# serialised: second start is after first end
s2=$(grep flip-start "$S/stub.log" | sed -n 2p | cut -d' ' -f1); e1=$(grep flip-end "$S/stub.log" | sed -n 1p | cut -d' ' -f1)
ok "the second change started after the first ended" [ "$s2" -ge "$e1" ]
unset FLIP_DELAY

echo "T5  the power profile cycles on screen first"
fresh; "$QSR" >/dev/null
"$QSF" power & fp=$!
sleep 0.1
mid=$(last_update)
ok "on screen: performance -> power-saver at once"   eq "$(tile "$mid" power sub)" power-saver
ok "and the tile is still 'on' (not balanced)"       eq "$(tile "$mid" power on)" true
wait $fp
ok "real profile is power-saver"                     eq "$(jq -r '[.[] | select(.id == "power")][0].sub' "$S/state")" power-saver
ok "pending entry cleared"                           eq "$(pend_count)" 0

echo "T6  a disabled tile ignores clicks; a click before the first poll still works"
fresh; jq -c 'map(if .id == "power" then .enabled = false else . end)' "$S/state" >"$S/s2" && mv "$S/s2" "$S/state"
"$QSR" >/dev/null; : >"$S/eww.log"
"$QSO" power
ok "disabled tile: no screen update"                 eq "$(n_updates)" 0
fresh; "$QSO" bluetooth                              # no rows.json yet
ok "cold start: update still sent"                   eq "$(n_updates)" 1
ok "cold start: bluetooth shown off"                 eq "$(tile "$(last_update)" bluetooth on)" false

echo "T7  time budget of the instant path with a slow backend (rows 1 s, change 2 s)"
fresh; export ROWS_DELAY=1 FLIP_DELAY=2; "$QSR" >/dev/null
t0=$(date +%s%N); "$QSF" theme & fp=$!
for _ in $(seq 400); do [ -s "$S/eww.log" ] && break; sleep 0.002; done
lat=$(( ($(head -1 "$S/eww.log" | cut -d' ' -f1) - t0) / 1000000 ))
echo "      first on-screen update after ${lat} ms"
ok "still under 80 ms however slow the backend is"   lt "$lat" 80
kill $fp 2>/dev/null; wait $fp 2>/dev/null
unset ROWS_DELAY FLIP_DELAY

echo "T8  the state object the panel binds to"
fresh; st=$("$QSR")
ok "three rows of tiles"               eq "$(jq -c '[.rows[] | length]' <<<"$st")" "[2,2,2]"
ok "the power profile is on it"        eq "$(jq -r '.power.profile' <<<"$st")" performance
ok "and its control is enabled"        eq "$(jq -r '.power.enabled' <<<"$st")" true
ok "the theme is mocha"                eq "$(jq -r '.theme' <<<"$st")" mocha
ok "the chevron only on the four tiles" eq \
    "$(jq -r '[.rows[][] | select(.more)] | map(.id) | join(",")' <<<"$st")" "wifi,bluetooth,dnd,caffeine"
ok "power and theme are not tiles"     eq \
    "$(jq -r '[.rows[][] | select(.id == "power" or .id == "theme")] | length' <<<"$st")" 0
fresh; "$QSR" >/dev/null
"$QSO" power
ok "a power click moves the segment at once" eq "$(tile "$(last_update)" power sub)" power-saver
ok "and the segment reads on (not balanced)"  eq "$(tile "$(last_update)" power on)" true
ok "a poll during the change keeps the pick"  eq "$(tile "$("$QSR")" power sub)" power-saver
fresh; "$QSR" >/dev/null
"$QSO" theme
ok "a theme click shows latte at once"        eq "$(tile "$(last_update)" theme sub)" Latte
ok "and the theme field flips to latte"       eq "$(jq -r '.theme' <<<"$(last_update)")" latte
fresh; "$QSR" >/dev/null
"$QSO" dnd
ok "a toggle click still patches its row"     eq "$(tile "$(last_update)" dnd on)" true
ok "and leaves power alone"                   eq "$(jq -r '.power.profile' <<<"$(last_update)")" performance

echo
echo "passed: $pass   failed: $fail"
rm -rf "$S"
[ "$fail" = 0 ]
