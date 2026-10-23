#!/usr/bin/env bash
# firefox/install.sh: profile discovery, FF Ultima check, links, backups, user.js block, git exclude.
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
mkdir -p "$PROFILE"

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
fake_ultima() {
    mkdir -p "$CHROME/.git/info"
    echo '@import url(customChrome.css);' >"$CHROME/userChrome.css"
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

# without FF Ultima it refuses
ok "refuses without FF Ultima" bash -c "! '$INSTALL' >/dev/null 2>&1"

fake_ultima
echo 'user_pref("my.own", 1);' >"$PROFILE/user.js"
echo "real file" >"$CHROME/custom.css"
"$INSTALL" >/dev/null 2>&1

ok "finds the profile from profiles.ini" test -L "$CHROME/customChrome.css"
ok "links custom.css" test -L "$CHROME/custom.css"
ok "links rice/" test -L "$CHROME/rice"
ok "link points at the repo" test "$(readlink "$CHROME/rice")" = "$ROOT/firefox/chrome/rice"
ok "real file backed up, not deleted" bash -c "cat '$HOME'/.dotfiles-backup/*/custom.css | grep -q 'real file'"
ok "user.js keeps the user's line" grep -q 'my.own' "$PROFILE/user.js"
ok "user.js has the rice block" grep -q 'legacyUserProfileCustomizations' "$PROFILE/user.js"

"$INSTALL" >/dev/null 2>&1
ok "re-run keeps one begin marker" test "$(grep -c '// chawal begin' "$PROFILE/user.js")" = 1
ok "re-run keeps the user's line" grep -q 'my.own' "$PROFILE/user.js"
ok "exclude lists each file once" test "$(grep -cxF rice "$CHROME/.git/info/exclude")" = 1
ok "exclude has customChrome.css" grep -qxF customChrome.css "$CHROME/.git/info/exclude"

ok "--profile overrides discovery" bash -c "mkdir -p '$T/p2/chrome' && echo '@import url(customChrome.css);' >'$T/p2/chrome/userChrome.css' && '$INSTALL' --profile '$T/p2' >/dev/null 2>&1 && test -L '$T/p2/chrome/rice'"

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
