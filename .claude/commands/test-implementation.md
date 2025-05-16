# Testing Command: Test Latest Implementation

## Test Plan Analysis

1. Analyze the testing plan for the current phase: 
   - Review testing sections in the implemented phase document (`specs/phase{N}_implementation_plan.md`)
   - Check `specs/testing_plan_template.md` for additional testing guidance
   - Identify test categories required (unit, widget, integration, golden)
   - Note any specific testing frameworks or dependencies needed

2. Verify testing environment:
   - Check existing test files related to the implemented phase
   - Identify test dependencies needed in pubspec.yaml
   - Install any missing testing dependencies
   - Verify testing utilities and helpers are available

## Test Implementation

1. For each implemented feature: Think Hard
   - Check if existing tests already cover the functionality
   - Create new tests for any untested functionality
   - Consider potential name conflicts with Flutter built-ins
   - Reference the `ai_doc/` directory for specific framework and library documentation
   - Use Web Fetch, Web Search, and Fetch tools to find examples and documentation if nit in `/ai_docs`
     - Compile new documentation that you find into a library specific markdown file and save it in `/ai_docs` for future reference
   - Ensure test coverage for:
     - Normal use cases
     - Edge cases
     - Error handling
     - Integration with existing components

2. Follow testing best practices: Ultra Think
   - Create unit tests for domain models and application logic
   - Implement widget tests for UI components
   - Add integration tests for end-to-end functionality
   - Create golden tests for visual regression testing when appropriate
   - Use mocks and fakes for isolating components
   - Handle name conflicts in test files properly (hide directives, alias types)
   - Add comments explaining complex test scenarios

3. Run all tests:
   - Use the provided testing scripts in the `scripts/` directory:
     - `scripts/run_all_tests.sh` to run all tests
     - `scripts/run_domain_tests.sh` for domain model tests
     - `scripts/run_layout_tests.sh` for layout tests
     - `scripts/run_documentation_tests.sh` for documentation tests
     - `scripts/run_ui_tests.sh` for UI component tests
   - Run tests for the specific components implemented
   - Run any affected existing tests
   - Document test results and failures
   - Debug and fix any test failures
   - Rerun tests until all pass

## Test Debugging and Refinement

1. For any test failures: Think Hard
   - Analyze error logs and traces
   - Debug implementation code
   - Fix issues in the implementation
   - Fix any issues with the tests themselves
   - Rerun tests to confirm fixes

2. Verify specific test requirements from the phase document:
   - Confirm all specified test cases are covered
   - Verify special testing requirements (if any)
   - Ensure proper test organization according to project structure

3. Expand test coverage if needed:
   - Add more test cases if gaps are identified
   - Improve edge case coverage
   - Enhance error case testing

## Guidelines

- Use appropriate testing frameworks for each test type
- Follow existing test patterns in the codebase
- Run tests frequently during implementation
- Update tests as implementation changes
- DO NOT leave any tests in a failing state
- Make sure tests are organized according to project structure
- Use descriptive test names that explain what is being tested
- Create test helpers for common testing patterns
- Use proper matchers and assertions

Provide a comprehensive testing report after completion, including:

1. What tests were created or modified
2. Test results and coverage metrics
3. Any implementation issues found during testing and how they were fixed
4. Recommendations for future testing improvements
