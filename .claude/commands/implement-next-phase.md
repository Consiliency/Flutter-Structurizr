# Implementation Command: Implement Next Incomplete Phase

## Phase Identification and Analysis

1. Analyze the implementation status in these files:
   - `specs/implementation_status.md`
   - `specs/flutter_structurizr_implementation_spec.md`
   - All phase files in `specs/phase*_implementation_plan.md`

2. Identify the lowest-numbered phase that has incomplete tasks (<100% complete)

3. For the identified phase:
   - Thoroughly review the specification in `specs/phase{N}_implementation_plan.md`
   - Analyze requirements, dependencies, and implementation approach
   - Create a detailed task breakdown of remaining implementation work
   - Review original Structurizr code mentioned in specs to understand expected functionality
   - Check for recent best practices and lessons learned in CLAUDE.md before starting implementation

## Implementation Strategy

1. Develop a systematic approach to complete the identified phase: Ultra Think
   - Prioritize core functionality first
   - Break down complex tasks into manageable components
   - Ensure compatibility with already implemented phases
   - Consider potential name conflicts with Flutter built-ins
   - Coordinate with the latest modular parser refactor and alias/type usage guidelines
   - Reference the `ai_doc/` directory for specific framework and library documentation
   - Use Web Fetch, Web Search, and Fetch tools to find examples and documentation if not in `/ai_docs`
     - Compile new documentation that you find into a library specific markdown file and save it in `/ai_docs` for future reference

2. Implementation execution: Think Hard
   - Create/modify necessary Dart files to implement required functionality
   - Follow clean architecture principles
   - Implement all remaining tasks from the phase specification
   - Ensure code quality meets project standards
   - After each major implementation step, run flutter analyze and flutter test to catch issues early
   - Resolve any compilation errors immediately
   - Follow existing code patterns and naming conventions
   - Handle name conflicts with Flutter built-ins as described in CLAUDE.md
   - Document any new best practices or lessons learned during implementation for later inclusion in CLAUDE.md or specs

3. Use parallel processing with Agent/Task/Batch tools:
   - Launch multiple agents for different implementation tasks
   - Use Batch for file operations and searches
   - Split complex implementations into parallel tasks where possible

## Important Guidelines

- Follow existing architectural patterns in the codebase
- Adhere to clean architecture principles with clear separation of concerns
- Handle naming conflicts properly (using `hide` directives or alias types)
- Do not add features that aren't in the specification documents
- Only implement what's specified in the phase document
- For each implemented feature, verify basic functionality (automated testing will be done in the next command)
- Maintain immutability of model classes
- Use proper extension methods for updating immutable models
- DO NOT CREATE new specification documents or update exiting ones (this will be done in a separate prompt)
- DO NOT STOP until all specified implementations for the phase are complete

Provide a summary of completed work after implementation in the terminal, including:
1. Which phase was implemented
2. What specific tasks were completed
3. Any challenges encountered and how they were resolved
4. Next steps for testing