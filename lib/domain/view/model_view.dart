/// Export the View class to make it available as ModelView
export 'package:flutter_structurizr/domain/view/view_alias.dart';

import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/view/view.dart';

// typedef Color = String; // TODO: Replace with platform-specific color handling

/// Extension on ElementView to provide setter methods for position
extension ElementViewExtension on ElementView {
  /// Creates a copy of this element view with a new X position
  ElementView copyWithX(int x) {
    return copyWith(x: x);
  }

  /// Creates a copy of this element view with a new Y position
  ElementView copyWithY(int y) {
    return copyWith(y: y);
  }

  /// Creates a copy of this element view with a new X and Y position
  ElementView copyWithPosition(int x, int y) {
    return copyWith(x: x, y: y);
  }

  /// Creates a copy of this element view with a new width and height
  ElementView copyWithSize(int width, int height) {
    return copyWith(width: width, height: height);
  }

  /// Creates a copy of this element view with a new parent ID
  ElementView copyWithParent(String? parentId) {
    return copyWith(parentId: parentId);
  }

  /// Checks if this element is a child of the given parent element ID
  bool isChildOf(String parentElementId) {
    return parentId == parentElementId;
  }

  /// Checks if this element has a parent
  bool get hasParent => parentId != null;

  /// Returns the position of this element as an Offset
  Offset get position {
    return Offset(x?.toDouble() ?? 0.0, y?.toDouble() ?? 0.0);
  }

  /// Creates a copy of this element view with a new position, preserving other properties
  ElementView copyWithPositionOffset(Offset position) {
    return copyWith(x: position.dx.round(), y: position.dy.round());
  }
}
