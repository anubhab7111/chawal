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

# fastfetch with the spinning 3D Arch logo (~/.config/fastfetch/logo).
# kitty animates it natively through `kitten icat`. alacritty can't animate,
# so the logo spins once through chafa (sixel) and settles facing front;
# Ctrl+C skips. With arguments, inside tmux, or in a short window it uses
# the static front-facing logo from config.jsonc.
fastfetch() {
    local logo=~/.config/fastfetch/logo/arch-spin.webp
    if [[ $TERM == xterm-kitty && -f $logo ]]; then
        command fastfetch --logo "$logo" --logo-type kitty-icat "$@"
    elif [[ $TERM == alacritty && -z $TMUX && $# -eq 0 && -t 1 && -f $logo ]] &&
        command -v chafa >/dev/null && (($(tput lines) >= 24)); then
        _rice_fetch_spin "$logo"
    else
        command fastfetch "$@"
    fi
}

_rice_fetch_spin() (
    local logo=$1 w=20 h=13 room=20 row end blank
    local bg='#1e1e2e' # terminal background (Mocha base)
    # Make room first, so nothing scrolls while the logo is drawn in place.
    printf '\n%.0s' $(seq "$room")
    printf '\e[%dA' "$room"
    IFS='[;' read -rs -d R -p $'\e[6n' _ row _ </dev/tty
    blank=$(for _ in $(seq "$h"); do printf '%*s\n' "$w" ''; done)
    command fastfetch --logo-type data-raw --logo "$blank"
    IFS='[;' read -rs -d R -p $'\e[6n' _ end _ </dev/tty

    # chafa saves/restores the cursor itself, so jump to the rows explicitly.
    trap 'printf "\e[?25h\e[%d;1H" "$end"; exit 130' INT
    # --probe off: format and size are given, and late probe replies would
    # otherwise be echoed onto the prompt line.
    printf '\e[?25l\e[%d;1H' "$row"
    chafa --probe off -f sixels --animate on --duration 4 --bg "$bg" -s "${w}x$h" "$logo"
    printf '\e[%d;1H' "$row"
    chafa --probe off -f sixels --animate off --bg "$bg" -s "${w}x$h" "$logo"
    printf '\e[?25h\e[%d;1H' "$end"
)
