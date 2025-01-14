#!/bin/zsh

# Focus Mode Monitor v13
# For macOS Sonoma and later
# Monitors Focus status and configures dock/wallpaper based on YAML configs

# Ensure we have the right PATH for Homebrew
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Set up logging
LOG_DIR="/opt/homebrew/var/log/macfocusmodes"
LOG_FILE="$LOG_DIR/macfocusmodes.log"

# Create log directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" || {
        LOG_DIR="$HOME/.local/var/log/macfocusmodes"
        mkdir -p "$LOG_DIR"
    }
fi

if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE" || {
        LOG_FILE="$HOME/.local/var/log/macfocusmodes/macfocusmodes.log"
        mkdir -p "$(dirname "$LOG_FILE")"
        touch "$LOG_FILE"
    }
fi

# Function to log messages with timestamps
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $1" >> "$LOG_FILE"
    echo "$timestamp - $1"
}

# Function to clean up on exit
cleanup() {
    log "Service stopping..."
    exit 0
}

# Set up signal handling
trap cleanup SIGTERM SIGINT SIGHUP

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then 
    log "Error: Please do not run this script with sudo!"
    log "Run it normally as: brew services start macfocusmodes"
    exit 1
fi

# Function to handle errors
handle_error() {
    echo "Error: $1"
    return 1
}

