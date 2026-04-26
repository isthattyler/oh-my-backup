#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotbak_path_expand() {
    local path="$1"
    local expanded="${path/#\~/$HOME}"
    if command -v cygpath &> /dev/null; then
        expanded=$(cygpath -u "$expanded" 2>/dev/null || echo "$expanded")
    fi
    echo "$expanded"
}

dotbak_path_to_posix() {
    local path="$1"
    local expanded="${path/#\~/$HOME}"
    if command -v cygpath &> /dev/null; then
        expanded=$(cygpath -u "$expanded" 2>/dev/null || echo "$expanded")
    fi
    expanded="${expanded/#\/c\//~/}"
    expanded="${expanded/#\/C\//~/}"
    echo "$expanded"
}

dotbak_path_from_posix() {
    local posix_path="$1"
    if [[ "$posix_path" == ~* ]]; then
        echo "$posix_path"
        return
    fi
    if command -v cygpath &> /dev/null; then
        local win_path
        win_path=$(cygpath -w "$posix_path" 2>/dev/null || echo "$posix_path")
        echo "$win_path"
    else
        echo "$posix_path"
    fi
}

dotbak_get_config_path() {
    local tool_dir="${DOTBAK_TOOL_DIR:-$HOME/dotbak}"
    local backup_dir="${DOTBAK_BACKUP_DIR:-$HOME/config-backups}"
    echo "$backup_dir"
}

dotbak_ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

dotbak_file_exists() {
    local path="$1"
    local expanded
    expanded=$(dotbak_path_expand "$path")
    [[ -f "$expanded" ]]
}

dotbak_normalize_config_path() {
    local input="$1"
    local normalized

    if [[ "$input" == \.* ]] || [[ "$input" == ~* ]]; then
        normalized="$input"
    elif [[ "$input" == /* ]]; then
        normalized="$input"
    else
        normalized="~/$input"
    fi

    normalized=$(echo "$normalized" | sed 's|/\+|/|g')

    echo "$normalized"
}

dotbak_get_file_from_config() {
    local config_path="$1"
    local filename
    filename=$(basename "$config_path")
    echo "$filename"
}

dotbak_get_folder_from_config() {
    local config_path="$1"
    local folder="${config_path#/}"
    folder="${folder/#\~}"
    folder="${folder#/}"
    folder="${folder%/*}"
    echo "$folder"
}

dotbak_resolve_to_home() {
    local path="$1"
    local expanded
    expanded=$(dotbak_path_expand "$path")
    if [[ -f "$expanded" ]]; then
        echo "$expanded"
    elif [[ "$path" != "~"* ]] && [[ "$path" != "/"* ]]; then
        local with_home="$HOME/$path"
        if [[ -f "$with_home" ]]; then
            echo "$with_home"
        else
            echo ""
        fi
    else
        echo ""
    fi
}