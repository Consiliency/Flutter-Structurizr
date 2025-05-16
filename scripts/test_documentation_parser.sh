#!/bin/bash

# Documentation Parser Testing Script
# This script runs tests specifically focused on the documentation parsing functionality

# Print header
echo "==============================================="
echo "Running Documentation Parser Tests"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
cd "$PROJECT_DIR"

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

failed_tests=0

# Documentation Parser Tests
# These tests specifically focus on the parsing and mapping of documentation from DSL

# 1. Domain model tests
echo "Running documentation domain model tests..."
run_test "$PROJECT_DIR/test/domain/documentation/documentation_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# 2. Lexer tests (token recognition)
echo "Running documentation lexer tests..."
run_test "$PROJECT_DIR/test/domain/parser/documentation_lexer_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# 3. Parser tests (AST node creation)
echo "Running documentation parser tests..."
run_test "$PROJECT_DIR/test/domain/parser/documentation_parser_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# 4. Mapper tests (AST to domain model)
echo "Running documentation mapper tests..."
if [ -f "$PROJECT_DIR/test/application/dsl/documentation_mapper_test.dart" ]; then
  run_test "$PROJECT_DIR/test/application/dsl/documentation_mapper_test.dart"
  [ $? -ne 0 ] && ((failed_tests++))
else
  echo "❌ Documentation mapper test not found"
  ((failed_tests++))
fi

# 5. Integration tests
echo "Running documentation integration tests..."
run_test "$PROJECT_DIR/test/integration/documentation_integration_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# Print summary
echo ""
echo "==============================================="
echo "Documentation Parser Test Summary"
echo "==============================================="

if [ $failed_tests -eq 0 ]; then
  echo "All documentation parser tests passed! ✅"
  exit 0
else
  echo "$failed_tests documentation parser tests failed. ❌"
  exit 1
fi