// Export Container from model.dart to avoid conflicts with Flutter's Container
// This export must be placed before the typedef
export 'package:flutter_structurizr/domain/model/model.dart' show Container;

import 'package:flutter_structurizr/domain/model/container.dart';

// Alias for Container to avoid conflicts
// Use this type when you need to refer to Structurizr's Container in UI components
typedef ModelContainer = Container;
