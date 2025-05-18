# Fetch Documentation

## Description
Use the WebFetch TOOL to read the documentation at $ARGUMENTS.

## Process
1. Read the documents in the ../specs directory to understand the project goals
2. Fetch documentation from the specified URL
3. Cross-reference fetched documentation with existing specs and ../ai_docs to avoid redundancy
4. CREATE a new file that captures the content in the ../ai_docs directory
   1. At the top of the new file, extract and summarize actionable insights or implementation examples
   2. Tag the documentation with relevant phase/component for easier future retrieval
   3. Make sure to capture all information that may be useful for the project goals.
   4. Make sure to keep specific implementation examples  
5. Name the file with a name that makes sense
6. If there is a similar file already in the ../ai_docs directory, use the same name with a new version number

## Usage
```
/project:fetch_documentation <url>
```

## Examples
```
/project:fetch_documentation https://structurizr.com/help
/project:fetch_documentation https://c4model.com/
```