#!/bin/bash

LIB_DIR="${DOTBAK_TOOL_DIR:-$HOME/dotbak}/lib"
source "$LIB_DIR/path-utils.sh"
source "$LIB_DIR/git-utils.sh"

dotbak_read_json_field() {
    local file="$1"
    local field="$2"
    grep -o "\"$field\":[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | tr -d '\n' | sed 's/.*": *//' | tr -d '"'
}

dotbak_backup_single() {
    local config_path="$1"
    local backup_dir
    backup_dir=$(dotbak_get_config_path)

    if [[ -z "$backup_dir" ]]; then
        echo "Error: Backup directory not configured. Run 'dotbak init' first."
        return 1
    fi

    local normalized_path
    normalized_path=$(dotbak_normalize_config_path "$config_path")

    local actual_path
    actual_path=$(dotbak_resolve_to_home "$normalized_path")

    if [[ -z "$actual_path" ]] || [[ ! -f "$actual_path" ]]; then
        echo "Error: File not found at $normalized_path. Cannot backup."
        return 1
    fi

    local filename
    filename=$(basename "$actual_path")

    local folder_from_home
    folder_from_home=$(dotbak_path_to_home_relative "$normalized_path")
    folder_from_home="${folder_from_home#/}"
    folder_from_home="${folder_from_home/#\~}"
    folder_from_home="${folder_from_home#/}"
    folder_from_home="${folder_from_home%/*}"

    local target_folder="$backup_dir"
    if [[ -n "$folder_from_home" ]]; then
        target_folder="$backup_dir/$folder_from_home"
    else
        target_folder="$backup_dir"
    fi

    mkdir -p "$target_folder"
    cp "$actual_path" "$target_folder/"

    local metadata_file="$target_folder/metadata.json"
    local backup_date
    backup_date=$(date -Iseconds)
    local original_path
    original_path=$(dotbak_path_to_home_relative "$normalized_path")

    if [[ -f "$metadata_file" ]]; then
        local temp_file
        temp_file=$(mktemp)
        local existing_tools
        existing_tools=$(dotbak_read_json_field "$metadata_file" "required_tools")
        cat > "$temp_file" << EOF
{
  "original_path": "$original_path",
  "backup_date": "$backup_date",
  "required_tools": "${existing_tools:-[]}"
}
EOF
        mv "$temp_file" "$metadata_file"
    else
        cat > "$metadata_file" << EOF
{
  "original_path": "$original_path",
  "backup_date": "$backup_date",
  "required_tools": []
}
EOF
    fi

    echo "Backed up: $normalized_path"
    echo "  -> $target_folder/$filename"

    return 0
}

dotbak_backup_all() {
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
    echo "  Backing up all tracked configs"
    echo "=========================================="
    echo ""

    local backed_up=()
    local skipped=()
    local updated=()

    while IFS= read -r -d '' file; do
        local metadata_file="${file%/*}/metadata.json"
        if [[ -f "$metadata_file" ]]; then
            local original_path
            original_path=$(dotbak_read_json_field "$metadata_file" "original_path")

            if [[ -n "$original_path" ]]; then
                local actual_path
                actual_path=$(dotbak_resolve_to_home "$original_path")

                if [[ -f "$actual_path" ]]; then
                    cp "$actual_path" "$file"
                    backed_up+=("$original_path")
                else
                    skipped+=("$original_path (file not found)")
                fi
            fi
        fi
    done < <(find "$backup_dir" -type f ! -name "metadata.json" -print0 2>/dev/null)

    if [[ ${#updated[@]} -gt 0 ]]; then
        echo "Updated:"
        for path in "${updated[@]}"; do
            echo "  - $path"
        done
        echo ""
    fi

    if [[ ${#backed_up[@]} -gt 0 ]]; then
        echo "Backed up:"
        for path in "${backed_up[@]}"; do
            echo "  - $path"
        done
        echo ""
    fi

    if [[ ${#skipped[@]} -gt 0 ]]; then
        echo "Skipped (not found):"
        for path in "${skipped[@]}"; do
            echo "  - $path"
        done
    fi

    if [[ ${#updated[@]} -eq 0 ]] && [[ ${#backed_up[@]} -eq 0 ]] && [[ ${#skipped[@]} -eq 0 ]]; then
        echo "No configs to backup. Add configs first with 'dotbak backup <file>'"
        return 0
    fi

    echo ""
    echo "=========================================="
    echo "  Git operations"
    echo "=========================================="
    echo ""

    if dotbak_git_is_repo "$backup_dir"; then
        local branch_name="backup/$(date +%Y%m%d-%H%M%S)"
        dotbak_git_create_branch "$backup_dir" "$branch_name"

        local commit_message="Backup all: $(date +%Y-%m-%d)"
        dotbak_git_commit_and_push "$backup_dir" "$commit_message"

        if dotbak_git_has_remote "$backup_dir"; then
            echo ""
            read -p "Create PR for this backup? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                local pr_title="Backup: $(date +%Y-%m-%d)"
                dotbak_git_create_pr "$backup_dir" "$pr_title"
            fi
        fi
    else
        echo "Backup directory is not a git repo. Skipping git operations."
        echo "Run 'dotbak init' to initialize git."
    fi

    return 0
}