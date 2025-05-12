import 'dart:math';
import 'dart:ui';

import 'package:flutter_structurizr/domain/view/view.dart';
import 'package:flutter/material.dart' hide Element, Container, View;

/// A physics-based layout algorithm that positions elements using spring and repulsive forces.
/// 
/// This layout algorithm simulates physics to position diagram elements:
/// - Elements repel each other (repulsive force)
/// - Related elements attract each other via relationships (spring force)
/// - Boundaries contain their children with containment forces
/// - Damping reduces oscillation and helps the system reach equilibrium
class ForceDirectedLayout {
  /// Spring constant for relationships (attraction force)
  final double springConstant;
  
  /// Repulsion constant between elements (repulsive force)
  final double repulsionConstant;
  
  /// Damping factor to reduce oscillation (0.0-1.0)
  final double dampingFactor;
  
  /// Boundary containment force multiplier
  final double boundaryForce;
  
  /// Maximum iterations for the algorithm to run
  final int maxIterations;
  
  /// Energy threshold below which the system is considered stable
  final double energyThreshold;
  
  /// Minimum distance between elements to prevent division by zero
  final double minDistance;
  
  /// Maximum movement per iteration to prevent instability
  final double maxMovement;
  
  /// Random number generator for initial positions
  final Random _random = Random(42); // Fixed seed for reproducibility
  
  /// Map to store current positions of elements
  final Map<String, Offset> _positions = {};
  
  /// Map to store velocities of elements
  final Map<String, Offset> _velocities = {};
  
  /// Map to store forces acting on elements
  final Map<String, Offset> _forces = {};
  
  /// Map to store element sizes
  final Map<String, Size> _sizes = {};
  
  /// Map to store boundaries and their children
  final Map<String, List<String>> _boundaries = {};

  ForceDirectedLayout({
    this.springConstant = 0.05,
    this.repulsionConstant = 20000.0,
    this.dampingFactor = 0.85,
    this.boundaryForce = 1.5,
    this.maxIterations = 500,
    this.energyThreshold = 0.01,
    this.minDistance = 10.0,
    this.maxMovement = 100.0,
  });

