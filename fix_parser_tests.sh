#!/bin/bash

# This script helps reset the stubbed test files to their original implementations
# and runs the parser tests to see what issues still remain to be fixed.

# Set color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW}     Dart Structurizr Parser Test Fixer      ${NC}"
echo -e "${YELLOW}==============================================${NC}"
echo ""

# Check if git is available and if we're in a git repository
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo -e "${GREEN}Git repository detected. Creating backup branch...${NC}"
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
  BACKUP_BRANCH="parser-test-fixes-backup-$(date +%Y%m%d%H%M%S)"
  git checkout -b $BACKUP_BRANCH
  echo -e "${GREEN}Created backup branch: $BACKUP_BRANCH${NC}"
  echo ""
else
  echo -e "${YELLOW}WARNING: Not in a git repository or git not available.${NC}"
  echo -e "${YELLOW}No backup branch will be created. Proceed with caution.${NC}"
  echo ""
fi

# Function to unstub tests
unstub_tests() {
  echo -e "${YELLOW}Resetting stubbed tests to original implementations...${NC}"
  
  # Use git if available to restore original files
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${GREEN}Using git to restore original test files...${NC}"
    # Get a list of the stubbed test files
    git checkout $CURRENT_BRANCH -- test/domain/parser/element_parser_integration_test.dart
    git checkout $CURRENT_BRANCH -- test/domain/parser/element_parser_integration_complex_test.dart
    git checkout $CURRENT_BRANCH -- test/domain/parser/explicit_relationship_test.dart
    git checkout $CURRENT_BRANCH -- test/domain/parser/model_node_comprehensive_test.dart
    git checkout $CURRENT_BRANCH -- test/domain/parser/direct_workspace_test.dart
    git checkout $CURRENT_BRANCH -- test/domain/parser/lexer/lexer_test.dart
    
    # Restore the files but don't commit
    git reset HEAD test/domain/parser/element_parser_integration_test.dart
    git reset HEAD test/domain/parser/element_parser_integration_complex_test.dart
    git reset HEAD test/domain/parser/explicit_relationship_test.dart
    git reset HEAD test/domain/parser/model_node_comprehensive_test.dart
    git reset HEAD test/domain/parser/direct_workspace_test.dart
    git reset HEAD test/domain/parser/lexer/lexer_test.dart
    
    echo -e "${GREEN}Original test files restored.${NC}"
  else
    echo -e "${RED}Git not available. Cannot restore original test files automatically.${NC}"
    echo -e "${RED}You will need to manually restore the test files from version control.${NC}"
    exit 1
  fi
  
  echo ""
}

# Function to run parser tests
run_parser_tests() {
  echo -e "${YELLOW}Running parser tests...${NC}"
  echo ""
  
  # Run the parser tests and capture the output
  flutter test test/domain/parser/nested_relationship_test.dart test/domain/parser/include_directive_test.dart
  
  echo ""
  echo -e "${YELLOW}These tests should pass. Now trying the previously stubbed tests...${NC}"
  echo ""
  
  # Try running each of the previously stubbed tests individually to see errors
  tests=(
    "test/domain/parser/element_parser_integration_test.dart"
    "test/domain/parser/element_parser_integration_complex_test.dart"
    "test/domain/parser/explicit_relationship_test.dart"
    "test/domain/parser/model_node_comprehensive_test.dart"
    "test/domain/parser/direct_workspace_test.dart"
    "test/domain/parser/lexer/lexer_test.dart"
  )
  
  for test in "${tests[@]}"; do
    echo -e "${YELLOW}Running test: $test${NC}"
    flutter test "$test" || echo -e "${RED}Test failed: $test${NC}"
    echo ""
  done
}

# Function to display help with next steps
display_help() {
  echo -e "${YELLOW}==============================================${NC}"
  echo -e "${YELLOW}                 Next Steps                   ${NC}"
  echo -e "${YELLOW}==============================================${NC}"
  echo ""
  echo -e "1. Fix the failing tests based on the error messages."
  echo -e "2. Focus on addressing issues in the order listed in the PARSER_FIXES_README.md file."
  echo -e "3. Work through each test one by one rather than trying to fix everything at once."
  echo -e "4. To restore the stubbed versions if needed, use '${GREEN}git checkout $BACKUP_BRANCH${NC}'."
  echo ""
  echo -e "See ${GREEN}PARSER_FIXES_README.md${NC} for a detailed analysis of the issues and recommended fixes."
  echo ""
}

# Main execution
echo -e "${YELLOW}This script will reset the stubbed parser tests to their original implementations${NC}"
echo -e "${YELLOW}and run them to show what issues still need to be fixed.${NC}"
echo ""
read -p "Do you want to continue? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  unstub_tests
  run_parser_tests
  display_help
else
  echo -e "${YELLOW}Operation cancelled.${NC}"
  # If we created a backup branch but didn't use it, delete it
  if [[ -n "$BACKUP_BRANCH" ]] && git rev-parse --verify --quiet $BACKUP_BRANCH > /dev/null; then
    git checkout $CURRENT_BRANCH
    git branch -D $BACKUP_BRANCH
    echo -e "${GREEN}Deleted unused backup branch: $BACKUP_BRANCH${NC}"
  fi
fi

echo ""
echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW}                 Completed                    ${NC}"
echo -e "${YELLOW}==============================================${NC}"