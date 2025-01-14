#!/bin/bash

# Configuration directory
CONFIG_DIR="$HOME/.config/macfocusmodes"
mkdir -p "$CONFIG_DIR"

# Function to handle errors
error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >&2
    return 1
}

# Function to get current focus mode
get_focus_mode() {
    local assertions_file="/Users/$USER/Library/DoNotDisturb/DB/Assertions.json"
    local config_file="/Users/$USER/Library/DoNotDisturb/DB/ModeConfigurations.json"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking assertions file: $assertions_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Checking config file: $config_file"
    
    if [[ ! -r "$assertions_file" ]]; then
        error "Assertions file not readable: $assertions_file"
        return 1
    fi
    
    if [[ ! -r "$config_file" ]]; then
        error "Config file not readable: $config_file"
        return 1
    }
    
    # Parse assertions file
    local mode_id
    mode_id=$(jq -r '.assertions[0].mode_id' "$assertions_file" 2>/dev/null)
    if [[ $? -ne 0 || -z "$mode_id" ]]; then
        error "Failed to parse mode_id from assertions file"
        return 1
    fi
    
    echo "$mode_id"
}

# Function to save current environment
save_environment() {
    local mode="$1"
    if [[ -z "$mode" ]]; then
        error "No mode specified for saving environment"
        return 1
    }
    
    echo "Saving current environment for focus mode: $mode"
    
    # Get current wallpaper
    local wallpaper
    wallpaper=$(osascript -e 'tell application "System Events" to tell every desktop to get picture' 2>/dev/null)
    echo "Debug: Current wallpaper path: $wallpaper"
    
    # Create config file path using sanitized mode name
    local safe_mode=$(echo "$mode" | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]')
    local config_file="$CONFIG_DIR/${safe_mode}.yaml"
    
    # Save environment to YAML
    cat > "$config_file" << EOL
wallpaper: "$wallpaper"
dock_apps:
$(dockutil --list | awk -F'\t' '{print "  - " $1}')
EOL
    
    if [[ $? -eq 0 ]]; then
        echo "Environment saved to $config_file"
    else
        error "Failed to save environment to $config_file"
        return 1
    fi
}

# Function to configure environment
configure_environment() {
    local mode="$1"
    if [[ -z "$mode" ]]; then
        error "No mode specified for configuring environment"
        return 1
    }
    
    echo "Configuring environment for focus mode: $mode"
    
    # Create config file path using sanitized mode name
    local safe_mode=$(echo "$mode" | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]')
    local config_file="$CONFIG_DIR/${safe_mode}.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        echo "No configuration file found for $mode"
        echo "Creating new configuration from current setup..."
        save_environment "$mode"
        return 0
    fi
    
    # Read and apply configuration
    local wallpaper
    wallpaper=$(yq -r '.wallpaper' "$config_file" 2>/dev/null)
    if [[ $? -eq 0 && -n "$wallpaper" ]]; then
        osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaper\""
    else
        error "Failed to read wallpaper from config file"
    fi
    
    # Configure dock
    local dock_apps
    dock_apps=$(yq -r '.dock_apps[]' "$config_file" 2>/dev/null)
    if [[ $? -eq 0 && -n "$dock_apps" ]]; then
        dockutil --remove all
        echo "$dock_apps" | while read app; do
            dockutil --add "$app"
        done
    else
        error "Failed to read dock apps from config file"
    fi
}

# Main loop
previous_mode=""

while true; do
    current_mode=$(get_focus_mode)
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Current focus mode: $current_mode"
    
    if [[ "$current_mode" != "$previous_mode" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Focus Mode changed from '$previous_mode' to '$current_mode'"
        
        if [[ -n "$previous_mode" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Saving environment for previous mode: $previous_mode"
            save_environment "$previous_mode"
        fi
        
        configure_environment "$current_mode"
    fi
    
    previous_mode="$current_mode"
    sleep 3
done 