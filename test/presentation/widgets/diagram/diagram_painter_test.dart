import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter_structurizr/domain/model/element.dart';
import 'package:flutter_structurizr/domain/model/workspace.dart';
import 'package:flutter_structurizr/domain/style/styles.dart';
import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter_structurizr/presentation/layout/layout_strategy.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/diagram_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagramPainter', () {
    // Test data
    late Workspace workspace;
    late View view;
    late DiagramPainter painter;
    
    setUp(() {
      // Create a simple workspace with some elements and relationships
      workspace = Workspace(
        id: 'test',
        name: 'Test Workspace',
        description: 'Test workspace for diagram painter tests',
        model: WorkspaceModel(
          people: [
            Person(
              id: 'user',
              name: 'User',
              description: 'A user of the system',
            ),
          ],
          softwareSystems: [
            SoftwareSystem(
              id: 'system',
              name: 'Software System',
              description: 'The software system',
            ),
            SoftwareSystem(
              id: 'external',
              name: 'External System',
              description: 'An external system',
            ),
          ],
          relationships: [
            Relationship(
              id: 'rel1',
              sourceId: 'user',
              destinationId: 'system',
              description: 'Uses',
            ),
            Relationship(
              id: 'rel2',
              sourceId: 'system',
              destinationId: 'external',
              description: 'Gets data from',
            ),
          ],
        ),
        views: WorkspaceViews(
          configuration: ViewConfiguration(
            styles: Styles(
              elements: [
                ElementStyle(
                  tag: 'Person',
                  shape: 'Person',
                  background: '#08427B',
                  color: '#FFFFFF',
                ),
                ElementStyle(
                  tag: 'Software System',
                  shape: 'RoundedBox',
                  background: '#1168BD',
                  color: '#FFFFFF',
                ),
              ],
              relationships: [
                RelationshipStyle(
                  tag: 'Relationship',
                  color: '#707070',
                  thickness: 2,
                ),
              ],
            ),
          ),
        ),
      );
      
      // Create a simple view with fixed positions for testing
      view = SystemContextView(
        key: 'test-view',
        softwareSystemId: 'system',
        description: 'Test view',
        elements: [
          ElementView(
            id: 'user',
            x: 100,
            y: 100,
            width: 120,
            height: 160,
          ),
          ElementView(
            id: 'system',
            x: 300,
            y: 300,
            width: 200,
            height: 100,
          ),
          ElementView(
            id: 'external',
            x: 600,
            y: 300,
            width: 200,
            height: 100,
          ),
        ],
        relationships: [
          RelationshipView(
            id: 'rel1',
          ),
          RelationshipView(
            id: 'rel2',
          ),
        ],
      );
      
      // Create the painter
      painter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: Offset.zero,
      );
    });
    
    test('should initialize renderers correctly', () {
      // Not much we can test directly, but we can verify the painter exists
      expect(painter, isNotNull);
    });
    
    test('getBoundingBox should return correct rect', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // Now check bounding box - it should contain all elements
      final boundingBox = painter.getBoundingBox();
      
      // The bounding box should contain all elements
      expect(boundingBox.left, lessThanOrEqualTo(100)); // user x position
      expect(boundingBox.top, lessThanOrEqualTo(100)); // user y position
      expect(boundingBox.right, greaterThanOrEqualTo(800)); // external x + width
      expect(boundingBox.bottom, greaterThanOrEqualTo(400)); // system y + height
    });
    
    test('hitTest should detect elements correctly', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // Test hit testing for user element
      final userHit = painter.hitTest(const Offset(150, 150));
      expect(userHit.type, HitTestResultType.element);
      expect(userHit.id, 'user');
      expect(userHit.element, isNotNull);
      expect(userHit.element?.name, 'User');
      
      // Test hit testing for system element
      final systemHit = painter.hitTest(const Offset(350, 350));
      expect(systemHit.type, HitTestResultType.element);
      expect(systemHit.id, 'system');
      expect(systemHit.element, isNotNull);
      expect(systemHit.element?.name, 'Software System');
      
      // Test hit testing for background (no element)
      final backgroundHit = painter.hitTest(const Offset(50, 50));
      expect(backgroundHit.type, HitTestResultType.none);
    });
    
    test('hitTest should detect relationships', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // For relationship hit test, we need to hit a point on the relationship path
      // This is highly dependent on the actual rendering implementation
      // We'll test multiple points along the likely path between user and system
      
      // Try several points along the path from user to system
      bool foundRelationship = false;
      for (int i = 0; i < 10; i++) {
        // Calculate points along the potential path
        final point = Offset(
          160 + (300 - 160) * i / 10, 
          180 + (300 - 180) * i / 10
        );
        
        final result = painter.hitTest(point);
        if (result.type == HitTestResultType.relationship) {
          foundRelationship = true;
          expect(result.id, 'rel1');
          expect(result.relationship, isNotNull);
          break;
        }
      }
      
      // We should be able to hit the relationship at least once
      // If the test fails, the relationship hit testing may need adjustment
      expect(foundRelationship, isTrue, reason: 'Could not hit test any point on relationship path');
    });
    
    test('getElementRect should return correct rect for element', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // Get rectangle for user element
      final userRect = painter.getElementRect('user');
      expect(userRect, isNotNull);
      expect(userRect!.left, equals(100));
      expect(userRect.top, equals(100));
      expect(userRect.width, equals(120));
      expect(userRect.height, equals(160));
      
      // Get rectangle for nonexistent element
      final nonexistentRect = painter.getElementRect('nonexistent');
      expect(nonexistentRect, isNull);
    });
    
    test('shouldRepaint should return true when properties change', () {
      // Initial painter
      final initialPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: Offset.zero,
      );
      
      // Changed zoom scale
      final zoomChangedPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 2.0,
        panOffset: Offset.zero,
      );
      expect(initialPainter.shouldRepaint(zoomChangedPainter), isTrue);
      
      // Changed pan offset
      final panChangedPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: const Offset(100, 100),
      );
      expect(initialPainter.shouldRepaint(panChangedPainter), isTrue);
      
      // Changed selected ID
      final selectionChangedPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: Offset.zero,
        selectedId: 'user',
      );
      expect(initialPainter.shouldRepaint(selectionChangedPainter), isTrue);
      
      // No changes
      final identicalPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: Offset.zero,
      );
      expect(initialPainter.shouldRepaint(identicalPainter), isFalse);
    });
    
    test('paint handles null layout strategy gracefully', () {
      // Test that painting with a null layout strategy doesn't crash
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      final nullLayoutPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        layoutStrategy: null,
      );
      
      // Should not throw
      expect(() => nullLayoutPainter.paint(canvas, const Size(800, 600)), returnsNormally);
    });
    
    test('paint handles custom layout strategy', () {
      // Create a mock layout strategy
      final mockLayoutStrategy = _MockLayoutStrategy();
      
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      final customLayoutPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        layoutStrategy: mockLayoutStrategy,
      );
      
      // Should not throw and should use the mock layout
      expect(() => customLayoutPainter.paint(canvas, const Size(800, 600)), returnsNormally);
    });
    
    test('handles hovered elements', () {
      // Create painter with hovered element
      final hoveredPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        hoveredId: 'user',
      );
      
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Should not throw when rendering with hover
      expect(() => hoveredPainter.paint(canvas, const Size(800, 600)), returnsNormally);
    });
    
    test('handles animation steps', () {
      // Create a view with animation steps
      final animatedView = SystemContextView(
        key: 'animated-view',
        softwareSystemId: 'system',
        description: 'Animated test view',
        elements: view.elements,
        relationships: view.relationships,
        animations: [
          const AnimationStep(
            order: 1,
            elements: ['user'],
            relationships: [],
          ),
          const AnimationStep(
            order: 2,
            elements: ['user', 'system'],
            relationships: ['rel1'],
          ),
          const AnimationStep(
            order: 3,
            elements: ['user', 'system', 'external'],
            relationships: ['rel1', 'rel2'],
          ),
        ],
      );
      
      // Create painter with animation step
      final animatedPainter = DiagramPainter(
        view: animatedView,
        workspace: workspace,
        animationStep: 1, // Show only user
      );
      
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Should not throw when rendering with animation step
      expect(() => animatedPainter.paint(canvas, const Size(800, 600)), returnsNormally);
    });
  });
}

// Mock layout strategy for testing
class _MockLayoutStrategy implements LayoutStrategy {
  final Map<String, Offset> _positions = {};
  
  @override
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    // Simple layout - place elements in a grid
    int col = 0;
    int row = 0;
    final maxCol = 3;
    const spacing = 200.0;
    
    for (final element in elementViews) {
      _positions[element.id] = Offset(
        col * spacing + 100,
        row * spacing + 100,
      );
      
      col++;
      if (col >= maxCol) {
        col = 0;
        row++;
      }
    }
    
    return _positions;
  }
  
  @override
  Rect getBoundingBox() {
    if (_positions.isEmpty) return Rect.zero;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final pos in _positions.values) {
      minX = math.min(minX, pos.dx);
      minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + 200); // Assuming width
      maxY = math.max(maxY, pos.dy + 200); // Assuming height
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  @override
  Rect calculateBoundingBox() {
    return getBoundingBox();
  }
}