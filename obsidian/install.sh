#!/usr/bin/env bash
# Load obsidian/glass into Obsidian by adding `-r <dir>` to the flags file of the
# electron it runs on. Only our own block in that file changes.
# Run it again when Obsidian moves to a new electron major: the flags file is
# named after it, and without this the window is simply opaque again.
# Usage: obsidian/install.sh. Restart Obsidian afterwards.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BEGIN="# chawal begin"
END="# chawal end"

launcher="$(command -v obsidian)" || { echo "obsidian is not installed" >&2; exit 1; }
electron="$(sed -n 's/^exec \(electron[0-9]*\) .*/\1/p' "$launcher")"
[ -n "$electron" ] || { echo "no electron named in $launcher" >&2; exit 1; }

conf="$CONFIG/$electron-flags.conf"
mkdir -p "$CONFIG"
# Once this file exists the wrapper stops reading the shared fallback.
[ -e "$conf" ] || [ ! -f "$CONFIG/electron-flags.conf" ] || cp "$CONFIG/electron-flags.conf" "$conf"
[ -f "$conf" ] || : >"$conf"

# One argument per line, and the wrapper does no expansion: hence two absolute lines.
tmp="$(mktemp)"
awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$conf" >"$tmp"
{ cat "$tmp"; echo "$BEGIN"; echo "-r"; echo "$HERE/glass"; echo "$END"; } >"$conf"
rm -f "$tmp"

echo "added glass to $conf; restart Obsidian"
