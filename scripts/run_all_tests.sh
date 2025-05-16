#!/bin/bash

# Master script to run all tests for Flutter Structurizr

# Print header
echo "==============================================="
echo "Running All Tests for Flutter Structurizr"
echo "==============================================="

# Set paths
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
SCRIPTS_DIR="$PROJECT_DIR/scripts"

# Source environment setup if available
if [ -f "$PROJECT_DIR/.flutter-env/setup.sh" ]; then
  source "$PROJECT_DIR/.flutter-env/setup.sh"
fi

# Run all test categories
"$SCRIPTS_DIR/run_domain_tests.sh"
domain_exit=$?

"$SCRIPTS_DIR/run_layout_tests.sh"
layout_exit=$?

"$SCRIPTS_DIR/run_documentation_tests.sh"
doc_exit=$?

"$SCRIPTS_DIR/run_ui_tests.sh"
ui_exit=$?

"$SCRIPTS_DIR/run_integration_tests.sh"
integration_exit=$?

# Print summary
echo ""
echo "==============================================="
echo "Test Summary"
echo "==============================================="
echo "Domain Tests: $([ $domain_exit -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "Layout Tests: $([ $layout_exit -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "Documentation Tests: $([ $doc_exit -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "UI Tests: $([ $ui_exit -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "Integration Tests: $([ $integration_exit -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"

# Calculate overall status
overall_exit=$((domain_exit + layout_exit + doc_exit + ui_exit + integration_exit))

if [ $overall_exit -eq 0 ]; then
  echo ""
  echo "All tests passed! ✅"
  exit 0
else
  echo ""
  echo "Some tests failed. ❌"
  exit 1
fi