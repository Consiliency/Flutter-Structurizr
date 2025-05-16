#\!/bin/bash

# Script to run the export preview example

echo "Running Export Preview Example..."

# Check if the project directory exists
if [ \! -d "$(dirname "$0")" ]; then
    echo "Error: Project directory not found."
    exit 1
fi

# Navigate to the project directory
cd "$(dirname "$0")"

# Check if Flutter is installed
if \! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH."
    exit 1
fi

# Check dependencies
echo "Checking dependencies..."
flutter pub get

# Check if the app can be built
echo "Verifying app..."
if \! flutter analyze --no-fatal-infos; then
    echo "Warning: Analysis issues detected. Continuing anyway..."
fi

# Run the app
echo "Launching app..."
flutter run --release
