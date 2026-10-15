# shellcheck shell=bash
# Shell helpers for the rice. Source this from ~/.bashrc with:
#   [[ -f ~/.config/bash/rice-aliases.sh ]] && source ~/.config/bash/rice-aliases.sh
#
# These replace alacritty's old one-key sudo binds: updates, removals and
# kills now only start from a command you typed and confirmed.

# Update repo and AUR packages in one go; yay asks for sudo itself.
alias up='yay -Syu'

# Remove orphaned packages. pacman lists them and asks [Y/n] before removing.
orphans() {
    local -a pkgs
    mapfile -t pkgs < <(pacman -Qdtq)
    if ((${#pkgs[@]} == 0)); then
        echo "no orphans"
        return 0
    fi
    sudo pacman -Rns "${pkgs[@]}"
}

# Pick your own processes with fzf (Tab selects several) and kill them.
# Sends SIGTERM; `fkill -9` sends SIGKILL.
fkill() {
    local sig=TERM
    case $1 in
        '') ;;
        -9) sig=KILL ;;
        *) echo "usage: fkill [-9]" >&2; return 2 ;;
    esac
    local -a pids
    mapfile -t pids < <(ps -u "$USER" -o pid=,args= |
        fzf -m --header="kill -$sig  (Tab selects several)" |
        awk '{print $1}')
    ((${#pids[@]})) || return 0
    kill -s "$sig" "${pids[@]}"
}

# fastfetch's config draws the logo as sixel (alacritty, tmux). kitty has no
# sixel, so there the logo goes through `kitten icat`, which also animates it.
fastfetch() {
    if [[ $TERM == xterm-kitty ]]; then
        command fastfetch --logo-type kitty-icat "$@"
    else
        command fastfetch "$@"
    fi
}
