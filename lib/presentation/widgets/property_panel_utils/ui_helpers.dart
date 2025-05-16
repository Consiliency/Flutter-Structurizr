import 'package:flutter/material.dart' hide Border;
import 'package:flutter_structurizr/domain/style/styles.dart';

/// Helper functions for UI elements in property panel

/// Gets a shape name from a Shape enum value
String getShapeName(Shape shape) {
  return shape.toString().split('.').last;
}

/// Gets a line style name from a LineStyle enum value
String getLineStyleName(LineStyle style) {
  return style.toString().split('.').last;
}

/// Gets a border style name from a Border enum value
String getBorderStyleName(Border style) {
  return style.toString().split('.').last;
}

/// Gets a routing name from a StyleRouting enum value
String getRoutingName(StyleRouting routing) {
  return routing.toString().split('.').last;
}

/// Gets a label position name from a LabelPosition enum value
String getLabelPositionName(LabelPosition position) {
  return position.toString().split('.').last;
}

/// Gets a shape icon based on the shape type
Widget getShapeIcon(Shape shape) {
  switch (shape) {
    case Shape.box:
      return Container(
        width: 24,
        height: 24,
        color: Colors.grey.shade300,
      );
    case Shape.roundedBox:
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    case Shape.circle:
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );
    case Shape.ellipse:
      return Container(
        width: 24,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    case Shape.hexagon:
      return const Icon(Icons.hexagon, size: 24);
    case Shape.cylinder:
      return const Icon(Icons.panorama_vertical, size: 24);
    case Shape.pipe:
      return const Icon(Icons.priority_high, size: 24);
    case Shape.person:
      return const Icon(Icons.person, size: 24);
    case Shape.robot:
      return const Icon(Icons.smart_toy, size: 24);
    case Shape.folder:
      return const Icon(Icons.folder, size: 24);
    case Shape.webBrowser:
      return const Icon(Icons.web, size: 24);
    case Shape.mobileDevicePortrait:
      return const Icon(Icons.smartphone, size: 24);
    case Shape.mobileDeviceLandscape:
      return const Icon(Icons.smartphone_landscape, size: 24);
    case Shape.component:
      return const Icon(Icons.settings, size: 24);
    default:
      return const Icon(Icons.square, size: 24);
  }
}