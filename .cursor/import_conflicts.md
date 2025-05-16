# Import Conflict Resolution Rules

## Overview
When both Flutter and your domain model define classes with the same name (e.g., `Container`, `Element`, `View`, `Border`), you must avoid symbol conflicts.

## Best Practices
- Use `hide` to exclude conflicting symbols from Flutter imports when you only need your domain model's version.
- Use `as` to import your domain model with a prefix if you need both versions in the same file.
- Prefer Material or SizedBox over Container for UI layout if you only need simple layout.

## Examples

### Hiding Flutter Symbols
```dart
import 'package:flutter/material.dart' hide Container, Element, View, Border;
import 'package:flutter_structurizr/domain/model/model.dart';
```

### Using Import Prefixes
```dart
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/model/model.dart' as structurizr_model;

// Use Flutter's Container
Container(...)
// Use domain model's Container
structurizr_model.Container(...)
```

### When to Use Each
- Use `hide` when you only need the domain model's version in a file.
- Use `as` when you need both Flutter and domain model versions in the same file.

## Additional Tips
- For tests, prefer DecoratedBox + SizedBox + Padding over Container if you run into conflicts.
- Always check for symbol conflicts when adding new imports. 