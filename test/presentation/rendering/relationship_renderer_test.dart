import 'dart:ui';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/domain/model/element.dart';
// Import with alias to avoid conflicts
import 'package:flutter_structurizr/domain/style/styles.dart' as styles;
import 'package:flutter_structurizr/domain/view/view.dart' hide Routing;
import 'package:flutter_structurizr/presentation/rendering/relationships/arrow_style.dart';
import 'package:flutter_structurizr/presentation/rendering/relationships/relationship_renderer.dart';

import 'mock_canvas.dart';

void main() {
  group('RelationshipRenderer', () {
    late RelationshipRenderer renderer;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = RelationshipRenderer();
      mockCanvas = MockCanvas();
    });

    test('calculateRelationshipPath creates direct path between elements', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      final path = renderer.calculateRelationshipPath(
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
      );

      // Path should not be empty
      expect(path.getBounds(), isNot(Rect.zero));
    });

    test('calculateRelationshipPath creates curved path between elements', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.curved,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      final path = renderer.calculateRelationshipPath(
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
      );

      // Path should not be empty
      expect(path.getBounds(), isNot(Rect.zero));
    });

    test('calculateRelationshipPath creates orthogonal path between elements', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.orthogonal,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      final path = renderer.calculateRelationshipPath(
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
      );

      // Path should not be empty
      expect(path.getBounds(), isNot(Rect.zero));
    });

    test('renderRelationship draws solid line correctly', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      renderer.renderRelationship(
        canvas: mockCanvas,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        selected: false,
      );

      // Solid line should be drawn as a path
      expect(mockCanvas.drawnPaths.isNotEmpty, true,
          reason: 'Solid relationship line should be drawn as a path');
    });

    test('renderRelationship draws dashed line correctly', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.dashed,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      renderer.renderRelationship(
        canvas: mockCanvas,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        selected: false,
      );

      // Dashed line should be drawn as a path
      expect(mockCanvas.drawnPaths.isNotEmpty, true,
          reason: 'Dashed relationship line should be drawn as a path');
    });

    test('renderRelationship draws dotted line correctly', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.dotted,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      renderer.renderRelationship(
        canvas: mockCanvas,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        selected: false,
      );

      // Dotted line should produce circles to be drawn
      expect(mockCanvas.drawnCircles.isNotEmpty, true,
          reason: 'Dotted relationship line should draw circles');
    });

    test('renderRelationship handles selection state', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
        technology: 'HTTP',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      renderer.renderRelationship(
        canvas: mockCanvas,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        selected: true, // Selected
      );

      // Two paths should be drawn - one for the relationship, one for the selection highlight
      expect(mockCanvas.drawnPaths.length, greaterThanOrEqualTo(2),
          reason: 'Selected relationship should draw with highlight');
    });

    test('hitTestRelationship returns true when point is close to the line', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      // Calculate a point that should be on or very close to the direct line
      final sourceMidpoint = sourceRect.center;
      final targetMidpoint = targetRect.center;
      final midpoint = Offset(
        (sourceMidpoint.dx + targetMidpoint.dx) / 2,
        (sourceMidpoint.dy + targetMidpoint.dy) / 2,
      );

      final result = renderer.hitTestRelationship(
        point: midpoint,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        hitTolerance: 10.0,
      );

      expect(result, true);
    });

    test('hitTestRelationship returns false when point is far from the line', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses',
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.direct,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      // A point that should be far from the line
      final farPoint = Offset(500, 500);

      final result = renderer.hitTestRelationship(
        point: farPoint,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        hitTolerance: 10.0,
      );

      expect(result, false);
    });

    test('renderRelationship draws text for relationship description', () {
      final relationship = Relationship(
        id: 'rel1',
        sourceId: 'src1',
        destinationId: 'dest1',
        description: 'Uses API', // Non-empty description
      );

      final relationshipView = RelationshipView(
        id: 'rel1',
      );

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
        style: styles.LineStyle.solid,
        routing: styles.Routing.direct,
        fontSize: 12,
      );

      final sourceRect = Rect.fromLTWH(10, 10, 100, 80);
      final targetRect = Rect.fromLTWH(200, 150, 100, 80);

      renderer.renderRelationship(
        canvas: mockCanvas,
        relationship: relationship,
        relationshipView: relationshipView,
        style: style,
        sourceRect: sourceRect,
        targetRect: targetRect,
        selected: false,
      );

      // Expect the path for the line to be drawn
      expect(mockCanvas.drawnPaths.isNotEmpty, true,
          reason: 'Relationship line should be drawn');

      // While we can't directly test TextPainter usage in our mock,
      // we can verify the canvas save() method is called when text is drawn
    });
  });

  group('ArrowStyle', () {
    late ArrowStyle arrowStyle;
    late MockCanvas mockCanvas;

    setUp(() {
      arrowStyle = const ArrowStyle();
      mockCanvas = MockCanvas();
    });

    test('drawArrowhead draws a path for the arrowhead', () {
      final position = Offset(100, 100);
      final angle = 0.0; // Pointing right

      final style = const styles.RelationshipStyle(
        color: Colors.black,
        thickness: 1,
      );

      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      arrowStyle.drawArrowhead(
        mockCanvas,
        position,
        angle,
        style,
        paint,
      );

      // An arrowhead should be drawn as a path
      expect(mockCanvas.drawnPaths.isNotEmpty, true,
          reason: 'Arrowhead should be drawn as a path');
    });
  });
}