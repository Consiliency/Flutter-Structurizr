# Structurizr Test Application

This is a demonstration application for the Flutter Structurizr library. It showcases various components and features of the Structurizr architecture diagramming tool.

## Available Demos

This test application contains several demonstrations:

1. **Basic UI Components Test** (`main.dart`):
   - Shows integration issues with the original UI components
   - Demonstrates naming conflicts with Flutter built-ins

2. **Fixed UI Components** (`main_fixed.dart`):
   - Shows how to use the fixed versions of UI components
   - Demonstrates proper handling of naming conflicts

3. **Integrated Demo** (`integrated_demo.dart`):
   - Full-featured demo with real Structurizr models
   - Demonstrates C4 model views (System Context, Container, Component)
   - Shows rendering and layout functionality
   - Includes interactive diagram functionality

## Running the Demos

Choose the demo you want to run using the appropriate Flutter command:

```bash
# Run the basic UI components test
flutter run -t lib/main.dart

# Run the fixed UI components demo
flutter run -t lib/main_fixed.dart

# Run the comprehensive integrated demo
flutter run -t lib/integrated_demo.dart
```

## Features Demonstrated

This test application demonstrates:

1. **Structurizr Model Creation**:
   - Creating software systems, containers, components, and persons
   - Establishing relationships between elements
   - Setting element properties and metadata

2. **View Creation and Management**:
   - System Context views
   - Container views
   - Component views

3. **Style Customization**:
   - Custom element styles
   - Shape customization
   - Color schemes

4. **Layout Functionality**:
   - Force-directed automatic layout
   - Custom positioning

5. **UI Components**:
   - Structurizr diagram widget
   - Property panels
   - Filter panels

## Naming Conflict Resolution

This demo shows how to handle naming conflicts between Flutter built-ins and Structurizr model classes:

```dart
// Hide conflicting Flutter classes when importing Material
import 'package:flutter/material.dart' hide Container, Element, View;

// Import Structurizr model classes
import 'package:flutter_structurizr/domain/model/container.dart';
// ...
```

## Key Files

- `lib/main.dart`: Basic UI components test with integration issues
- `lib/main_fixed.dart`: Fixed UI components demo
- `lib/integrated_demo.dart`: Comprehensive integrated demo

## Troubleshooting

If you encounter rendering issues:
1. Make sure you're using the latest version of Flutter
2. Check that all dependencies are properly installed
3. Try running `flutter clean` and then `flutter pub get`
4. Ensure your device/emulator has sufficient resources

## Next Steps

After exploring these demos, you can:
1. Create your own architecture models
2. Customize the styles to match your organization's branding
3. Export diagrams to various formats
4. Integrate Structurizr into your own applications