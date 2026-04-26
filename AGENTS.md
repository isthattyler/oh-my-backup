# AGENTS.md

## Project Overview

`dotbak` is a CLI tool for backing up and restoring configuration files across machines. It stores configs in a dedicated folder (`~/config-backups/` by default) with metadata for tracking.

## Directory Structure

```
oh-my-backup/               # Tool repository
├── dotbak                  # Main entry point
├── lib/                    # Library scripts
│   ├── backup.sh          # Backup logic
│   ├── install.sh         # Install logic (lib)
│   ├── git-utils.sh       # Git operations
│   ├── init.sh            # Initialization
│   ├── list.sh            # List configs
│   └── path-utils.sh      # Path handling
├── install.sh             # Top-level installer
├── .dotbakrc.template     # Config template
└── README.md

~/config-backups/          # User's backup storage
├── .bashrc/
│   ├── .bashrc
│   └── metadata.json
└── ...
```

## Key Files

### dotbak (main script)
- Reads `~/.dotbakrc` for `DOTBAK_TOOL_DIR` and `DOTBAK_BACKUP_DIR`
- Dispatches commands to lib scripts
- Commands: init, backup, backup-all, install, install-all, list, status

### lib/*.sh
- Use `LIB_DIR="${DOTBAK_TOOL_DIR:-$HOME/dotbak}/lib"` to find lib path
- Source `path-utils.sh` for path functions
- All functions prefixed with `dotbak_`

### path-utils.sh
- `dotbak_path_expand()` - Expand ~ to HOME
- `dotbak_normalize_config_path()` - Normalize input paths
- `dotbak_resolve_to_home()` - Find file in home directory
- `dotbak_get_config_path()` - Get backup directory from config
- `dotbak_read_json_field()` - Parse metadata.json (via grep/sed)

### metadata.json Format
```json
{
  "original_path": "~/.bashrc",
  "backup_date": "2026-04-26T12:00:00Z",
  "required_tools": []
}
```

## Important Conventions

1. **Path Handling**: Store paths in POSIX format (`~/.config/...`)
2. **Metadata**: Always include `original_path` and `backup_date`
3. **Git**: Only commit on backup, never on install
4. **Error Handling**: Return 1 on error, 0 on success
5. **Cross-Platform**: Work with Git Bash on Windows

## Adding New Commands

1. Add function in appropriate lib/*.sh file
2. Add command case in main dotbak script
3. Test with `dotbak <command>`

## Testing

```bash
# After install
source ~/.dotbakrc
dotbak status
dotbak list
```