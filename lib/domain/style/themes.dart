import 'dart:ui';
import 'package:flutter_structurizr/domain/style/styles.dart';

/// A collection of default themes for architecture diagrams.
class Themes {
  Themes._(); // Private constructor to prevent instantiation

  /// Default Structurizr theme with standard colors and shapes.
  static Styles defaultTheme() {
    return Styles(
      elements: [
        // Person style
        ElementStyle(
          tag: 'Person',
          shape: Shape.person,
          background: const Color(0xFF08427B),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Software System style
        ElementStyle(
          tag: 'SoftwareSystem',
          shape: Shape.box,
          background: const Color(0xFF1168BD),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Container style
        ElementStyle(
          tag: 'Container',
          shape: Shape.box,
          background: const Color(0xFF438DD5),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Component style
        ElementStyle(
          tag: 'Component',
          shape: Shape.component,
          background: const Color(0xFF85BBF0),
          color: const Color(0xFF000000),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Database style
        ElementStyle(
          tag: 'Database',
          shape: Shape.cylinder,
          background: const Color(0xFF438DD5),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // External System style
        ElementStyle(
          tag: 'External',
          shape: Shape.box,
          background: const Color(0xFF999999),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Infrastructure Node style
        ElementStyle(
          tag: 'InfrastructureNode',
          shape: Shape.box,
          background: const Color(0xFF999999),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Deployment Node style
        ElementStyle(
          tag: 'DeploymentNode',
          shape: Shape.box,
          background: const Color(0xFFFFFFFF),
          color: const Color(0xFF000000),
          fontSize: 22,
          strokeWidth: 2,
          border: Border.dashed,
        ),
      ],
      relationships: [
        // Default relationship style
        const RelationshipStyle(
          tag: 'Relationship',
          thickness: 2,
          color: Color(0xFF707070),
          fontSize: 18,
          routing: Routing.direct,
        ),
        
        // Asynchronous relationship style
        const RelationshipStyle(
          tag: 'Asynchronous',
          thickness: 2,
          color: Color(0xFF707070),
          style: LineStyle.dashed,
          fontSize: 18,
          routing: Routing.direct,
        ),
      ],
    );
  }

  /// Dark theme with lighter colors on a dark background.
  static Styles darkTheme() {
    return Styles(
      elements: [
        // Person style
        ElementStyle(
          tag: 'Person',
          shape: Shape.person,
          background: const Color(0xFF1168BD),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Software System style
        ElementStyle(
          tag: 'SoftwareSystem',
          shape: Shape.box,
          background: const Color(0xFF3385D6),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Container style
        ElementStyle(
          tag: 'Container',
          shape: Shape.box,
          background: const Color(0xFF64A1E4),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Component style
        ElementStyle(
          tag: 'Component',
          shape: Shape.component,
          background: const Color(0xFF85BBF0),
          color: const Color(0xFF000000),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Database style
        ElementStyle(
          tag: 'Database',
          shape: Shape.cylinder,
          background: const Color(0xFF64A1E4),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // External System style
        ElementStyle(
          tag: 'External',
          shape: Shape.box,
          background: const Color(0xFF777777),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Infrastructure Node style
        ElementStyle(
          tag: 'InfrastructureNode',
          shape: Shape.box,
          background: const Color(0xFF777777),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Deployment Node style
        ElementStyle(
          tag: 'DeploymentNode',
          shape: Shape.box,
          background: const Color(0xFF333333),
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
          border: Border.dashed,
        ),
      ],
      relationships: [
        // Default relationship style
        const RelationshipStyle(
          tag: 'Relationship',
          thickness: 2,
          color: Color(0xFFAAAAAA),
          fontSize: 18,
          routing: Routing.direct,
        ),
        
        // Asynchronous relationship style
        const RelationshipStyle(
          tag: 'Asynchronous',
          thickness: 2,
          color: Color(0xFFAAAAAA),
          style: LineStyle.dashed,
          fontSize: 18,
          routing: Routing.direct,
        ),
      ],
    );
  }

  /// Minimal theme with a simplified, clean appearance.
  static Styles minimalTheme() {
    return Styles(
      elements: [
        // Person style
        ElementStyle(
          tag: 'Person',
          shape: Shape.person,
          background: const Color(0xFFEEEEEE),
          color: const Color(0xFF000000),
          fontSize: 20,
          strokeWidth: 1,
        ),
        
        // Software System style
        ElementStyle(
          tag: 'SoftwareSystem',
          shape: Shape.box,
          background: const Color(0xFFDDDDDD),
          color: const Color(0xFF000000),
          fontSize: 20,
          strokeWidth: 1,
        ),
        
        // Container style
        ElementStyle(
          tag: 'Container',
          shape: Shape.box,
          background: const Color(0xFFCCCCCC),
          color: const Color(0xFF000000),
          fontSize: 20,
          strokeWidth: 1,
        ),
        
        // Component style
        ElementStyle(
          tag: 'Component',
          shape: Shape.component,
          background: const Color(0xFFBBBBBB),
          color: const Color(0xFF000000),
          fontSize: 20,
          strokeWidth: 1,
        ),
        
        // Database style
        ElementStyle(
          tag: 'Database',
          shape: Shape.cylinder,
          background: const Color(0xFFCCCCCC),
          color: const Color(0xFF000000),
          fontSize: 20,
          strokeWidth: 1,
        ),
      ],
      relationships: [
        // Default relationship style
        const RelationshipStyle(
          tag: 'Relationship',
          thickness: 1,
          color: Color(0xFF555555),
          fontSize: 16,
          routing: Routing.direct,
        ),
      ],
    );
  }

  /// Vibrant theme with bright colors for high contrast.
  static Styles vibrantTheme() {
    return Styles(
      elements: [
        // Person style
        ElementStyle(
          tag: 'Person',
          shape: Shape.person,
          background: const Color(0xFFE91E63), // Pink
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Software System style
        ElementStyle(
          tag: 'SoftwareSystem',
          shape: Shape.box,
          background: const Color(0xFF2196F3), // Blue
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Container style
        ElementStyle(
          tag: 'Container',
          shape: Shape.box,
          background: const Color(0xFF4CAF50), // Green
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Component style
        ElementStyle(
          tag: 'Component',
          shape: Shape.component,
          background: const Color(0xFF8BC34A), // Light Green
          color: const Color(0xFF000000),
          fontSize: 22,
          strokeWidth: 2,
        ),
        
        // Database style
        ElementStyle(
          tag: 'Database',
          shape: Shape.cylinder,
          background: const Color(0xFF9C27B0), // Purple
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          strokeWidth: 2,
        ),
      ],
      relationships: [
        // Default relationship style
        const RelationshipStyle(
          tag: 'Relationship',
          thickness: 2,
          color: Color(0xFF424242),
          fontSize: 18,
          routing: Routing.direct,
        ),
      ],
    );
  }
}