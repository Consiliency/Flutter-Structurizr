#!/usr/bin/env bash

echo "=== Flutter Structurizr Codex Environment Setup ==="
echo "This script sets up the development environment for Codex with network access"

# Get absolute path to repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    # Check if it's Ubuntu/Debian
    if command -v apt-get &> /dev/null; then
        DISTRO="debian"
    elif command -v dnf &> /dev/null; then
        DISTRO="fedora"
    else
        DISTRO="other"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="unknown"
fi

echo "Detected OS: $OS"

# Function to compare version numbers
version_compare() {
    printf '%s\n' "$1" "$2" | sort -V | head -n1
}

# Required Flutter and Dart versions
MIN_FLUTTER_VERSION="3.19.0"
MIN_DART_VERSION="3.4.0"

# 1. Install required system dependencies
echo "Installing system dependencies..."

if [[ "$OS" == "linux" && "$DISTRO" == "debian" ]]; then
    echo "Installing Linux (Debian/Ubuntu) dependencies..."
    sudo apt-get update
    sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev
elif [[ "$OS" == "linux" && "$DISTRO" == "fedora" ]]; then
    echo "Installing Linux (Fedora) dependencies..."
    sudo dnf install -y clang cmake git ninja-build gtk3-devel
elif [[ "$OS" == "macos" ]]; then
    echo "Installing macOS dependencies..."
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install cmake ninja
else
    echo "WARNING: Unsupported OS. You may need to install dependencies manually."
fi

# 2. Install Flutter and Dart SDK
if command -v flutter &> /dev/null; then
    echo "Flutter found, checking version..."
    
    # Get current Flutter version
    FLUTTER_VERSION=$(flutter --version | grep -o 'Flutter [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}' || echo "0.0.0")
    DART_VERSION=$(dart --version | grep -o 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}' || echo "0.0.0")
    
    echo "Current Flutter version: $FLUTTER_VERSION"
    echo "Current Dart SDK version: $DART_VERSION"
    
    # Check if Flutter/Dart version is sufficient
    if [[ "$(version_compare "$DART_VERSION" "$MIN_DART_VERSION")" == "$DART_VERSION" ]] && [[ "$DART_VERSION" != "$MIN_DART_VERSION" ]]; then
        echo "ERROR: Dart SDK version $DART_VERSION is too old. Need $MIN_DART_VERSION or newer."
        echo "Installing Flutter version $MIN_FLUTTER_VERSION..."
        FLUTTER_NEEDS_UPDATE=true
    else
        echo "Flutter/Dart version is compatible ✓"
        FLUTTER_NEEDS_UPDATE=false
    fi
else
    echo "Flutter not found. Installing version $MIN_FLUTTER_VERSION..."
    FLUTTER_NEEDS_UPDATE=true
fi

# Install Flutter if needed
if [ "$FLUTTER_NEEDS_UPDATE" = true ]; then
    if [[ "$OS" == "linux" ]]; then
        echo "Installing Flutter for Linux..."
        FLUTTER_DIR="${HOME}/development/flutter"
        
        # Backup existing Flutter if it exists
        if [ -d "$FLUTTER_DIR" ]; then
            echo "Backing up existing Flutter installation..."
            mv "$FLUTTER_DIR" "${FLUTTER_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        mkdir -p "$(dirname "$FLUTTER_DIR")"
        
        echo "Downloading Flutter SDK..."
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
        
        # Add to PATH
        export PATH="$PATH:${FLUTTER_DIR}/bin"
        
        # Add to shell profile
        if [[ -f "$HOME/.bashrc" ]]; then
            echo "Adding Flutter to PATH in .bashrc..."
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.bashrc"
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            echo "Adding Flutter to PATH in .zshrc..."
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.zshrc"
        fi
        
    elif [[ "$OS" == "macos" ]]; then
        echo "Installing Flutter for macOS..."
        FLUTTER_DIR="${HOME}/development/flutter"
        
        # Backup existing Flutter if it exists
        if [ -d "$FLUTTER_DIR" ]; then
            echo "Backing up existing Flutter installation..."
            mv "$FLUTTER_DIR" "${FLUTTER_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        mkdir -p "$(dirname "$FLUTTER_DIR")"
        
        echo "Downloading Flutter SDK..."
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
        
        # Add to PATH
        export PATH="$PATH:${FLUTTER_DIR}/bin"
        
        # Add to shell profile
        if [[ -f "$HOME/.zshrc" ]]; then
            echo "Adding Flutter to PATH in .zshrc..."
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.zshrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            echo "Adding Flutter to PATH in .bash_profile..."
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.bash_profile"
        fi
    else
        echo "ERROR: Unsupported OS for automatic Flutter installation."
        echo "Please install Flutter manually following the instructions at:"
        echo "https://docs.flutter.dev/get-started/install"
        exit 1
    fi
