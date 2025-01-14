# Mac Focus Modes

A macOS service that automatically configures your dock and wallpaper based on your Focus Mode state. When you change Focus Modes (like Work, Personal, Sleep, etc.), this service will automatically update your desktop environment to match.

## Features

- Automatically detects Focus Mode changes
- Configures dock apps and folders based on your Focus Mode
- Sets custom wallpapers for each Focus Mode
- Saves your environment changes automatically
- Runs as a system service

## Prerequisites

The following dependencies are required and will be installed automatically via Homebrew:

- dockutil
- yq
- jq

## Installation

1. Clone this repository: