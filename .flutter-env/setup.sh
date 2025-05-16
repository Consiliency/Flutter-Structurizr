#!/bin/bash

# Setup script for Flutter/Dart environment in dart-structurizr project
# This script should be sourced, not executed directly

# Get the project root directory
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Add Flutter and Dart to PATH
export PATH="$PROJECT_ROOT/flutter/bin:$PATH"

# Set up environment variables
export FLUTTER_ROOT="$PROJECT_ROOT/flutter"

# Verify Flutter and Dart availability
echo "Verifying Flutter and Dart installation..."
if command -v flutter &> /dev/null; then
    flutter --version
else
    echo "ERROR: Flutter command not found."
    echo "Please make sure the Flutter SDK is properly installed at $PROJECT_ROOT/flutter"
fi

if command -v dart &> /dev/null; then
    dart --version
else
    echo "ERROR: Dart command not found."
    echo "Please make sure the Dart SDK is properly installed with Flutter at $PROJECT_ROOT/flutter/bin/cache/dart-sdk"
fi

# Define helper functions
flutter_test() {
    pushd "$PROJECT_ROOT" > /dev/null
    flutter test "$@"
    popd > /dev/null
}

dart_test() {
    pushd "$PROJECT_ROOT" > /dev/null
    dart test "$@"
    popd > /dev/null
}

flutter_run() {
    pushd "$PROJECT_ROOT" > /dev/null
    flutter run "$@"
    popd > /dev/null
}

flutter_build() {
    pushd "$PROJECT_ROOT" > /dev/null
    flutter build "$@"
    popd > /dev/null
}

flutter_clean() {
    pushd "$PROJECT_ROOT" > /dev/null
    flutter clean
    popd > /dev/null
}

flutter_pub_get() {
    pushd "$PROJECT_ROOT" > /dev/null
    flutter pub get
    popd > /dev/null
}

flutter_pub_run() {
    pushd "$PROJECT_ROOT" > /dev/null
    flutter pub run "$@"
    popd > /dev/null
}

# Usage instructions
echo ""
echo "Flutter/Dart environment setup complete"
echo "Available commands:"
echo "  flutter_test [args]     - Run Flutter tests"
echo "  dart_test [args]        - Run Dart tests"
echo "  flutter_run [args]      - Run the Flutter application"
echo "  flutter_build [args]    - Build the Flutter application"
echo "  flutter_clean           - Clean the Flutter project"
echo "  flutter_pub_get         - Get Flutter dependencies"
echo "  flutter_pub_run [args]  - Run a script using Flutter's pub"
echo ""
echo "To set up a persistent alias in your shell, add this line to your ~/.bashrc:"
echo "  alias fsetup='source ${PROJECT_ROOT}/.flutter-env/setup.sh'"