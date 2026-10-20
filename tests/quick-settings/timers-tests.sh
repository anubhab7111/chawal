#!/usr/bin/env bash
# Timed Do-not-disturb and Caffeine, the tile sub-text that shows a timer, and
# the eww scripts behind the timers strip (qs-set, qs-timer, qs-more).
#
# Two sandboxes, nothing real is touched:
#   part 1  the real rice-dnd / rice-caffeine / rice-toggle with stub
#           swaync-client, systemd-run, systemctl, busctl, systemd-inhibit, iw
#           and nmcli first on PATH and a temp XDG_RUNTIME_DIR,
#   part 2  copies of the eww scripts under $S2/cfg against stub backends that
#           take a second and a stub eww that logs every update.
set -u

ROOT=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)
SRC=$ROOT/config-eww/.config/eww/scripts
BIN=$ROOT/config-rice/.config/rice/bin
T=$(dirname "$(readlink -f "$0")")

pass=0; fail=0
ok() { # description, then a command whose success is the check
    local d=$1; shift
    if "$@"; then pass=$((pass + 1)); printf '  ok    %s\n' "$d"; else fail=$((fail + 1)); printf '  FAIL  %s\n' "$d"; fi
}
eq() { [ "$1" = "$2" ]; }
lt() { [ "$1" -lt "$2" ]; }
ge() { [ "$1" -ge "$2" ]; }
le() { [ "$1" -le "$2" ]; }
has() { grep -qF -- "$1" "$2"; }
hasnt() { ! grep -qF -- "$1" "$2"; }
is_until() { [[ $1 =~ ^Until\ [0-9]{2}:[0-9]{2}$ ]]; }
until_about() { # sub, minute, next minute (the check may straddle a minute turn)
    [ "$1" = "Until $2" ] || [ "$1" = "Until $3" ]
}
minute() { date -d "@$1" +%H:%M; }
tile() { jq -r --arg id "$2" --arg f "$3" '
    if $id == "power" then
        {on: (.power.profile != "balanced"), sub: .power.profile, enabled: .power.enabled}[$f]
    elif $id == "theme" then
        {on: (.theme == "latte"),
         sub: (if .theme == "latte" then "Latte" else "Mocha" end), enabled: true}[$f]
    else ([.rows[][] | select(.id == $id)][0] | .[$f]) end' <<<"$1"; }
rtile() { jq -r --arg id "$2" "[.[][] | select(.id == \$id)][0].$3" <<<"$1"; } # raw rice-toggle rows
cleanup() { rm -rf "${S1:-}" "${S2:-}"; }
trap cleanup EXIT

# ---- part 1: the rice-* backends ------------------------------------------
S1=$(mktemp -d)
mkdir -p "$S1/bin" "$S1/run"
export XDG_RUNTIME_DIR=$S1/run RICE_BIN=$BIN
export STUB_LOG=$S1/log STUB_DND=$S1/dndstate

cat >"$S1/bin/swaync-client" <<'EOF'
#!/usr/bin/env bash
case "$*" in
"-D -sw") [ "$(cat "$STUB_DND" 2>/dev/null)" = on ] && echo true || echo false ;;
"-dn -sw") echo on >"$STUB_DND" ;;
"-df -sw") echo off >"$STUB_DND" ;;
esac
exit 0
EOF
cat >"$S1/bin/systemd-run" <<'EOF'
#!/usr/bin/env bash
printf 'systemd-run %s\n' "$*" >>"$STUB_LOG"
EOF
cat >"$S1/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf 'systemctl %s\n' "$*" >>"$STUB_LOG"
EOF
cat >"$S1/bin/busctl" <<'EOF'
#!/usr/bin/env bash
case ${2:-} in
get-property)
    case ${6:-} in
    WirelessEnabled | Powered) echo "b true" ;;
    ActiveProfile) echo 's "balanced"' ;;
    esac
    ;;
esac
exit 0
EOF
# systemd-inhibit runs the command after the options (here: sleep N) as the
# holder itself; argv[0] stays "systemd-inhibit" so rice-caffeine's running()
# still recognises it by the process name.
cat >"$S1/bin/systemd-inhibit" <<'EOF'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
    if [ "$1" = sleep ]; then
        shift
        exec -a systemd-inhibit sleep "$@"
    fi
    shift
