#!/usr/bin/env bash
# firefox/install.sh: profile discovery, links, backups, user.js block.
# A fake HOME with a fake profile: no Firefox, nothing real.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
INSTALL=$ROOT/firefox/install.sh

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
PROFILE=$HOME/.mozilla/firefox/abc.default-release
CHROME=$PROFILE/chrome
mkdir -p "$CHROME"

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

cat >"$HOME/.mozilla/firefox/profiles.ini" <<INI
[Install1234]
Default=abc.default-release
Locked=1

[Profile0]
Name=default-release
IsRelative=1
Path=abc.default-release
Default=1
INI

echo "real file" >"$CHROME/userChrome.css"
echo "not ours" >"$CHROME/userContent.css"
# a block left by the old FF Ultima overlay installer
cat >"$PROFILE/user.js" <<'JS'
user_pref("my.own", 1);
// chawal begin
user_pref("rice.tint", "subtle");
// chawal end
JS
"$INSTALL" >/dev/null 2>&1

ok "finds the profile from profiles.ini" test -L "$CHROME/userChrome.css"
ok "link points at the repo" test "$(readlink "$CHROME/userChrome.css")" = "$ROOT/firefox/chrome/userChrome.css"
ok "real file backed up, not deleted" bash -c "cat '$HOME'/.dotfiles-backup/*/userChrome.css | grep -q 'real file'"
ok "other chrome files left alone" bash -c "test ! -L '$CHROME/userContent.css' && grep -q 'not ours' '$CHROME/userContent.css'"
ok "user.js keeps the user's line" grep -q 'my.own' "$PROFILE/user.js"
ok "user.js has the stylesheets pref" grep -q 'legacyUserProfileCustomizations' "$PROFILE/user.js"
ok "user.js keeps pages opaque" grep -q 'allow_transparent_browser", false' "$PROFILE/user.js"
ok "old block's prefs are gone" bash -c "! grep -q 'rice.tint' '$PROFILE/user.js'"

"$INSTALL" >/dev/null 2>&1
ok "re-run keeps one begin marker" test "$(grep -c '// chawal begin' "$PROFILE/user.js")" = 1
ok "re-run keeps the user's line" grep -q 'my.own' "$PROFILE/user.js"
ok "re-run keeps the link" test "$(readlink "$CHROME/userChrome.css")" = "$ROOT/firefox/chrome/userChrome.css"

ok "--profile overrides discovery, makes chrome/" bash -c "mkdir -p '$T/p2' && '$INSTALL' --profile '$T/p2' >/dev/null 2>&1 && test -L '$T/p2/chrome/userChrome.css'"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
