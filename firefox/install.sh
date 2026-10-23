#!/usr/bin/env bash
# Link the chawal Firefox rice (FF Ultima add-on CSS) into the default profile.
# Needs FF Ultima installed in <profile>/chrome (its userChrome.css imports
# customChrome.css) and toolkit.legacyUserProfileCustomizations.stylesheets.
# Restart Firefox afterwards: it reads chrome CSS at startup.
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/chrome"
root="$HOME/.mozilla/firefox"

profile="$(awk -F= '/^\[Install/{i=1} i&&/^Default=/{print $2; exit}' "$root/profiles.ini")"
[[ -n $profile && -d $root/$profile ]] || { echo "no default Firefox profile found" >&2; exit 1; }
chrome="$root/$profile/chrome"
[[ -f $chrome/userChrome.css ]] || { echo "FF Ultima missing in $chrome" >&2; exit 1; }

ln -sfn "$src/customChrome.css" "$chrome/customChrome.css"
ln -sfn "$src/rice" "$chrome/rice"
echo "linked into $chrome; restart Firefox"
