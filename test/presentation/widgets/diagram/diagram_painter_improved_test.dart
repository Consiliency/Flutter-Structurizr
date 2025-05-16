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
  group('DiagramPainter - Improved Tests', () {
    // Test data
    late Workspace workspace;
    late View view;
    late DiagramPainter painter;
    
    setUp(() {
      // Create a simple workspace with well-defined elements and relationships
      workspace = Workspace(
        id: 1, // Use numeric ID
        name: 'Test Workspace',
        description: 'Test workspace for diagram painter tests',
        model: Model(
          people: [
            Person.create(
              name: 'User',
              description: 'A user of the system',
            ),
          ],
          softwareSystems: [
            SoftwareSystem.create(
              name: 'Software System',
              description: 'The software system',
            ),
            SoftwareSystem.create(
              name: 'External System',
              description: 'An external system',
            ),
          ],
        ),
      );
      
      // Get element IDs for making relationships
      final user = workspace.model.people.first;
      final system = workspace.model.softwareSystems.first;
      final externalSystem = workspace.model.softwareSystems.last;
      
      // Add relationships to the model through the elements to ensure proper registration
      final updatedUser = user.addRelationship(
        destinationId: system.id,
        description: 'Uses',
      );
      
      final updatedSystem = system.addRelationship(
        destinationId: externalSystem.id,
        description: 'Gets data from',
      );
      
      // Update model with the elements that have relationships
      final updatedModel = workspace.model.copyWith(
        people: [updatedUser],
        softwareSystems: [
          updatedSystem,
          externalSystem,
        ],
      );
      
      workspace = workspace.copyWith(model: updatedModel);
      
      // Get relationship IDs for the view
      final rel1 = updatedUser.getRelationshipsWithDestination(system.id).first.id;
      final rel2 = updatedSystem.getRelationshipsWithDestination(externalSystem.id).first.id;
      
      // Create a simple view with fixed positions for testing
      view = SystemContextView(
        key: 'test-view',
        softwareSystemId: system.id,
        description: 'Test view',
        elements: [
          ElementView(id: user.id, x: 100, y: 100, width: 120, height: 160),
          ElementView(id: system.id, x: 300, y: 300, width: 200, height: 100),
          ElementView(id: externalSystem.id, x: 600, y: 300, width: 200, height: 100),
        ],
        relationships: [
          RelationshipView(id: rel1),
          RelationshipView(id: rel2),
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
    
    test('relationship hit testing with more sampling points', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // For relationship hit testing, we'll test more thoroughly
      // by creating a grid of points between elements
      
      // Get element rectangles
      final user = painter.getElementRect(workspace.model.people.first.id);
      final system = painter.getElementRect(workspace.model.softwareSystems.first.id);
      
      expect(user, isNotNull);
      expect(system, isNotNull);
      
      if (user != null && system != null) {
        // Calculate center points of each element
        final userCenter = user.center;
        final systemCenter = system.center;
        
        // Sample points along the path with tighter spacing
        bool foundRelationship = false;
        int sampleCount = 30; // More sample points
        
        for (int i = 0; i <= sampleCount; i++) {
          // Calculate points along the potential path
          final t = i / sampleCount;
          final point = Offset(
            userCenter.dx + (systemCenter.dx - userCenter.dx) * t,
            userCenter.dy + (systemCenter.dy - userCenter.dy) * t
          );
          
          // Skip points that are inside elements
          if (user.contains(point) || system.contains(point)) {
            continue;
          }
          
          final result = painter.hitTest(point);
          if (result.type == HitTestResultType.relationship) {
            foundRelationship = true;
            expect(result.relationship, isNotNull);
            
            // Extract relationship IDs from the model for comparison
            final expectedRelId = workspace.model.people.first
                .getRelationshipsWithDestination(workspace.model.softwareSystems.first.id).first.id;
            
            expect(result.id, equals(expectedRelId));
            break;
          }
        }
        
        // We should be able to hit the relationship with our more thorough approach
        expect(foundRelationship, isTrue, reason: 'Could not hit test any point on relationship path');
      }
    });
    
    test('relationship hit testing with perpendicular distance', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // Get element rectangles
      final user = painter.getElementRect(workspace.model.people.first.id);
      final system = painter.getElementRect(workspace.model.softwareSystems.first.id);
      
      expect(user, isNotNull);
      expect(system, isNotNull);
      
      if (user != null && system != null) {
        // Calculate center points of each element
        final userCenter = user.center;
        final systemCenter = system.center;
        
        // Calculate a line between the centers of the two elements
        final lineAngle = math.atan2(
          systemCenter.dy - userCenter.dy,
          systemCenter.dx - userCenter.dx
        );
        
        // Create points that are slightly off the direct line
        // This tests if the relationship hit testing considers perpendicular distance
        bool foundRelationship = false;
        
        // Find a point in the middle, offset from the line
        final midPoint = Offset(
          (userCenter.dx + systemCenter.dx) / 2,
          (userCenter.dy + systemCenter.dy) / 2
        );
        
        // Create several points perpendicular to the line at different distances
        const offsets = [5.0, 10.0, 15.0, 20.0]; // Perpendicular distances to test
        
        for (final offset in offsets) {
          // Calculate perpendicular points (both sides of the line)
          final perpOffset1 = Offset(
            midPoint.dx + offset * math.sin(lineAngle),
            midPoint.dy - offset * math.cos(lineAngle)
          );
          
          final perpOffset2 = Offset(
            midPoint.dx - offset * math.sin(lineAngle),
            midPoint.dy + offset * math.cos(lineAngle)
          );
          
          // Test both sides of the line
          for (final point in [perpOffset1, perpOffset2]) {
            final result = painter.hitTest(point);
            if (result.type == HitTestResultType.relationship) {
              foundRelationship = true;
              expect(result.relationship, isNotNull);
              
              // Extract relationship ID from the model for comparison
              final expectedRelId = workspace.model.people.first
                  .getRelationshipsWithDestination(workspace.model.softwareSystems.first.id).first.id;
              
              expect(result.id, equals(expectedRelId));
              break;
            }
          }
          
          if (foundRelationship) break;
        }
        
        // We should be able to hit the relationship with this approach
        expect(foundRelationship, isTrue, 
          reason: 'Could not hit test relationship with perpendicular distance approach');
      }
    });
    
    test('relationship hit detection for curved relationships', () {
      // Get relationship IDs
      final rel1 = workspace.model.people.first
          .getRelationshipsWithDestination(workspace.model.softwareSystems.first.id).first.id;
      final rel2 = workspace.model.softwareSystems.first
          .getRelationshipsWithDestination(workspace.model.softwareSystems.last.id).first.id;
      
      // Create a new view with curved relationships
      final curvedView = view.copyWith(
        relationships: [
          RelationshipView(id: rel1, routing: Routing.curved),
          RelationshipView(id: rel2, routing: Routing.curved),
        ],
      );
      
      // Create a painter with the curved view
      final curvedPainter = DiagramPainter(
        view: curvedView,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: Offset.zero,
      );
      
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      curvedPainter.paint(canvas, const Size(800, 600));
      
      // Get element rectangles
      final user = curvedPainter.getElementRect(workspace.model.people.first.id);
      final system = curvedPainter.getElementRect(workspace.model.softwareSystems.first.id);
      
      expect(user, isNotNull);
      expect(system, isNotNull);
      
      if (user != null && system != null) {
        // For curved relationships, we need to test more points
        // There is no simple formula for curve points, so we'll sample many points in the area
        
        // Define a bounding area between elements to sample points
        final bounds = Rect.fromLTRB(
          math.min(user.left, system.left),
          math.min(user.top, system.top),
          math.max(user.right, system.right),
          math.max(user.bottom, system.bottom)
        );
        
        // Sample points in a grid pattern throughout the bounding area
        bool foundCurvedRelationship = false;
        const gridSize = 15; // Number of sample points in each dimension
        
        for (int x = 0; x < gridSize; x++) {
          for (int y = 0; y < gridSize; y++) {
            // Calculate a point in the grid
            final point = Offset(
              bounds.left + (bounds.width / gridSize) * x,
              bounds.top + (bounds.height / gridSize) * y
            );
            
            // Skip points that are inside elements
            if (user.contains(point) || system.contains(point)) {
              continue;
            }
            
            final result = curvedPainter.hitTest(point);
            if (result.type == HitTestResultType.relationship) {
              foundCurvedRelationship = true;
              expect(result.relationship, isNotNull);
              
              // Extract relationship ID for comparison
              // This could be either relationship since we're sampling the whole area
              final validRelIds = [rel1, rel2];
              expect(validRelIds.contains(result.id), isTrue);
              
              // One hit is enough to verify functionality
              break;
            }
          }
          if (foundCurvedRelationship) break;
        }
        
        // We should be able to hit at least one curved relationship
        expect(foundCurvedRelationship, isTrue,
          reason: 'Could not hit test any point on curved relationship paths');
      }
    });
    
    test('relationship hit detection for orthogonal relationships', () {
      // Get relationship IDs
      final rel1 = workspace.model.people.first
          .getRelationshipsWithDestination(workspace.model.softwareSystems.first.id).first.id;
      final rel2 = workspace.model.softwareSystems.first
          .getRelationshipsWithDestination(workspace.model.softwareSystems.last.id).first.id;
      
      // Create a new view with orthogonal relationships
      final orthoView = view.copyWith(
        relationships: [
          RelationshipView(id: rel1, routing: Routing.orthogonal),
          RelationshipView(id: rel2, routing: Routing.orthogonal),
        ],
      );
      
      // Create a painter with the orthogonal view
      final orthoPainter = DiagramPainter(
        view: orthoView,
        workspace: workspace,
        zoomScale: 1.0,
        panOffset: Offset.zero,
      );
      
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      orthoPainter.paint(canvas, const Size(800, 600));
      
      // Get element rectangles
      final user = orthoPainter.getElementRect(workspace.model.people.first.id);
      final system = orthoPainter.getElementRect(workspace.model.softwareSystems.first.id);
      
      expect(user, isNotNull);
      expect(system, isNotNull);
      
      if (user != null && system != null) {
        // For orthogonal relationships, we need to test horizontal and vertical segments
        
        // Test midpoints of expected orthogonal path segments
        bool foundOrthogonalRelationship = false;
        
        // Calculate midpoints of element sides
        final userBottom = Offset(user.center.dx, user.bottom);
        final userRight = Offset(user.right, user.center.dy);
        final systemTop = Offset(system.center.dx, system.top);
        final systemLeft = Offset(system.left, system.center.dy);
        
        // Calculate potential orthogonal path points
        // Basic approach: sample points along candidate orthogonal paths
        final samplePoints = <Offset>[];
        
        // Option 1: User bottom → System top (vertical then horizontal)
        final midX1 = userBottom.dx;
        final midY1 = (userBottom.dy + systemTop.dy) / 2;
        samplePoints.add(Offset(midX1, midY1)); // Vertical segment
        samplePoints.add(Offset((midX1 + systemTop.dx) / 2, midY1)); // Horizontal segment
        
        // Option 2: User right → System left (horizontal then vertical)
        final midY2 = userRight.dy;
        final midX2 = (userRight.dx + systemLeft.dx) / 2;
        samplePoints.add(Offset(midX2, midY2)); // Horizontal segment
        samplePoints.add(Offset(midX2, (midY2 + systemLeft.dy) / 2)); // Vertical segment
        
        // Test each sample point
        for (final point in samplePoints) {
          final result = orthoPainter.hitTest(point);
          if (result.type == HitTestResultType.relationship) {
            foundOrthogonalRelationship = true;
            expect(result.relationship, isNotNull);
            expect(result.id, equals(rel1));
            break;
          }
        }
        
        // We should be able to hit at least one segment of the orthogonal relationship
        expect(foundOrthogonalRelationship, isTrue,
          reason: 'Could not hit test any point on orthogonal relationship paths');
      }
    });
    
    test('hit test respects zoom scale and pan offset', () {
      // Create a painter with zoom and pan
      final zoomedPanPainter = DiagramPainter(
        view: view,
        workspace: workspace,
        zoomScale: 2.0, // Zoom in
        panOffset: const Offset(100, 100), // Pan
      );
      
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      zoomedPanPainter.paint(canvas, const Size(800, 600));
      
      // With zoom scale 2.0 and pan offset (100,100),
      // The user element's position would be transformed from (100,100) to:
      // ((100 * 2.0) + 100, (100 * 2.0) + 100) = (300, 300)
      
      // Test hit testing at this transformed position
      final result = zoomedPanPainter.hitTest(const Offset(350, 350)); // Inside transformed user element
      
      // Should hit the user element
      expect(result.type, equals(HitTestResultType.element));
      expect(result.id, equals(workspace.model.people.first.id));
      expect(result.element, isNotNull);
      expect(result.element?.name, equals('User'));
    });
    
    test('multi-hit test works for element bounding boxes', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // Create a selection rect that bounds multiple elements
      final selectionRect = Rect.fromLTRB(50, 50, 400, 400);
      
      // Perform multi-hit test
      final result = painter.multiHitTest(selectionRect);
      
      // Should hit both user and system elements
      expect(result.elementIds.length, equals(2));
      expect(result.elementIds, contains(workspace.model.people.first.id));
      expect(result.elementIds, contains(workspace.model.softwareSystems.first.id));
      
      // Relationship hits may vary depending on implementation,
      // but we're primarily testing elements here
    });
    
    test('multi-hit test works for relationships', () {
      // Mock the canvas for painting to trigger layout calculation
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Paint to trigger layout calculation
      painter.paint(canvas, const Size(800, 600));
      
      // Create a selection rect that should intersect the relationship
      // between user and system (based on their positions)
      final userElement = painter.getElementRect(workspace.model.people.first.id)!;
      final systemElement = painter.getElementRect(workspace.model.softwareSystems.first.id)!;
      
      // Create a selection rect in the area between user and system
      final selectionRect = Rect.fromLTRB(
        userElement.center.dx,
        userElement.bottom - 10,
        systemElement.center.dx,
        systemElement.top + 10
      );
      
      // Perform multi-hit test
      final result = painter.multiHitTest(selectionRect);
      
      // Get the expected relationship ID
      final rel1 = workspace.model.people.first
          .getRelationshipsWithDestination(workspace.model.softwareSystems.first.id).first.id;
      
      // Should hit the relationship between user and system
      expect(result.relationshipIds.length, greaterThanOrEqualTo(1), 
        reason: 'Should detect at least one relationship in selection area');
      expect(result.relationshipIds, contains(rel1),
        reason: 'Should detect relationship between user and system');
    });
  });
}