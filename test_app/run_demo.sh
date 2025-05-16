#!/bin/bash

# Script to run different Structurizr demos

function show_help {
  echo "Usage: ./run_demo.sh [OPTION]"
  echo "Run different Flutter Structurizr demos."
  echo ""
  echo "Options:"
  echo "  -b, --basic       Run the basic UI components test (main.dart)"
  echo "  -f, --fixed       Run the fixed UI components demo (main_fixed.dart)"
  echo "  -i, --integrated  Run the comprehensive integrated demo (integrated_demo.dart)"
  echo "  -h, --help        Display this help and exit"
  echo ""
  echo "If no option is provided, the script will display a menu to choose from."
}

function run_demo {
  local demo_file=$1
  echo "Running $demo_file demo..."
  flutter run -t lib/$demo_file
}

function show_menu {
  echo "=== Flutter Structurizr Demos ==="
  echo "1. Basic UI Components Test (main.dart)"
  echo "2. Fixed UI Components Demo (main_fixed.dart)"
  echo "3. Comprehensive Integrated Demo (integrated_demo.dart)"
  echo "4. Exit"
  echo ""
  read -p "Choose a demo (1-4): " choice
  
  case $choice in
    1) run_demo "main.dart" ;;
    2) run_demo "main_fixed.dart" ;;
    3) run_demo "integrated_demo.dart" ;;
    4) echo "Exiting." && exit 0 ;;
    *) echo "Invalid choice. Please enter a number from 1 to 4." && show_menu ;;
  esac
}

# Check for command line arguments
if [ $# -eq 0 ]; then
  show_menu
else
  case "$1" in
    -b|--basic)
      run_demo "main.dart"
      ;;
    -f|--fixed)
      run_demo "main_fixed.dart"
      ;;
    -i|--integrated)
      run_demo "integrated_demo.dart"
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
fi

exit 0