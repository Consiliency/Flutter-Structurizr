import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/documentation/documentation.dart';
import 'package:flutter_structurizr/presentation/widgets/documentation/decision_graph_enhanced.dart';

void main() {
  runApp(const DecisionGraphExampleApp());
}

class DecisionGraphExampleApp extends StatelessWidget {
  const DecisionGraphExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Decision Graph Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const DecisionGraphExample(),
    );
  }
}

class DecisionGraphExample extends StatefulWidget {
  const DecisionGraphExample({Key? key}) : super(key: key);

  @override
  State<DecisionGraphExample> createState() => _DecisionGraphExampleState();
}

class _DecisionGraphExampleState extends State<DecisionGraphExample>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showClusters = true;
  bool _showTooltips = true;
  bool _useDarkMode = false;
  int? _selectedDecisionIndex;

  // Sample decisions for the example
  final List<Decision> _decisions = [
    Decision(
      id: 'ADR-001',
      date: DateTime(2023, 1, 15),
      status: 'Accepted',
      title: 'Use Flutter for UI Framework',
      content: 'We will use Flutter for cross-platform UI development.',
      links: ['ADR-002', 'ADR-003', 'ADR-004'],
    ),
    Decision(
      id: 'ADR-002',
      date: DateTime(2023, 2, 10),
      status: 'Accepted',
      title: 'Adopt Clean Architecture',
      content: 'We will adopt Clean Architecture for separation of concerns.',
      links: ['ADR-005', 'ADR-006'],
    ),
    Decision(
      id: 'ADR-003',
      date: DateTime(2023, 3, 5),
      status: 'Proposed',
      title: 'Authentication Strategy',
      content: 'Proposed OAuth2 for authentication.',
      links: ['ADR-007'],
    ),
    Decision(
      id: 'ADR-004',
      date: DateTime(2023, 2, 20),
      status: 'Rejected',
      title: 'Use REST API Only',
      content: 'Proposal to use REST API exclusively was rejected.',
      links: ['ADR-008'],
    ),
    Decision(
      id: 'ADR-005',
      date: DateTime(2023, 4, 10),
      status: 'Accepted',
      title: 'Database Selection',
      content: 'We will use PostgreSQL for primary storage.',
      links: [],
    ),
    Decision(
      id: 'ADR-006',
      date: DateTime(2023, 4, 15),
      status: 'Accepted',
      title: 'Caching Strategy',
      content: 'Redis will be used for caching.',
      links: ['ADR-005'],
    ),
    Decision(
      id: 'ADR-007',
      date: DateTime(2023, 5, 1),
      status: 'Superseded',
      title: 'Initial Deployment Strategy',
      content: 'Initial plans for deployment via Docker containers.',
      links: ['ADR-009'],
    ),
    Decision(
      id: 'ADR-008',
      date: DateTime(2023, 5, 10),
      status: 'Accepted',
      title: 'GraphQL for Complex Queries',
      content: 'Use GraphQL for complex data requirements.',
      links: ['ADR-004'],
    ),
    Decision(
      id: 'ADR-009',
      date: DateTime(2023, 6, 5),
      status: 'Accepted',
      title: 'Kubernetes Deployment',
      content: 'Supersedes initial Docker-only strategy with Kubernetes.',
      links: ['ADR-007'],
    ),
  ];

  // Custom relationships with specific types
  late List<DecisionRelationship> _relationships;

  // Clusters for grouping related decisions
  late List<DecisionCluster> _clusters;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Define relationships with types
    _relationships = [
      const DecisionRelationship(
        sourceId: 'ADR-001',
        targetId: 'ADR-002',
        type: DecisionRelationshipType.enables,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-002',
        targetId: 'ADR-005',
        type: DecisionRelationshipType.depends,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-002',
        targetId: 'ADR-006',
        type: DecisionRelationshipType.depends,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-001',
        targetId: 'ADR-003',
        type: DecisionRelationshipType.related,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-001',
        targetId: 'ADR-004',
        type: DecisionRelationshipType.conflicts,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-004',
        targetId: 'ADR-008',
        type: DecisionRelationshipType.supersededBy,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-007',
        targetId: 'ADR-009',
        type: DecisionRelationshipType.supersededBy,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-005',
        targetId: 'ADR-006',
        type: DecisionRelationshipType.related,
      ),
      const DecisionRelationship(
        sourceId: 'ADR-003',
        targetId: 'ADR-007',
        type: DecisionRelationshipType.related,
      ),
    ];

    // Define clusters
    _clusters = [
      const DecisionCluster(
        decisionIds: ['ADR-001', 'ADR-002', 'ADR-003', 'ADR-004'],
        label: 'Architecture',
        color: Colors.blue,
      ),
      const DecisionCluster(
        decisionIds: ['ADR-005', 'ADR-006'],
        label: 'Data Storage',
        color: Colors.green,
      ),
      const DecisionCluster(
        decisionIds: ['ADR-007', 'ADR-009'],
        label: 'Deployment',
        color: Colors.orange,
      ),
      const DecisionCluster(
        decisionIds: ['ADR-008'],
        label: 'API',
        color: Colors.purple,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark || _useDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Architecture Decision Graph'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Enhanced Graph'),
            Tab(text: 'Basic Graph'),
            Tab(text: 'Selected Decision'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _useDarkMode = !_useDarkMode;
              });
            },
            tooltip:
                isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Enhanced graph tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Show Clusters'),
                      selected: _showClusters,
                      onSelected: (value) {
                        setState(() {
                          _showClusters = value;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Show Tooltips'),
                      selected: _showTooltips,
                      onSelected: (value) {
                        setState(() {
                          _showTooltips = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: EnhancedDecisionGraph(
                  decisions: _decisions,
                  onDecisionSelected: (index) {
                    setState(() {
                      _selectedDecisionIndex = index;
                      _tabController
                          .animateTo(2); // Switch to selected decision tab
                    });
                  },
                  isDarkMode: isDarkMode,
                  relationships: _relationships,
                  clusters: _showClusters ? _clusters : null,
                  enableTooltips: _showTooltips,
                ),
              ),
            ],
          ),

          // Basic graph tab - for comparison
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Basic Decision Graph (without clustering, types, or tooltips)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: DecisionGraph(
                  decisions: _decisions,
                  onDecisionSelected: (index) {
                    setState(() {
                      _selectedDecisionIndex = index;
                      _tabController
                          .animateTo(2); // Switch to selected decision tab
                    });
                  },
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),

          // Selected decision details tab
          _selectedDecisionIndex != null
              ? _buildDecisionDetails(
                  _decisions[_selectedDecisionIndex!], isDarkMode)
              : const Center(
                  child: Text(
                      'No decision selected. Tap on a decision in the graph.')),
        ],
      ),
    );
  }

  Widget _buildDecisionDetails(Decision decision, bool isDarkMode) {
    // Find related decisions based on relationships
    final relatedDecisions = <MapEntry<String, DecisionRelationshipType>>[];

    for (final relationship in _relationships) {
      if (relationship.sourceId == decision.id) {
        relatedDecisions.add(MapEntry(
          relationship.targetId,
          relationship.type,
        ));
      } else if (relationship.targetId == decision.id) {
        // Inverse the relationship type for incoming relationships
        DecisionRelationshipType inverseType;
        switch (relationship.type) {
          case DecisionRelationshipType.supersedes:
            inverseType = DecisionRelationshipType.supersededBy;
            break;
          case DecisionRelationshipType.supersededBy:
            inverseType = DecisionRelationshipType.supersedes;
            break;
          case DecisionRelationshipType.depends:
            inverseType = DecisionRelationshipType.dependedBy;
            break;
          case DecisionRelationshipType.dependedBy:
            inverseType = DecisionRelationshipType.depends;
            break;
          default:
            inverseType = relationship.type;
        }

        relatedDecisions.add(MapEntry(
          relationship.sourceId,
          inverseType,
        ));
      }
    }

    // Find which cluster this decision belongs to
    String? clusterLabel;
    Color? clusterColor;

    if (_showClusters) {
      for (final cluster in _clusters) {
        if (cluster.decisionIds.contains(decision.id)) {
          clusterLabel = cluster.label;
          clusterColor = cluster.color;
          break;
        }
      }
    }

    // Status color mapping
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  decision.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                decision.id,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              if (clusterLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: clusterColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    clusterLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _formatDate(decision.date),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            decision.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            decision.content,
            style: const TextStyle(fontSize: 16),
          ),
          if (relatedDecisions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Related Decisions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...relatedDecisions.map((entry) {
              final relatedId = entry.key;
              final relationType = entry.value;

              // Find the related decision
              final relatedDecision = _decisions.firstWhere(
                (d) => d.id == relatedId,
                orElse: () => Decision(
                  id: relatedId,
                  date: DateTime.now(),
                  status: 'Unknown',
                  title: relatedId,
                  content: '',
                ),
              );

              final relationship = DecisionRelationship(
                sourceId: '',
                targetId: '',
                type: relationType,
              );

              // Find relationship color
              final relationshipColor = relationship.getColor(isDarkMode);

              return ListTile(
                leading: Icon(
                  _getRelationshipIcon(relationType),
                  color: relationshipColor,
                ),
                title: Text(relatedDecision.title),
                subtitle: Text(relationship.description),
                trailing: Text(relatedDecision.status),
                onTap: () {
                  // Find the index of the related decision
                  final index = _decisions.indexWhere((d) => d.id == relatedId);
                  if (index >= 0) {
                    setState(() {
                      _selectedDecisionIndex = index;
                    });
                  }
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  IconData _getRelationshipIcon(DecisionRelationshipType type) {
    switch (type) {
      case DecisionRelationshipType.related:
        return Icons.link;
      case DecisionRelationshipType.supersedes:
        return Icons.upgrade;
      case DecisionRelationshipType.supersededBy:
        return Icons.history;
      case DecisionRelationshipType.depends:
        return Icons.call_received;
      case DecisionRelationshipType.dependedBy:
        return Icons.call_made;
      case DecisionRelationshipType.conflicts:
        return Icons.warning;
      case DecisionRelationshipType.enables:
        return Icons.check_circle_outline;
    }
  }
}

// For backward compatibility, include the original DecisionGraph
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

  // Force simulation parameters
  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );

    _initializePositions();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializePositions() {
    // Initialize positions in a circle
    const centerX = 0.0;
    const centerY = 0.0;
    const radius = 200.0;

    for (var i = 0; i < widget.decisions.length; i++) {
      final decision = widget.decisions[i];
      final angle = 2 * 3.14159 * i / widget.decisions.length;

      _positions[decision.id] = Offset(
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(500),
        minScale: 0.1,
        maxScale: 2.0,
        child: Stack(
          children: [
            // Custom painter for edges - basic version
            CustomPaint(
              size: Size.infinite,
              painter: _BasicDecisionGraphPainter(
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Basic painter for comparison
class _BasicDecisionGraphPainter extends CustomPainter {
  final List<Decision> decisions;
  final Map<String, Offset> positions;
  final bool isDarkMode;

  _BasicDecisionGraphPainter({
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
  bool shouldRepaint(_BasicDecisionGraphPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.decisions != decisions ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

// Math utility functions
class math {
  static double sin(double x) {
    return Math.sin(x);
  }

  static double cos(double x) {
    return Math.cos(x);
  }
}

class Math {
  static double sin(double x) {
    return math.sin(x);
  }

  static double cos(double x) {
    return math.cos(x);
  }
}
