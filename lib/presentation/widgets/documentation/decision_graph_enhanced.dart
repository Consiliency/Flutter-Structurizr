import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// Represents a type of relationship between decisions
enum DecisionRelationshipType {
  related,
  supersedes,
  supersededBy,
  depends,
  dependedBy,
  conflicts,
  enables,
}

/// A relationship between two decisions with a specific type
class DecisionRelationship {
  final String sourceId;
  final String targetId;
  final DecisionRelationshipType type;

  const DecisionRelationship({
    required this.sourceId,
    required this.targetId,
    this.type = DecisionRelationshipType.related,
  });

  /// Helper method to get a descriptive string for the relationship type
  String get description {
    switch (type) {
      case DecisionRelationshipType.related:
        return 'Related to';
      case DecisionRelationshipType.supersedes:
        return 'Supersedes';
      case DecisionRelationshipType.supersededBy:
        return 'Superseded by';
      case DecisionRelationshipType.depends:
        return 'Depends on';
      case DecisionRelationshipType.dependedBy:
        return 'Depended on by';
      case DecisionRelationshipType.conflicts:
        return 'Conflicts with';
      case DecisionRelationshipType.enables:
        return 'Enables';
    }
  }

  /// Helper method to get a color for the relationship type
  Color getColor(bool isDarkMode) {
    switch (type) {
      case DecisionRelationshipType.related:
        return isDarkMode ? Colors.blue.shade300 : Colors.blue;
      case DecisionRelationshipType.supersedes:
        return isDarkMode ? Colors.green.shade300 : Colors.green;
      case DecisionRelationshipType.supersededBy:
        return isDarkMode ? Colors.red.shade300 : Colors.red;
      case DecisionRelationshipType.depends:
        return isDarkMode ? Colors.orange.shade300 : Colors.orange;
      case DecisionRelationshipType.dependedBy:
        return isDarkMode ? Colors.purple.shade300 : Colors.purple;
      case DecisionRelationshipType.conflicts:
        return isDarkMode ? Colors.red.shade300 : Colors.red;
      case DecisionRelationshipType.enables:
        return isDarkMode ? Colors.teal.shade300 : Colors.teal;
    }
  }
}

/// Represents a cluster of decisions
class DecisionCluster {
  final List<String> decisionIds;
  final String label;
  final Color color;

  const DecisionCluster({
    required this.decisionIds,
    required this.label,
    required this.color,
  });
}

/// An enhanced graph visualization for architecture decisions that supports
/// relationship types, tooltips, and clustering.
class EnhancedDecisionGraph extends StatefulWidget {
  /// The list of decisions to display.
  final List<Decision> decisions;

  /// Called when a decision is selected.
  final Function(int) onDecisionSelected;

  /// Whether to use dark mode styling.
  final bool isDarkMode;

  /// Optional list of relationships between decisions with types.
  /// If not provided, relationships will be inferred from decision.links.
  final List<DecisionRelationship>? relationships;

  /// Optional list of clusters to group decisions.
  final List<DecisionCluster>? clusters;

  /// Whether to enable tooltips on relationships.
  final bool enableTooltips;

  /// Creates a new enhanced decision graph.
  const EnhancedDecisionGraph({
    Key? key,
    required this.decisions,
    required this.onDecisionSelected,
    this.isDarkMode = false,
    this.relationships,
    this.clusters,
    this.enableTooltips = true,
  }) : super(key: key);

  @override
  State<EnhancedDecisionGraph> createState() => _EnhancedDecisionGraphState();
}

