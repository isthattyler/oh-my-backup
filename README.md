# dotbak

A CLI tool to backup and restore configuration files across machines.

## Features

- Backup individual config files with a single command
- Backup all tracked configs at once
- Restore configs from backup to their original locations
- Cross-platform support (Linux, macOS, Windows via Git Bash)
- Git integration with automatic commits and PR creation
- Tool availability checks before installing configs

## Prerequisites

- Git Bash (required for Windows)
- Git (for version control features)
- `gh` CLI (optional, for automatic PR creation)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/YOUR_USERNAME/oh-my-backup.git
cd oh-my-backup
```

2. Run the installer:
```bash
bash install.sh
```

3. Restart your shell or run:
```bash
source ~/.dotbakrc
```

## Usage

### Initialize (first time)
```bash
bash install.sh
```

### Backup Commands
```bash
# Backup a single config file
dotbak backup .bashrc
dotbak backup ~/.zshrc
dotbak backup .config/opencode/opencode.json

# Backup all tracked configs
dotbak backup-all
```

### Install Commands
```bash
# Install a single config
dotbak install .bashrc

# Install all tracked configs
dotbak install-all
```

### Other Commands
```bash
# List all available configs
dotbak list

# Show status
dotbak status

# Initialize backup folder (if not done during install)
dotbak init
```

## Configuration

Configuration is stored in `~/.dotbakrc`:
```bash
export DOTBAK_TOOL_DIR="$HOME/dotbak"
export DOTBAK_BACKUP_DIR="$HOME/config-backups"
```

## Backup Folder Structure

Configs are stored in individual folders:
```
~/config-backups/
├── .bashrc/
│   ├── .bashrc
│   └── metadata.json
├── .zshrc/
│   ├── .zshrc
│   └── metadata.json
└── .config/
    └── opencode/
        └── opencode.json/
            ├── opencode.json
            └── metadata.json
```

## Git Integration

When backing up:
- If backup folder is a git repo with remote: creates branch, commits, pushes, and offers to create PR
- If no remote: creates local commit only

## Notes

- Requires Git Bash on Windows
- Backup paths are stored in POSIX format for cross-platform compatibility
- Use `dotbak list` to see all tracked configs and their last backup date