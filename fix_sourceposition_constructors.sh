#!/bin/bash

# Script to fix SourcePosition constructor calls across all test files
# The constructor expects positional parameters: SourcePosition(line, column, [offset])

echo "Reverting incorrect changes and fixing SourcePosition constructor calls..."

# First, revert the incorrect named parameter changes
find /home/jenner/Code/dart-structurizr/test -name "*.dart" -exec \
    sed -i 's/SourcePosition(line: \([0-9]\+\), column: \([0-9]\+\), offset: \([0-9]\+\))/SourcePosition(\1, \2, \3)/g' {} \;

# Revert 2-parameter named changes  
find /home/jenner/Code/dart-structurizr/test -name "*.dart" -exec \
    sed -i 's/SourcePosition(line: \([0-9]\+\), column: \([0-9]\+\))/SourcePosition(\1, \2)/g' {} \;

echo "SourcePosition constructor fixes completed - now using positional parameters!"