# Function to set up Homebrew
setup_homebrew() {
    # Check for Apple Silicon Mac Homebrew
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    fi
    
    # Check for Intel Mac Homebrew
    if [ -f "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return 0
    fi
    
    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
        return 0
    fi
    
    echo "Error: Homebrew not found"
    return 1
}

# Set up environment
CONFIG_DIR="$HOME/.config/macfocusmodes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating configuration directory at $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

setup_homebrew || handle_error "Failed to set up Homebrew"

# Check for required dependencies
for cmd in dockutil yq jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed"
        echo "Install it using: brew install $cmd"
        exit 1
    fi
done

# Function to find wallpaper file
find_wallpaper() {
    local focus_name="$1"
    local extensions=("jpg" "jpeg" "png" "heic" "webp" "HEIC" "JPG" "JPEG" "PNG" "WEBP")
    
    # First check in config directory
    for ext in "${extensions[@]}"; do
        local wallpaper_path="$CONFIG_DIR/$focus_name.$ext"
        if [ -f "$wallpaper_path" ]; then
            echo "$wallpaper_path"
            return 0
        fi
    done
    
    # Then check in script directory as fallback
    for ext in "${extensions[@]}"; do
        local wallpaper_path="$SCRIPT_DIR/$focus_name.$ext"
        if [ -f "$wallpaper_path" ]; then
            echo "$wallpaper_path"
            return 0
        fi
    done
    
    return 1
}

# Function to get current wallpaper
get_current_wallpaper() {
    local wallpaper_path=$(osascript -e 'tell application "System Events" to get picture of every desktop' | head -n 1)
    # Remove any quotes that might be in the path
    wallpaper_path="${wallpaper_path//\"}"
    echo "$wallpaper_path"
}

# Function to get current dock apps
get_dock_apps() {
    # Print raw dock data to stderr for debugging
    echo "Debug: Raw dock data from dockutil:" >&2
    dockutil --list >&2
    
    # Process dock items for the YAML
    dockutil --list | while read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Try to extract the path (second column)
        path=$(echo "$line" | awk -F'\t' '{print $2}')
        
        # Check if it's a spacer (com.apple.dock.plist) or a valid app path
        if [[ "$path" == *"com.apple.dock.plist"* ]]; then
            echo "spacer"
        elif [[ "$path" == file://* ]]; then
            # Remove the "file://" prefix and decode URL encoding
            cleaned_path="${path#file://}"
            cleaned_path="$(printf '%b' "${cleaned_path//%/\\x}")"
            echo "$cleaned_path"
        fi
    done
}

# Function to save current environment to YAML
save_current_environment() {
    local focus_mode="$1"
    local config_file="$CONFIG_DIR/$focus_mode.yaml"
    local temp_file="$CONFIG_DIR/.temp_$focus_mode.yaml"
    
    echo "Saving current environment for focus mode: $focus_mode"
    
    # Get current wallpaper path
    local current_wallpaper=$(get_current_wallpaper)
    echo "Debug: Current wallpaper path: $current_wallpaper"
    
    # Create new YAML content
    {
        echo "# Focus Mode Configuration for $focus_mode"
        if [ -n "$current_wallpaper" ] && [ -f "$current_wallpaper" ]; then
            echo "wallpaper: \"$current_wallpaper\""
        else
            echo "wallpaper: null"
        fi
        
        # Save dock apps and spacers
        echo "Applications:"
        get_dock_apps | while read -r item; do
            if [ "$item" = "spacer" ]; then
                echo "  - spacer"
            elif [ -n "$item" ]; then
                echo "  - \"$item\""
            fi
        done
        
        # Save dock folders
        echo "Other:"
        dockutil --list | grep "directory:" | while IFS=$'\t' read -r folder_name folder_path view display sort; do
            if [[ "$folder_path" == /* && "$folder_path" == *"/"* ]]; then
                local safe_name=$(echo "$folder_name" | tr ' ' '_')
                echo "  $safe_name:"
                echo "    path: \"$folder_path\""
                echo "    view: \"$view\""
                echo "    display: \"$display\""
                echo "    sort: \"$sort\""
            fi
        done
    } > "$config_file"
    
    echo "Environment saved to $config_file"
}

# Function to configure dock and wallpaper
configure_focus_environment() {
    local focus_mode="$1"
    local config_file="$CONFIG_DIR/$focus_mode.yaml"
    
    echo "Configuring environment for focus mode: $focus_mode"
    
    # Check for config file
    if [ ! -f "$config_file" ]; then
        echo "No configuration file found for $focus_mode"
        echo "Creating new configuration from current setup..."
        save_current_environment "$focus_mode"
        echo "Created initial configuration for $focus_mode"
        return 0
    fi
    
    # Set wallpaper from YAML config
    local wallpaper_path=$(yq e '.wallpaper' "$config_file")
    if [ -n "$wallpaper_path" ] && [ "$wallpaper_path" != "null" ] && [ -f "$wallpaper_path" ]; then
        echo "Setting wallpaper to: $wallpaper_path"
        osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaper_path\"" || echo "Failed to set wallpaper"
    else
        # Fallback to looking for wallpaper file by focus mode name
        wallpaper_path=$(find_wallpaper "$focus_mode")
        if [ -n "$wallpaper_path" ]; then
            echo "Setting wallpaper to: $wallpaper_path"
            osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaper_path\"" || echo "Failed to set wallpaper"
        fi
    fi
    
    # Configure Dock
    echo "Updating Dock configuration..."
    
    # Remove existing apps
    dockutil --remove all --no-restart --section apps || handle_error "Failed to remove apps from Dock"
    
    # Add applications from YAML
    while read -r item; do
        if [ "$item" = "spacer" ]; then
            echo "Adding spacer to Dock..."
            dockutil --add '' --type small-spacer --section apps --no-restart || echo "Failed to add spacer"
        elif [ -n "$item" ]; then
            echo "Adding $(basename "$item") to Dock..."
            dockutil --add "$item" --no-restart || echo "Failed to add $(basename "$item")"
        fi
    done < <(yq e '.Applications[]' "$config_file" 2>/dev/null || echo "")
    
    # Add folders with settings
    while read -r folder; do
        if [ -n "$folder" ]; then
            local path=$(yq e ".Other.$folder.path" "$config_file")
            local view=$(yq e ".Other.$folder.view" "$config_file")
            local display=$(yq e ".Other.$folder.display" "$config_file")
            local sort=$(yq e ".Other.$folder.sort" "$config_file")
            
            if [ -n "$path" ] && [ -n "$view" ] && [ -n "$display" ] && [ -n "$sort" ]; then
                echo "Adding folder: $folder"
                dockutil --add "$path" \
                    --view "$view" \
                    --display "$display" \
                    --sort "$sort" \
                    --no-restart || echo "Failed to add folder: $folder"
            fi
        fi
    done < <(yq e '.Other | keys | .[]' "$config_file" 2>/dev/null || echo "")
    
    # Restart Dock only once at the end to apply all changes
    echo "Restarting Dock to apply all changes..."
    killall Dock
    echo "Dock configuration updated"
}

# Function to get dock configuration hash
get_dock_hash() {
    dockutil --list | md5
}

# Function to check and save environment changes
check_environment_changes() {
    local focus_mode="$1"
    local current_wallpaper="$2"
    local current_dock_hash="$3"
    
    # Skip if no focus mode
    if [[ "$focus_mode" == "No focus" || -z "$focus_mode" ]]; then
        return 0
    fi
    
    local changed=0
    
    # Check wallpaper changes
    local new_wallpaper=$(get_current_wallpaper)
    if [[ "$new_wallpaper" != "$current_wallpaper" ]]; then
        echo "Wallpaper change detected"
        changed=1
    fi
    
    # Check dock changes
    local new_dock_hash=$(get_dock_hash)
    if [[ "$new_dock_hash" != "$current_dock_hash" ]]; then
        echo "Dock configuration change detected"
        changed=1
    fi
    
    # If either changed, save the new configuration
    if [[ $changed -eq 1 ]]; then
        echo "Saving updated configuration for $focus_mode"
        save_current_environment "$focus_mode"
        # Return the new state
        echo "$new_wallpaper"
        echo "$new_dock_hash"
    else
        # Return the old state
        echo "$current_wallpaper"
        echo "$current_dock_hash"
    fi
}

echo "Starting Focus mode monitor service..."
echo "Press Ctrl+C to exit"

previous_mode=""
current_wallpaper=""
current_dock_hash=""

get_focus_status() {
    # Default focus status
    local focus="No focus"
    
    # Paths to DoNotDisturb configuration files
    local assertions_file="$HOME/Library/DoNotDisturb/DB/Assertions.json"
    local config_file="$HOME/Library/DoNotDisturb/DB/ModeConfigurations.json"
    
    # Check if files exist
    if [[ ! -f "$assertions_file" ]] || [[ ! -f "$config_file" ]]; then
        echo "Error: Focus configuration files not found"
        return 1
    fi
    
    # Check for manual focus assertion
    if assertion_records=$(jq -r '.data[0].storeAssertionRecords' "$assertions_file" 2>/dev/null); then
        if [[ "$assertion_records" != "null" && "$assertion_records" != "[]" ]]; then
            # Get mode identifier from assertions
            mode_id=$(jq -r '.data[0].storeAssertionRecords[0].assertionDetails.assertionDetailsModeIdentifier' "$assertions_file")
            if [[ -n "$mode_id" && "$mode_id" != "null" ]]; then
                # Get mode name from configurations
                focus=$(jq -r ".data[0].modeConfigurations[\"$mode_id\"].mode.name" "$config_file")
            fi
        else
            # Check for scheduled focus
            current_time=$(date +%H:%M)
            hour=$(date +%H)
            minute=$(date +%M)
            current_minutes=$((hour * 60 + minute))
            
            # Parse configurations for scheduled focus
            jq -r '.data[0].modeConfigurations | to_entries[] | select(.value.triggers.triggers[0].enabledSetting == 2)' "$config_file" | \
            while IFS= read -r entry; do
                start_hour=$(echo "$entry" | jq -r '.value.triggers.triggers[0].timePeriodStartTimeHour')
                start_min=$(echo "$entry" | jq -r '.value.triggers.triggers[0].timePeriodStartTimeMinute')
                end_hour=$(echo "$entry" | jq -r '.value.triggers.triggers[0].timePeriodEndTimeHour')
                end_min=$(echo "$entry" | jq -r '.value.triggers.triggers[0].timePeriodEndTimeMinute')
                
                start_time=$((start_hour * 60 + start_min))
                end_time=$((end_hour * 60 + end_min))
                
                if [[ $start_time -lt $end_time ]]; then
                    if [[ $current_minutes -ge $start_time && $current_minutes -lt $end_time ]]; then
                        focus=$(echo "$entry" | jq -r '.value.mode.name')
                    fi
                elif [[ $start_time -gt $end_time ]]; then
                    if [[ $current_minutes -ge $start_time || $current_minutes -lt $end_time ]]; then
                        focus=$(echo "$entry" | jq -r '.value.mode.name')
                    fi
                fi
            done
        fi
    fi
    
    echo "$focus"
}

# Main loop modifications
log "Starting Focus mode monitor service..."

while true; do
    current_mode=$(get_focus_status)
    
    # Only update when the mode changes
    if [[ "$current_mode" != "$previous_mode" ]]; then
        log "Focus Mode changed to: $current_mode"
        
        # Save current environment to the previous mode's config if it wasn't "No focus"
        if [[ "$previous_mode" != "" && "$previous_mode" != "No focus" ]]; then
            log "Saving environment for previous mode: $previous_mode"
            save_current_environment "$previous_mode"
        fi
        
        # Configure environment for the new focus mode
        if [[ "$current_mode" != "No focus" ]]; then
            log "Configuring environment for new mode: $current_mode"
            configure_focus_environment "$current_mode"
            # Initialize state tracking for the new mode
            current_wallpaper=$(get_current_wallpaper)
            current_dock_hash=$(get_dock_hash)
        fi
        
        previous_mode="$current_mode"
    else
        # Check for environment changes if we're in a focus mode
        if [[ "$current_mode" != "No focus" ]]; then
            # Get changes and read into variables
            IFS=$'\n' read -r new_wallpaper new_dock_hash < <(check_environment_changes "$current_mode" "$current_wallpaper" "$current_dock_hash")
            if [ -n "$new_wallpaper" ]; then
                log "Environment changes detected and saved for mode: $current_mode"
                current_wallpaper="$new_wallpaper"
                current_dock_hash="$new_dock_hash"
            fi
        fi
    fi
    
    sleep 2
done 