# References Directory

This directory contains reference implementations of the original Structurizr project components. These are essential for understanding the Java implementation that this Dart/Flutter port is based on.

## Reference Components

- **dsl/**: Structurizr DSL implementation (Java)
- **lite/**: Structurizr Lite application (Java)
- **ui/**: Structurizr UI implementation (JavaScript)
- **json/**: JSON schema definitions

## Strategy for Managing References

### Option 1: Git Submodules (Recommended)

The references are best managed as git submodules to keep them separate but easily accessible:

```bash
# Add the original repositories as submodules
git submodule add https://github.com/structurizr/dsl.git references/dsl
git submodule add https://github.com/structurizr/lite.git references/lite
git submodule add https://github.com/structurizr/ui.git references/ui
git submodule add https://github.com/structurizr/json.git references/json

# Clone with submodules
git clone --recurse-submodules https://github.com/yourusername/dart-structurizr.git

# Update submodules to latest
git submodule update --remote --merge
```

### Option 2: Manual Download

If you're not using submodules, download the reference code manually:

1. Download the latest releases from:
   - https://github.com/structurizr/dsl
   - https://github.com/structurizr/lite
   - https://github.com/structurizr/ui
   - https://github.com/structurizr/json

2. Extract them into the corresponding directories under `references/`

### Option 3: Separate Repository

Keep the references in a separate repository and reference them as needed during development.

## Important Notes

- These reference implementations are read-only and should not be modified
- They serve as the authoritative source for feature parity
- Consult them when implementing new features or debugging compatibility issues
- The Java code can be particularly helpful for understanding parsing logic and model relationships