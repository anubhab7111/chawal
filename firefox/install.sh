#!/usr/bin/env bash
# Link the chawal Firefox chrome (every file in firefox/chrome) into a Firefox
# profile's chrome dir, one link per file, so anything else there stays.
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
mkdir -p "$chrome"

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
for src in "$SRC"/*; do
  link "$src" "$(basename "$src")"
done

# user.js: replace only our own block, keep every other line
js="$profile/user.js"
[ -f "$js" ] || : >"$js"
tmp="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$js" >"$tmp"
{ cat "$tmp"; echo "$BEGIN"; cat "$HERE/user.js"; echo "$END"; } >"$js"
rm -f "$tmp"

echo "linked into $chrome; restart Firefox"
