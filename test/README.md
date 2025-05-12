# Dart Structurizr Tests

This directory contains the test suite for the Dart Structurizr library.

## Test Organization

- `core/` - Tests for the core model and view classes
- `export/` - Tests for the diagram export functionality
- `presentation/` - Tests for presentation and rendering
  - `layout/` - Tests for layout strategies
    - `force_directed_layout_test.dart` - Tests for physics-based layout
    - `grid_layout_test.dart` - Tests for grid-based layout
    - `automatic_layout_test.dart` - Tests for automatic layout selection
    - `manual_layout_test.dart` - Tests for manual position preservation
  - `rendering/` - Tests for rendering components
- `widgets/` - Tests for Flutter widgets

## Running Tests

To run all tests:

```bash
./run_tests.sh
```

To run a specific test:

```bash
flutter test test/path/to/test_file.dart
```

## Test Coverage

The test suite aims to provide comprehensive coverage of:

- Core model functionality
- Layout strategies
- Rendering components
- Widget behavior
- Export functionality

Each test group focuses on verifying the correct behavior of a specific component, ensuring that it meets the expected requirements and handles edge cases appropriately.