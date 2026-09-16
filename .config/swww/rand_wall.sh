#!/bin/bash
# ~/.config/hypr/scripts/swww_parallax_effect.sh
# Enhanced version with better error handling and debugging

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Check if Hyprland is running
if ! pgrep -x "Hyprland" > /dev/null; then
    log "Error: Hyprland is not running"
    exit 1
fi

# Check if swww daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    log "Warning: swww-daemon is not running. Starting it..."
    swww-daemon &
    sleep 2
fi

# Find the Hyprland cache directory
HYPR_CACHE_DIRS=(
    "$HOME/.cache/hypr"
    "/tmp/hypr/$USER"
    "$XDG_RUNTIME_DIR/hypr"
    "/run/user/$(id -u)/hypr"
)

HYPRLAND_SOCKET_DIR=""
for cache_dir in "${HYPR_CACHE_DIRS[@]}"; do
    log "Checking directory: $cache_dir"
    if [ -d "$cache_dir" ]; then
        # Look for socket files in this directory
        socket_file=$(find "$cache_dir" -name "*.socket2.sock" 2>/dev/null | head -n1)
        if [ -n "$socket_file" ]; then
            HYPRLAND_SOCKET_DIR=$(dirname "$socket_file")
            log "Found Hyprland socket directory: $HYPRLAND_SOCKET_DIR"
            break
        fi
    fi
done

# Alternative method: try to get from Hyprland environment
if [ -z "$HYPRLAND_SOCKET_DIR" ]; then
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        # Try common locations with the instance signature
        for base_dir in "$HOME/.cache/hypr" "/tmp/hypr/$USER" "$XDG_RUNTIME_DIR/hypr"; do
            potential_dir="$base_dir/$HYPRLAND_INSTANCE_SIGNATURE"
            if [ -S "$potential_dir/.socket2.sock" ]; then
                HYPRLAND_SOCKET_DIR="$potential_dir"
                log "Found socket using HYPRLAND_INSTANCE_SIGNATURE: $HYPRLAND_SOCKET_DIR"
                break
            fi
        done
    fi
fi

# Final fallback: try to find any .socket2.sock file
if [ -z "$HYPRLAND_SOCKET_DIR" ]; then
    log "Searching for socket files in common locations..."
    socket_file=$(find /tmp /run/user/$(id -u) "$HOME/.cache" -name "*.socket2.sock" 2>/dev/null | head -n1)
    if [ -n "$socket_file" ]; then
        HYPRLAND_SOCKET_DIR=$(dirname "$socket_file")
        log "Found socket file: $socket_file"
        log "Using directory: $HYPRLAND_SOCKET_DIR"
    fi
fi

if [ -z "$HYPRLAND_SOCKET_DIR" ]; then
    log "Error: Could not find Hyprland IPC socket"
    log "Debugging info:"
    log "- HYPRLAND_INSTANCE_SIGNATURE: ${HYPRLAND_INSTANCE_SIGNATURE:-not set}"
    log "- XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-not set}"
    log "- USER: $USER"
    log "- UID: $(id -u)"

    log "Searching for any Hyprland-related files:"
    find /tmp /run/user/$(id -u) "$HOME/.cache" -name "*hypr*" 2>/dev/null | head -10

    exit 1
fi

HYPRLAND_EVENT_SOCKET="$HYPRLAND_SOCKET_DIR/.socket2.sock"

if [ ! -S "$HYPRLAND_EVENT_SOCKET" ]; then
    log "Error: Socket file does not exist or is not a socket: $HYPRLAND_EVENT_SOCKET"
    exit 1
fi

log "Successfully found Hyprland event socket: $HYPRLAND_EVENT_SOCKET"

# Create cache directory for wallpaper tracking if it doesn't exist
mkdir -p ~/.cache/swww

# Function to apply parallax effect
apply_parallax_effect() {
    local output="$1"

    if [ -f ~/.cache/swww/current_wallpaper ]; then
        CURRENT_WALLPAPER_PATH=$(cat ~/.cache/swww/current_wallpaper)
        if [ -f "$CURRENT_WALLPAPER_PATH" ]; then
            log "Applying parallax effect to $output with wallpaper: $(basename "$CURRENT_WALLPAPER_PATH")"
            swww img "$CURRENT_WALLPAPER_PATH" \
                --transition-type grow \
                --transition-duration 0.4 \
                --transition-fps 60 \
                --transition-bezier 0.25,1.0,0.5,1.0 \
                ${output:+--outputs "$output"}
        else
            log "Warning: Wallpaper file not found: $CURRENT_WALLPAPER_PATH"
        fi
    else
        log "Warning: ~/.cache/swww/current_wallpaper not found. Creating with current wallpaper..."
        # Try to get current wallpaper from swww
        swww query 2>/dev/null | head -n1 | grep -o '/[^"]*\.\(jpg\|jpeg\|png\|webp\|gif\)' > ~/.cache/swww/current_wallpaper 2>/dev/null || true
    fi
}

log "Starting to listen for Hyprland events..."

# Listen for Hyprland workspace change events
socat -U - UNIX-CONNECT:"$HYPRLAND_EVENT_SOCKET" | while read -r line; do
    if [[ "$line" == workspace\>\>* ]]; then
        NEW_WS=$(echo "$line" | cut -d'>' -f3)
        log "Switched to workspace: $NEW_WS"

        # Get the active monitor for the workspace
        if command -v hyprctl >/dev/null && command -v jq >/dev/null; then
            ACTIVE_MONITOR=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.monitor // empty')
            apply_parallax_effect "$ACTIVE_MONITOR"
        else
            apply_parallax_effect ""
        fi
    elif [[ "$line" == focusedmon\>\>* ]]; then
        MON_INFO=$(echo "$line" | cut -d'>' -f3)
        MON_NAME=$(echo "$MON_INFO" | cut -d',' -f1)
        log "Focused monitor: $MON_NAME"
        apply_parallax_effect "$MON_NAME"
    fi
done
