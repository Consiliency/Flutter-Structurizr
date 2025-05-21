# Codex Development Workflow

This document explains the workflow for setting up and using this repository in Codex's environment.

## Overview

Dart Structurizr is a Flutter project that requires the Flutter SDK and various dependencies. In Codex, we leverage network access during the initial setup phase to install these dependencies. After setup, development continues in offline mode.

## Codex Environment Setup

When working with this repository in Codex, follow these steps:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/dart-structurizr.git
   cd dart-structurizr
   ```

2. **Run the Codex setup script:**
   ```bash
   ./setup_for_codex.sh
   ```
   
   This script will:
   - Install any required system dependencies
   - Install the Flutter SDK from the official source
   - Install all dart/flutter package dependencies for every sub-project
   - Run initial code generation
   - Pre-cache Flutter artifacts for desktop targets
   - Create convenient wrapper scripts for Flutter and Dart commands
   
   **Note:** This script requires network access, which is available during the setup phase in Codex.

3. **Verify the setup:**
   ```bash
   ./flutter doctor
   ```

## Development in Codex (Offline Mode)

After the initial setup, Codex operates in offline mode (no network access). Use these commands for development:

```bash
# Use the wrapper scripts for all Flutter/Dart commands
./flutter run        # Run the application
./flutter test       # Run tests
./flutter analyze    # Analyze code
./dart analyze       # Dart-specific commands
```

## File Structure

```
dart-structurizr/
├── lib/                          # Main source code
├── test/                         # Test suite
├── example/                      # Example applications
├── specs/                        # Implementation specifications
├── AGENTS.md                     # AI agent instructions (for post-setup)
├── setup_for_codex.sh            # Codex setup script (uses network)
└── clean_codex_cache.sh          # Script to clean offline cache files
```

## Best Practices for Codex

1. **Always use the wrapper scripts:**
   ```bash
   ./flutter [command]
   ./dart [command]
   ```

2. **Run the full test suite before committing:**
   ```bash
   ./flutter test
   ```

3. **Check code quality:**
   ```bash
   ./flutter analyze
   ```

4. **Follow import conflict resolution guidance in AGENTS.md**

## Troubleshooting

### Flutter command not found

If Flutter commands fail, ensure the setup script completed successfully:

```bash
test -f .codex_setup_complete && echo "Setup complete" || echo "Setup incomplete"
```

If setup is incomplete, run the setup script again:

```bash
./setup_for_codex.sh
```

### Dependencies missing

If dependencies are missing after setup:

```bash
# Manually install dependencies
./flutter pub get
```

## Updating the Project

For repository maintainers, when updating the project for Codex:

1. **Update the setup script if needed:**
   ```bash
   # Edit setup_for_codex.sh with any new setup requirements
   ```

2. **Update AGENTS.md for new development guidance:**
   ```bash
   # Edit AGENTS.md with new instructions for AI agents
   ```

3. **Commit the changes:**
   ```bash
   git add setup_for_codex.sh AGENTS.md
   git commit -m "Update Codex setup and guidance"
   git push
   ```