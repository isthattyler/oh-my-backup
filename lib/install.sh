#!/bin/bash

LIB_DIR="${DOTBAK_TOOL_DIR:-$HOME/dotbak}/lib"
source "$LIB_DIR/path-utils.sh"

dotbak_read_json_field() {
    local file="$1"
    local field="$2"
    grep -o "\"$field\":[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | tr -d '\n' | sed 's/.*": *//' | tr -d '"'
}

dotbak_check_required_tools() {
    local metadata_file="$1"
    if [[ ! -f "$metadata_file" ]]; then
        return 0
    fi

    local required_tools
    required_tools=$(dotbak_read_json_field "$metadata_file" "required_tools")

    if [[ -z "$required_tools" ]] || [[ "$required_tools" == "[]" ]]; then
        return 0
    fi

    local missing_tools=()
    IFS=',' read -ra tools <<< "$required_tools"
    for tool in "${tools[@]}"; do
        tool=$(echo "$tool" | tr -d '[]" ')
        if [[ -n "$tool" ]] && ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Warning: Missing required tools for this config:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        return 1
    fi

    return 0
}

dotbak_install_single() {
    local config_name="$1"
    local backup_dir
    backup_dir=$(dotbak_get_config_path)

    if [[ -z "$backup_dir" ]]; then
        echo "Error: Backup directory not configured. Run 'dotbak init' first."
        return 1
    fi

    local config_path_in_backup
    config_path_in_backup=$(find "$backup_dir" -type f ! -name "metadata.json" -name "$config_name" 2>/dev/null | head -1)

    if [[ -z "$config_path_in_backup" ]]; then
        echo "Error: Config '$config_name' not found in backup directory."
        return 1
    fi

    local metadata_file="${config_path_in_backup%/*}/metadata.json"
    dotbak_check_required_tools "$metadata_file" || true

    local original_path="~/$config_name"
    if [[ -f "$metadata_file" ]]; then
        original_path=$(dotbak_read_json_field "$metadata_file" "original_path")
        [[ -z "$original_path" ]] && original_path="~/$config_name"
    fi

    local target_path
    target_path=$(dotbak_path_expand "$original_path")

    local target_dir
    target_dir=$(dirname "$target_path")

    mkdir -p "$target_dir"
    cp "$config_path_in_backup" "$target_path"

    echo "Installed: $config_path_in_backup"
    echo "  -> $target_path"

    return 0
}

dotbak_install_all() {
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
    echo "  Installing all tracked configs"
    echo "=========================================="
    echo ""

    local installed=()
    local skipped=()

    while IFS= read -r -d '' file; do
        local filename
        filename=$(basename "$file")

        local folder="${file#$backup_dir/}"
        folder="${folder%/*}"

        local metadata_file="$backup_dir/$folder/metadata.json"
        local original_path="~/$filename"
        if [[ -f "$metadata_file" ]]; then
            original_path=$(dotbak_read_json_field "$metadata_file" "original_path")
            [[ -z "$original_path" ]] && original_path="~/$filename"
        fi

        dotbak_check_required_tools "$metadata_file" || true

        local target_path
        target_path=$(dotbak_path_expand "$original_path")

        local target_dir
        target_dir=$(dirname "$target_path")

        mkdir -p "$target_dir"
        cp "$file" "$target_path"

        installed+=("$filename -> $original_path")
    done < <(find "$backup_dir" -type f ! -name "metadata.json" -print0 2>/dev/null)

    echo "Installed:"
    for item in "${installed[@]}"; do
        echo "  - $item"
    done

    if [[ ${#skipped[@]} -gt 0 ]]; then
        echo ""
        echo "Skipped:"
        for item in "${skipped[@]}"; do
            echo "  - $item"
        done
    fi

    echo ""
    echo "=========================================="
    echo "  All configs installed!"
    echo "=========================================="

    return 0
}