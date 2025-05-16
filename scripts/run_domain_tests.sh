#!/bin/bash

# Script to run domain model tests

# Print header
echo "==============================================="
echo "Running Domain Model Tests"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

# Source environment setup if available
if [ -f "$PROJECT_DIR/.flutter-env/setup.sh" ]; then
  source "$PROJECT_DIR/.flutter-env/setup.sh"
fi

# Run domain tests
echo "Running model tests..."
flutter test test/domain/model/

echo "Running documentation domain tests..."
flutter test test/domain/documentation/

echo "Running style tests..."
flutter test test/domain/style/

echo "Running view tests..."
flutter test test/domain/view/

echo "Running parser tests..."
flutter test test/domain/parser/

# Check exit code
if [ $? -eq 0 ]; then
  echo "======================================="
  echo "✅ All domain tests passed!"
  echo "======================================="
  exit 0
else
  echo "======================================="
  echo "❌ Some domain tests failed!"
  echo "======================================="
  exit 1
fi