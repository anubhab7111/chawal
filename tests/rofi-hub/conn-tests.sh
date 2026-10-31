#!/usr/bin/env bash
# rice-conn: Wi-Fi and Bluetooth share one rofi window, as two tabs.
# Stubs only (a fake rofi and fake tab scripts first on PATH / RICE_BIN): no GUI, nothing real.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
CONN=$ROOT/config-rice/.config/rice/bin/rice-conn

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/run"
LOG=$T/log

cat >"$T/bin/rofi" <<EOF
#!/usr/bin/env bash
echo "rofi \$*" >>"$LOG"
EOF
for s in net bt; do
    cat >"$T/bin/rice-$s" <<EOF
#!/usr/bin/env bash
echo "rice-$s \${ROFI_RETV:-none}" >>"$LOG"
EOF
done
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
hasnt() { ! grep -q -F -- "$1" "$LOG"; }
run() { : >"$LOG"; PATH="$T/bin:$PATH" RICE_BIN="$T/bin" XDG_RUNTIME_DIR="$T/run" bash "$CONN" "$@" >/dev/null 2>&1; sleep 0.3; }

echo "default window"
run
ok "opens rofi on Wi-Fi"          has "rofi -show net"
ok "has the Wi-Fi tab"            has "net:$T/bin/rice-net"
ok "has the Bluetooth tab"        has "bt:$T/bin/rice-bt"
ok "pre-runs Wi-Fi"               has "rice-net 0"
ok "pre-runs Bluetooth"           has "rice-bt 0"
ok "keeps the tab switcher"       hasnt "mainbox"
ok "forwards Alt+3 rescan"        has "-kb-custom-3 Alt+3"

echo "jumps"
run bt
ok "bt opens the Bluetooth tab"   has "rofi -show bt"
run wifi
ok "wifi is an alias for Wi-Fi"   has "rofi -show net"
run bluetooth
ok "bluetooth is an alias too"    has "rofi -show bt"

echo "other arguments"
run bogus
ok "an unknown tab calls no rofi" hasnt "rofi "

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
