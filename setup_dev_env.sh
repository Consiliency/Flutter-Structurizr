#!/usr/bin/env bash

set -e

echo "=== Flutter Structurizr Development Environment Setup ==="

# Detect if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Warning: Running as root. Flutter should be installed as a regular user."
    echo "Consider running this script as a non-root user for better security."
    echo ""
fi

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

# Fix Flutter git safe directory if running as root
fix_flutter_git_safe_directory() {
    if [ "$EUID" -eq 0 ] && [ -d "$1" ]; then
        echo "Fixing Flutter git repository permissions..."
        git config --global --add safe.directory "$1" || true
    fi
}

# 1. Check Flutter version requirement first
MIN_FLUTTER_VERSION="3.19.0"
MIN_DART_VERSION="3.4.0"

# Function to compare version numbers
version_compare() {
    printf '%s\n' "$1" "$2" | sort -V | head -n1
}

# Check if Flutter exists and version is compatible
if command -v flutter &> /dev/null; then
    echo "Flutter found, checking version compatibility..."
    
    # Get current Flutter version
    FLUTTER_VERSION=$(flutter --version | grep -o 'Flutter [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}' || echo "0.0.0")
    DART_VERSION=$(dart --version | grep -o 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}' || echo "0.0.0")
    
    echo "Current Flutter version: $FLUTTER_VERSION"
    echo "Current Dart SDK version: $DART_VERSION"
    echo "Required minimum Dart version: $MIN_DART_VERSION"
    
    # Check if Dart version is sufficient
    if [[ "$(version_compare "$DART_VERSION" "$MIN_DART_VERSION")" == "$DART_VERSION" ]] && [[ "$DART_VERSION" != "$MIN_DART_VERSION" ]]; then
        echo "ERROR: Dart SDK version $DART_VERSION is too old. Need $MIN_DART_VERSION or newer."
        echo "Flutter version $MIN_FLUTTER_VERSION or newer includes the required Dart SDK."
        FLUTTER_NEEDS_UPDATE=true
    else
        echo "Dart SDK version is compatible ✓"
        FLUTTER_NEEDS_UPDATE=false
    fi
else
    echo "Flutter not found. Will install version $MIN_FLUTTER_VERSION"
    FLUTTER_NEEDS_UPDATE=true
fi

