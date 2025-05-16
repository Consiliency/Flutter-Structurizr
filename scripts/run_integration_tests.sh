#!/bin/bash

# Script to run integration tests

# Print header
echo "==============================================="
echo "Running Integration Tests"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
TEST_DIR="$PROJECT_DIR/test/integration"

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
  
  flutter test --timeout=120s "$test_file"
  test_result=$?
  
  if [ $test_result -eq 0 ]; then
    echo "✅ Test passed: $test_name"
    return 0
  else
    echo "❌ Test failed: $test_name"
    return 1
  fi
}

# Run integration tests
echo "Running integration tests..."
failed_tests=0

# Check if integration test directory exists
if [ ! -d "$TEST_DIR" ]; then
  echo "No integration tests directory found at $TEST_DIR"
  exit 0
fi

# Find all integration test files
integration_test_files=$(find "$TEST_DIR" -name "*_test.dart")

# Run each test file
for test_file in $integration_test_files; do
  run_test "$test_file"
  [ $? -ne 0 ] && ((failed_tests++))
done

# Print summary
echo ""
echo "==============================================="
echo "Integration Test Summary"
echo "==============================================="

if [ $failed_tests -eq 0 ]; then
  echo "All integration tests passed! ✅"
  exit 0
else
  echo "$failed_tests integration tests failed. ❌"
  exit 1
fi