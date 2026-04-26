#!/bin/bash

LIB_DIR="${DOTBAK_TOOL_DIR:-$HOME/dotbak}/lib"
source "$LIB_DIR/path-utils.sh"

dotbak_read_json_field() {
    local file="$1"
    local field="$2"
    grep -o "\"$field\":[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | tr -d '\n' | sed 's/.*": *//' | tr -d '"'
}

dotbak_list_configs() {
    local backup_dir
    backup_dir=$(dotbak_get_config_path)

    if [[ -z "$backup_dir" ]]; then
        echo "Error: Backup directory not configured. Run 'dotbak init' first."
        return 1
    fi

    if [[ ! -d "$backup_dir" ]]; then
        echo "Error: Backup directory not found at $backup_dir"
        return 1
    fi

    echo "=========================================="
    echo "  Available configs in backup"
    echo "=========================================="
    echo ""

    local count=0
    while IFS= read -r -d '' file; do
        local rel_path="${file#$backup_dir/}"
        local metadata_file="${file%/*}/metadata.json"

        echo "  $rel_path"

        if [[ -f "$metadata_file" ]]; then
            local backup_date
            backup_date=$(dotbak_read_json_field "$metadata_file" "backup_date")
            [[ -z "$backup_date" ]] && backup_date="Unknown"

            local required_tools
            required_tools=$(dotbak_read_json_field "$metadata_file" "required_tools")
            [[ -z "$required_tools" ]] && required_tools=""

            echo "    Last backup: $backup_date"
            if [[ -n "$required_tools" ]]; then
                echo "    Requires: $required_tools"
            fi
        fi
        echo ""
        count=$((count + 1))
    done < <(find "$backup_dir" -type f ! -name "metadata.json" -print0 2>/dev/null)

    if [[ $count -eq 0 ]]; then
        echo "  No configs backed up yet."
        echo ""
        echo "  Run 'dotbak backup <file>' to add configs."
    fi

    echo "=========================================="
    echo "  Total: $count configs"
    echo "=========================================="

    return 0
}

dotbak_status() {
    local backup_dir
    backup_dir=$(dotbak_get_config_path)

    if [[ -z "$backup_dir" ]]; then
        echo "Error: Backup directory not configured. Run 'dotbak init' first."
        return 1
    fi

    echo "=========================================="
    echo "  dotbak status"
    echo "=========================================="
    echo ""
    echo "  Tool directory: ${DOTBAK_TOOL_DIR:-$HOME/dotbak}"
    echo "  Backup directory: $backup_dir"
    echo ""

    if [[ -d "$backup_dir/.git" ]]; then
        cd "$backup_dir" || return 1
        echo "  Git status:"
        echo ""
        git status --short 2>/dev/null || echo "    (not a git repo)"
        echo ""
    else
        echo "  Backup directory is not a git repo."
        echo "  Run 'dotbak init' and choose to initialize git."
    fi

    echo "=========================================="

    return 0
}