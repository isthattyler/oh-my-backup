#!/bin/bash

dotbak_git_has_remote() {
    local repo_dir="$1"
    if [[ ! -d "$repo_dir/.git" ]]; then
        return 1
    fi
    cd "$repo_dir" && git remote -v &> /dev/null
}

dotbak_git_is_repo() {
    local dir="$1"
    [[ -d "$dir/.git" ]]
}

dotbak_git_init() {
    local dir="$1"
    if [[ ! -d "$dir/.git" ]]; then
        mkdir -p "$dir"
        cd "$dir" && git init
    fi
}

dotbak_git_commit_and_push() {
    local repo_dir="$1"
    local message="$2"
    local branch="${3:-main}"

    cd "$repo_dir" || return 1

    if ! git diff --quiet || [[ -n "$(git status --porcelain)" ]]; then
        git add -A
        git commit -m "$message"
    else
        echo "Nothing to commit"
        return 0
    fi

    if dotbak_git_has_remote "$repo_dir"; then
        local current_branch
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        git push -u origin "$current_branch" 2>/dev/null
        echo "Pushed to remote"
        return 0
    else
        echo "No remote configured, skipping push"
        return 0
    fi
}

dotbak_git_create_branch() {
    local repo_dir="$1"
    local branch_name="$2"

    cd "$repo_dir" || return 1
    git checkout -b "$branch_name" 2>/dev/null || git checkout "$branch_name"
}

dotbak_git_create_pr() {
    local repo_dir="$1"
    local title="$2"
    local body="${3:-}"
    local base_branch="${4:-main}"

    cd "$repo_dir" || return 1

    if ! command -v gh &> /dev/null; then
        echo "GitHub CLI (gh) not found. Install it to create PRs automatically."
        return 1
    fi

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [[ -z "$body" ]]; then
        body="Automated backup via dotbak"
    fi

    local pr_url
    pr_url=$(gh pr create --title "$title" --body "$body" --base "$base_branch" --head "$current_branch" 2>/dev/null)

    if [[ -n "$pr_url" ]]; then
        echo "PR created: $pr_url"
        echo "$pr_url"
        return 0
    else
        echo "Failed to create PR"
        return 1
    fi
}

dotbak_git_backup_flow() {
    local repo_dir="$1"
    local commit_message="$2"
    local pr_title="${3:-}"

    dotbak_git_create_branch "$repo_dir" "backup/$(date +%Y%m%d-%H%M%S)"
    dotbak_git_commit_and_push "$repo_dir" "$commit_message"

    if dotbak_git_has_remote "$repo_dir" && [[ -n "$pr_title" ]]; then
        dotbak_git_create_pr "$repo_dir" "$pr_title"
    fi
}