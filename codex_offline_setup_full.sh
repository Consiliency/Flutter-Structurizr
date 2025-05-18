#!/usr/bin/env bash

echo "=== Codex Offline Flutter Environment Setup (Full SDK) ==="
echo "Extracting and configuring complete Flutter SDK for offline development..."

# Get absolute path to repo root
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CODEX_DIR="$REPO_ROOT/.codex"

# Check if Git LFS files are present
if [ ! -f "$CODEX_DIR/flutter-sdk.tar.gz" ] || [ ! -f "$CODEX_DIR/pub-cache.tar.gz" ]; then
    echo "ERROR: Git LFS files not found. Please ensure Git LFS is installed and run:"
    echo "  git lfs pull"
    exit 1
fi

# Check if extraction is needed
if [ -f "$CODEX_DIR/.flutter-sdk-packed" ] && [ ! -d "$CODEX_DIR/flutter-sdk" ]; then
    echo "Extracting Flutter SDK (this may take a while)..."
    cd "$CODEX_DIR"
    tar -xzf flutter-sdk.tar.gz
    rm .flutter-sdk-packed
    echo "Flutter SDK extracted successfully"
fi

if [ -f "$CODEX_DIR/.pub-cache-packed" ] && [ ! -d "$CODEX_DIR/pub-cache" ]; then
    echo "Extracting pub cache..."
    cd "$CODEX_DIR"
    tar -xzf pub-cache.tar.gz
    rm .pub-cache-packed
    echo "Pub cache extracted successfully"
fi

cd "$REPO_ROOT"

# Verify extraction completed
if [ ! -d "$CODEX_DIR/pub-cache" ] || [ ! -d "$CODEX_DIR/flutter-sdk" ]; then
    echo "ERROR: Failed to extract offline cache."
    echo "Expected directories:"
    echo "  - $CODEX_DIR/pub-cache"
    echo "  - $CODEX_DIR/flutter-sdk"
    exit 1
fi

echo "Setting up environment variables..."

# Configure for offline operation
export PUB_OFFLINE=true
export FLUTTER_OFFLINE=true
export PUB_CACHE="$CODEX_DIR/pub-cache"
export FLUTTER_ROOT="$CODEX_DIR/flutter-sdk"
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Create configuration file for persistent settings
cat > "$HOME/.flutter_offline_config" << EOF
export PUB_OFFLINE=true
export FLUTTER_OFFLINE=true
export PUB_CACHE="$CODEX_DIR/pub-cache"
export FLUTTER_ROOT="$CODEX_DIR/flutter-sdk"
export PATH="$FLUTTER_ROOT/bin:\$PATH"
EOF

# Add to shell profile
if [ -f "$HOME/.bashrc" ]; then
    echo "source $HOME/.flutter_offline_config" >> "$HOME/.bashrc"
fi
if [ -f "$HOME/.profile" ]; then
    echo "source $HOME/.flutter_offline_config" >> "$HOME/.profile"
fi

# Create necessary symlinks
echo "Creating symlinks..."
mkdir -p "$HOME/.pub-cache"
ln -sfn "$CODEX_DIR/pub-cache" "$HOME/.pub-cache"

# Set up Flutter for offline use
echo "Configuring Flutter for offline use..."
cd "$REPO_ROOT"

# Mark Flutter as configured
touch "$FLUTTER_ROOT/bin/cache/.dartignore"

# Use the full Flutter SDK
flutter config --no-analytics
flutter config --offline

echo "Resolving dependencies offline..."
flutter pub get --offline

# Resolve for sub-projects
for dir in demo_app example test_app; do
    if [ -d "$dir" ]; then
        echo "Resolving dependencies for $dir..."
        (cd "$dir" && flutter pub get --offline)
    fi
done

# Run build_runner if it exists
if [ -f "pubspec.yaml" ] && grep -q "build_runner:" "pubspec.yaml"; then
    echo "Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs || true
fi

# Create convenience wrapper for flutter command
cat > "$REPO_ROOT/flutter" << 'EOF'
#!/usr/bin/env bash
REPO_ROOT="$(dirname "$0")"
export PUB_OFFLINE=true
export FLUTTER_OFFLINE=true
export PUB_CACHE="$REPO_ROOT/.codex/pub-cache"
export FLUTTER_ROOT="$REPO_ROOT/.codex/flutter-sdk"
exec "$FLUTTER_ROOT/bin/flutter" "$@"
EOF
chmod +x "$REPO_ROOT/flutter"

# Create dart wrapper
cat > "$REPO_ROOT/dart" << 'EOF'
#!/usr/bin/env bash
REPO_ROOT="$(dirname "$0")"
export PUB_OFFLINE=true
export PUB_CACHE="$REPO_ROOT/.codex/pub-cache"
export FLUTTER_ROOT="$REPO_ROOT/.codex/flutter-sdk"
exec "$FLUTTER_ROOT/bin/dart" "$@"
EOF
chmod +x "$REPO_ROOT/dart"

# Test Flutter installation
echo "Testing Flutter installation..."
"$REPO_ROOT/flutter" doctor -v

# Clean up archives after extraction (optional, to save space)
if [ -d "$CODEX_DIR/flutter-sdk" ] && [ -f "$CODEX_DIR/flutter-sdk.tar.gz" ]; then
    echo "Cleaning up archive files to save space..."
    rm -f "$CODEX_DIR/flutter-sdk.tar.gz"
    rm -f "$CODEX_DIR/pub-cache.tar.gz"
fi

# Mark setup as complete
touch "$REPO_ROOT/.codex_setup_complete"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Full Flutter SDK is now available offline!"
echo ""
echo "Available commands:"
echo "  ./flutter  - Full Flutter SDK (offline)"
echo "  ./dart     - Dart SDK (offline)"
echo ""
echo "Examples:"
echo "  ./flutter run -d linux"
echo "  ./flutter test"
echo "  ./flutter build linux"
echo "  ./dart analyze"
echo ""
echo "All Flutter features are available in offline mode."