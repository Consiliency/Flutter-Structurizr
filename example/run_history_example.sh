#!/bin/bash

# Navigate to the history example directory
cd "$(dirname "$0")/history"

# Run flutter pub get
flutter pub get

# Run the example
flutter run "$@"