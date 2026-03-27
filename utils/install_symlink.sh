#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <target> <source> [parent_dir_to_create] [skip_backup]" >&2
    exit 1
fi

TARGET="$1"
SOURCE="$2"
PARENT_DIR="${3:-}"
SKIP_BACKUP="${4:-0}"
BACKUP_TARGET=""

backup_path() {
    local path="$1"
    local backup="$path.backup"
    if [ -e "$backup" ] || [ -L "$backup" ]; then
        backup="$path.backup.$(date +%s)"
    fi
    printf '%s\n' "$backup"
}

if [ -n "$PARENT_DIR" ]; then
    mkdir -p "$PARENT_DIR"
fi

if [ -L "$TARGET" ]; then
    CURRENT_TARGET="$(readlink "$TARGET")"
    if [ "$CURRENT_TARGET" = "$SOURCE" ]; then
        echo "Symlink already exists at $TARGET"
        exit 0
    fi

    if [ "$SKIP_BACKUP" = "1" ]; then
        echo "Removing existing symlink $TARGET after external backup"
        rm -f "$TARGET"
    else
        BACKUP_TARGET="$(backup_path "$TARGET")"
        echo "Backing up existing symlink $TARGET to $BACKUP_TARGET"
        cp -a "$TARGET" "$BACKUP_TARGET"
        rm -f "$TARGET"
    fi
elif [ -e "$TARGET" ]; then
    if [ "$SKIP_BACKUP" = "1" ]; then
        echo "Removing existing $TARGET after external backup"
        rm -rf "$TARGET"
    else
        BACKUP_TARGET="$(backup_path "$TARGET")"
        echo "Backing up existing $TARGET to $BACKUP_TARGET"
        mv "$TARGET" "$BACKUP_TARGET"
    fi
fi

ln -s "$SOURCE" "$TARGET"
echo "Symlink created: $TARGET -> $SOURCE"

if [ -n "$BACKUP_TARGET" ] && [ -d "$BACKUP_TARGET" ] && [ -d "$SOURCE" ]; then
    echo "Migrating contents from $BACKUP_TARGET into $SOURCE"
    rsync -a "$BACKUP_TARGET"/ "$SOURCE"/
elif [ -n "$BACKUP_TARGET" ] && [ -f "$BACKUP_TARGET" ] && [ -f "$SOURCE" ]; then
    echo "Migrating contents from $BACKUP_TARGET into $SOURCE"
    cp -a "$BACKUP_TARGET" "$SOURCE"
fi
