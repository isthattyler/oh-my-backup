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
    
    # Convert any path to home-relative (~) format
    local converted
    converted=$(dotbak_path_to_home_relative "$input")
    echo "$converted"
}

dotbak_path_to_home_relative() {
    local path="$1"
    
    # If already starts with ~, return as-is
    if [[ "$path" == ~* ]]; then
        echo "$path"
        return
    fi
    
    # If path starts with HOME directory, convert to ~
    if [[ "$path" == "$HOME"* ]]; then
        local rel="${path#$HOME}"
        echo "~$rel"
        return
    fi
    
    # If absolute path starting with /c/ or /C/ (Windows Git Bash style)
    if [[ "$path" =~ ^/[cC]/ ]]; then
        local converted="${path#/c/}"
        converted="${converted#/C/}"
        echo "~$converted"
        return
    fi
    
    # For other absolute paths, return as-is
    if [[ "$path" == /* ]]; then
        echo "$path"
        return
    fi
    
    # For relative paths, return as-is
    echo "$path"
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
    
    # If path starts with HOME directory, check it directly
    if [[ "$path" == "$HOME"* ]]; then
        if [[ -f "$path" ]]; then
            echo "$path"
        else
            echo ""
        fi
        return
    fi
    
    # If absolute path starting with /c/ or /C/ (Windows Git Bash style)
    if [[ "$path" =~ ^/[cC]/ ]]; then
        if [[ -f "$path" ]]; then
            echo "$path"
        else
            echo ""
        fi
        return
    fi
    
    # If path starts with ~, expand and check
    if [[ "$path" == ~* ]]; then
        local expanded="${path/#\~/$HOME}"
        if [[ -f "$expanded" ]]; then
            echo "$expanded"
        else
            echo ""
        fi
        return
    fi
    
    # If absolute path, check as-is
    if [[ "$path" == /* ]]; then
        if [[ -f "$path" ]]; then
            echo "$path"
        else
            echo ""
        fi
        return
    fi
    
    # Check current directory first
    local pwd_path="$PWD/$path"
    if [[ -f "$pwd_path" ]]; then
        echo "$pwd_path"
        return
    fi
    
    # Check home directory
    local in_home="$HOME/$path"
    if [[ -f "$in_home" ]]; then
        echo "$in_home"
    else
        echo ""
    fi
}