fi

# Update PATH for current session
if [[ -d "${HOME}/development/flutter/bin" ]] && [[ ":$PATH:" != *":${HOME}/development/flutter/bin:"* ]]; then
    export PATH="$PATH:${HOME}/development/flutter/bin"
fi

# 3. Verify Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter installation failed or not in PATH."
    echo "Please install manually following the instructions at:"
    echo "https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "Flutter is installed ✓"

# Verify Dart SDK version
DART_VERSION=$(dart --version | grep -o 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}' || echo "0.0.0")
echo "Dart SDK version: $DART_VERSION"

# 4. Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get || { echo "ERROR: flutter pub get failed at repo root"; exit 1; }

# 5. Install dependencies for all sub-projects
echo "Scanning for additional pubspec.yaml files..."
while IFS= read -r pubspec; do
    dir="$(dirname "$pubspec")"
    if [[ "$dir" != "$REPO_ROOT" ]]; then
        echo "Installing dependencies in $dir/..."
        (cd "$dir" && flutter pub get) || { echo "ERROR: flutter pub get failed in $dir"; exit 1; }
    fi
done < <(find "$REPO_ROOT" \( -path '*/build' -o -path '*/.dart_tool' \) -prune -o -name pubspec.yaml -print)

# 6. Run code generation
echo "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs || echo "Warning: Code generation had issues"

# 7. Run Flutter doctor for verification
echo "Running flutter doctor to check environment..."
flutter doctor -v

# 8. Run Flutter analyze (for initial verification)
echo "Running flutter analyze..."
flutter analyze || echo "Warning: Some analysis issues found"

# 9. Pre-cache Flutter artifacts for offline use
echo "Pre-caching Flutter artifacts..."
flutter precache --linux --macos --windows

# 10. Create a simple wrapper for Flutter and Dart
# These wrappers will help ensure consistent command usage after setup
cat > "$REPO_ROOT/flutter" << 'EOF'
#!/usr/bin/env bash
REPO_ROOT="$(dirname "$0")"
exec flutter "$@"
EOF
chmod +x "$REPO_ROOT/flutter"

cat > "$REPO_ROOT/dart" << 'EOF'
#!/usr/bin/env bash
REPO_ROOT="$(dirname "$0")"
exec dart "$@"
EOF
chmod +x "$REPO_ROOT/dart"

# Mark setup as complete
touch "$REPO_ROOT/.codex_setup_complete"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Your Flutter Structurizr development environment for Codex is ready."
echo ""
echo "Current versions:"
echo "  Flutter: $(flutter --version | grep -o 'Flutter [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}')"
echo "  Dart SDK: $(dart --version | grep -o 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}')"
echo ""
echo "You can now use the following commands within Codex:"
echo "  ./flutter run          # Run the application"
echo "  ./flutter test         # Run all tests"
echo "  ./flutter analyze      # Analyze code"
echo ""
echo "Note: After this initial setup, Codex will NOT have network access during development."
echo "All dependencies have been pre-installed during this setup phase."