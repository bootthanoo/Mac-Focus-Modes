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
```bash
git clone https://github.com/yourusername/Mac-Focus-Modes.git
cd Mac-Focus-Modes
```

2. Install via Homebrew:
```bash
brew install --formula ./macfocusmodes.rb
```

3. Start the service:
```bash
brew services start macfocusmodes
```

## Configuration

Configuration files are stored in `~/.config/macfocusmodes/`. For each Focus Mode, a YAML configuration file will be automatically created when you first enter that mode.

### Wallpapers

You can add custom wallpapers for each Focus Mode by placing them in the `~/.config/macfocusmodes/` directory with the name matching your Focus Mode (e.g., `Work.jpg`, `Personal.png`).

### Logs

Logs are stored in `/usr/local/var/log/macfocusmodes.log`

## Usage

The service runs automatically in the background. When you change your Focus Mode in macOS:

1. The service detects the change
2. Applies the corresponding dock configuration
3. Sets the matching wallpaper
4. Saves any changes you make while in that Focus Mode

To stop the service:
```bash
brew services stop macfocusmodes
```

To restart the service:
```bash
brew services restart macfocusmodes
```

## Troubleshooting

If you encounter any issues:

1. Check the logs:
```bash
tail -f /usr/local/var/log/macfocusmodes.log
```

2. Make sure the service is running:
```bash
brew services list | grep macfocusmodes
```

3. Verify your configuration directory exists:
```bash
ls ~/.config/macfocusmodes/
```

## License

MIT License 