#!/usr/bin/env bash
# Symlink this repo's rice configs into $HOME via GNU Stow.
# Any real file/directory already at a target path is moved into a
# timestamped backup dir first, so nothing is ever deleted.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$(dirname "$DOTFILES_DIR")"
PACKAGE="$(basename "$DOTFILES_DIR")"
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

# Recursively reconcile $HOME/<rel> with the repo's copy, backing up any real
# file/dir in the way. A path is checked for symlink-ness *before* anything
# else at every level of recursion, so we never read or write through an
# already-existing symlink -- it's either left alone (correct) or backed up
# whole (anything else), but never descended into.
reconcile() {
  local rel="$1" target="$HOME/$1" source="$DOTFILES_DIR/$1"

  if [ -L "$target" ]; then
    is_correct_symlink "$target" "$source" || back_up "$rel"
    return 0
  fi

  [ -e "$target" ] || [ -L "$target" ] || return 0

  if [ -d "$source" ] && [ ! -L "$source" ] && [ -d "$target" ]; then
    local child
    for child in "$source"/*; do
      [ -e "$child" ] || [ -L "$child" ] || continue
      reconcile "$rel/$(basename "$child")"
    done
    rmdir "$target" 2>/dev/null || true
    return 0
  fi

  back_up "$rel"
}

for entry in "$DOTFILES_DIR"/.config/*; do
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  reconcile ".config/$(basename "$entry")"
done
for entry in "$DOTFILES_DIR"/.*; do
  base="$(basename "$entry")"
  case "$base" in
    .|..|.git|.gitignore|.config|.stow-local-ignore) continue ;;
  esac
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  reconcile "$base"
done

stow --dir="$STOW_DIR" --target="$HOME" --verbose=1 --restow "$PACKAGE"

if [ "$backed_up" -eq 1 ]; then
  echo
  echo "Pre-existing files were moved to: $BACKUP_DIR"
fi
