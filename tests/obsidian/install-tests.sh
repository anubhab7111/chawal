#!/usr/bin/env bash
# obsidian/install.sh: finding the electron, the flags block, what it leaves alone.
# A fake HOME and a fake obsidian launcher: no Obsidian, nothing real.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
INSTALL=$ROOT/obsidian/install.sh

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
unset XDG_CONFIG_HOME
CONFIG=$HOME/.config
BIN=$T/bin
REAL_PATH=$PATH
mkdir -p "$CONFIG" "$BIN"
export PATH=$BIN:$REAL_PATH

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

launcher() { # ELECTRON
    printf '#!/bin/bash\nexec %s /usr/lib/obsidian/app.asar "$@"\n' "$1" >"$BIN/obsidian"
    chmod +x "$BIN/obsidian"
}

count() { grep -cxF -- "$2" "$1"; }
line_after() { # FILE LINE EXPECTED: EXPECTED is the line right after LINE
    [ "$(grep -xF -A1 -- "$2" "$1" | tail -1)" = "$3" ]
}

GLASS=$ROOT/obsidian/glass
CONF=$CONFIG/electron43-flags.conf

launcher electron43
cat >"$CONF" <<'CONF'
--ozone-platform=wayland
# chawal begin
-r
/old/path/glass
# chawal end
CONF
"$INSTALL" >/dev/null

ok "exit 0 and flags file named after the electron" test -f "$CONF"
ok "keeps other flags" grep -qxF -- "--ozone-platform=wayland" "$CONF"
ok "drops the old block" test "$(grep -cF /old/path "$CONF")" = 0
ok "-r and the path are separate lines" line_after "$CONF" "-r" "$GLASS"
ok "path is absolute, to a directory" test -d "$GLASS"
ok "preload is in that directory" test -f "$GLASS/index.js"
ok "css is in that directory" test -f "$GLASS/glass.css"

"$INSTALL" >/dev/null
ok "second run leaves one block" test "$(count "$CONF" "# chawal begin")" = 1
ok "second run leaves one -r" test "$(count "$CONF" "-r")" = 1

# A new electron major: its own file, seeded from the shared fallback the wrapper
# would otherwise stop reading.
launcher electron44
echo "--from-fallback" >"$CONFIG/electron-flags.conf"
"$INSTALL" >/dev/null
ok "new electron gets its own file" line_after "$CONFIG/electron44-flags.conf" "-r" "$GLASS"
ok "new file keeps the fallback's flags" grep -qxF -- "--from-fallback" "$CONFIG/electron44-flags.conf"
ok "fallback file itself untouched" test "$(cat "$CONFIG/electron-flags.conf")" = "--from-fallback"

# XDG_CONFIG_HOME is what the electron wrapper reads too.
launcher electron43
XDG_CONFIG_HOME=$T/xdg "$INSTALL" >/dev/null
ok "honours XDG_CONFIG_HOME" line_after "$T/xdg/electron43-flags.conf" "-r" "$GLASS"

# Refuses rather than guesses.
printf '#!/bin/bash\nexec /opt/Obsidian/obsidian "$@"\n' >"$BIN/obsidian"
ok "fails when no electron is named" test "$("$INSTALL" >/dev/null 2>&1; echo $?)" = 1
# Only the tools the installer uses, so a real obsidian on this machine is not found.
rm "$BIN/obsidian"
for tool in bash env dirname sed awk mktemp mkdir cp cat rm; do
    ln -s "$(command -v "$tool")" "$BIN/$tool"
done
ok "fails when obsidian is not installed" test "$(PATH=$BIN "$INSTALL" >/dev/null 2>&1; echo $?)" = 1

echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
