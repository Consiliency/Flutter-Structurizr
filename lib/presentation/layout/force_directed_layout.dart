import 'dart:math';

import 'package:flutter_structurizr/domain/view/model_view.dart';
import 'package:flutter_structurizr/util/import_helper.dart';

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

    // TODO: Replace with proper logging or remove for production

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
      if (element.hasParent) {
        parentToChildren
            .putIfAbsent(element.parentId!, () => [])
            .add(element.id);
      }
    }

    // Store the boundary information
    _boundaries.addAll(parentToChildren);

    // TODO: Replace with proper logging or remove for production

    // Debug output for boundary information
    if (_boundaries.isNotEmpty) {
      // TODO: Replace with proper logging or remove for production
    }
  }

  /// Calculate repulsive forces between all elements
  void _calculateRepulsiveForces(List<ElementView> elementViews) {
    // Apply repulsion between all pairs of elements
    final ids = _positions.keys.toList();

    for (int i = 0; i < ids.length; i++) {
      final id1 = ids[i];
      final pos1 = _positions[id1]!;
      final size1 =
          _sizes[id1] ?? const Size(100, 100); // Default if size not available

      for (int j = i + 1; j < ids.length; j++) {
        final id2 = ids[j];
        final pos2 = _positions[id2]!;
        final size2 = _sizes[id2] ??
            const Size(100, 100); // Default if size not available

        // Calculate element centers
        final center1 = pos1 + Offset(size1.width / 2, size1.height / 2);
        final center2 = pos2 + Offset(size2.width / 2, size2.height / 2);

        // Vector from element2 to element1
        final dx = center1.dx - center2.dx;
        final dy = center1.dy - center2.dy;

        // Distance between centers
        double distance = sqrt(dx * dx + dy * dy);
        distance = max(distance, minDistance); // Prevent division by zero

        // Consider element sizes to prevent overlap
        final minSeparation =
            (size1.width + size2.width + size1.height + size2.height) / 4;
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

      // Skip if either element is not in our layout or IDs are null
      if (sourceId == null ||
          destinationId == null ||
          !_positions.containsKey(sourceId) ||
          !_positions.containsKey(destinationId)) {
        continue;
      }

      final sourcePos = _positions[sourceId]!;
      final destPos = _positions[destinationId]!;
      final sourceSize = _sizes[sourceId] ?? const Size(100, 100);
      final destSize = _sizes[destinationId] ?? const Size(100, 100);

      // Calculate element centers
      final sourceCenter =
          sourcePos + Offset(sourceSize.width / 2, sourceSize.height / 2);
      final destCenter =
          destPos + Offset(destSize.width / 2, destSize.height / 2);

      // Vector from source to destination
      final dx = destCenter.dx - sourceCenter.dx;
      final dy = destCenter.dy - sourceCenter.dy;

      // Distance between centers
      double distance = sqrt(dx * dx + dy * dy);
      distance = max(distance, minDistance); // Prevent division by zero

      // Calculate ideal distance based on element sizes
      final idealDistance = (sourceSize.width +
              destSize.width +
              sourceSize.height +
              destSize.height) /
          3;

      // Calculate spring force using Hooke's law: F = k * (d - rest_length)
      final displacement = distance - idealDistance;
      final force = springConstant * displacement;

      // Normalize the direction vector
      final normDx = dx / distance;
      final normDy = dy / distance;

      // Apply force to both elements in opposite directions
      _forces[sourceId] =
          _forces[sourceId]! + Offset(normDx * force, normDy * force);
      _forces[destinationId] =
          _forces[destinationId]! - Offset(normDx * force, normDy * force);
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
      final boundarySize = _sizes[boundaryId] ??
          const Size(400, 400); // Default if size not available

      // First, calculate the bounding box of all child elements
      Rect childrenBounds = _calculateChildrenBoundingBox(childrenIds);

      // Dynamically adjust boundary size based on children if needed
      Size adjustedBoundarySize = boundarySize;
      if (childrenBounds != Rect.zero) {
        // Ensure boundary is large enough to contain children with padding
        adjustedBoundarySize = Size(
            max(boundarySize.width,
                childrenBounds.width + 80.0), // 40px padding on each side
            max(boundarySize.height,
                childrenBounds.height + 80.0) // 40px padding on each side
            );
      }

      // Calculate boundary rectangle with padding
      const padding = 40.0; // Padding inside boundary
      final boundaryRect = Rect.fromLTWH(
          boundaryPos.dx + padding,
          boundaryPos.dy + padding,
          adjustedBoundarySize.width - 2 * padding,
          adjustedBoundarySize.height - 2 * padding);

      // Apply containment force to each child
      for (final childId in childrenIds) {
        // Skip if child is not in our layout
        if (!_positions.containsKey(childId)) {
          continue;
        }

        final childPos = _positions[childId]!;
        final childSize = _sizes[childId] ??
            const Size(100, 100); // Default if size not available

        // Calculate child rectangle
        final childRect = Rect.fromLTWH(
            childPos.dx, childPos.dy, childSize.width, childSize.height);

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
          distance = max(distance, minDistance); // Prevent division by zero

          // Calculate the nearest point on the boundary to pull the child toward
          Offset nearestPoint =
              _findNearestPointOnBoundary(childCenter, boundaryRect);
          Offset pullDirection = nearestPoint - childCenter;
          double pullDistance = pullDirection.distance;
          pullDistance =
              max(pullDistance, minDistance); // Prevent division by zero

          // Calculate containment force (stronger than normal forces)
          // Use a stronger force for elements that are further outside
          final outsideDistance =
              _calculateOutsideDistance(childRect, boundaryRect);
          final force = boundaryForce * (1.0 + outsideDistance / 100.0);

          // Normalize the pull direction vector
          final normPullDx = pullDirection.dx / pullDistance;
          final normPullDy = pullDirection.dy / pullDistance;

          // Apply containment force to the child
          _forces[childId] = _forces[childId]! +
              Offset(normPullDx * force, normPullDy * force);
        }

        // Also add a small force to separate children within the same boundary
        _applyChildSeparationForces(childId, childrenIds);
      }

      // Update boundary size based on children positions
      _updateBoundarySize(boundaryId, childrenIds);
    }
  }

  /// Calculate the bounding box of all child elements
  Rect _calculateChildrenBoundingBox(List<String> childrenIds) {
    if (childrenIds.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    bool foundAny = false;

    for (final childId in childrenIds) {
      if (_positions.containsKey(childId) && _sizes.containsKey(childId)) {
        foundAny = true;
        final childPos = _positions[childId]!;
        final childSize = _sizes[childId]!;

        minX = min(minX, childPos.dx);
        minY = min(minY, childPos.dy);
        maxX = max(maxX, childPos.dx + childSize.width);
        maxY = max(maxY, childPos.dy + childSize.height);
      }
    }

    if (!foundAny) {
      return Rect.zero;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calculate how far outside the boundary a child element is
  double _calculateOutsideDistance(Rect childRect, Rect boundaryRect) {
    double dx = 0.0;
    double dy = 0.0;

    // Calculate horizontal distance outside boundary
    if (childRect.left < boundaryRect.left) {
      dx = boundaryRect.left - childRect.left;
    } else if (childRect.right > boundaryRect.right) {
      dx = childRect.right - boundaryRect.right;
    }

    // Calculate vertical distance outside boundary
    if (childRect.top < boundaryRect.top) {
      dy = boundaryRect.top - childRect.top;
    } else if (childRect.bottom > boundaryRect.bottom) {
      dy = childRect.bottom - boundaryRect.bottom;
    }

    // Return the Euclidean distance
    return sqrt(dx * dx + dy * dy);
  }

  /// Find the nearest point on the boundary rectangle to a given point
  Offset _findNearestPointOnBoundary(Offset point, Rect boundary) {
    // Clamp point to boundary edges
    double x, y;

    if (point.dx < boundary.left) {
      x = boundary.left;
    } else if (point.dx > boundary.right) {
      x = boundary.right;
    } else {
      x = point.dx;
    }

    if (point.dy < boundary.top) {
      y = boundary.top;
    } else if (point.dy > boundary.bottom) {
      y = boundary.bottom;
    } else {
      y = point.dy;
    }

    // If the point is already inside the boundary, find the nearest edge
    if (boundary.contains(point)) {
      double distToLeft = (point.dx - boundary.left).abs();
      double distToRight = (boundary.right - point.dx).abs();
      double distToTop = (point.dy - boundary.top).abs();
      double distToBottom = (boundary.bottom - point.dy).abs();

      double minDist =
          min(min(distToLeft, distToRight), min(distToTop, distToBottom));

      if (minDist == distToLeft) {
        x = boundary.left;
      } else if (minDist == distToRight) {
        x = boundary.right;
      } else if (minDist == distToTop) {
        y = boundary.top;
      } else {
        y = boundary.bottom;
      }
    }

    return Offset(x, y);
  }

  /// Apply forces to separate children within the same boundary
  void _applyChildSeparationForces(String childId, List<String> siblingIds) {
    final childPos = _positions[childId]!;
    final childSize = _sizes[childId] ?? const Size(100, 100);
    final childCenter =
        childPos + Offset(childSize.width / 2, childSize.height / 2);

    for (final siblingId in siblingIds) {
      if (siblingId == childId || !_positions.containsKey(siblingId)) {
        continue;
      }

      final siblingPos = _positions[siblingId]!;
      final siblingSize = _sizes[siblingId] ?? const Size(100, 100);
      final siblingCenter =
          siblingPos + Offset(siblingSize.width / 2, siblingSize.height / 2);

      // Vector from sibling to child
      final dx = childCenter.dx - siblingCenter.dx;
      final dy = childCenter.dy - siblingCenter.dy;

      // Distance between centers
      double distance = sqrt(dx * dx + dy * dy);
      distance = max(distance, minDistance); // Prevent division by zero

      // Define minimum desired separation
      final minSeparation = (childSize.width +
              siblingSize.width +
              childSize.height +
              siblingSize.height) /
          5;

      // Apply a small separation force if siblings are too close
      if (distance < minSeparation) {
        final separation = (minSeparation - distance) / minSeparation;
        final separationForce = 5.0 * separation; // Small force constant

        // Normalize the direction vector
        final normDx = dx / distance;
        final normDy = dy / distance;

        // Apply separation force
        _forces[childId] = _forces[childId]! +
            Offset(normDx * separationForce, normDy * separationForce);
      }
    }
  }

  /// Update boundary size based on children positions
  void _updateBoundarySize(String boundaryId, List<String> childrenIds) {
    if (childrenIds.isEmpty) {
      return;
    }

    Rect childrenBounds = _calculateChildrenBoundingBox(childrenIds);

    if (childrenBounds == Rect.zero) {
      return;
    }

    // Add padding around children
    const padding = 40.0;
    final requiredWidth = childrenBounds.width + 2 * padding;
    final requiredHeight = childrenBounds.height + 2 * padding;

    // Get current boundary size
    final currentSize = _sizes[boundaryId] ?? const Size(400, 400);

    // Update size if needed
    if (requiredWidth > currentSize.width ||
        requiredHeight > currentSize.height) {
      _sizes[boundaryId] = Size(max(currentSize.width, requiredWidth),
          max(currentSize.height, requiredHeight));
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
      final size =
          _sizes[id] ?? const Size(100, 100); // Default if size not available

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

    // Working copy of element views that we'll update between phases
    var currentElementViews = List<ElementView>.from(elementViews);

    // Run each phase
    for (final layoutPhase in layouts) {
      // If we have positions from a previous phase, update the element views
      if (positions.isNotEmpty) {
        List<ElementView> updatedViews = [];

        for (final element in currentElementViews) {
          if (positions.containsKey(element.id)) {
            final position = positions[element.id]!;
            // Use extension method to create a new immutable copy with updated position
            updatedViews.add(element.copyWithPositionOffset(position));
          } else {
            updatedViews.add(element);
          }
        }

        // Update our working copy with the new immutable views
        currentElementViews = updatedViews;
      }

      // Run this layout phase with the current state of element views
      positions = layoutPhase.calculateLayout(
        elementViews: currentElementViews,
        relationshipViews: relationshipViews,
        canvasSize: canvasSize,
        elementSizes: elementSizes,
      );
    }

    return positions;
  }
}
