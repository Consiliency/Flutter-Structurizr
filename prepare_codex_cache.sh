#!/usr/bin/env bash

echo "=== Preparing Codex Offline Cache with Git LFS ==="

# Ensure Git LFS is installed
if ! command -v git-lfs &> /dev/null; then
    echo "ERROR: Git LFS is not installed."
    echo "Please install Git LFS first:"
    echo "  Ubuntu/Debian: sudo apt-get install git-lfs"
    echo "  macOS: brew install git-lfs"
    echo "  Then run: git lfs install"
    exit 1
fi

# Get repo root
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$REPO_ROOT"

# Initialize Git LFS
echo "Initializing Git LFS..."
git lfs install

# Create the .codex directory
mkdir -p .codex

# Create temporary cache directory
echo "Creating temporary cache directory..."
mkdir -p .temp-cache/pub-cache
mkdir -p .temp-cache/dart-sdk

# Ensure all dependencies are cached
echo "Caching all project dependencies..."
flutter pub get

# Cache for sub-projects
for dir in demo_app example test_app; do
    if [ -d "$dir" ]; then
        echo "Caching dependencies for $dir..."
        (cd "$dir" && flutter pub get)
    fi
done

# Copy pub cache
echo "Copying pub cache..."
cp -r ~/.pub-cache/* .temp-cache/pub-cache/

# Copy Dart SDK
echo "Copying Dart SDK..."
FLUTTER_ROOT=$(dirname $(dirname $(which flutter)))
cp -r "$FLUTTER_ROOT/bin/cache/dart-sdk" .temp-cache/

# Create compressed archives
echo "Creating compressed archives..."
cd .temp-cache
tar -czf ../.codex/dart-sdk.tar.gz dart-sdk/
tar -czf ../.codex/pub-cache.tar.gz pub-cache/
cd ..

# Create extraction markers
touch .codex/.dart-sdk-packed
touch .codex/.pub-cache-packed

# Clean up temporary directory
echo "Cleaning up..."
rm -rf .temp-cache

# Set up Git LFS tracking
echo "Configuring Git LFS tracking..."
git lfs track ".codex/*.tar.gz"
git add .gitattributes

# Update .gitignore
echo "Updating .gitignore..."
cat >> .gitignore << 'EOF'

# Codex offline cache
!.codex/
!.codex/*.tar.gz
!.codex/.*-packed

# But ignore extracted directories
.codex/dart-sdk/
.codex/pub-cache/

# Temporary cache directory
.temp-cache/

# Setup markers
.codex_setup_complete
EOF

# Create documentation
echo "Creating documentation..."
cat > CODEX_SETUP.md << 'EOF'
# Codex Offline Development Setup

This repository includes Git LFS files for offline development in Codex.

## Prerequisites

1. Git LFS must be installed in Codex
2. Clone with LFS support: `git lfs clone [repo-url]`

## Setup Process

1. After cloning, run:
   ```bash
   ./codex_offline_setup.sh
   ```

2. Use the provided commands:
   - `./dart` - Run Dart commands
   - `./pub` - Manage packages offline
   - `./flutter` - Limited Flutter simulation

## Architecture

- Dependencies are in `.codex/*.tar.gz` (managed by Git LFS)
- Setup script extracts and configures on first run
- All operations are completely offline after setup

## Troubleshooting

If LFS files are missing:
```bash
git lfs pull
./codex_offline_setup.sh
```
EOF

echo ""
echo "=== Preparation Complete ==="
echo ""
echo "Next steps:"
echo "1. Review the files to be committed:"
echo "   git status"
echo "   git lfs ls-files"
echo ""
echo "2. Commit the changes:"
echo "   git add -A"
echo "   git commit -m \"Add Git LFS offline cache for Codex\""
echo ""
echo "3. Push to repository:"
echo "   git lfs push origin main --all"
echo "   git push origin main"
echo ""
echo "Archive sizes:"
du -sh .codex/*.tar.gz
echo ""
echo "The repository is now ready for offline Codex development!"