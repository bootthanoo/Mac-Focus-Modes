#!/bin/zsh

# Set up environment
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Ensure Homebrew is set up
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Run the main script
exec /opt/homebrew/opt/macfocusmodes/bin/macfocusmodes 