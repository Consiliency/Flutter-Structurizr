#!/bin/bash
echo "Setting up dart-structurizr development environment..."

# Ensure Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate code
echo "Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "Setup complete!"
echo "Note: Default branch is now 'main' (not 'master')"
echo ""
echo "To run the demo app:"
echo "  cd demo_app"
echo "  flutter pub get"
echo "  flutter run -d [device]"
echo ""
echo "For more examples, see the example/ directory"