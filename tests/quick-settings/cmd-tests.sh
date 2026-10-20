#!/usr/bin/env bash
# What commands do rice-toggle flip / rice-power-profile issue? Logging stubs for busctl, nmcli,
# bluetoothctl, rfkill and tlpctl stand in for the real ones, so nothing real is touched.
W=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd) # the repo root
BIN=$W/config-rice/.config/rice/bin
S=$(mktemp -d); mkdir -p "$S/stubs" "$S/run"
LOG=$S/cmds.log

mk() { # name: a stub that logs its argv; behaviour from env: <NAME>_RC (exit code), BUS_GET (what get-property prints)
    cat >"$S/stubs/$1" <<EOF
#!/usr/bin/env bash
echo "$1 \$*" >>"$LOG"
EOF
}
mk nmcli; mk bluetoothctl; mk rfkill; mk tlpctl
cat >"$S/stubs/busctl" <<EOF
#!/usr/bin/env bash
echo "busctl \$*" >>"$LOG"
case \$2 in
get-property)
    case \$6 in
    WirelessEnabled|Powered) [ -n "\${BUS_FAIL:-}" ] && exit 1; echo "b \${BUS_BOOL:-true}"; exit 0 ;;
    ActiveProfile) [ -n "\${BUS_FAIL:-}" ] && exit 1; echo "s \"\${BUS_PROFILE:-performance}\""; exit 0 ;;
    esac ;;
set-property) [ -n "\${BUS_SET_FAIL:-}" ] && exit 1; exit 0 ;;
esac
EOF
chmod +x "$S"/stubs/*
export PATH="$S/stubs:$PATH" RICE_BIN=$BIN XDG_RUNTIME_DIR=$S/run

pass=0; fail=0
check() { # description, expected (grep -F), then the log must contain it
    if grep -qF -- "$2" "$LOG"; then pass=$((pass + 1)); printf '  ok    %s\n' "$1"; else fail=$((fail + 1)); printf '  FAIL  %s  (wanted: %s)\n' "$1" "$2"; fi
}
absent() { if grep -qF -- "$2" "$LOG"; then fail=$((fail + 1)); printf '  FAIL  %s  (should not run: %s)\n' "$1" "$2"; else pass=$((pass + 1)); printf '  ok    %s\n' "$1"; fi; }
fresh() { : >"$LOG"; unset BUS_FAIL BUS_BOOL BUS_SET_FAIL BUS_PROFILE; }

echo "Wi-Fi flip"
fresh; BUS_BOOL=true "$BIN/rice-toggle" flip wifi
check  "wifi on -> sets WirelessEnabled false over D-Bus" "busctl --system set-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager WirelessEnabled b false"
absent "no nmcli needed"                                   "nmcli radio wifi"
fresh; BUS_BOOL=false "$BIN/rice-toggle" flip wifi
check  "wifi off -> sets WirelessEnabled true"             "WirelessEnabled b true"
fresh; BUS_BOOL=true BUS_SET_FAIL=1 "$BIN/rice-toggle" flip wifi
check  "D-Bus write fails -> falls back to nmcli radio wifi off" "nmcli radio wifi off"
fresh; BUS_FAIL=1 "$BIN/rice-toggle" flip wifi
check  "D-Bus read fails -> state read falls back to nmcli"      "nmcli radio wifi"

echo "Bluetooth flip"
fresh; BUS_BOOL=true "$BIN/rice-toggle" flip bluetooth
check  "bt on -> Powered false over D-Bus"                 "org.bluez.Adapter1 Powered b false"
absent "no rfkill unblock when turning off"                "rfkill unblock"
fresh; BUS_BOOL=false "$BIN/rice-toggle" flip bluetooth
check  "bt off -> rfkill unblock first"                    "rfkill unblock bluetooth"
check  "then Powered true over D-Bus"                      "org.bluez.Adapter1 Powered b true"
fresh; BUS_BOOL=false BUS_SET_FAIL=1 "$BIN/rice-toggle" flip bluetooth
check  "D-Bus write fails -> falls back to bluetoothctl power on" "bluetoothctl power on"

echo "Power profile"
fresh; BUS_PROFILE=performance "$BIN/rice-power-profile" cycle
check  "performance -> power-saver over D-Bus"             "net.hadess.PowerProfiles ActiveProfile s power-saver"
absent "tlpctl not started"                                "tlpctl"
fresh; BUS_PROFILE=power-saver "$BIN/rice-power-profile" cycle
check  "power-saver -> balanced"                           "ActiveProfile s balanced"
fresh; BUS_PROFILE=balanced "$BIN/rice-power-profile" cycle
check  "balanced -> performance"                           "ActiveProfile s performance"
fresh; out=$(BUS_PROFILE=balanced "$BIN/rice-power-profile" get)
if [ "$out" = balanced ]; then pass=$((pass + 1)); echo "  ok    get prints the bare profile name ($out)"; else fail=$((fail + 1)); echo "  FAIL  get printed '$out'"; fi
fresh; BUS_FAIL=1 "$BIN/rice-power-profile" get >/dev/null
check  "D-Bus read fails -> tlpctl get fallback"           "tlpctl get"
fresh; BUS_SET_FAIL=1 "$BIN/rice-power-profile" set balanced
check  "D-Bus write fails -> tlpctl set fallback"          "tlpctl set balanced"

echo
echo "passed: $pass   failed: $fail"
rm -rf "$S"
[ "$fail" = 0 ]
