#!/usr/bin/env bash

echo "=== Preparing Complete Codex Offline Cache with Flutter SDK ==="

# Get repo root
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$REPO_ROOT"

# Create the .codex directory
mkdir -p .codex

# Create temporary cache directory
echo "Creating temporary cache directory..."
mkdir -p .temp-cache/pub-cache
mkdir -p .temp-cache/flutter-sdk

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

# Copy FULL Flutter SDK (not just Dart)
echo "Copying complete Flutter SDK..."
FLUTTER_ROOT=$(dirname $(dirname $(which flutter)))
echo "Flutter SDK location: $FLUTTER_ROOT"

# Copy the entire Flutter SDK
cp -r "$FLUTTER_ROOT" .temp-cache/flutter-sdk

# Create compressed archives
echo "Creating compressed archives..."
cd .temp-cache

echo "Creating Flutter SDK archive (this may take a while)..."
tar -czf ../.codex/flutter-sdk.tar.gz flutter-sdk/

echo "Creating pub cache archive..."
tar -czf ../.codex/pub-cache.tar.gz pub-cache/

cd ..

# Show archive sizes
echo ""
echo "Archive sizes:"
du -sh .codex/*.tar.gz

# Create extraction markers
touch .codex/.flutter-sdk-packed
touch .codex/.pub-cache-packed

# Clean up temporary directory
echo "Cleaning up..."
rm -rf .temp-cache

# Create .gitattributes for LFS (if not exists)
if [ ! -f .gitattributes ]; then
    echo "Creating .gitattributes for Git LFS..."
    cat > .gitattributes << 'EOF'
# Git LFS tracking for large files
.codex/*.tar.gz filter=lfs diff=lfs merge=lfs -text
.codex/*.zip filter=lfs diff=lfs merge=lfs -text
EOF
fi

# Update .gitignore
echo "Updating .gitignore..."
if ! grep -q "# Codex offline cache" .gitignore; then
    cat >> .gitignore << 'EOF'

# Codex offline cache
!.codex/
!.codex/*.tar.gz
!.codex/.*-packed

# But ignore extracted directories
.codex/flutter-sdk/
.codex/pub-cache/

# Temporary cache directory
.temp-cache/

# Setup markers
.codex_setup_complete
EOF
fi

echo ""
echo "=== Cache Preparation Complete ==="
echo ""
echo "IMPORTANT: Git LFS must be installed to continue."
echo ""
echo "If Git LFS is installed, run:"
echo "  git lfs install"
echo "  git lfs track '.codex/*.tar.gz'"
echo "  git add .gitattributes"
echo "  git add -A"
echo "  git commit -m 'Add complete Flutter SDK cache for Codex'"
echo "  git lfs push origin main --all"
echo "  git push origin main"
echo ""
echo "If Git LFS is NOT installed:"
echo "  Ubuntu/Debian: sudo apt-get install git-lfs"
echo "  macOS: brew install git-lfs"
echo "  Then run: git lfs install"
echo ""
echo "The Flutter SDK and all dependencies are now packaged for offline use."