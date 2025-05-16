// Export Element from element.dart to avoid conflicts with Flutter's Element
// This export must be placed before the typedef
export 'package:flutter_structurizr/domain/model/element.dart' show Element;

import 'package:flutter_structurizr/domain/model/element.dart' show Element;

// Alias for Element to avoid conflicts
// Use this type when you need to refer to Structurizr's Element in UI components
typedef ModelElement = Element;