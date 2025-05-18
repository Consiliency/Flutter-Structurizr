#!/usr/bin/env bash

echo "=== Codex Offline Flutter Environment Setup ==="
echo "Extracting and configuring offline development environment..."

# Get absolute path to repo root
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CODEX_DIR="$REPO_ROOT/.codex"

# Check if Git LFS files are present
if [ ! -f "$CODEX_DIR/dart-sdk.tar.gz" ] || [ ! -f "$CODEX_DIR/pub-cache.tar.gz" ]; then
    echo "ERROR: Git LFS files not found. Please ensure Git LFS is installed and run:"
    echo "  git lfs pull"
    exit 1
fi

# Check if extraction is needed
if [ -f "$CODEX_DIR/.dart-sdk-packed" ] && [ ! -d "$CODEX_DIR/dart-sdk" ]; then
    echo "Extracting Dart SDK..."
    cd "$CODEX_DIR"
    tar -xzf dart-sdk.tar.gz
    rm .dart-sdk-packed
    echo "Dart SDK extracted successfully"
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
if [ ! -d "$CODEX_DIR/pub-cache" ] || [ ! -d "$CODEX_DIR/dart-sdk" ]; then
    echo "ERROR: Failed to extract offline cache."
    echo "Expected directories:"
    echo "  - $CODEX_DIR/pub-cache"
    echo "  - $CODEX_DIR/dart-sdk"
    exit 1
fi

echo "Setting up environment variables..."

# Configure for offline operation
export PUB_OFFLINE=true
export FLUTTER_OFFLINE=true
export PUB_CACHE="$CODEX_DIR/pub-cache"
export DART_SDK="$CODEX_DIR/dart-sdk"
export PATH="$CODEX_DIR:$PATH"

# Create configuration file for persistent settings
cat > "$HOME/.dart_offline_config" << EOF
export PUB_OFFLINE=true
export FLUTTER_OFFLINE=true
export PUB_CACHE="$CODEX_DIR/pub-cache"
export DART_SDK="$CODEX_DIR/dart-sdk"
export PATH="$CODEX_DIR:\$PATH"
EOF

# Add to shell profile
if [ -f "$HOME/.bashrc" ]; then
    echo "source $HOME/.dart_offline_config" >> "$HOME/.bashrc"
fi
if [ -f "$HOME/.profile" ]; then
    echo "source $HOME/.dart_offline_config" >> "$HOME/.profile"
fi

# Create necessary symlinks
echo "Creating symlinks..."
mkdir -p "$HOME/.pub-cache"
ln -sfn "$CODEX_DIR/pub-cache" "$HOME/.pub-cache"

# Create wrapper executables
echo "Creating command wrappers..."

cat > "$CODEX_DIR/dart" << 'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DART_SDK="$SCRIPT_DIR/dart-sdk"
export PUB_CACHE="$SCRIPT_DIR/pub-cache"
export PUB_OFFLINE=true
exec "$DART_SDK/bin/dart" "$@"
EOF
chmod +x "$CODEX_DIR/dart"

cat > "$CODEX_DIR/pub" << 'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export DART_SDK="$SCRIPT_DIR/dart-sdk"
export PUB_CACHE="$SCRIPT_DIR/pub-cache"
export PUB_OFFLINE=true
exec "$DART_SDK/bin/pub" "$@"
EOF
chmod +x "$CODEX_DIR/pub"

echo "Resolving dependencies offline..."
cd "$REPO_ROOT"

# Use the bundled dart/pub commands
"$CODEX_DIR/dart" pub get --offline

# Resolve for sub-projects
for dir in demo_app example test_app; do
    if [ -d "$dir" ]; then
        echo "Resolving dependencies for $dir..."
        (cd "$dir" && "$CODEX_DIR/dart" pub get --offline)
    fi
done

# Run build_runner if it exists
if [ -f "pubspec.yaml" ] && grep -q "build_runner:" "pubspec.yaml"; then
    echo "Running code generation..."
    "$CODEX_DIR/dart" run build_runner build --delete-conflicting-outputs || true
fi

# Create convenience wrappers in repo root
cat > "$REPO_ROOT/dart" << 'EOF'
#!/usr/bin/env bash
exec "$(dirname "$0")/.codex/dart" "$@"
EOF
chmod +x "$REPO_ROOT/dart"

cat > "$REPO_ROOT/pub" << 'EOF'
#!/usr/bin/env bash
exec "$(dirname "$0")/.codex/pub" "$@"
EOF
chmod +x "$REPO_ROOT/pub"

# Create flutter simulator (limited functionality)
cat > "$REPO_ROOT/flutter" << 'EOF'
#!/usr/bin/env bash
REPO_ROOT="$(dirname "$0")"
COMMAND="$1"
shift

case "$COMMAND" in
    "pub")
        exec "$REPO_ROOT/.codex/pub" "$@"
        ;;
    "test")
        exec "$REPO_ROOT/.codex/dart" test "$@"
        ;;
    "analyze")
        exec "$REPO_ROOT/.codex/dart" analyze "$@"
        ;;
    "format")
        exec "$REPO_ROOT/.codex/dart" format "$@"
        ;;
    "doctor")
        echo "Flutter doctor (offline simulation)"
        echo "[✓] Dart SDK: Available (offline)"
        echo "[✓] Pub packages: Cached locally"
        echo "[✗] Flutter SDK: Not available (using Dart-only mode)"
        echo "[✗] Platform development: Not available in offline mode"
        ;;
    *)
        echo "Limited flutter command simulation in offline mode"
        echo "Supported commands: pub, test, analyze, format, doctor"
        echo "For full Flutter support, use the actual Flutter SDK"
        exit 1
        ;;
esac
EOF
chmod +x "$REPO_ROOT/flutter"

# Clean up archives after extraction (optional, to save space)
if [ -d "$CODEX_DIR/dart-sdk" ] && [ -f "$CODEX_DIR/dart-sdk.tar.gz" ]; then
    echo "Cleaning up archive files to save space..."
    rm -f "$CODEX_DIR/dart-sdk.tar.gz"
    rm -f "$CODEX_DIR/pub-cache.tar.gz"
fi

# Mark setup as complete
touch "$REPO_ROOT/.codex_setup_complete"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Available commands:"
echo "  ./dart    - Run Dart commands"
echo "  ./pub     - Run pub commands (offline)"
echo "  ./flutter - Limited Flutter command simulation"
echo ""
echo "Examples:"
echo "  ./dart test"
echo "  ./dart analyze"
echo "  ./dart run"
echo "  ./flutter test"
echo "  ./flutter pub get --offline"
echo ""
echo "All dependencies have been extracted and configured for offline use."
echo "This is a one-time setup - the environment is now configured for Codex."