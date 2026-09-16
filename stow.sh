#!/usr/bin/env bash
# Symlink this repo's rice configs into $HOME via GNU Stow.
# Each top-level directory here (config-*, home-*) is its own stow package;
# any real file/directory already at a target path is moved into a
# timestamped backup dir first, so nothing is ever deleted.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow is not installed. Install it first, e.g.:" >&2
  echo "  sudo pacman -S stow" >&2
  exit 1
fi

backed_up=0

back_up() { # <path relative to $HOME>
  local rel="$1" dest="$BACKUP_DIR/$1"
  mkdir -p "$(dirname "$dest")"
  mv "$HOME/$rel" "$dest"
  echo "backed up $rel -> $dest"
  backed_up=1
}

is_correct_symlink() { # <target path> <source path>
  local target="$1" source="$2"
  [ -L "$target" ] || return 1
  case "$(readlink "$target")" in
    ../*) ;;
    *) return 1 ;;
  esac
  local rt rs
  rt="$(readlink -f "$target" 2>/dev/null || true)"
  rs="$(readlink -f "$source")"
  [ -n "$rt" ] && [ "$rt" = "$rs" ]
}

# Recursively reconcile $HOME/<rel> with <source_root>/<rel>, backing up any
# real file/dir in the way. A path is checked for symlink-ness *before*
# anything else at every level of recursion, so we never read or write
# through an already-existing symlink -- it's either left alone (correct)
# or backed up whole (anything else), but never descended into.
reconcile() {
  local source_root="$1" rel="$2"
  local target="$HOME/$rel" source="$source_root/$rel"

  if [ -L "$target" ]; then
    is_correct_symlink "$target" "$source" || back_up "$rel"
    return 0
  fi

  [ -e "$target" ] || [ -L "$target" ] || return 0

  if [ -d "$source" ] && [ ! -L "$source" ] && [ -d "$target" ]; then
    local child
    for child in "$source"/*; do
      [ -e "$child" ] || [ -L "$child" ] || continue
      reconcile "$source_root" "$rel/$(basename "$child")"
    done
    rmdir "$target" 2>/dev/null || true
    return 0
  fi

  back_up "$rel"
}

# The single real path (relative to $HOME) a package provides, e.g.
# "config-hypr" -> ".config/hypr", "home-fonts" -> ".fonts".
package_rel() {
  local pkg_dir="$1" child grandchild
  child="$(cd "$pkg_dir" && ls -A)"
  if [ "$child" = ".config" ]; then
    grandchild="$(cd "$pkg_dir/.config" && ls -A)"
    echo ".config/$grandchild"
  else
    echo "$child"
  fi
}

packages=()
for entry in "$DOTFILES_DIR"/*/; do
  [ -d "$entry" ] || continue
  packages+=("$(basename "$entry")")
done

for pkg in "${packages[@]}"; do
  reconcile "$DOTFILES_DIR/$pkg" "$(package_rel "$DOTFILES_DIR/$pkg")"
done

stow --dir="$DOTFILES_DIR" --target="$HOME" --verbose=1 --restow "${packages[@]}"

if [ "$backed_up" -eq 1 ]; then
  echo
  echo "Pre-existing files were moved to: $BACKUP_DIR"
fi
