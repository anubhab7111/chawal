#!/bin/bash
# ~/.config/hypr/scripts/manage_workspace_wallpapers.sh
# Helper script to manage workspace wallpapers

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG_FILE="$HOME/.config/hypr/workspace_wallpapers.conf"
SCRIPT_DIR="$HOME/.config/hypr/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_colored() {
    echo -e "${!1}$2${NC}"
}

# Function to list available wallpapers
list_wallpapers() {
    print_colored "BLUE" "Available wallpapers in $WALLPAPER_DIR:"
    if [ -d "$WALLPAPER_DIR" ]; then
        find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -printf "%f\n" | sort | nl
    else
        print_colored "RED" "Wallpaper directory not found: $WALLPAPER_DIR"
        return 1
    fi
}

# Function to show current configuration
show_config() {
    print_colored "BLUE" "Current workspace wallpaper configuration:"
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE" | grep -v '^#' | grep -v '^$' | while read -r line; do
            ws=$(echo "$line" | cut -d':' -f1)
            wallpaper=$(echo "$line" | cut -d':' -f2-)
            if [ -f "$WALLPAPER_DIR/$wallpaper" ] || [ -f "$wallpaper" ]; then
                print_colored "GREEN" "Workspace $ws: $wallpaper ✓"
            else
                print_colored "RED" "Workspace $ws: $wallpaper ✗ (not found)"
            fi
        done
    else
        print_colored "YELLOW" "No configuration file found"
    fi
}

# Function to set wallpaper for workspace
set_workspace_wallpaper() {
    local workspace="$1"
    local wallpaper="$2"

    if [ -z "$workspace" ] || [ -z "$wallpaper" ]; then
        print_colored "RED" "Usage: set_workspace_wallpaper <workspace> <wallpaper>"
        return 1
    fi

    # Check if wallpaper exists
    if [ ! -f "$WALLPAPER_DIR/$wallpaper" ] && [ ! -f "$wallpaper" ]; then
        print_colored "RED" "Wallpaper not found: $wallpaper"
        return 1
    fi

    # Create config file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        touch "$CONFIG_FILE"
    fi

    # Remove existing entry for this workspace
    sed -i "/^${workspace}:/d" "$CONFIG_FILE"

    # Add new entry
    echo "${workspace}:${wallpaper}" >> "$CONFIG_FILE"

    print_colored "GREEN" "Set workspace $workspace wallpaper to: $wallpaper"
}

