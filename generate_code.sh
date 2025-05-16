#!/bin/bash

# Script to generate code using build_runner

echo "Generating code using build_runner"
flutter pub run build_runner build --delete-conflicting-outputs

echo "Code generation completed"