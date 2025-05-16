#!/bin/bash

# Script to run UI component tests

# Print header
echo "==============================================="
echo "Running UI Component Tests"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
TEST_DIR="$PROJECT_DIR/test/presentation/widgets"

# Source environment setup if available
if [ -f "$PROJECT_DIR/.flutter-env/setup.sh" ]; then
  source "$PROJECT_DIR/.flutter-env/setup.sh"
fi

# Function to run a test file
run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file")
  
  echo ""
  echo "Running test: $test_name"
  echo "-----------------------------------------------"
  
  flutter test "$test_file"
  test_result=$?
  
  if [ $test_result -eq 0 ]; then
    echo "✅ Test passed: $test_name"
    return 0
  else
    echo "❌ Test failed: $test_name"
    return 1
  fi
}

# Run UI component tests
echo "Running widget tests..."
failed_tests=0

# Find all UI component test files (excluding documentation tests which are handled separately)
ui_test_files=$(find "$TEST_DIR" -name "*_test.dart" | grep -v "/documentation/")

# Run each test file
for test_file in $ui_test_files; do
  run_test "$test_file"
  [ $? -ne 0 ] && ((failed_tests++))
done

# Also run renderer tests
echo ""
echo "Running renderer tests..."
renderer_test_files=$(find "$PROJECT_DIR/test/presentation/rendering" -name "*_test.dart")

for test_file in $renderer_test_files; do
  run_test "$test_file"
  [ $? -ne 0 ] && ((failed_tests++))
done

# Print summary
echo ""
echo "==============================================="
echo "UI Test Summary"
echo "==============================================="

if [ $failed_tests -eq 0 ]; then
  echo "All UI tests passed! ✅"
  exit 0
else
  echo "$failed_tests UI tests failed. ❌"
  exit 1
fi