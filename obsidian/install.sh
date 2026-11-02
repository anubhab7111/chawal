#!/usr/bin/env bash
# Load obsidian/glass into Obsidian: writes a small loader outside the repo and adds
# `-r <loader>` to the flags file of the electron Obsidian runs on. Only our own
# block in that file changes.
# Run it again when Obsidian moves to a new electron major: the flags file is
# named after it, and without this the window is simply opaque again.
# Usage: obsidian/install.sh. Restart Obsidian afterwards.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOADER="${XDG_DATA_HOME:-$HOME/.local/share}/chawal/obsidian-glass"
BEGIN="# chawal begin"
END="# chawal end"

launcher="$(command -v obsidian)" || { echo "obsidian is not installed" >&2; exit 1; }
electron="$(sed -n 's/^exec \(electron[0-9]*\) .*/\1/p' "$launcher")"
[ -n "$electron" ] || { echo "no electron named in $launcher" >&2; exit 1; }

# electron refuses to start if the `-r` target is missing, so it must not live in
# the repo: a checkout without obsidian/glass should cost the glass, not the app.
# A directory, because Obsidian opens any file path in its arguments as a note.
mkdir -p "$LOADER"
cat >"$LOADER/index.js" <<JS
// Written by obsidian/install.sh.
try {
  require('$HERE/glass');
} catch (err) {
  console.error('glass:', err.message);
}
JS

conf="$CONFIG/$electron-flags.conf"
mkdir -p "$CONFIG"
# Once this file exists the wrapper stops reading the shared fallback.
[ -e "$conf" ] || [ ! -f "$CONFIG/electron-flags.conf" ] || cp "$CONFIG/electron-flags.conf" "$conf"
[ -f "$conf" ] || : >"$conf"

# One argument per line, and the wrapper does no expansion: hence two absolute lines.
tmp="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$conf" >"$tmp"
{ cat "$tmp"; echo "$BEGIN"; echo "-r"; echo "$LOADER"; echo "$END"; } >"$conf"
rm -f "$tmp"

echo "added glass to $conf; restart Obsidian"
