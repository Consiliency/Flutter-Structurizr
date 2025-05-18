# Complete Codex Offline Development Workflow

This document explains the complete workflow for setting up and using this repository in Codex's offline environment.

## Overview

We provide a complete Flutter SDK and all dependencies in the repository for offline development in Codex. Due to GitHub's file size limitations, the archives are split into smaller chunks in the `.codex/` directory:
- `flutter-sdk.tar.gz.part.*` - Complete Flutter SDK (704MB, split into 95MB chunks)
- `pub-cache.tar.gz.part.*` - All Dart/Flutter packages (387MB, split into 95MB chunks)

The setup script automatically reassembles these files before extraction.

## Initial Setup (One-time, by repository maintainer)

1. **Prepare the offline cache:**
   ```bash
   ./prepare_codex_cache_full.sh
   ```
   This creates compressed archives of the complete Flutter SDK and all dependencies in `.codex/`

2. **Commit with Git LFS:**
   ```bash
   git add -A
   git commit -m "Add Git LFS offline cache for Codex"
   git lfs push origin main --all
   git push origin main
   ```

## Codex Environment Setup (For each Codex session)

1. **Clone with LFS support (if using Git LFS):**
   ```bash
   git lfs clone https://github.com/yourusername/dart-structurizr.git
   cd dart-structurizr
   ```
   
   Or regular clone if LFS not available:
   ```bash
   git clone https://github.com/yourusername/dart-structurizr.git
   cd dart-structurizr
   ```

2. **Run the offline setup:**
   ```bash
   ./codex_offline_setup_split.sh
   ```
   
   This script will:
   - Reassemble the split archive files
   - Extract the Flutter SDK and packages
   - Configure the offline environment

3. **Use offline commands:**
   ```bash
   ./flutter test      # Run tests (full Flutter SDK)
   ./flutter analyze   # Analyze code
   ./flutter run -d linux    # Run on Linux desktop
   ./flutter build linux     # Build for Linux
   ./dart analyze      # Dart-specific commands
   ```

## File Structure

```
dart-structurizr/
├── .codex/                          # Offline cache directory
│   ├── flutter-sdk.tar.gz.part.*   # Flutter SDK split files (8 parts)
│   ├── pub-cache.tar.gz.part.*     # Package cache split files (5 parts)
│   ├── reassemble.sh               # Script to reassemble split files
│   ├── .flutter-sdk-packed         # Extraction marker
│   └── .pub-cache-packed           # Extraction marker
├── codex_offline_setup_split.sh    # Codex setup script (handles split files)
├── setup_dev_env.sh                # Regular dev setup (requires internet)
├── prepare_codex_cache_full.sh     # Cache preparation script
└── split_large_files.sh            # Script to split large archives
```

## How It Works

1. **Repository includes** compressed archives via Git LFS
2. **Setup script extracts** archives on first run
3. **Creates wrappers** for dart/pub/flutter commands
4. **Configures environment** for offline operation
5. **All subsequent operations** work without internet

## Troubleshooting

### LFS files not found
```bash
git lfs pull
./codex_offline_setup.sh
```

### Dependencies missing
```bash
# Re-run cache preparation (requires internet)
./prepare_codex_cache.sh
git add .codex/
git commit -m "Update offline cache"
git push
```

### Command not found
```bash
# Ensure setup completed
./codex_offline_setup.sh
# Use wrapper commands
./dart --version
```

## Updating Dependencies

When dependencies change:

1. **On a machine with internet:**
   ```bash
   ./prepare_codex_cache.sh
   git add .codex/
   git commit -m "Update offline dependencies"
   git lfs push origin main --all
   git push origin main
   ```

2. **In Codex:**
   ```bash
   git pull
   git lfs pull
   ./codex_offline_setup.sh
   ```

## Best Practices

1. Always use `./dart`, `./pub`, `./flutter` wrappers in Codex
2. Run setup script after each clone
3. Keep dependencies up to date with prepare script
4. Use Git LFS for all large binary files

This workflow ensures seamless offline development in Codex while maintaining a reasonable repository size.