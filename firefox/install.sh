#!/usr/bin/env bash
# Link the chawal Firefox rice (an overlay for FF Ultima) into a Firefox profile.
# Needs FF Ultima cloned into <profile>/chrome: its userChrome.css imports
# customChrome.css and its userContent.css imports custom.css, which is where
# this overlay plugs in. FF Ultima's own files are never touched.
# A real file in the way is moved to a timestamped backup dir, never deleted.
# Usage: firefox/install.sh [--profile DIR]. Restart Firefox afterwards.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/chrome"
ROOT="$HOME/.mozilla/firefox"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BEGIN="// chawal begin"
END="// chawal end"

profile=""
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) profile="${2:?--profile needs a directory}"; shift 2 ;;
    *) echo "usage: $0 [--profile DIR]" >&2; exit 2 ;;
  esac
done

if [ -z "$profile" ]; then
  ini="$ROOT/profiles.ini"
  [ -f "$ini" ] || { echo "no $ini; pass --profile DIR" >&2; exit 1; }
  rel="$(awk -F= '/^\[Install/{i=1} i&&/^Default=/{print $2; exit}' "$ini")"
  if [ -z "$rel" ]; then
    rel="$(awk -F= '/^\[/{p=""} /^Path=/{p=$2} /^Default=1/{print p; exit}' "$ini")"
  fi
  [ -n "$rel" ] || { echo "no default profile in $ini; pass --profile DIR" >&2; exit 1; }
  case "$rel" in /*) profile="$rel" ;; *) profile="$ROOT/$rel" ;; esac
fi
[ -d "$profile" ] || { echo "profile $profile does not exist" >&2; exit 1; }

chrome="$profile/chrome"
if ! grep -qs "customChrome.css" "$chrome/userChrome.css"; then
  echo "FF Ultima is not installed in $chrome. Install it first:" >&2
  echo "  git clone https://github.com/soulhotel/FF-ULTIMA \"$chrome\"" >&2
  exit 1
fi

link() { # <source> <name in chrome>
  local src="$1" target="$chrome/$2"
  if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$src" ] && return 0
    rm "$target"
  elif [ -e "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/$2"
    echo "backed up $target -> $BACKUP_DIR/$2"
  fi
  ln -s "$src" "$target"
}
link "$SRC/customChrome.css" customChrome.css
link "$SRC/custom.css" custom.css
link "$SRC/rice" rice

# user.js: replace only our own block, keep every other line
js="$profile/user.js"
[ -f "$js" ] || : >"$js"
tmp="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$js" >"$tmp"
{ cat "$tmp"; echo "$BEGIN"; cat "$HERE/user.js"; echo "$END"; } >"$js"
rm -f "$tmp"

# keep the FF Ultima clone clean
if [ -d "$chrome/.git" ]; then
  exclude="$chrome/.git/info/exclude"
  mkdir -p "$(dirname "$exclude")"
  for f in customChrome.css custom.css rice; do
    grep -qxF "$f" "$exclude" 2>/dev/null || echo "$f" >>"$exclude"
  done
fi

echo "linked into $chrome; restart Firefox"
