#!/bin/bash

# Focus Mode Monitor Service
# For macOS Sonoma and later
# Monitors Focus status and configures dock/wallpaper based on YAML configs

# Set up logging
setup_logging() {
    LOG_DIR="$HOME/Library/Logs"
    LOG_FILE="$LOG_DIR/macfocusmodes.log"
    ERROR_LOG="$LOG_DIR/macfocusmodes.error.log"
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Initialize or rotate logs if they're too large (>10MB)
    for log in "$LOG_FILE" "$ERROR_LOG"; do
        if [ -f "$log" ] && [ "$(stat -f%z "$log")" -gt 10485760 ]; then
            mv "$log" "${log}.old"
        fi
        touch "$log"
    done
    
    # Redirect stdout and stderr to both console and log files
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$ERROR_LOG" >&2)
}

# Function to handle errors
handle_error() {
    local error_msg="$1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $error_msg" >&2
    return 1
}

# Function to log info messages
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ... [existing code from macfocusmodes.sh remains the same] ...

# Main execution
setup_logging

log_info "Starting Focus Mode Monitor Service..."
log_info "Configuration directory: $CONFIG_DIR"

# Check for required dependencies
for cmd in dockutil yq jq; do
    if ! command -v $cmd &> /dev/null; then
        handle_error "$cmd is not installed. Please install it using: brew install $cmd"
        exit 1
    fi
done

previous_mode=""
current_wallpaper=""
current_dock_hash=""

# Trap signals for clean shutdown
trap 'log_info "Received shutdown signal, cleaning up..."; exit 0' SIGTERM SIGINT SIGQUIT

while true; do
    current_mode=$(get_focus_status)
    
    if [[ "$current_mode" != "$previous_mode" ]]; then
        log_info "Focus Mode changed: $current_mode"
        
        if [[ "$previous_mode" != "" && "$previous_mode" != "No focus" ]]; then
            save_current_environment "$previous_mode"
        fi
        
        if [[ "$current_mode" != "No focus" ]]; then
            configure_focus_environment "$current_mode"
            current_wallpaper=$(get_current_wallpaper)
            current_dock_hash=$(get_dock_hash)
        fi
        
        previous_mode="$current_mode"
    else
        if [[ "$current_mode" != "No focus" ]]; then
            IFS=$'\n' read -r new_wallpaper new_dock_hash < <(check_environment_changes "$current_mode" "$current_wallpaper" "$current_dock_hash")
            if [ -n "$new_wallpaper" ]; then
                current_wallpaper="$new_wallpaper"
                current_dock_hash="$new_dock_hash"
            fi
        fi
    fi
    
    sleep 2
done 