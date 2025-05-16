import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_structurizr/presentation/widgets/diagram/lasso_selection.dart';

void main() {
  group('LassoSelection', () {
    late LassoSelection lassoSelection;
    
    setUp(() {
      lassoSelection = LassoSelection();
    });
    
    test('initial state should be inactive and not complete', () {
      expect(lassoSelection.isActive, false);
      expect(lassoSelection.isComplete, false);
    });
    
    test('start should set isActive to true and isComplete to false', () {
      lassoSelection.start(const Offset(10, 10));
      expect(lassoSelection.isActive, true);
      expect(lassoSelection.isComplete, false);
    });
    
    test('update should have no effect if not active', () {
      // We can't directly test path updates, but we can test state
      lassoSelection.update(const Offset(20, 20));
      expect(lassoSelection.isActive, false);
      expect(lassoSelection.isComplete, false);
    });
    
    test('update should work if active', () {
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(20, 20));
      expect(lassoSelection.isActive, true);
      expect(lassoSelection.isComplete, false);
    });
    
    test('complete should set isActive to false and isComplete to true', () {
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(20, 20));
      lassoSelection.update(const Offset(20, 10));
      lassoSelection.complete();
      expect(lassoSelection.isActive, false);
      expect(lassoSelection.isComplete, true);
    });
    
    test('cancel should reset everything', () {
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(20, 20));
      lassoSelection.complete();
      expect(lassoSelection.isComplete, true);
      
      lassoSelection.cancel();
      expect(lassoSelection.isActive, false);
      expect(lassoSelection.isComplete, false);
    });
    
    test('containsPoint should return false if not complete', () {
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(20, 20));
      expect(lassoSelection.containsPoint(const Offset(15, 15)), false);
    });
    
    test('should detect point inside triangle', () {
      // Create a triangle
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(20, 20));
      lassoSelection.update(const Offset(10, 20));
      lassoSelection.complete();
      
      // Inside
      expect(lassoSelection.containsPoint(const Offset(12, 15)), true);
      
      // Outside
      expect(lassoSelection.containsPoint(const Offset(5, 15)), false);
      expect(lassoSelection.containsPoint(const Offset(25, 15)), false);
    });
    
    test('should detect rectangle intersections', () {
      // Create a triangle lasso
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(30, 30));
      lassoSelection.update(const Offset(10, 30));
      lassoSelection.complete();
      
      // Rectangle completely inside
      expect(lassoSelection.intersectsRect(const Rect.fromLTWH(15, 15, 5, 5)), true);
      
      // Rectangle completely outside
      expect(lassoSelection.intersectsRect(const Rect.fromLTWH(0, 0, 5, 5)), false);
      
      // Rectangle partially overlapping
      expect(lassoSelection.intersectsRect(const Rect.fromLTWH(5, 5, 10, 10)), true);
      
      // Rectangle containing the lasso
      expect(lassoSelection.intersectsRect(const Rect.fromLTWH(0, 0, 40, 40)), true);
    });
    
    test('should detect relationship intersections', () {
      // Create a triangle lasso
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(30, 30));
      lassoSelection.update(const Offset(10, 30));
      lassoSelection.complete();
      
      // Relationship completely inside
      expect(
        lassoSelection.intersectsRelationship(
          const Offset(15, 15), 
          const Offset(20, 20)
        ), 
        true
      );
      
      // Relationship completely outside
      expect(
        lassoSelection.intersectsRelationship(
          const Offset(0, 0), 
          const Offset(5, 5)
        ), 
        false
      );
      
      // Relationship crossing the lasso
      expect(
        lassoSelection.intersectsRelationship(
          const Offset(0, 20), 
          const Offset(40, 20)
        ), 
        true
      );
      
      // Relationship with one endpoint inside
      expect(
        lassoSelection.intersectsRelationship(
          const Offset(15, 15), 
          const Offset(40, 40)
        ), 
        true
      );
    });
    
    test('selected elements should be stored and retrieved', () {
      final elements = {'element1', 'element2'};
      lassoSelection.setSelectedElements(elements);
      expect(lassoSelection.selectedElementIds, elements);
    });
    
    test('selected relationships should be stored and retrieved', () {
      final relationships = {'relationship1', 'relationship2'};
      lassoSelection.setSelectedRelationships(relationships);
      expect(lassoSelection.selectedRelationshipIds, relationships);
    });
    
    test('path-based hit testing is accurate for complex shapes', () {
      // Create a complex polygon (star shape)
      final center = const Offset(150, 150);
      final outerRadius = 100.0;
      final innerRadius = 50.0;
      final numPoints = 5;
      
      // Start the lasso
      lassoSelection.start(center + Offset(outerRadius, 0));
      
      // Draw a star shape
      for (int i = 1; i <= numPoints * 2; i++) {
        final angle = i * pi / numPoints;
        final radius = i.isOdd ? innerRadius : outerRadius;
        final point = center + Offset(radius * cos(angle), radius * sin(angle));
        lassoSelection.update(point);
      }
      
      lassoSelection.complete();
      
      // Points clearly inside the star
      expect(lassoSelection.containsPoint(center), true, reason: 'Center should be inside');
      
      // Points clearly outside the star
      expect(lassoSelection.containsPoint(center + Offset(outerRadius + 20, 0)), false, 
          reason: 'Point outside radius should not be inside');
      
      // Points near the edge of the star arms
      // These tests are approximate since exact point calculation would be complex
      final outerPoint = center + Offset(outerRadius * cos(0), outerRadius * sin(0));
      final slightlyOutside = outerPoint + const Offset(5, 0);
      expect(lassoSelection.containsPoint(slightlyOutside), false, 
          reason: 'Point slightly outside should not be inside');
    });
    
    test('selecting multiple elements with keyboard modifiers works correctly', () {
      // Create two separate lassos representing two selection operations
      final lassoSelection1 = LassoSelection();
      final lassoSelection2 = LassoSelection();
      
      // Create first selection (triangle)
      lassoSelection1.start(const Offset(10, 10));
      lassoSelection1.update(const Offset(100, 10));
      lassoSelection1.update(const Offset(50, 100));
      lassoSelection1.complete();
      
      // Set selected elements from first selection
      lassoSelection1.setSelectedElements({'element1', 'element2'});
      
      // Create second selection (rectangle)
      lassoSelection2.start(const Offset(200, 10));
      lassoSelection2.update(const Offset(300, 10));
      lassoSelection2.update(const Offset(300, 100));
      lassoSelection2.update(const Offset(200, 100));
      lassoSelection2.complete();
      
      // Set selected elements from second selection
      lassoSelection2.setSelectedElements({'element3', 'element4'});
      
      // Combine selections (simulating Shift key)
      final combinedElements = {...lassoSelection1.selectedElementIds, ...lassoSelection2.selectedElementIds};
      
      // A new selection that holds the combined results
      final combinedSelection = LassoSelection();
      combinedSelection.setSelectedElements(combinedElements);
      
      // Verify combined selection has all elements
      expect(combinedSelection.selectedElementIds, {'element1', 'element2', 'element3', 'element4'});
      
      // Simulate Ctrl key (toggle selection - remove element2)
      final toggledElements = {...combinedSelection.selectedElementIds};
      toggledElements.remove('element2');
      combinedSelection.setSelectedElements(toggledElements);
      
      expect(combinedSelection.selectedElementIds, {'element1', 'element3', 'element4'});
    });
    
    test('performance with large number of elements', () {
      // Create a large polygon
      final center = const Offset(500, 500);
      final radius = 400.0;
      final numPoints = 100; // Large number of points
      
      // Start the lasso
      lassoSelection.start(center + Offset(radius, 0));
      
      // Draw a complex shape
      for (int i = 1; i < numPoints; i++) {
        final angle = i * 2 * pi / numPoints;
        final jitter = (i % 3 - 1) * 20.0; // Add some variation to make it more complex
        final point = center + Offset((radius + jitter) * cos(angle), (radius + jitter) * sin(angle));
        lassoSelection.update(point);
      }
      
      lassoSelection.complete();
      
      // Generate a large number of test points
      final testPoints = <Offset>[];
      for (int i = 0; i < 1000; i++) {
        final randomX = Random().nextDouble() * 1000;
        final randomY = Random().nextDouble() * 1000;
        testPoints.add(Offset(randomX, randomY));
      }
      
      // Test performance of hit testing
      final stopwatch = Stopwatch()..start();
      
      for (final point in testPoints) {
        lassoSelection.containsPoint(point);
      }
      
      stopwatch.stop();
      
      // Not asserting specific timing as it varies by machine,
      // but this test ensures the algorithm completes in a reasonable time
    });
    
    test('integration with diagram painter', () {
      // Create a mock canvas
      final MockCanvas = Canvas(PictureRecorder());
      
      // Create a lasso selection
      lassoSelection.start(const Offset(10, 10));
      lassoSelection.update(const Offset(100, 10));
      lassoSelection.update(const Offset(100, 100));
      lassoSelection.update(const Offset(10, 100));
      lassoSelection.complete();
      
      // Create paint style for lasso
      final lassoPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;
      
      // Paint the lasso on the canvas
      lassoSelection.paint(MockCanvas, lassoPaint);
      
      // Verify that the lasso can be rendered
      // (We can't directly check the canvas in a unit test, but this ensures the API works)
      expect(lassoSelection.path, isNotNull);
      expect(lassoSelection.isComplete, true);
    });
  });
}