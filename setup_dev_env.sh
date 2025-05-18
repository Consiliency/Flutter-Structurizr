#!/usr/bin/env bash

set -e

echo "=== Flutter Structurizr Development Environment Setup ==="

# 1. Check for Flutter installation
if ! command -v flutter &> /dev/null; then
  echo "Flutter is not installed. Please install Flutter SDK 3.10.0+ and ensure it's in your PATH."
  exit 1
fi

# 2. Check for Dart installation (should be included with Flutter)
if ! command -v dart &> /dev/null; then
  echo "Dart is not installed. Please install Dart SDK (comes with Flutter) and ensure it's in your PATH."
  exit 1
fi

# 3. Install Flutter dependencies
echo "Running flutter pub get..."
flutter pub get

# 4. Install dependencies for demo_app, example, and test_app if present
for dir in demo_app example test_app; do
  if [ -d "$dir" ]; then
    echo "Running flutter pub get in $dir/..."
    (cd "$dir" && flutter pub get)
  fi
done

# 5. Install any additional tools (e.g., lcov for coverage reports)
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

# 6. Run code generation (build_runner)
echo "Running code generation (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs

# 7. (Optional) Run analyzer and tests to verify setup
echo "Running flutter analyze..."
flutter analyze

echo "Running flutter test (smoke test)..."
flutter test

echo "=== Setup complete! ==="
echo "You can now start developing or running the application." 