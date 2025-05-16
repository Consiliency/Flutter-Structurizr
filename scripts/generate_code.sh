#!/bin/bash

# Script to generate code using build_runner

# Print header
echo "==============================================="
echo "Generating Code Using build_runner"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

# Source environment setup if available
if [ -f "$PROJECT_DIR/.flutter-env/setup.sh" ]; then
  source "$PROJECT_DIR/.flutter-env/setup.sh"
fi

# Run build_runner
echo "Running build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs

# Check exit code
if [ $? -eq 0 ]; then
  echo "========================================="
  echo "✅ Code generation completed successfully!"
  echo "========================================="
  exit 0
else
  echo "========================================="
  echo "❌ Code generation failed!"
  echo "========================================="
  exit 1
fi