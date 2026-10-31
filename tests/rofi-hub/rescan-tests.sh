#!/usr/bin/env bash
# rice-net / rice-bt: Wi-Fi power / forget / rescan and Bluetooth rescan keys.
# Stubs only (fake rofi, nmcli, bluetoothctl and rfkill first on PATH): no GUI, no radios.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN=$ROOT/config-rice/.config/rice/bin

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"
LOG=$T/log
echo enabled >"$T/wifi"

cat >"$T/bin/rofi" <<EOF
#!/usr/bin/env bash
echo "rofi \$*" >>"$LOG"
EOF
cat >"$T/bin/nmcli" <<EOF
#!/usr/bin/env bash
echo "nmcli \$*" >>"$LOG"
case "\$*" in
"radio wifi") cat "$T/wifi" ;;
"radio wifi on") echo enabled >"$T/wifi" ;;
"radio wifi off") echo disabled >"$T/wifi" ;;
"-t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no") echo "*:80:WPA2:Home" ;;
esac
EOF
cat >"$T/bin/rfkill" <<EOF
#!/usr/bin/env bash
echo "rfkill \$*" >>"$LOG"
EOF
cat >"$T/bin/bluetoothctl" <<EOF
#!/usr/bin/env bash
echo "bluetoothctl \$*" >>"$LOG"
case "\$1" in
show) printf 'Controller AA:BB:CC:DD:EE:FF\n\tPowered: yes\n' ;;
devices) echo "Device 11:22:33:44:55:66 Headphones" ;;
info) printf 'Device 11:22:33:44:55:66\n\tConnected: no\n' ;;
esac
EOF
chmod +x "$T"/bin/*

pass=0 fail=0
ok() { # NAME CMD...
    local name=$1
    shift
    if "$@"; then
        pass=$((pass + 1))
        echo "  ok    $name"
    else
        fail=$((fail + 1))
        echo "  FAIL  $name"
    fi
}
has() { grep -q -F -- "$1" "$LOG"; }
run() { # RETV SCRIPT [ROFI_INFO]
    : >"$LOG"
    ROFI_INFO=${3:-} PATH="$T/bin:$PATH" ROFI_RETV=$1 bash "$BIN/$2" >/dev/null 2>&1
}
open() { # SCRIPT
    : >"$LOG"
    PATH="$T/bin:$PATH" bash "$BIN/$1" >/dev/null 2>&1
}

echo "Wi-Fi keys"
run 10 rice-net
ok "Alt+1 powers Wi-Fi off"        has "nmcli radio wifi off"
echo disabled >"$T/wifi"
run 10 rice-net
ok "Alt+1 powers Wi-Fi on"         has "nmcli radio wifi on"
ok "and unblocks rfkill"           has "rfkill unblock wifi"
run 11 rice-net Home
ok "Alt+2 forgets the network"     has "nmcli connection delete id Home"
run 12 rice-net
ok "Alt+3 rescans Wi-Fi"           has "nmcli device wifi rescan"

echo "Bluetooth rescan"
run 12 rice-bt
ok "Alt+3 scans for devices"       has "bluetoothctl --timeout 5 scan on"
ok "and still draws the list"      has "bluetoothctl devices"

echo "standalone windows bind the key"
open rice-net
ok "rice-net binds Alt+3"          has "-kb-custom-3 Alt+3"
open rice-bt
ok "rice-bt binds Alt+3"           has "-kb-custom-3 Alt+3"

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