# Function to auto-assign wallpapers
auto_assign() {
    local max_workspace="$1"
    [ -z "$max_workspace" ] && max_workspace=5

    print_colored "BLUE" "Auto-assigning wallpapers to workspaces 1-$max_workspace..."

    if [ ! -d "$WALLPAPER_DIR" ]; then
        print_colored "RED" "Wallpaper directory not found: $WALLPAPER_DIR"
        return 1
    fi

    # Get list of wallpapers
    wallpapers=($(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -printf "%f\n" | sort))

    if [ ${#wallpapers[@]} -eq 0 ]; then
        print_colored "RED" "No wallpapers found in $WALLPAPER_DIR"
        return 1
    fi

    # Create or backup config file
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%s)"
        print_colored "YELLOW" "Backed up existing config"
    fi

    # Create new config
    cat > "$CONFIG_FILE" << EOF
# Auto-generated workspace wallpaper configuration
# Generated on $(date)
# Edit this file to customize your wallpaper assignments

EOF

    # Assign wallpapers
    for ((i=1; i<=max_workspace; i++)); do
        wallpaper_index=$(( (i-1) % ${#wallpapers[@]} ))
        wallpaper="${wallpapers[$wallpaper_index]}"
        echo "$i:$wallpaper" >> "$CONFIG_FILE"
        print_colored "GREEN" "Workspace $i: $wallpaper"
    done

    # Add fallback
    echo "special:${wallpapers[0]}" >> "$CONFIG_FILE"
    print_colored "BLUE" "Set fallback wallpaper: ${wallpapers[0]}"
}

# Function to test current workspace wallpaper
test_current() {
    if ! command -v hyprctl >/dev/null; then
        print_colored "RED" "hyprctl not found"
        return 1
    fi

    current_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
    print_colored "BLUE" "Current workspace: $current_ws"

    if [ -f "$CONFIG_FILE" ]; then
        wallpaper=$(grep "^${current_ws}:" "$CONFIG_FILE" | cut -d':' -f2- | tr -d ' ')
        if [ -n "$wallpaper" ]; then
            if [ -f "$WALLPAPER_DIR/$wallpaper" ]; then
                wallpaper_path="$WALLPAPER_DIR/$wallpaper"
            elif [ -f "$wallpaper" ]; then
                wallpaper_path="$wallpaper"
            else
                print_colored "RED" "Wallpaper not found: $wallpaper"
                return 1
            fi

            print_colored "GREEN" "Applying wallpaper: $(basename "$wallpaper_path")"
            swww img "$wallpaper_path" \
                --transition-type grow \
                --transition-duration 0.5 \
                --transition-fps 60 \
                --transition-bezier 0.25,1.0,0.5,1.0
        else
            print_colored "YELLOW" "No wallpaper configured for workspace $current_ws"
        fi
    else
        print_colored "RED" "Configuration file not found: $CONFIG_FILE"
    fi
}

# Function to start the parallax service
start_service() {
    local script_path="$SCRIPT_DIR/swww_parallax_effect.sh"

    if [ ! -f "$script_path" ]; then
        print_colored "RED" "Parallax script not found: $script_path"
        return 1
    fi

    if pgrep -f "swww_parallax_effect.sh" >/dev/null; then
        print_colored "YELLOW" "Parallax service already running"
        return 0
    fi

    print_colored "BLUE" "Starting parallax service..."
    chmod +x "$script_path"
    nohup "$script_path" > /dev/null 2>&1 &
    sleep 1

    if pgrep -f "swww_parallax_effect.sh" >/dev/null; then
        print_colored "GREEN" "Parallax service started successfully"
    else
        print_colored "RED" "Failed to start parallax service"
    fi
}

# Function to stop the parallax service
stop_service() {
    if pgrep -f "swww_parallax_effect.sh" >/dev/null; then
        print_colored "BLUE" "Stopping parallax service..."
        pkill -f "swww_parallax_effect.sh"
        print_colored "GREEN" "Parallax service stopped"
    else
        print_colored "YELLOW" "Parallax service not running"
    fi
}

# Function to show service status
service_status() {
    if pgrep -f "swww_parallax_effect.sh" >/dev/null; then
        print_colored "GREEN" "Parallax service is running"
        print_colored "BLUE" "PID: $(pgrep -f "swww_parallax_effect.sh")"
    else
        print_colored "RED" "Parallax service is not running"
    fi

    if pgrep -x "swww-daemon" >/dev/null; then
        print_colored "GREEN" "swww-daemon is running"
    else
        print_colored "RED" "swww-daemon is not running"
    fi
}

# Function to show help
show_help() {
    cat << EOF
Workspace Wallpaper Manager

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
    list                    List available wallpapers
    show                    Show current configuration
    set <ws> <wallpaper>    Set wallpaper for workspace
    auto [max_ws]           Auto-assign wallpapers (default: 5 workspaces)
    test                    Test wallpaper for current workspace
    start                   Start the parallax service
    stop                    Stop the parallax service
    status                  Show service status
    help                    Show this help

Examples:
    $(basename "$0") list
    $(basename "$0") set 1 nature.jpg
    $(basename "$0") auto 10
    $(basename "$0") start

Configuration file: $CONFIG_FILE
Wallpaper directory: $WALLPAPER_DIR
EOF
}

# Main script logic
case "$1" in
    "list")
        list_wallpapers
        ;;
    "show")
        show_config
        ;;
    "set")
        set_workspace_wallpaper "$2" "$3"
        ;;
    "auto")
        auto_assign "$2"
        ;;
    "test")
        test_current
        ;;
    "start")
        start_service
        ;;
    "stop")
        stop_service
        ;;
    "status")
        service_status
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        print_colored "RED" "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
