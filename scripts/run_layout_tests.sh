#!/bin/bash

# Script to run layout tests

# Print header
echo "==============================================="
echo "Running Layout Tests"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
TEST_DIR="$PROJECT_DIR/test/presentation/layout"

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

# Run individual layout tests
echo "Running individual layout tests..."
failed_tests=0

# Automatic Layout Test
run_test "$TEST_DIR/automatic_layout_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# Force Directed Layout Test
run_test "$TEST_DIR/force_directed_layout_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# Grid Layout Test
run_test "$TEST_DIR/grid_layout_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# Manual Layout Test
run_test "$TEST_DIR/manual_layout_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# Parent Child Layout Test (if exists)
if [ -f "$TEST_DIR/parent_child_layout_test.dart" ]; then
  run_test "$TEST_DIR/parent_child_layout_test.dart"
  [ $? -ne 0 ] && ((failed_tests++))
fi

# Print summary
echo ""
echo "==============================================="
echo "Layout Test Summary"
echo "==============================================="

if [ $failed_tests -eq 0 ]; then
  echo "All layout tests passed! ✅"
  exit 0
else
  echo "$failed_tests layout tests failed. ❌"
  exit 1
fi