  /// Calculate the layout for elements in the given diagram view
  /// Returns a map of element IDs to their calculated positions
  Map<String, Offset> calculateLayout({
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    // 1. Initialize positions and velocities
    _initializeLayout(elementViews, elementSizes, canvasSize);
    
    // 2. Identify boundaries and their children
    _identifyBoundaries(elementViews);
    
    // 3. Run the physics simulation
    double totalEnergy = double.infinity;
    int iterations = 0;
    
    while (totalEnergy > energyThreshold && iterations < maxIterations) {
      // Reset forces
      for (final id in _positions.keys) {
        _forces[id] = Offset.zero;
      }
      
      // Calculate repulsive forces between all elements
      _calculateRepulsiveForces(elementViews);
      
      // Calculate attractive forces along relationships
      _calculateAttractiveForces(relationshipViews);
      
      // Calculate boundary containment forces
      _calculateBoundaryForces();
      
      // Apply forces and update positions
      totalEnergy = _updatePositions();
      
      iterations++;
      
      // Optional: break early if movement is very small
      if (totalEnergy < energyThreshold / 10) {
        break;
      }
    }
    
    print('Force-directed layout: Completed in $iterations iterations with energy: $totalEnergy');
    
    // Return the calculated positions
    return Map.from(_positions);
  }

  /// Initialize element positions and velocities
  void _initializeLayout(
    List<ElementView> elementViews, 
    Map<String, Size> elementSizes,
    Size canvasSize,
  ) {
    _positions.clear();
    _velocities.clear();
    _forces.clear();
    _sizes.clear();
    
    // Store the element sizes
    _sizes.addAll(elementSizes);
    
    // Initialize positions - either use existing positions or random positions
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = min(canvasSize.width, canvasSize.height) * 0.4;
    
    for (final element in elementViews) {
      final id = element.id;
      
      // Use existing position if available, otherwise create initial position
      if (element.x != null && element.y != null) {
        _positions[id] = Offset(element.x!.toDouble(), element.y!.toDouble());
      } else {
        // Use a spiral layout for initial positions to avoid all elements starting at center
        final angle = _random.nextDouble() * 2 * pi;
        final distance = _random.nextDouble() * radius;
        final x = center.dx + cos(angle) * distance;
        final y = center.dy + sin(angle) * distance;
        
        _positions[id] = Offset(x, y);
      }
      
      // Initialize with zero velocity
      _velocities[id] = Offset.zero;
    }
  }

  /// Identify boundaries and their children
  void _identifyBoundaries(List<ElementView> elementViews) {
    _boundaries.clear();
    
    // First pass: find all elements with parent IDs
    Map<String, List<String>> parentToChildren = {};
    
    for (final element in elementViews) {
      if (element.parentId != null) {
        parentToChildren.putIfAbsent(element.parentId!, () => []).add(element.id);
      }
    }
    
    // Store the boundary information
    _boundaries.addAll(parentToChildren);
  }

  /// Calculate repulsive forces between all elements
  void _calculateRepulsiveForces(List<ElementView> elementViews) {
    // Apply repulsion between all pairs of elements
    final ids = _positions.keys.toList();
    
    for (int i = 0; i < ids.length; i++) {
      final id1 = ids[i];
      final pos1 = _positions[id1]!;
      final size1 = _sizes[id1] ?? Size(100, 100);  // Default if size not available
      
      for (int j = i + 1; j < ids.length; j++) {
        final id2 = ids[j];
        final pos2 = _positions[id2]!;
        final size2 = _sizes[id2] ?? Size(100, 100);  // Default if size not available
        
        // Calculate element centers
        final center1 = pos1 + Offset(size1.width / 2, size1.height / 2);
        final center2 = pos2 + Offset(size2.width / 2, size2.height / 2);
        
        // Vector from element2 to element1
        final dx = center1.dx - center2.dx;
        final dy = center1.dy - center2.dy;
        
        // Distance between centers
        double distance = sqrt(dx * dx + dy * dy);
        distance = max(distance, minDistance);  // Prevent division by zero
        
        // Consider element sizes to prevent overlap
        final minSeparation = (size1.width + size2.width + size1.height + size2.height) / 4;
        final repulsionMultiplier = minSeparation / distance;
        
        // Calculate repulsive force (inverse square law)
        final force = repulsionConstant / (distance * distance);
        
        // Normalize the direction vector
        final normDx = dx / distance;
        final normDy = dy / distance;
        
        // Apply force to both elements in opposite directions
        _forces[id1] = _forces[id1]! + Offset(normDx * force, normDy * force);
        _forces[id2] = _forces[id2]! - Offset(normDx * force, normDy * force);
      }
    }
  }

  /// Calculate attractive forces along relationships
  void _calculateAttractiveForces(List<RelationshipView> relationshipViews) {
    for (final relationship in relationshipViews) {
      final sourceId = relationship.sourceId;
      final destinationId = relationship.destinationId;
      
      // Skip if either element is not in our layout
      if (!_positions.containsKey(sourceId) || !_positions.containsKey(destinationId)) {
        continue;
      }
      
      final sourcePos = _positions[sourceId]!;
      final destPos = _positions[destinationId]!;
      final sourceSize = _sizes[sourceId] ?? Size(100, 100);
      final destSize = _sizes[destinationId] ?? Size(100, 100);
      
      // Calculate element centers
      final sourceCenter = sourcePos + Offset(sourceSize.width / 2, sourceSize.height / 2);
      final destCenter = destPos + Offset(destSize.width / 2, destSize.height / 2);
      
      // Vector from source to destination
      final dx = destCenter.dx - sourceCenter.dx;
      final dy = destCenter.dy - sourceCenter.dy;
      
      // Distance between centers
      double distance = sqrt(dx * dx + dy * dy);
      distance = max(distance, minDistance);  // Prevent division by zero
      
      // Calculate ideal distance based on element sizes
      final idealDistance = (sourceSize.width + destSize.width + sourceSize.height + destSize.height) / 3;
      
      // Calculate spring force using Hooke's law: F = k * (d - rest_length)
      final displacement = distance - idealDistance;
      final force = springConstant * displacement;
      
      // Normalize the direction vector
      final normDx = dx / distance;
      final normDy = dy / distance;
      
      // Apply force to both elements in opposite directions
      _forces[sourceId] = _forces[sourceId]! + Offset(normDx * force, normDy * force);
      _forces[destinationId] = _forces[destinationId]! - Offset(normDx * force, normDy * force);
    }
  }

  /// Calculate forces to keep elements inside their boundaries
  void _calculateBoundaryForces() {
    // Process each boundary and its children
    for (final entry in _boundaries.entries) {
      final boundaryId = entry.key;
      final childrenIds = entry.value;
      
      // Skip if boundary is not in our layout
      if (!_positions.containsKey(boundaryId)) {
        continue;
      }
      
      final boundaryPos = _positions[boundaryId]!;
      final boundarySize = _sizes[boundaryId] ?? Size(400, 400);  // Default if size not available
      
      // Calculate boundary rectangle with padding
      const padding = 40.0;  // Padding inside boundary
      final boundaryRect = Rect.fromLTWH(
        boundaryPos.dx + padding,
        boundaryPos.dy + padding,
        boundarySize.width - 2 * padding,
        boundarySize.height - 2 * padding
      );
      
      // Apply containment force to each child
      for (final childId in childrenIds) {
        // Skip if child is not in our layout
        if (!_positions.containsKey(childId)) {
          continue;
        }
        
        final childPos = _positions[childId]!;
        final childSize = _sizes[childId] ?? Size(100, 100);  // Default if size not available
        
        // Calculate child rectangle
        final childRect = Rect.fromLTWH(
          childPos.dx,
          childPos.dy,
          childSize.width,
          childSize.height
        );
        
        // Check if child is outside boundary and calculate containment force
        if (!boundaryRect.contains(childRect.topLeft) ||
            !boundaryRect.contains(childRect.topRight) ||
            !boundaryRect.contains(childRect.bottomLeft) ||
            !boundaryRect.contains(childRect.bottomRight)) {
          
          // Calculate center points
          final boundaryCenter = boundaryRect.center;
          final childCenter = childRect.center;
          
          // Vector from child to boundary center
          final dx = boundaryCenter.dx - childCenter.dx;
          final dy = boundaryCenter.dy - childCenter.dy;
          
          // Distance from child to boundary center
          double distance = sqrt(dx * dx + dy * dy);
          distance = max(distance, minDistance);  // Prevent division by zero
          
          // Calculate containment force (stronger than normal forces)
          final force = boundaryForce * (1.0 - distance / (boundaryRect.shortestSide / 2));
          
          // Normalize the direction vector
          final normDx = dx / distance;
          final normDy = dy / distance;
          
          // Apply containment force to the child
          _forces[childId] = _forces[childId]! + Offset(normDx * force, normDy * force);
        }
      }
    }
  }

  /// Apply forces to update positions and velocities
  /// Returns the total energy of the system
  double _updatePositions() {
    double totalEnergy = 0.0;
    
    for (final id in _positions.keys) {
      // Get current force, velocity, and position
      final force = _forces[id]!;
      final velocity = _velocities[id]!;
      final position = _positions[id]!;
      
      // Update velocity using force and damping
      final newVelocity = (velocity + force) * dampingFactor;
      
      // Calculate the movement magnitude and limit if necessary
      double movementMagnitude = newVelocity.distance;
      final movement = movementMagnitude <= maxMovement 
          ? newVelocity 
          : newVelocity * (maxMovement / movementMagnitude);
      
      // Update position
      final newPosition = position + movement;
      
      // Update stored values
      _velocities[id] = newVelocity;
      _positions[id] = newPosition;
      
      // Accumulate energy (kinetic energy: 0.5 * m * v^2, assuming m=1)
      totalEnergy += 0.5 * movement.distanceSquared;
    }
    
    return totalEnergy;
  }

  /// Helper method to calculate the bounding box of all elements
  Rect calculateBoundingBox() {
    if (_positions.isEmpty) {
      return Rect.zero;
    }
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final entry in _positions.entries) {
      final id = entry.key;
      final position = entry.value;
      final size = _sizes[id] ?? Size(100, 100);  // Default if size not available
      
      minX = min(minX, position.dx);
      minY = min(minY, position.dy);
      maxX = max(maxX, position.dx + size.width);
      maxY = max(maxY, position.dy + size.height);
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Helper method for optimization - approximates forces for large graphs using a quadtree
  /// This is a TODO for future performance improvements
  void _optimizeForLargeGraphs() {
    // This would implement Barnes-Hut algorithm or another optimization technique
    // for larger diagrams to reduce the O(n²) complexity of the force calculations
  }
}

/// Extension class for performance optimizations of force-directed layout
class ForceDirectedLayoutOptimizer {
  /// Apply layout in multiple phases with decreasing spring constants
  /// This helps avoid local minima and can produce better layouts
  static Map<String, Offset> multiPhaseLayout({
    required ForceDirectedLayout layout,
    required List<ElementView> elementViews,
    required List<RelationshipView> relationshipViews,
    required Size canvasSize,
    required Map<String, Size> elementSizes,
  }) {
    // Create a sequence of layout algorithms with different parameters
    final layouts = [
      // Initial phase with strong forces to quickly arrange elements
      ForceDirectedLayout(
        springConstant: 0.1,
        repulsionConstant: 30000.0,
        dampingFactor: 0.9,
        maxIterations: 100,
        energyThreshold: 0.1,
      ),
      // Fine-tuning phase with more balanced forces
      ForceDirectedLayout(
        springConstant: 0.05,
        repulsionConstant: 20000.0,
        dampingFactor: 0.85,
        maxIterations: 200,
        energyThreshold: 0.05,
      ),
      // Final phase with gentle forces for precise positioning
      ForceDirectedLayout(
        springConstant: 0.01,
        repulsionConstant: 10000.0,
        dampingFactor: 0.8,
        maxIterations: 200,
        energyThreshold: 0.01,
      ),
    ];
    
    // Start with initial positions (random or provided)
    Map<String, Offset> positions = {};
    
    // Run each phase
    for (final layoutPhase in layouts) {
      // If we have positions from a previous phase, update the element views
      if (positions.isNotEmpty) {
        for (final element in elementViews) {
          if (positions.containsKey(element.id)) {
            final position = positions[element.id]!;
            element.x = position.dx.round();
            element.y = position.dy.round();
          }
        }
      }
      
      // Run this layout phase
      positions = layoutPhase.calculateLayout(
        elementViews: elementViews,
        relationshipViews: relationshipViews,
        canvasSize: canvasSize,
        elementSizes: elementSizes,
      );
    }
    
    return positions;
  }
}