done
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$S1/bin/iw"
printf '#!/usr/bin/env bash\nexit 0\n' >"$S1/bin/nmcli"
chmod +x "$S1"/bin/*
export PATH=$S1/bin:$PATH

RUN1=$S1/run/rice
fresh1() {
    rm -rf "$S1/run"
    mkdir -p "$RUN1"
    : >"$STUB_LOG"
    echo off >"$STUB_DND"
}

echo "T1  rice-dnd for schedules one timer and a second for replaces it"
fresh1
"$BIN/rice-dnd" for 60
u=$(cat "$RUN1/dnd-until" 2>/dev/null)
ok "DND is on"                        eq "$(cat "$STUB_DND")" on
ok "the expiry is written"            le "$u" "$(( $(date +%s) + 61 ))"
ok "the expiry is about now + 60 s"   ge "$u" "$(( $(date +%s) + 59 ))"
ok "exactly one systemd-run"          eq "$(grep -c '^systemd-run' "$STUB_LOG")" 1
ok "the timer runs this script expire" has "--user --quiet --collect --unit=rice-dnd-timer --on-active=60 $BIN/rice-dnd expire" "$STUB_LOG"
ok "until prints the expiry as HH:MM" eq "$("$BIN/rice-dnd" until)" "$(minute "$u")"
: >"$STUB_LOG"
"$BIN/rice-dnd" for 120
ok "a second for stops the old timer" has "systemctl --user stop rice-dnd-timer.timer rice-dnd-timer.service" "$STUB_LOG"
ok "and schedules the new one after"  has "--on-active=120 $BIN/rice-dnd expire" "$STUB_LOG"
ok "the new expiry replaced the old"  ge "$(cat "$RUN1/dnd-until")" "$u"
stop=$(grep -n '^systemctl' "$STUB_LOG" | head -1 | cut -d: -f1)
sched=$(grep -n '^systemd-run' "$STUB_LOG" | head -1 | cut -d: -f1)
ok "the stop comes before the schedule" lt "$stop" "$sched"

echo "T2  rice-dnd expire only ends a due timer, never during game mode"
fresh1
echo on >"$STUB_DND"
printf '%s\n' "$(( $(date +%s) + 60 ))" >"$RUN1/dnd-until"
"$BIN/rice-dnd" expire
ok "before the time: DND stays on"    eq "$(cat "$STUB_DND")" on
ok "the entry is always cleared"      [ ! -f "$RUN1/dnd-until" ]
fresh1
echo on >"$STUB_DND"
printf '%s\n' "$(( $(date +%s) - 1 ))" >"$RUN1/dnd-until"
"$BIN/rice-dnd" expire
ok "once due: DND goes off"           eq "$(cat "$STUB_DND")" off
ok "and the entry is cleared"         [ ! -f "$RUN1/dnd-until" ]
fresh1
echo on >"$STUB_DND"
printf '%s\n' "$(( $(date +%s) - 1 ))" >"$RUN1/dnd-until"
: >"$RUN1/gamemode"
"$BIN/rice-dnd" expire
ok "game mode on: DND stays on"       eq "$(cat "$STUB_DND")" on
ok "the entry is cleared anyway"      [ ! -f "$RUN1/dnd-until" ]

echo "T3  off, toggle off and on cancel the timer; hold/release still work"
fresh1
"$BIN/rice-dnd" for 60
: >"$STUB_LOG"
"$BIN/rice-dnd" off
ok "off turns DND off"                eq "$(cat "$STUB_DND")" off
ok "off stops the timer"              has "systemctl --user stop rice-dnd-timer.timer rice-dnd-timer.service" "$STUB_LOG"
ok "off removes the entry"            [ ! -f "$RUN1/dnd-until" ]
fresh1
"$BIN/rice-dnd" for 60
: >"$STUB_LOG"
"$BIN/rice-dnd" toggle
ok "toggle off turns DND off"         eq "$(cat "$STUB_DND")" off
ok "toggle off stops the timer"       has "systemctl --user stop" "$STUB_LOG"
ok "toggle off removes the entry"     [ ! -f "$RUN1/dnd-until" ]
fresh1
"$BIN/rice-dnd" for 60
: >"$STUB_LOG"
"$BIN/rice-dnd" on
ok "on leaves DND on"                 eq "$(cat "$STUB_DND")" on
ok "on cancels the timer"             has "systemctl --user stop" "$STUB_LOG"
ok "on removes the entry"             [ ! -f "$RUN1/dnd-until" ]
fresh1
"$BIN/rice-dnd" hold game
ok "hold turns DND on"                eq "$(cat "$STUB_DND")" on
ok "hold remembers it was off"        [ ! -f "$RUN1/dnd-game-was-on" ]
"$BIN/rice-dnd" release game
ok "release turns DND off again"      eq "$(cat "$STUB_DND")" off
fresh1
echo on >"$STUB_DND"
"$BIN/rice-dnd" hold game
ok "hold remembers it was on"         [ -f "$RUN1/dnd-game-was-on" ]
"$BIN/rice-dnd" release game
ok "release leaves it on"             eq "$(cat "$STUB_DND")" on

echo "T4  rice-caffeine for ends by itself; on and for replace a holder"
fresh1
"$BIN/rice-caffeine" for 2
cu=$(cat "$RUN1/caffeine-until" 2>/dev/null)
ok "the timed holder is running"       [ -f "$RUN1/caffeine.pid" ]
ok "its expiry is written"             ge "$cu" "$(( $(date +%s) + 1 ))"
ok "until prints the expiry as HH:MM"  eq "$("$BIN/rice-caffeine" until)" "$(minute "$cu")"
"$BIN/rice-caffeine" status >"$S1/status"
ok "status says on"                    has '"alt":"on"' "$S1/status"
sleep 2.2
"$BIN/rice-caffeine" status >"$S1/status"
ok "the holder ended by itself"        hasnt '"alt":"on"' "$S1/status"
ok "the entry is still on disk"        [ -f "$RUN1/caffeine-until" ]
ok "until prints nothing after it ends" [ -z "$("$BIN/rice-caffeine" until)" ]
ok "until cleaned up the stale entry"  [ ! -f "$RUN1/caffeine-until" ]
fresh1
"$BIN/rice-caffeine" on
p1=$(cat "$RUN1/caffeine.pid")
"$BIN/rice-caffeine" on
p2=$(cat "$RUN1/caffeine.pid")
ok "on replaces a running holder"      [ "$p1" != "$p2" ]
"$BIN/rice-caffeine" for 5
p3=$(cat "$RUN1/caffeine.pid")
ok "for replaces the holder too"       [ "$p2" != "$p3" ]
ok "for writes its own expiry"         [ -f "$RUN1/caffeine-until" ]
"$BIN/rice-caffeine" off
"$BIN/rice-caffeine" status >"$S1/status"
ok "off stops the holder"              hasnt '"alt":"on"' "$S1/status"
ok "off removes the entry"             [ ! -f "$RUN1/caffeine-until" ]

echo "T5  rice-toggle shows the timer in the dnd and caffeine sub text"
fresh1
row=$("$BIN/rice-toggle" rows)
ok "no timer: dnd reads Off"           eq "$(rtile "$row" dnd sub)" Off
ok "no timer: caffeine reads Off"      eq "$(rtile "$row" caffeine sub)" Off
"$BIN/rice-dnd" on
row=$("$BIN/rice-toggle" rows)
ok "plain dnd on reads On"             eq "$(rtile "$row" dnd sub)" On
"$BIN/rice-dnd" for 60
row=$("$BIN/rice-toggle" rows)
ok "a dnd timer reads Until HH:MM"     is_until "$(rtile "$row" dnd sub)"
"$BIN/rice-caffeine" for 5
row=$("$BIN/rice-toggle" rows)
ok "a caffeine timer reads Until HH:MM" is_until "$(rtile "$row" caffeine sub)"
"$BIN/rice-dnd" off
"$BIN/rice-caffeine" off
row=$("$BIN/rice-toggle" rows)
ok "after off dnd reads Off again"     eq "$(rtile "$row" dnd sub)" Off

# ---- part 2: the eww scripts ----------------------------------------------
S2=$(mktemp -d)
mkdir -p "$S2/cfg/scripts" "$S2/bin" "$S2/run"
cp "$SRC/qs-state" "$SRC/qs-opt" "$SRC/qs-lib.sh" "$SRC/qs-flip" \
    "$SRC/qs-set" "$SRC/qs-timer" "$SRC/qs-more" "$S2/cfg/scripts/" 2>/dev/null
cp "$T/stub-rice-toggle" "$S2/bin/rice-toggle"
cp "$T/stub-eww" "$S2/eww"
cat >"$S2/bin/rice-power-profile" <<'EOF'
#!/usr/bin/env bash
S=${STUB_STATE:?}
case ${1:-} in
get) jq -r '[.[] | select(.id == "power")][0].sub // ""' "$S" ;;
set)
    echo "$(date +%s%N) profile-start set $2" >>"$STUB_LOG"
    sleep "${PP_DELAY:-1}"
    jq -c --arg p "$2" 'map(if .id == "power" then .sub = $p | .on = ($p != "balanced") else . end)' "$S" >"$S.tmp" &&
        mv -f "$S.tmp" "$S"
    echo "$(date +%s%N) profile-end set $2" >>"$STUB_LOG"
    ;;
esac
EOF
cat >"$S2/bin/rice-theme" <<'EOF'
#!/usr/bin/env bash
S=${STUB_STATE:?}
case ${1:-} in
get) cat "${STUB_THEME:-/dev/null}" 2>/dev/null ;;
apply)
    echo "$(date +%s%N) theme-start apply $2" >>"$STUB_LOG"
    sleep "${THEME_DELAY:-1}"
    printf '%s' "$2" >"${STUB_THEME:-/dev/null}"
    jq -c --arg n "$2" 'map(if .id == "theme" then .on = ($n == "latte") |
        .sub = (if $n == "latte" then "Latte" else "Mocha" end) else . end)' "$S" >"$S.tmp" &&
        mv -f "$S.tmp" "$S"
    echo "$(date +%s%N) theme-end apply $2" >>"$STUB_LOG"
    ;;
esac
EOF
cat >"$S2/bin/rice-dnd" <<'EOF'
#!/usr/bin/env bash
S=${STUB_STATE:?}
upd() { jq -c --arg id dnd --argjson on "$1" --arg sub "$2" 'map(if .id == $id then .on = $on | .sub = $sub else . end)' "$S" >"$S.tmp" && mv -f "$S.tmp" "$S"; }
case ${1:-} in
for) echo "$(date +%s%N) dnd-for $2" >>"$STUB_LOG"; sleep "${DND_DELAY:-1}"; upd true "Until 23:59" ;;
on) echo "$(date +%s%N) dnd-on" >>"$STUB_LOG"; sleep "${DND_DELAY:-1}"; upd true On ;;
off) echo "$(date +%s%N) dnd-off" >>"$STUB_LOG"; upd false Off ;;
status) jq -r '[.[] | select(.id == "dnd")][0].on' "$S" | sed 's/true/on/;s/false/off/' ;;
esac
EOF
cat >"$S2/bin/rice-caffeine" <<'EOF'
#!/usr/bin/env bash
S=${STUB_STATE:?}
upd() { jq -c --arg id caffeine --argjson on "$1" --arg sub "$2" 'map(if .id == $id then .on = $on | .sub = $sub else . end)' "$S" >"$S.tmp" && mv -f "$S.tmp" "$S"; }
case ${1:-} in
for) echo "$(date +%s%N) caffeine-for $2" >>"$STUB_LOG"; sleep "${CAFF_DELAY:-1}"; upd true "Until 23:59" ;;
on) echo "$(date +%s%N) caffeine-on" >>"$STUB_LOG"; sleep "${CAFF_DELAY:-1}"; upd true On ;;
off) echo "$(date +%s%N) caffeine-off" >>"$STUB_LOG"; upd false Off ;;
esac
EOF
cat >"$S2/bin/rice-hub" <<'EOF'
#!/usr/bin/env bash
echo "$(date +%s%N) rice-hub $*" >>"$STUB_LOG"
EOF
cat >"$S2/cfg/scripts/qs-ctl" <<'EOF'
#!/usr/bin/env bash
echo "$(date +%s%N) qs-ctl $*" >>"$STUB_LOG"
EOF
chmod +x "$S2/bin/"* "$S2/eww" "$S2/cfg/scripts/"*

export RICE_BIN=$S2/bin QS_RUN=$S2/run EWW=$S2/eww
export STUB_STATE=$S2/state STUB_EWW_LOG=$S2/eww.log STUB_EWW_ALL=$S2/eww.all STUB_SEL=$S2/sel STUB_THEME=$S2/theme
export PP_DELAY=1 THEME_DELAY=1 DND_DELAY=1 CAFF_DELAY=1 ROWS_DELAY=0.02
QS2=$S2/cfg/scripts

fresh2() { # wifi on, bluetooth on, dnd off, night on, caffeine off, game off, power performance, theme Mocha
    rm -rf "$S2/run"
    mkdir -p "$S2/run"
    : >"$STUB_LOG"; : >"$S2/eww.log"; : >"$S2/eww.all"
    rm -f "$S2/sel" "$S2/theme"
    cat >"$STUB_STATE" <<'EOF'
[{"id":"wifi","icon":"w","label":"Wi-Fi","on":true,"enabled":true,"sub":"Home"},
 {"id":"bluetooth","icon":"b","label":"Bluetooth","on":true,"enabled":true,"sub":"On"},
 {"id":"dnd","icon":"d","label":"DND","on":false,"enabled":true,"sub":"Off"},
 {"id":"night","icon":"n","label":"Night","on":true,"enabled":true,"sub":"On"},
 {"id":"caffeine","icon":"c","label":"Caffeine","on":false,"enabled":true,"sub":"Off"},
 {"id":"game","icon":"g","label":"Game","on":false,"enabled":true,"sub":"Off"},
 {"id":"power","icon":"p","label":"Power","on":true,"enabled":true,"sub":"performance"},
 {"id":"theme","icon":"t","label":"Theme","on":false,"enabled":true,"sub":"Mocha"}]
EOF
}
# prime the rows cache the way qs-ctl does on open, then run CMD: leave the
# first on-screen update in $opt_rows and its latency in $opt_lat.
run_opt() {
    "$QS2/qs-state" >/dev/null 2>&1
    : >"$S2/eww.log"
    local t0
    t0=$(date +%s%N)
    "$@" &
    opt_pid=$!
    for _ in $(seq 400); do [ -s "$S2/eww.log" ] && break; sleep 0.002; done
    opt_lat=$(( ($(head -1 "$S2/eww.log" | cut -d' ' -f1) - t0) / 1000000 ))
    opt_rows=$(head -1 "$S2/eww.log" | cut -d' ' -f3-)
}
last2() { tail -1 "$S2/eww.log" | cut -d' ' -f3-; }
pend2() { find "$S2/run/pend" -mindepth 1 -maxdepth 1 | wc -l; }

echo "T6  qs-set power: the segment moves at once, the real profile wins"
fresh2
run_opt "$QS2/qs-set" power saver
ok "the first update is under 80 ms"   lt "$opt_lat" 80
ok "the pick shows at once"            eq "$(tile "$opt_rows" power sub)" power-saver
ok "and a non-default profile is on"   eq "$(tile "$opt_rows" power on)" true
wait "$opt_pid"
ok "the backend got the right command" has "profile-start set power-saver" "$STUB_LOG"
ok "the real profile is power-saver"   eq "$(jq -r '[.[] | select(.id == "power")][0].sub' "$STUB_STATE")" power-saver
ok "the last update is the real state" eq "$(tile "$(last2)" power sub)" power-saver
ok "the pending entry is gone"         eq "$(pend2)" 0
fresh2
run_opt "$QS2/qs-set" power balanced
ok "balanced shows off at once"        eq "$(tile "$opt_rows" power on)" false
ok "and its sub is balanced"           eq "$(tile "$opt_rows" power sub)" balanced
wait "$opt_pid"
ok "the backend got balanced"          has "profile-start set balanced" "$STUB_LOG"

echo "T7  qs-set theme: applied once, skipped when already active"
fresh2
run_opt "$QS2/qs-set" theme latte
ok "the first update is under 80 ms"   lt "$opt_lat" 80
ok "Latte shows at once"               eq "$(tile "$opt_rows" theme sub)" Latte
ok "and counts as on"                  eq "$(tile "$opt_rows" theme on)" true
wait "$opt_pid"
ok "the theme was applied"             has "theme-start apply latte" "$STUB_LOG"
ok "the real theme is latte"           eq "$(cat "$STUB_THEME")" latte
ok "the last update is the real state" eq "$(tile "$(last2)" theme sub)" Latte
fresh2
printf latte >"$STUB_THEME"
run_opt "$QS2/qs-set" theme latte
wait "$opt_pid"
ok "the same theme is not applied again" hasnt "theme-start" "$STUB_LOG"
ok "but the pick still shows at once"  eq "$(tile "$opt_rows" theme sub)" Latte

echo "T8  two quick qs-set power clicks run in order (flock)"
fresh2
PP_DELAY=0.4 "$QS2/qs-set" power saver & a=$!
sleep 0.05
PP_DELAY=0.4 "$QS2/qs-set" power performance & b=$!
wait "$a" "$b"
ok "both clicks ran"                   eq "$(grep -c profile-start "$STUB_LOG")" 2
s2=$(grep profile-start "$STUB_LOG" | sed -n 2p | cut -d' ' -f1)
e1=$(grep profile-end "$STUB_LOG" | sed -n 1p | cut -d' ' -f1)
ok "the second started after the first ended" ge "$s2" "$e1"
ok "the last pick is the real state"   eq "$(jq -r '[.[] | select(.id == "power")][0].sub' "$STUB_STATE")" performance

echo "T9  qs-timer starts a real timer and closes the strip"
fresh2
now=$(date +%s)
run_opt "$QS2/qs-timer" dnd 1800
ok "the first update is under 80 ms"   lt "$opt_lat" 80
ok "the sub is Until HH:MM"            is_until "$(tile "$opt_rows" dnd sub)"
ok "for the time now + 1800 s"         until_about "$(tile "$opt_rows" dnd sub)" \
    "$(minute $((now + 1800)))" "$(minute $((now + 1801)))"
ok "and dnd counts as on"              eq "$(tile "$opt_rows" dnd on)" true
wait "$opt_pid"
ok "rice-dnd for 1800 was issued"      has "dnd-for 1800" "$STUB_LOG"
ok "the real dnd state is on"          eq "$(jq -r '[.[] | select(.id == "dnd")][0].on' "$STUB_STATE")" true
ok "the last update is the real state" eq "$(tile "$(last2)" dnd on)" true
ok "the strip was closed (qs_sel=)"    ge "$(grep -c 'qs_sel=' "$S2/eww.all")" 1
fresh2
run_opt "$QS2/qs-timer" caffeine 0
ok "until off shows On at once"        eq "$(tile "$opt_rows" caffeine sub)" On
wait "$opt_pid"
ok "rice-caffeine on was issued"       has "caffeine-on" "$STUB_LOG"
ok "the real caffeine state is on"     eq "$(jq -r '[.[] | select(.id == "caffeine")][0].on' "$STUB_STATE")" true
ok "the strip was closed (qs_sel=)"    ge "$(grep -c 'qs_sel=' "$S2/eww.all")" 1

echo "T10 qs-more: right clicks"
fresh2
"$QS2/qs-more" wifi
for _ in $(seq 100); do has "rice-hub net" "$STUB_LOG" && break; sleep 0.02; done
ok "wifi closes the panel first"       has "qs-ctl close" "$STUB_LOG"
ok "wifi opens the network list"       has "rice-hub net" "$STUB_LOG"
close=$(grep -n 'qs-ctl close' "$STUB_LOG" | head -1 | cut -d: -f1)
hub=$(grep -n 'rice-hub net' "$STUB_LOG" | head -1 | cut -d: -f1)
ok "the close comes before the hub"    lt "$close" "$hub"
fresh2
"$QS2/qs-more" bluetooth
for _ in $(seq 100); do has "rice-hub bt" "$STUB_LOG" && break; sleep 0.02; done
ok "bluetooth opens the Bluetooth list" has "rice-hub bt" "$STUB_LOG"
fresh2
"$QS2/qs-more" dnd
ok "first right-click selects dnd"     eq "$(cat "$STUB_SEL")" dnd
"$QS2/qs-more" dnd
ok "a second one clears it again"      eq "$(cat "$STUB_SEL")" ""
fresh2
"$QS2/qs-more" night
ok "any other tile does nothing"       eq "$(grep -c . "$STUB_LOG")" 0

echo
echo "passed: $pass   failed: $fail"
[ "$fail" = 0 ]
