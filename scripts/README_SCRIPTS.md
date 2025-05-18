# Setup Scripts Documentation

This directory contains various setup and utility scripts for the project.

## Development Setup Scripts

### setup_dev_env.sh
- **Purpose:** Sets up regular development environment with internet access
- **Usage:** `./setup_dev_env.sh`
- **Features:**
  - Installs Flutter SDK (3.19.0+) if needed
  - Installs system dependencies 
  - Handles network connectivity issues gracefully
  - Configures complete Flutter development environment

### codex_offline_setup.sh
- **Purpose:** Sets up offline environment for Codex development
- **Usage:** `./codex_offline_setup.sh` (after cloning with Git LFS)
- **Features:**
  - Extracts pre-cached dependencies from Git LFS archives
  - Configures offline Dart/Flutter environment
  - Creates command wrappers for offline operation
  - No internet connection required

### prepare_codex_cache.sh
- **Purpose:** Prepares Git LFS archives for offline Codex development
- **Usage:** `./prepare_codex_cache.sh` (requires internet)
- **Features:**
  - Creates compressed archives of Dart SDK and packages
  - Configures Git LFS tracking
  - Updates .gitignore appropriately
  - Only run by repository maintainers

## Workflow

1. **Regular developers:** Use `setup_dev_env.sh`
2. **Codex users:** Use `codex_offline_setup.sh`
3. **Maintainers:** Use `prepare_codex_cache.sh` to update offline cache

See [CODEX_WORKFLOW.md](../CODEX_WORKFLOW.md) for complete offline development workflow.