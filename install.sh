#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DEFAULT="$HOME/config-backups"
TOOL_DEFAULT="$HOME/dotbak"

echo "=========================================="
echo "  dotbak installer"
echo "=========================================="
echo ""

echo "Step 1: Installing dotbak tool..."
echo ""

local_tool_path=""
while true; do
    echo "How would you like to install the dotbak tool?"
    echo "  1) Link to existing ~/dotbak folder"
    echo "  2) Fresh copy to ~/dotbak/ (default)"
    read -p "Choice [1/2]: " choice
    choice="${choice:-2}"

    case "$choice" in
        1)
            read -p "Enter path to existing ~/dotbak folder: " local_tool_path
            if [[ -d "$local_tool_path" ]]; then
                echo "Linked to: $local_tool_path"
                TOOL_DIR="$local_tool_path"
                break
            else
                echo "Error: Directory not found. Please try again."
            fi
            ;;
        2|*)
            echo "Copying files to: $TOOL_DEFAULT"
            mkdir -p "$TOOL_DEFAULT"
            mkdir -p "$TOOL_DEFAULT/lib"
            cp "$SCRIPT_DIR/dotbak" "$TOOL_DEFAULT/"
            cp "$SCRIPT_DIR/lib/"*.sh "$TOOL_DEFAULT/lib/"
            chmod +x "$TOOL_DEFAULT/dotbak"
            chmod +x "$TOOL_DEFAULT/lib/"*.sh
            TOOL_DIR="$TOOL_DEFAULT"
            break
            ;;
    esac
done

echo ""
echo "Step 2: Setting up PATH..."
mkdir -p "$HOME/bin"
if [[ -L "$HOME/bin/dotbak" ]]; then
    rm "$HOME/bin/dotbak"
fi
ln -sf "$TOOL_DIR/dotbak" "$HOME/bin/dotbak"
echo "Created symlink: ~/bin/dotbak"
echo "Make sure ~/bin is in your PATH (added automatically in ~/.bashrc/.zshrc)"
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo ""
echo "Step 3: Setting up backup folder..."
echo ""

backup_dir=""
while true; do
    echo "How would you like to set up your backup folder?"
    echo "  1) Clone existing backup repo"
    echo "  2) Link to existing local folder"
    echo "  3) Fresh setup (default: ~/config-backups/)"
    read -p "Choice [1/2/3]: " choice
    choice="${choice:-3}"

    case "$choice" in
        1)
            read -p "Enter backup repo URL: " repo_url
            if [[ -n "$repo_url" ]]; then
                if [[ -d "$BACKUP_DEFAULT" ]]; then
                    read -p "Folder exists. Pull updates (p) or clone fresh (f)? " -n 1
                    echo ""
                    if [[ $REPLY =~ ^[Pp]$ ]]; then
                        cd "$BACKUP_DEFAULT" && git pull
                    else
                        rm -rf "$BACKUP_DEFAULT"
                        git clone "$repo_url" "$BACKUP_DEFAULT"
                    fi
                else
                    git clone "$repo_url" "$BACKUP_DEFAULT"
                fi
                backup_dir="$BACKUP_DEFAULT"
                echo "Cloned backup repo to: $backup_dir"
                break
            else
                echo "Error: Please enter a valid repo URL."
            fi
            ;;
        2)
            read -p "Enter path to existing backup folder: " local_backup_path
            if [[ -d "$local_backup_path" ]]; then
                backup_dir="$local_backup_path"
                echo "Linked to: $backup_dir"
                break
            else
                echo "Error: Directory not found. Please try again."
            fi
            ;;
        3|*)
            mkdir -p "$BACKUP_DEFAULT"
            backup_dir="$BACKUP_DEFAULT"
            read -p "Initialize git in backup folder? (y/n) " -n 1
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cd "$backup_dir" && git init
            fi
            echo "Created: $backup_dir"
            break
            ;;
    esac
done

echo ""
echo "Step 4: Creating ~/.dotbakrc..."
if [[ -f "$HOME/.dotbakrc" ]]; then
    read -p "~/.dotbakrc already exists. Overwrite? (y/n) " -n 1
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing ~/.dotbakrc"
    else
        cat > "$HOME/.dotbakrc" << EOF
export DOTBAK_TOOL_DIR="$TOOL_DIR"
export DOTBAK_BACKUP_DIR="$backup_dir"
EOF
        echo "Created new ~/.dotbakrc"
    fi
else
    cat > "$HOME/.dotbakrc" << EOF
export DOTBAK_TOOL_DIR="$TOOL_DIR"
export DOTBAK_BACKUP_DIR="$backup_dir"
EOF
    echo "Created ~/.dotbakrc"
fi

echo ""
echo "=========================================="
echo "  Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Restart your shell, or run:"
echo "     source ~/.dotbakrc"
echo ""
echo "  2. Verify installation:"
echo "     dotbak status"
echo ""
echo "  3. Backup your first config:"
echo "     dotbak backup .bashrc"
echo ""
echo "=========================================="
echo ""

source "$HOME/.dotbakrc"