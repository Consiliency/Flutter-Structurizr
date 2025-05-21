#!/usr/bin/env bash

echo "=== Cleaning Codex Offline Cache ==="
echo "Removing unnecessary offline cache files since network access is available during setup"

# Get absolute path to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Remove offline cache directories if they exist
if [ -d ".codex" ]; then
    echo "Removing .codex directory with offline cache files..."
    rm -rf .codex
fi

# Remove any remaining extraction marker files
rm -f .codex_setup_complete

# Remove old offline setup scripts
for script in codex_offline_setup.sh codex_offline_setup_full.sh codex_offline_setup_fixed.sh codex_offline_setup_split.sh prepare_codex_cache.sh prepare_codex_cache_full.sh split_large_files.sh; do
    if [ -f "$script" ]; then
        echo "Removing old script: $script"
        rm -f "$script"
    fi
done

# Create empty .codex directory to maintain structure
mkdir -p .codex
touch .codex/.gitkeep

echo ""
echo "=== Cleanup Complete! ==="
echo ""
echo "Offline cache files have been removed."
echo "Network access will be used during the initial setup in Codex."
echo "Run ./setup_for_codex.sh during the Codex setup phase."