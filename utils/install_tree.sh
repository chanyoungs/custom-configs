#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <source_root> <target_root> <backup_root> [split_dirs_csv]" >&2
    exit 1
fi

SOURCE_ROOT="$1"
TARGET_ROOT="$2"
BACKUP_ROOT="$3"
SPLIT_DIRS_CSV="${4:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SYMLINK="$SCRIPT_DIR/install_symlink.sh"

is_split_dir() {
    local name="$1"
    local item
    IFS=',' read -r -a split_dirs <<< "$SPLIT_DIRS_CSV"
    for item in "${split_dirs[@]}"; do
        if [ -n "$item" ] && [ "$item" = "$name" ]; then
            return 0
        fi
    done
    return 1
}

backup_entry() {
    local target="$1"
    local backup="$2"

    if [ -e "$backup" ] || [ -L "$backup" ]; then
        return
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$(dirname "$backup")"
        echo "Creating backup: $backup"
        cp -a "$target" "$backup"
    fi
}

install_entries() {
    local source_root="$1"
    local target_root="$2"
    local backup_root="$3"
    local source
    local name
    local target
    local backup

    mkdir -p "$target_root"

    shopt -s dotglob nullglob
    for source in "$source_root"/*; do
        name="$(basename "$source")"

        if [ -d "$source" ] && is_split_dir "$name"; then
            install_entries "$source" "$target_root/$name" "$backup_root/$name"
            continue
        fi

        target="$target_root/$name"
        backup="$backup_root/$name"

        backup_entry "$target" "$backup"
        "$INSTALL_SYMLINK" "$target" "$source" "" "1"
    done
}

install_entries "$SOURCE_ROOT" "$TARGET_ROOT" "$BACKUP_ROOT"
