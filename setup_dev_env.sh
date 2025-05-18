#!/usr/bin/env bash

set -e

echo "=== Flutter Structurizr Development Environment Setup ==="

# 1. Check for Flutter installation
if ! command -v flutter &> /dev/null; then
  echo "Flutter is not installed. Let's help you install it."
  echo ""
  echo "Choose your operating system:"
  echo "1. Linux (Ubuntu/Debian)"
  echo "2. macOS"
  echo "3. Other"
  read -p "Enter your choice (1-3): " os_choice
  
  case $os_choice in
    1)
      echo "Installing Flutter on Linux..."
      echo ""
      echo "Option 1: Using snap (recommended):"
      echo "  sudo snap install flutter --classic"
      echo ""
      echo "Option 2: Manual installation:"
      echo "  1. Download Flutter SDK from: https://flutter.dev/docs/get-started/install/linux"
      echo "  2. Extract to a directory (e.g., ~/development/flutter)"
      echo "  3. Add Flutter to your PATH:"
      echo "     export PATH=\"\$PATH:~/development/flutter/bin\""
      echo "  4. Add the above line to your ~/.bashrc or ~/.zshrc"
      echo ""
      echo "After installation, run 'flutter doctor' to verify setup."
      ;;
    2)
      echo "Installing Flutter on macOS..."
      echo ""
      echo "Option 1: Using Homebrew:"
      echo "  brew install flutter"
      echo ""
      echo "Option 2: Manual installation:"
      echo "  1. Download Flutter SDK from: https://flutter.dev/docs/get-started/install/macos"
      echo "  2. Extract to a directory (e.g., ~/development/flutter)"
      echo "  3. Add Flutter to your PATH:"
      echo "     export PATH=\"\$PATH:~/development/flutter/bin\""
      echo "  4. Add the above line to your ~/.zshrc or ~/.bash_profile"
      echo ""
      echo "After installation, run 'flutter doctor' to verify setup."
      ;;
    3)
      echo "For other operating systems, please visit:"
      echo "https://flutter.dev/docs/get-started/install"
      ;;
  esac
  
  echo ""
  echo "Please install Flutter and then run this script again."
  exit 1
fi

# 2. Check Flutter version
FLUTTER_VERSION=$(flutter --version | grep -o 'Flutter [0-9]\+\.[0-9]\+\.[0-9]\+' | awk '{print $2}')
MIN_VERSION="3.10.0"

version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

if version_gt "$MIN_VERSION" "$FLUTTER_VERSION"; then
  echo "Flutter version $FLUTTER_VERSION is installed, but version $MIN_VERSION or higher is required."
  echo "Please upgrade Flutter using: flutter upgrade"
  exit 1
fi

echo "Flutter $FLUTTER_VERSION is installed ✓"

# 3. Run flutter doctor to check for issues
echo "Checking Flutter environment..."
flutter doctor

# 4. Check for Dart installation (should be included with Flutter)
if ! command -v dart &> /dev/null; then
  echo "Dart is not installed. It should come with Flutter."
  echo "Please ensure Flutter is properly installed and in your PATH."
  exit 1
fi

echo "Dart $(dart --version) is installed ✓"

# 5. Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# 6. Install dependencies for demo_app, example, and test_app if present
for dir in demo_app example test_app; do
  if [ -d "$dir" ]; then
    echo "Installing dependencies in $dir/..."
    (cd "$dir" && flutter pub get)
  fi
done

# 7. Install any additional tools (e.g., lcov for coverage reports)
if ! command -v lcov &> /dev/null; then
  echo "lcov not found. Installing lcov (for coverage reports)..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update && sudo apt-get install -y lcov
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install lcov
  else
    echo "Please install lcov manually for your OS."
  fi
fi

# 8. Run code generation (build_runner)
echo "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs

# 9. Run analyzer and tests to verify setup
echo "Running flutter analyze..."
flutter analyze

echo "Running flutter test (smoke test)..."
flutter test

echo ""
echo "=== Setup complete! ==="
echo "Your Flutter Structurizr development environment is ready."
echo "You can now start developing or running the application."
echo ""
echo "Quick start commands:"
echo "  flutter run          # Run the application"
echo "  flutter test         # Run all tests"
echo "  flutter analyze      # Analyze code"
echo "  flutter build        # Build the application"