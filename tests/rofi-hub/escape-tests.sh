#!/usr/bin/env bash
# rice-windows and rice-clip print rows as pango markup (the theme dims the app description line),
# so & < > in a window title or a clip must come out escaped. Stubs only: fake hyprctl, cliphist.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN=$ROOT/config-rice/.config/rice/bin

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/cache"

cat >"$T/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
echo '[{"address":"0x1","class":"fire&fox","title":"a < b & c > d","workspace":{"name":"1"},"floating":false,"pinned":false,"mapped":true,"hidden":false,"focusHistoryID":0}]'
EOF
cat >"$T/bin/cliphist" <<'EOF'
#!/usr/bin/env bash
printf '7\tif a<b && c>d\n'
EOF
chmod +x "$T/bin/"*

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
has() { grep -q -F -- "$1" <<<"$OUT"; }
hasnt() { ! grep -q -F -- "$1" <<<"$OUT"; }

echo "rice-windows"
OUT=$(PATH="$T/bin:$PATH" ROFI_RETV=0 bash "$BIN/rice-windows" 2>/dev/null | tr '\0' '\n')
ok "title is escaped"        has "a &lt; b &amp; c &gt; d"
ok "class is escaped"        has "fire&amp;fox"
ok "no raw < in the row"     hasnt "a < b"

echo "rice-clip"
OUT=$(PATH="$T/bin:$PATH" XDG_CACHE_HOME="$T/cache" ROFI_RETV=0 bash "$BIN/rice-clip" 2>/dev/null | tr '\0' '\n')
ok "clip text is escaped"    has "if a&lt;b &amp;&amp; c&gt;d"
ok "no raw < in the row"     hasnt "a<b"
ok "entry id still sent"     has "info"

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ]
