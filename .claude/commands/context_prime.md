# Context Prime

## Description
This command helps Claude understand the overall context of the project.

## Process
1. READ README.md to understand the project's purpose and structure
2. READ_CLAUDE.md
3. READ specs/flutter_structurizr_implementation_spec.md
4. READ specs/flutter_structurizr_implementation_spec_updated.md
5. Run git ls-files to get a complete listing of project files
6. Analyze the context to provide better assistance with $ARGUMENTS

## Usage
```
/project:context_prime [optional specific focus]
```

## Examples
```
/project:context_prime
/project:context_prime architecture
/project:context_prime file structure
```