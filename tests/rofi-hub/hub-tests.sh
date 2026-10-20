#!/usr/bin/env bash
# rice-hub: the hub has three tabs; Wi-Fi and Bluetooth open as windows of their own.
# Stubs only (a fake rofi and fake tab scripts first on PATH / RICE_BIN): no GUI, nothing real.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
HUB=$ROOT/config-rice/.config/rice/bin/rice-hub

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/run"
LOG=$T/log

cat >"$T/bin/rofi" <<EOF
#!/usr/bin/env bash
echo "rofi \$*" >>"$LOG"
EOF
for s in windows clip net bt; do
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
run() { : >"$LOG"; PATH="$T/bin:$PATH" RICE_BIN="$T/bin" XDG_RUNTIME_DIR="$T/run" bash "$HUB" "$@" >/dev/null 2>&1; sleep 0.3; }

echo "default hub"
run
ok "opens rofi on Apps"          has "rofi -show drun"
ok "has the Windows tab"         has "windows:$T/bin/rice-windows"
ok "has the Clip tab"            has "clip:$T/bin/rice-clip"
ok "has no Wi-Fi tab"            hasnt "net:"
ok "has no Bluetooth tab"        hasnt "bt:"
ok "pre-runs Windows and Clip"   has "rice-windows 0"
ok "does not pre-run Wi-Fi"      hasnt "rice-net"
ok "does not pre-run Bluetooth"  hasnt "rice-bt"

echo "windows and clip jumps"
run clip
ok "clip opens the Clip tab"     has "rofi -show clip"
run window
ok "window is still an alias"    has "rofi -show windows"

echo "Wi-Fi and Bluetooth"
run net
ok "net runs rice-net on its own"      has "rice-net none"
ok "net does not open the hub"         hasnt "rofi -show"
run bt
ok "bt runs rice-bt on its own"        has "rice-bt none"
ok "bt does not open the hub"          hasnt "rofi -show"

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
