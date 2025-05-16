#!/bin/bash

# Script to run documentation component tests

# Print header
echo "==============================================="
echo "Running Documentation Tests"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

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

# Domain documentation model tests
echo "Running documentation model tests..."
run_test "$PROJECT_DIR/test/domain/documentation/documentation_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# UI documentation component tests
echo "Running MarkdownRenderer tests..."
run_test "$PROJECT_DIR/test/presentation/widgets/documentation/markdown_renderer_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

echo "Running DocumentationNavigator tests..."
run_test "$PROJECT_DIR/test/presentation/widgets/documentation/documentation_navigator_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

echo "Running TableOfContents tests..."
run_test "$PROJECT_DIR/test/presentation/widgets/documentation/table_of_contents_test.dart"
[ $? -ne 0 ] && ((failed_tests++))

# Run additional documentation tests if they exist
if [ -f "$PROJECT_DIR/test/presentation/widgets/documentation/asciidoc_renderer_test.dart" ]; then
  echo "Running AsciiDocRenderer tests..."
  run_test "$PROJECT_DIR/test/presentation/widgets/documentation/asciidoc_renderer_test.dart"
  [ $? -ne 0 ] && ((failed_tests++))
fi

if [ -f "$PROJECT_DIR/test/presentation/widgets/documentation/decision_graph_test.dart" ]; then
  echo "Running DecisionGraph tests..."
  run_test "$PROJECT_DIR/test/presentation/widgets/documentation/decision_graph_test.dart"
  [ $? -ne 0 ] && ((failed_tests++))
fi

if [ -f "$PROJECT_DIR/test/presentation/widgets/documentation/decision_timeline_test.dart" ]; then
  echo "Running DecisionTimeline tests..."
  run_test "$PROJECT_DIR/test/presentation/widgets/documentation/decision_timeline_test.dart"
  [ $? -ne 0 ] && ((failed_tests++))
fi

# Print summary
echo ""
echo "==============================================="
echo "Documentation Test Summary"
echo "==============================================="

if [ $failed_tests -eq 0 ]; then
  echo "All documentation tests passed! ✅"
  exit 0
else
  echo "$failed_tests documentation tests failed. ❌"
  exit 1
fi