# 2. Install or update Flutter if needed
if [ "$FLUTTER_NEEDS_UPDATE" = true ]; then
    echo "Installing/updating Flutter to version $MIN_FLUTTER_VERSION..."
    
    if [[ "$OS" == "linux" ]]; then
        # Use manual installation for specific version
        echo "Installing Flutter $MIN_FLUTTER_VERSION manually..."
        
        FLUTTER_DIR="${HOME}/development/flutter"
        if [ "$EUID" -eq 0 ]; then
            FLUTTER_DIR="/opt/flutter"
        fi
        
        # Backup existing Flutter if it exists
        if [ -d "$FLUTTER_DIR" ]; then
            echo "Backing up existing Flutter installation..."
            mv "$FLUTTER_DIR" "${FLUTTER_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        mkdir -p "$(dirname "$FLUTTER_DIR")"
        
        # Download specific version
        echo "Downloading Flutter $MIN_FLUTTER_VERSION..."
        curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${MIN_FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz
        
        echo "Extracting Flutter..."
        tar xf flutter.tar.xz -C "$(dirname "$FLUTTER_DIR")"
        rm flutter.tar.xz
        
        # Add to PATH
        export PATH="$PATH:${FLUTTER_DIR}/bin"
        
        # Add to shell profile
        if [[ -f "$HOME/.bashrc" ]]; then
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.bashrc"
        fi
        if [[ -f "$HOME/.zshrc" ]]; then
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.zshrc"
        fi
        
        # Fix git safe directory if needed
        fix_flutter_git_safe_directory "$FLUTTER_DIR"
        
        echo "Flutter $MIN_FLUTTER_VERSION installed to $FLUTTER_DIR"
        echo "Please restart your terminal or run: source ~/.bashrc"
        
    elif [[ "$OS" == "macos" ]]; then
        # Similar for macOS
        echo "Installing Flutter $MIN_FLUTTER_VERSION manually..."
        
        FLUTTER_DIR="${HOME}/development/flutter"
        
        # Backup existing Flutter if it exists
        if [ -d "$FLUTTER_DIR" ]; then
            echo "Backing up existing Flutter installation..."
            mv "$FLUTTER_DIR" "${FLUTTER_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        mkdir -p "$(dirname "$FLUTTER_DIR")"
        
        # Download specific version
        echo "Downloading Flutter $MIN_FLUTTER_VERSION..."
        curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${MIN_FLUTTER_VERSION}-stable.zip" -o flutter.zip
        
        echo "Extracting Flutter..."
        unzip flutter.zip -d "$(dirname "$FLUTTER_DIR")"
        rm flutter.zip
        
        # Add to PATH
        export PATH="$PATH:${FLUTTER_DIR}/bin"
        
        # Add to shell profile
        if [[ -f "$HOME/.zshrc" ]]; then
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.zshrc"
        elif [[ -f "$HOME/.bash_profile" ]]; then
            echo "export PATH=\"\$PATH:${FLUTTER_DIR}/bin\"" >> "$HOME/.bash_profile"
        fi
        
        echo "Flutter $MIN_FLUTTER_VERSION installed to $FLUTTER_DIR"
        echo "Please restart your terminal or run: source ~/.zshrc"
    fi
fi

# Update PATH for current session
if [[ -d "${HOME}/development/flutter/bin" ]] && [[ ":$PATH:" != *":${HOME}/development/flutter/bin:"* ]]; then
    export PATH="$PATH:${HOME}/development/flutter/bin"
fi
if [[ -d "/opt/flutter/bin" ]] && [[ ":$PATH:" != *":/opt/flutter/bin:"* ]]; then
    export PATH="$PATH:/opt/flutter/bin"
fi

# 3. Verify Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "Flutter installation failed. Please install manually."
    echo "Visit: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "Flutter is installed ✓"

# Verify Dart SDK version again
DART_VERSION=$(dart --version | grep -o 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}' || echo "0.0.0")
echo "Dart SDK version: $DART_VERSION"

if [[ "$(version_compare "$DART_VERSION" "$MIN_DART_VERSION")" == "$DART_VERSION" ]] && [[ "$DART_VERSION" != "$MIN_DART_VERSION" ]]; then
    echo "ERROR: Dart SDK is still too old. Please restart your terminal and run this script again."
    exit 1
fi

# Fix git safe directory for existing Flutter installations
if command -v flutter &> /dev/null; then
    FLUTTER_DIR=$(dirname $(dirname $(which flutter)))
    fix_flutter_git_safe_directory "$FLUTTER_DIR"
fi

# 4. Accept Android licenses and install dependencies
echo "Running flutter doctor to check environment..."
flutter doctor

# Auto-accept Android licenses if needed
if flutter doctor | grep -q "Android license status unknown"; then
    echo "Accepting Android licenses..."
    flutter doctor --android-licenses || true
fi

# 5. Install system dependencies based on OS (with better error handling)
echo "Checking system dependencies..."

if [[ "$OS" == "linux" && "$DISTRO" == "debian" ]]; then
    echo "Checking for required Linux packages..."
    
    # First, check network connectivity
    if ! ping -c 1 google.com &> /dev/null && ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo "WARNING: No internet connectivity detected."
        echo "System packages cannot be installed automatically."
        echo ""
        echo "Required packages for Flutter development:"
        echo "  - clang"
        echo "  - cmake"
        echo "  - git"
        echo "  - ninja-build"
        echo "  - pkg-config"
        echo "  - libgtk-3-dev"
        echo "  - libblkid-dev"
        echo "  - liblzma-dev"
        echo "  - lcov (for coverage reports)"
        echo ""
        echo "Please install these manually when network is available."
        echo "Command: sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev lcov"
    else
        echo "Network connectivity detected. Attempting to install packages..."
        
        # Update package lists with timeout
        if ! timeout 30 sudo apt-get update; then
            echo "WARNING: Package list update failed. Trying with existing lists..."
        fi
        
        # Install packages
        PACKAGES="clang cmake git ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev"
        
        for package in $PACKAGES; do
            if ! dpkg -l | grep -q "^ii  $package"; then
                echo "Installing $package..."
                sudo apt-get install -y "$package" || echo "WARNING: Failed to install $package"
            else
                echo "$package is already installed ✓"
            fi
        done
        
        # Install lcov separately as it's optional
        if ! command -v lcov &> /dev/null; then
            echo "Installing lcov for coverage reports..."
            sudo apt-get install -y lcov || echo "WARNING: Failed to install lcov (optional)"
        fi
    fi
    
elif [[ "$OS" == "linux" && "$DISTRO" == "fedora" ]]; then
    echo "Installing Linux dependencies..."
    sudo dnf install -y \
        clang \
        cmake \
        git \
        ninja-build \
        gtk3-devel \
        lcov || echo "Some packages failed to install. Continuing..."
        
elif [[ "$OS" == "macos" ]]; then
    echo "Installing macOS dependencies..."
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install lcov cmake ninja || echo "Some packages failed to install. Continuing..."
fi

# 6. Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get || {
    echo "ERROR: Failed to install Flutter dependencies."
    echo "This usually means there's a version mismatch."
    echo "Current Dart SDK: $(dart --version)"
    echo "Please ensure you have Flutter $MIN_FLUTTER_VERSION or newer."
    exit 1
}

# 7. Install dependencies for sub-projects
for dir in demo_app example test_app; do
    if [ -d "$dir" ]; then
        echo "Installing dependencies in $dir/..."
        (cd "$dir" && flutter pub get) || echo "Warning: Failed to install dependencies in $dir"
    fi
done

# 8. Run code generation
echo "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs || echo "Warning: Code generation had issues"

# 9. Final verification
echo "Running flutter analyze..."
flutter analyze || echo "Warning: Some analysis issues found"

echo "Running flutter test (smoke test)..."
flutter test || echo "Warning: Some tests failed"

echo ""
echo "=== Setup complete! ==="
echo "Your Flutter Structurizr development environment is ready."
echo ""
echo "Current versions:"
echo "  Flutter: $(flutter --version | grep -o 'Flutter [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}')"
echo "  Dart SDK: $(dart --version | grep -o 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}')"
echo ""
echo "Quick start commands:"
echo "  flutter run          # Run the application"
echo "  flutter test         # Run all tests"
echo "  flutter analyze      # Analyze code"
echo "  flutter build        # Build the application"
echo ""
echo "If you still see version errors, please restart your terminal and run this script again."
echo ""

# 10. Check for common issues
if [ "$FLUTTER_NEEDS_UPDATE" = true ]; then
    echo "IMPORTANT: Flutter was updated. Please restart your terminal for PATH changes to take effect."
fi

echo "Setup process complete!"