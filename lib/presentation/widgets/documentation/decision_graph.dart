import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';

/// A widget that displays a graph of decision relationships.
class DecisionGraph extends StatefulWidget {
  /// The list of decisions.
  final List<Decision> decisions;

  /// Called when a decision is selected.
  final Function(int) onDecisionSelected;

  /// Whether to use dark mode.
  final bool isDarkMode;

  /// Creates a new decision graph widget.
  const DecisionGraph({
    Key? key,
    required this.decisions,
    required this.onDecisionSelected,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<DecisionGraph> createState() => _DecisionGraphState();
}

class _DecisionGraphState extends State<DecisionGraph>
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

  bool _isSimulating = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

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

    _controller.repeat();
    _initializePositions();
  }

  @override
  void didUpdateWidget(DecisionGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.decisions != widget.decisions) {
      _initializePositions();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializePositions() {
    // Clear existing positions
    _positions.clear();
    _velocities.clear();

    // Initialize positions in a circle
    const centerX = 0.0;
    const centerY = 0.0;
    const radius = 200.0;

    for (var i = 0; i < widget.decisions.length; i++) {
      final decision = widget.decisions[i];
      final angle = 2 * 3.14159 * i / widget.decisions.length;

      _positions[decision.id] = Offset(
        centerX + radius * Math.cos(angle),
        centerY + radius * Math.sin(angle),
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
    for (final decision in widget.decisions) {
      for (final linkedId in decision.links) {
        // Skip if the linked decision doesn't exist
        if (!_positions.containsKey(linkedId) ||
            !_positions.containsKey(decision.id)) {
          continue;
        }

        final pos1 = _positions[decision.id]!;
        final pos2 = _positions[linkedId]!;

        final delta = pos2 - pos1;
        final distance = delta.distance;

        // Avoid division by zero
        if (distance < 0.1) continue;

        final direction = delta / distance;

        // Calculate spring force (F = k * (x - rest_length))
        final springForce =
            direction * (distance - _springLength) * _springStrength;

        forces[decision.id] = forces[decision.id]! + springForce;
        forces[linkedId] = forces[linkedId]! - springForce;
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
                // Custom painter for edges - only one CustomPaint widget in the hierarchy
                CustomPaint(
                  size: Size.infinite,
                  painter: DecisionGraphPainter(
                    decisions: widget.decisions,
                    positions: _positions,
                    isDarkMode: widget.isDarkMode,
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
                    left: pos.dx,
                    top: pos.dy,
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class DecisionGraphPainter extends CustomPainter {
  final List<Decision> decisions;
  final Map<String, Offset> positions;
  final bool isDarkMode;

  DecisionGraphPainter({
    required this.decisions,
    required this.positions,
    this.isDarkMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Calculate the center of the canvas
    final center = Offset(size.width / 2, size.height / 2);

    // Draw edges
    for (final decision in decisions) {
      // Skip if position isn't calculated yet
      if (!positions.containsKey(decision.id)) continue;

      // Calculate start position
      final startPos = positions[decision.id]!;

      // Draw connections to linked decisions
      for (final linkedId in decision.links) {
        // Skip if the linked decision doesn't exist
        if (!positions.containsKey(linkedId)) continue;

        // Calculate end position
        final endPos = positions[linkedId]!;

        // Draw the line
        canvas.drawLine(startPos, endPos, paint);

        // Draw arrow
        _drawArrow(canvas, startPos, endPos, isDarkMode);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, bool isDarkMode) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    // Calculate arrow direction
    final delta = end - start;
    final direction = delta / delta.distance;

    // Calculate arrow position (80% along the line)
    final arrowPos = start + direction * (delta.distance * 0.8);

    // Calculate perpendicular direction
    final perpendicular = Offset(-direction.dy, direction.dx);

    // Calculate arrow points
    final point1 = arrowPos;
    final point2 = arrowPos - direction * 10.0 + perpendicular * 5.0;
    final point3 = arrowPos - direction * 10.0 - perpendicular * 5.0;

    // Draw arrow
    final path = Path()
      ..moveTo(point1.dx, point1.dy)
      ..lineTo(point2.dx, point2.dy)
      ..lineTo(point3.dx, point3.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DecisionGraphPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.decisions != decisions ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

// Math utility functions
class Math {
  static double sin(double x) {
    return math.sin(x);
  }

  static double cos(double x) {
    return math.cos(x);
  }
}
