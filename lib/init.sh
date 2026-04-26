#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotbak_init() {
    local tool_dir="${DOTBAK_TOOL_DIR:-$HOME/dotbak}"
    local default_backup_dir="$HOME/config-backups"
    local config_file="$HOME/.dotbakrc"

    echo "=========================================="
    echo "  dotbak initialization"
    echo "=========================================="
    echo ""

    if [[ -f "$config_file" ]]; then
        echo "Found existing .dotbakrc at $config_file"
        echo ""
        read -p "Use existing config (y) or overwrite (n)? " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            source "$config_file"
            tool_dir="${DOTBAK_TOOL_DIR:-$HOME/dotbak}"
            default_backup_dir="${DOTBAK_BACKUP_DIR:-$HOME/config-backups}"
            echo "Using existing config:"
            echo "  Tool dir: $tool_dir"
            echo "  Backup dir: $default_backup_dir"
        else
            echo "Will create new config..."
        fi
    fi

    if [[ -f "$config_file" ]] && [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "Initialization cancelled."
        return 0
    fi

    echo "Creating tool directory at: $tool_dir"
    mkdir -p "$tool_dir"
    mkdir -p "$tool_dir/lib"

    echo ""
    echo "Where should configs be backed up to?"
    echo "  (Press Enter for default: $default_backup_dir)"
    read -p "> " backup_dir
    backup_dir="${backup_dir:-$default_backup_dir}"

    if [[ -d "$backup_dir" ]]; then
        echo ""
        echo "Found existing backup directory at: $backup_dir"
        read -p "Use existing folder (y) or create new (n)? " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Please specify a different path and run init again."
            return 1
        fi
    else
        echo "Creating backup directory at: $backup_dir"
        mkdir -p "$backup_dir"
    fi

    echo "export DOTBAK_TOOL_DIR=\"$tool_dir\"" > "$config_file"
    echo "export DOTBAK_BACKUP_DIR=\"$backup_dir\"" >> "$config_file"

    echo ""
    echo "Created ~/.dotbakrc:"
    cat "$config_file"

    if [[ ! -d "$tool_dir/.git" ]]; then
        echo ""
        read -p "Initialize git in tool directory? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$tool_dir" && git init
        fi
    fi

    if [[ ! -d "$backup_dir/.git" ]]; then
        echo ""
        read -p "Initialize git in backup directory? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$backup_dir" && git init
        fi
    fi

    if [[ -d "$SCRIPT_DIR/lib" ]] && [[ "$tool_dir" != "$SCRIPT_DIR" ]]; then
        cp "$SCRIPT_DIR/lib/"*.sh "$tool_dir/lib/" 2>/dev/null
    fi

    echo ""
    echo "=========================================="
    echo "  dotbak initialized successfully!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Source ~/.dotbakrc or restart your shell"
    echo "  2. Run 'dotbak backup <file>' to backup a config"
    echo ""
}