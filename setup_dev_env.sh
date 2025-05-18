#!/usr/bin/env bash

set -e

echo "=== Flutter Structurizr Development Environment Setup ==="

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

# 1. Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing Flutter..."
    
    if [[ "$OS" == "linux" ]]; then
        if command -v snap &> /dev/null; then
            echo "Installing Flutter via snap..."
            sudo snap install flutter --classic
        else
            echo "Installing Flutter manually..."
            # Download and install Flutter
            FLUTTER_VERSION="3.19.0"  # Latest stable as of now
            curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz
            mkdir -p "$HOME/development"
            tar xf flutter.tar.xz -C "$HOME/development"
            rm flutter.tar.xz
            
            # Add to PATH
            export PATH="$PATH:$HOME/development/flutter/bin"
            
            # Add to shell profile
            if [[ -f "$HOME/.bashrc" ]]; then
                echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> "$HOME/.bashrc"
            fi
            if [[ -f "$HOME/.zshrc" ]]; then
                echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> "$HOME/.zshrc"
            fi
            
            echo "Flutter installed to $HOME/development/flutter"
            echo "Please restart your terminal or run: source ~/.bashrc"
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            echo "Installing Flutter via Homebrew..."
            brew install flutter
        else
            echo "Installing Flutter manually..."
            # Download and install Flutter
            FLUTTER_VERSION="3.19.0"  # Latest stable as of now
            curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip" -o flutter.zip
            mkdir -p "$HOME/development"
            unzip flutter.zip -d "$HOME/development"
            rm flutter.zip
            
            # Add to PATH
            export PATH="$PATH:$HOME/development/flutter/bin"
            
            # Add to shell profile
            if [[ -f "$HOME/.zshrc" ]]; then
                echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> "$HOME/.zshrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> "$HOME/.bash_profile"
            fi
            
            echo "Flutter installed to $HOME/development/flutter"
            echo "Please restart your terminal or run: source ~/.zshrc"
        fi
    else
        echo "Unable to automatically install Flutter on this OS."
        echo "Please visit: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
fi

# Update PATH for current session if Flutter was just installed
if [[ -d "$HOME/development/flutter/bin" ]] && [[ ":$PATH:" != *":$HOME/development/flutter/bin:"* ]]; then
    export PATH="$PATH:$HOME/development/flutter/bin"
fi

# 2. Verify Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "Flutter installation failed. Please install manually."
    exit 1
fi

echo "Flutter is installed ✓"

# 3. Accept Android licenses and install dependencies
echo "Running flutter doctor to check environment..."
flutter doctor

# Auto-accept Android licenses if needed
if flutter doctor | grep -q "Android license status unknown"; then
    echo "Accepting Android licenses..."
    flutter doctor --android-licenses || true
fi

# 4. Install system dependencies based on OS
echo "Installing system dependencies..."

if [[ "$OS" == "linux" && "$DISTRO" == "debian" ]]; then
    echo "Installing Linux dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        clang \
        cmake \
        git \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        libblkid-dev \
        liblzma-dev \
        lcov
elif [[ "$OS" == "linux" && "$DISTRO" == "fedora" ]]; then
    echo "Installing Linux dependencies..."
    sudo dnf install -y \
        clang \
        cmake \
        git \
        ninja-build \
        gtk3-devel \
        lcov
elif [[ "$OS" == "macos" ]]; then
    echo "Installing macOS dependencies..."
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install lcov cmake ninja
fi

# 5. Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# 6. Install dependencies for sub-projects
for dir in demo_app example test_app; do
    if [ -d "$dir" ]; then
        echo "Installing dependencies in $dir/..."
        (cd "$dir" && flutter pub get)
    fi
done

# 7. Run code generation
echo "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs || true

# 8. Final verification
echo "Running flutter analyze..."
flutter analyze || true

echo "Running flutter test (smoke test)..."
flutter test || true

echo ""
echo "=== Setup complete! ==="
echo "Your Flutter Structurizr development environment is ready."
echo ""
echo "Quick start commands:"
echo "  flutter run          # Run the application"
echo "  flutter test         # Run all tests"
echo "  flutter analyze      # Analyze code"
echo "  flutter build        # Build the application"
echo ""
echo "If you just installed Flutter, you may need to restart your terminal."