class _EnhancedDecisionGraphState extends State<EnhancedDecisionGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Force simulation parameters
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _velocities = {};
  final double _springLength = 150.0;
  final double _springStrength = 0.5;
  final double _repulsionStrength = 1000.0;
  final double _damping = 0.8;

  // Cluster parameters
  final Map<String, Offset> _clusterCenters = {};
  final double _clusterForceStrength = 0.3;

  bool _isSimulating = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Tooltip state
  String? _hoveredRelationshipId;
  Offset? _tooltipPosition;

  // Inferred relationships from decision links
  late List<DecisionRelationship> _effectiveRelationships;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        if (_isSimulating) {
          _simulateStep();
          setState(() {});
        }
      });

    _inferRelationships();
    _controller.repeat();
    _initializePositions();
  }

  @override
  void didUpdateWidget(EnhancedDecisionGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.decisions != widget.decisions ||
        oldWidget.relationships != widget.relationships ||
        oldWidget.clusters != widget.clusters) {
      _inferRelationships();
      _initializePositions();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Infer relationships from decision links if not explicitly provided
  void _inferRelationships() {
    if (widget.relationships != null) {
      _effectiveRelationships = List.from(widget.relationships!);
      return;
    }

    // Infer relationships from decision links
    _effectiveRelationships = [];

    final Map<String, Decision> decisionMap = {
      for (final d in widget.decisions) d.id: d
    };

    for (final decision in widget.decisions) {
      for (final linkedId in decision.links) {
        // Skip if the linked decision doesn't exist
        if (!decisionMap.containsKey(linkedId)) continue;

        // Infer relationship type based on dates
        final linkedDecision = decisionMap[linkedId]!;
        DecisionRelationshipType type;

        if (decision.date.isAfter(linkedDecision.date)) {
          if (decision.status == 'Superseded' &&
              linkedDecision.status == 'Accepted') {
            type = DecisionRelationshipType.supersededBy;
          } else {
            type = DecisionRelationshipType.depends;
          }
        } else {
          if (linkedDecision.status == 'Superseded' &&
              decision.status == 'Accepted') {
            type = DecisionRelationshipType.supersedes;
          } else {
            type = DecisionRelationshipType.related;
          }
        }

        _effectiveRelationships.add(DecisionRelationship(
          sourceId: decision.id,
          targetId: linkedId,
          type: type,
        ));
      }
    }
  }

  void _initializePositions() {
    // Clear existing positions
    _positions.clear();
    _velocities.clear();
    _clusterCenters.clear();

    // Initialize positions in a circle
    const centerX = 0.0;
    const centerY = 0.0;
    const radius = 200.0;

    // Initialize cluster centers if clusters are defined
    if (widget.clusters != null) {
      final clusterCount = widget.clusters!.length;
      for (var i = 0; i < clusterCount; i++) {
        final cluster = widget.clusters![i];
        final angle = 2 * math.pi * i / clusterCount;

        _clusterCenters[cluster.label] = Offset(
          centerX + radius * 2 * math.cos(angle),
          centerY + radius * 2 * math.sin(angle),
        );
      }
    }

    // First, initialize decisions that are part of clusters
    if (widget.clusters != null) {
      for (final cluster in widget.clusters!) {
        final clusterCenter = _clusterCenters[cluster.label]!;
        final decisionCount = cluster.decisionIds.length;

        for (var i = 0; i < decisionCount; i++) {
          final decisionId = cluster.decisionIds[i];
          final angle = 2 * math.pi * i / decisionCount;
          const clusterRadius = 100.0;

          _positions[decisionId] = Offset(
            clusterCenter.dx + clusterRadius * math.cos(angle),
            clusterCenter.dy + clusterRadius * math.sin(angle),
          );

          _velocities[decisionId] = Offset.zero;
        }
      }
    }

    // Then initialize remaining decisions
    var remainingDecisions = widget.decisions
        .where((decision) => !_positions.containsKey(decision.id))
        .toList();

    for (var i = 0; i < remainingDecisions.length; i++) {
      final decision = remainingDecisions[i];
      final angle = 2 * math.pi * i / remainingDecisions.length;

      _positions[decision.id] = Offset(
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      );

      _velocities[decision.id] = Offset.zero;
    }
  }

  void _simulateStep() {
    // Calculate forces
    final forces = <String, Offset>{};
    for (final decision in widget.decisions) {
      forces[decision.id] = Offset.zero;
    }

    // Calculate spring forces (attraction between linked decisions)
    for (final relationship in _effectiveRelationships) {
      // Skip if either decision doesn't exist in positions
      if (!_positions.containsKey(relationship.sourceId) ||
          !_positions.containsKey(relationship.targetId)) {
        continue;
      }

      final pos1 = _positions[relationship.sourceId]!;
      final pos2 = _positions[relationship.targetId]!;

      final delta = pos2 - pos1;
      final distance = delta.distance;

      // Avoid division by zero
      if (distance < 0.1) continue;

      final direction = delta / distance;

      // Calculate spring force (F = k * (x - rest_length))
      final springForce =
          direction * (distance - _springLength) * _springStrength;

      forces[relationship.sourceId] =
          forces[relationship.sourceId]! + springForce;
      forces[relationship.targetId] =
          forces[relationship.targetId]! - springForce;
    }

    // Calculate cluster attraction forces if clusters are defined
    if (widget.clusters != null) {
      for (final cluster in widget.clusters!) {
        final clusterCenter = _clusterCenters[cluster.label]!;

        for (final decisionId in cluster.decisionIds) {
          if (!_positions.containsKey(decisionId)) continue;

          final pos = _positions[decisionId]!;
          final delta = clusterCenter - pos;
          final distance = delta.distance;

          // Avoid division by zero
          if (distance < 0.1) continue;

          final direction = delta / distance;

          // Calculate cluster attraction force
          final clusterForce = direction * distance * _clusterForceStrength;

          forces[decisionId] = forces[decisionId]! + clusterForce;
        }
      }
    }

    // Calculate repulsion forces (repulsion between all decisions)
    for (var i = 0; i < widget.decisions.length; i++) {
      final decision1 = widget.decisions[i];

      if (!_positions.containsKey(decision1.id)) continue;

      for (var j = i + 1; j < widget.decisions.length; j++) {
        final decision2 = widget.decisions[j];

        if (!_positions.containsKey(decision2.id)) continue;

        final pos1 = _positions[decision1.id]!;
        final pos2 = _positions[decision2.id]!;

        final delta = pos2 - pos1;
        final distance = delta.distance;

        // Avoid division by zero
        if (distance < 1.0) continue;

        final direction = delta / distance;

        // Calculate repulsion force (F = k / r^2)
        final repulsionForce =
            direction * (-_repulsionStrength / (distance * distance));

        forces[decision1.id] = forces[decision1.id]! + repulsionForce;
        forces[decision2.id] = forces[decision2.id]! - repulsionForce;
      }
    }

    // Update velocities and positions
    var stable = true;
    for (final decision in widget.decisions) {
      // Skip if the decision doesn't have a position or velocity yet
      if (!_positions.containsKey(decision.id) ||
          !_velocities.containsKey(decision.id)) {
        continue;
      }

      // Apply damping to velocity
      var velocity = _velocities[decision.id]! * _damping;

      // Apply force to velocity (F = ma, a = F/m, v = v + a)
      if (forces.containsKey(decision.id)) {
        velocity += forces[decision.id]! / 5.0; // Mass = 5.0
      }

      // Update velocity
      _velocities[decision.id] = velocity;

      // Update position
      final pos = _positions[decision.id]!;
      _positions[decision.id] = pos + velocity;

      // Check if simulation is stable
      if (velocity.distance > 0.1) {
        stable = false;
      }
    }

    // Stop simulation if stable
    if (stable && _isSimulating) {
      setState(() {
        _isSimulating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      child: Stack(
        children: [
          // Zooming and panning control with InteractiveViewer
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(500),
            minScale: 0.1,
            maxScale: 2.0,
            child: Stack(
              children: [
                // Draw cluster backgrounds if clusters are defined
                if (widget.clusters != null)
                  ...widget.clusters!.map((cluster) {
                    // Find bounds of all decisions in this cluster
                    final decisionPositions = cluster.decisionIds
                        .where((id) => _positions.containsKey(id))
                        .map((id) => _positions[id]!)
                        .toList();

                    if (decisionPositions.isEmpty) {
                      return const SizedBox();
                    }

                    // Find min/max coordinates to determine bounds
                    double minX = double.infinity;
                    double minY = double.infinity;
                    double maxX = double.negativeInfinity;
                    double maxY = double.negativeInfinity;

                    for (final pos in decisionPositions) {
                      minX = math.min(minX, pos.dx);
                      minY = math.min(minY, pos.dy);
                      maxX = math.max(maxX, pos.dx);
                      maxY = math.max(maxY, pos.dy);
                    }

                    // Add padding around the cluster
                    const padding = 50.0;
                    minX -= padding;
                    minY -= padding;
                    maxX += padding;
                    maxY += padding;

                    return Positioned(
                      left: minX,
                      top: minY,
                      width: maxX - minX,
                      height: maxY - minY,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cluster.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cluster.color.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cluster.color.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cluster.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                // Custom painter for relationship edges
                CustomPaint(
                  size: Size.infinite,
                  painter: EnhancedDecisionGraphPainter(
                    decisions: widget.decisions,
                    relationships: _effectiveRelationships,
                    positions: _positions,
                    isDarkMode: widget.isDarkMode,
                    hoveredRelationshipId: _hoveredRelationshipId,
                  ),
                ),

                // Decision nodes
                ...widget.decisions.map((decision) {
                  // Skip if position isn't calculated yet
                  if (!_positions.containsKey(decision.id)) {
                    return const SizedBox();
                  }

                  // Calculate position
                  final pos = _positions[decision.id]!;

                  // Map status to color
                  Color statusColor;
                  switch (decision.status.toLowerCase()) {
                    case 'proposed':
                      statusColor = Colors.orange;
                      break;
                    case 'accepted':
                      statusColor = Colors.green;
                      break;
                    case 'superseded':
                      statusColor = Colors.purple;
                      break;
                    case 'deprecated':
                      statusColor = Colors.red;
                      break;
                    case 'rejected':
                      statusColor = Colors.red.shade900;
                      break;
                    default:
                      statusColor = Colors.blue;
                  }

                  return Positioned(
                    left: pos.dx - 75, // Center the 150px wide box
                    top: pos.dy - 40, // Center the box vertically
                    child: GestureDetector(
                      onTap: () {
                        final index = widget.decisions.indexOf(decision);
                        widget.onDecisionSelected(index);
                      },
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? Colors.grey.shade800
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.7),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isDarkMode
                                  ? Colors.black54
                                  : Colors.black12,
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    decision.id,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              decision.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(decision.date),
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Relationship tooltips
                if (widget.enableTooltips &&
                    _hoveredRelationshipId != null &&
                    _tooltipPosition != null)
                  Positioned(
                    left: _tooltipPosition!.dx,
                    top: _tooltipPosition!.dy -
                        40, // Position above the mouse pointer
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Colors.grey.shade800
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          const BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getRelationshipDescription(_hoveredRelationshipId!),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Controls overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom controls
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    setState(() {
                      _scale = _scale * 1.2;
                    });
                  },
                  backgroundColor:
                      widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Icon(
                    Icons.add,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    setState(() {
                      _scale = _scale / 1.2;
                    });
                  },
                  backgroundColor:
                      widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Icon(
                    Icons.remove,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_reset',
                  onPressed: () {
                    setState(() {
                      _scale = 1.0;
                      _offset = Offset.zero;
                    });
                  },
                  backgroundColor:
                      widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Icon(
                    Icons.refresh,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Simulation controls
                FloatingActionButton.small(
                  heroTag: 'simulation_toggle',
                  onPressed: () {
                    setState(() {
                      _isSimulating = !_isSimulating;
                      if (_isSimulating && !_controller.isAnimating) {
                        _controller.repeat();
                      }
                    });
                  },
                  backgroundColor:
                      widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
                  child: Icon(
                    _isSimulating ? Icons.pause : Icons.play_arrow,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Cluster legend if clusters are defined
          if (widget.clusters != null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.grey.shade800.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clusters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.clusters!.map((cluster) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: cluster.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cluster.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Relationship type legend
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.grey.shade800.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Relationship Types',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...DecisionRelationshipType.values.map((type) {
                    final relationship = DecisionRelationship(
                      sourceId: '',
                      targetId: '',
                      type: type,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 3,
                            color: relationship.getColor(widget.isDarkMode),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            relationship.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getRelationshipDescription(String relationshipId) {
    // Parse the relationship ID (format: "source_target_type")
    final parts = relationshipId.split('_');
    if (parts.length < 3) return 'Related to';

    final sourceId = parts[0];
    final targetId = parts[1];

    // Find the relationship in the effective relationships
    final relationship = _effectiveRelationships.firstWhere(
      (r) => r.sourceId == sourceId && r.targetId == targetId,
      orElse: () => DecisionRelationship(
        sourceId: sourceId,
        targetId: targetId,
      ),
    );

    // Get source and target decision titles
    final source = widget.decisions.firstWhere(
      (d) => d.id == sourceId,
      orElse: () => Decision(
        id: sourceId,
        date: DateTime.now(),
        status: 'Unknown',
        title: sourceId,
        content: '',
      ),
    );

    final target = widget.decisions.firstWhere(
      (d) => d.id == targetId,
      orElse: () => Decision(
        id: targetId,
        date: DateTime.now(),
        status: 'Unknown',
        title: targetId,
        content: '',
      ),
    );

    return '${source.title} ${relationship.description.toLowerCase()} ${target.title}';
  }
}

/// Custom painter for drawing the relationships between decisions
class EnhancedDecisionGraphPainter extends CustomPainter {
  final List<Decision> decisions;
  final List<DecisionRelationship> relationships;
  final Map<String, Offset> positions;
  final bool isDarkMode;
  final String? hoveredRelationshipId;

  EnhancedDecisionGraphPainter({
    required this.decisions,
    required this.relationships,
    required this.positions,
    this.isDarkMode = false,
    this.hoveredRelationshipId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw edges
    for (final relationship in relationships) {
      // Skip if either decision doesn't exist in positions
      if (!positions.containsKey(relationship.sourceId) ||
          !positions.containsKey(relationship.targetId)) {
        continue;
      }

      final startPos = positions[relationship.sourceId]!;
      final endPos = positions[relationship.targetId]!;

      // Generate a unique ID for this relationship for hover detection
      final relationshipId =
          '${relationship.sourceId}_${relationship.targetId}_${relationship.type.index}';
      final isHovered = hoveredRelationshipId == relationshipId;

      // Get relationship color
      final color = relationship.getColor(isDarkMode);

      // Create paint for the line
      final paint = Paint()
        ..color = isHovered ? color : color.withValues(alpha: 0.7)
        ..strokeWidth = isHovered ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;

      // For some relationship types, use dashed line style
      switch (relationship.type) {
        case DecisionRelationshipType.supersededBy:
        case DecisionRelationshipType.conflicts:
          _drawDashedLine(canvas, startPos, endPos, paint);
          break;
        default:
          canvas.drawLine(startPos, endPos, paint);
      }

      // Draw arrow
      _drawArrow(canvas, startPos, endPos, color, isHovered);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final count = math.sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace);
    final vx = dx / count;
    final vy = dy / count;

    final dashPath = Path();
    var x = start.dx;
    var y = start.dy;

    dashPath.moveTo(x, y);

    for (int i = 0; i < count; i++) {
      x += vx;
      y += vy;
      if (i % 2 == 0) {
        dashPath.lineTo(x, y);
      } else {
        dashPath.moveTo(x, y);
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  void _drawArrow(
      Canvas canvas, Offset start, Offset end, Color color, bool isHovered) {
    final paint = Paint()
      ..color = isHovered ? color : color.withValues(alpha: 0.7)
      ..strokeWidth = isHovered ? 2.0 : 1.0
      ..style = PaintingStyle.fill;

    // Calculate arrow direction
    final delta = end - start;
    final direction = delta / delta.distance;

    // Calculate arrow position (80% along the line)
    final arrowPos = start + direction * (delta.distance * 0.8);

    // Calculate perpendicular direction
    final perpendicular = Offset(-direction.dy, direction.dx);

    // Calculate arrow points
    final arrowSize = isHovered ? 12.0 : 10.0;
    final point1 = arrowPos;
    final point2 =
        arrowPos - direction * arrowSize + perpendicular * (arrowSize * 0.5);
    final point3 =
        arrowPos - direction * arrowSize - perpendicular * (arrowSize * 0.5);

    // Draw arrow
    final path = Path()
      ..moveTo(point1.dx, point1.dy)
      ..lineTo(point2.dx, point2.dy)
      ..lineTo(point3.dx, point3.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(EnhancedDecisionGraphPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.decisions != decisions ||
        oldDelegate.relationships != relationships ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.hoveredRelationshipId != hoveredRelationshipId;
  }
}
