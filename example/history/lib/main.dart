import 'package:flutter/material.dart' hide Element, Container, View, Border;
import 'package:flutter_structurizr/application/command/history_manager.dart';
import 'package:flutter_structurizr/presentation/widgets/history/history_panel.dart';
import 'package:flutter_structurizr/presentation/widgets/history/history_toolbar.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structurizr History Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: const HistoryExamplePage(),
    );
  }
}

class HistoryExamplePage extends StatefulWidget {
  const HistoryExamplePage({Key? key}) : super(key: key);

  @override
  State<HistoryExamplePage> createState() => _HistoryExamplePageState();
}

class _HistoryExamplePageState extends State<HistoryExamplePage> {
  // Create a history manager
  final historyManager = HistoryManager(maxHistorySize: 50);

  // Simple model for demonstration
  final List<ElementData> elements = [];

  // Panel visibility
  bool _showHistoryPanel = true;

  // Drag state
  ElementData? _draggedElement;
  Offset? _dragStartPosition;

  // Selection state
  ElementData? _selectedElement;

  @override
  void initState() {
    super.initState();

    // Add some initial elements
    _addInitialElements();
  }

  void _addInitialElements() {
    // Add a few elements to demonstrate
    historyManager.beginTransaction();

    final element1 = ElementData(
      id: 'element1',
      name: 'Person',
      type: ElementType.person,
      position: const Offset(100, 150),
    );

    final element2 = ElementData(
      id: 'element2',
      name: 'System',
      type: ElementType.system,
      position: const Offset(350, 150),
    );

    _addElementWithCommand(element1);
    _addElementWithCommand(element2);

    _addRelationshipWithCommand(
      RelationshipData(
        id: 'rel1',
        sourceId: 'element1',
        destinationId: 'element2',
        description: 'Uses',
      ),
    );

    historyManager.commitTransaction('Add initial elements');
  }

  @override
  void dispose() {
    historyManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Structurizr History Example'),
        actions: [
          // Show/hide history panel
          IconButton(
            icon: Icon(
                _showHistoryPanel ? Icons.visibility_off : Icons.visibility),
            tooltip:
                _showHistoryPanel ? 'Hide History Panel' : 'Show History Panel',
            onPressed: () {
              setState(() {
                _showHistoryPanel = !_showHistoryPanel;
              });
            },
          ),

          // Undo/Redo toolbar
          HistoryToolbar(
            historyManager: historyManager,
            showLabels: true,
          ),
        ],
      ),
      body: HistoryKeyboardShortcuts(
        historyManager: historyManager,
        child: Row(
          children: [
            // Main diagram area
            Expanded(
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: Colors.grey[100],
                  ),

                  // Draw relationships
                  CustomPaint(
                    painter: RelationshipPainter(
                      elements: elements,
                    ),
                    size: Size.infinite,
                  ),

                  // Draw elements
                  for (final element in elements)
                    Positioned(
                      left: element.position.dx - 50,
                      top: element.position.dy - 50,
                      child: _buildElement(element),
                    ),
                ],
              ),
            ),

            // History panel
            if (_showHistoryPanel)
              SizedBox(
                width: 300,
                child: HistoryPanel(
                  historyManager: historyManager,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add person
          FloatingActionButton(
            heroTag: 'add_person',
            mini: true,
            tooltip: 'Add Person',
            onPressed: () {
              _addElementWithCommand(
                ElementData(
                  id: 'person${elements.length + 1}',
                  name: 'Person ${elements.length + 1}',
                  type: ElementType.person,
                  position: Offset(
                    150 + (elements.length * 10) % 300,
                    150 + (elements.length * 20) % 200,
                  ),
                ),
              );
            },
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 8),

          // Add system
          FloatingActionButton(
            heroTag: 'add_system',
            mini: true,
            tooltip: 'Add System',
            onPressed: () {
              _addElementWithCommand(
                ElementData(
                  id: 'system${elements.length + 1}',
                  name: 'System ${elements.length + 1}',
                  type: ElementType.system,
                  position: Offset(
                    350 + (elements.length * 10) % 300,
                    150 + (elements.length * 20) % 200,
                  ),
                ),
              );
            },
            child: const Icon(Icons.computer),
          ),
          const SizedBox(height: 8),

          // Add container
          FloatingActionButton(
            heroTag: 'add_container',
            mini: true,
            tooltip: 'Add Container',
            onPressed: () {
              _addElementWithCommand(
                ElementData(
                  id: 'container${elements.length + 1}',
                  name: 'Container ${elements.length + 1}',
                  type: ElementType.container,
                  position: Offset(
                    250 + (elements.length * 10) % 300,
                    250 + (elements.length * 20) % 200,
                  ),
                ),
              );
            },
            child: const Icon(Icons.storage),
          ),
          const SizedBox(height: 8),

          // Add relationship
          FloatingActionButton(
            heroTag: 'add_relationship',
            mini: true,
            tooltip: 'Add Relationship',
            onPressed: _selectedElement != null && elements.length > 1
                ? () {
                    // Find a target element different from the selected one
                    final targetElement = elements.firstWhere(
                      (e) => e.id != _selectedElement!.id,
                    );

                    _addRelationshipWithCommand(
                      RelationshipData(
                        id: 'rel${DateTime.now().millisecondsSinceEpoch}',
                        sourceId: _selectedElement!.id,
                        destinationId: targetElement.id,
                        description: 'Uses',
                      ),
                    );
                  }
                : null,
            child: const Icon(Icons.arrow_forward),
          ),
          const SizedBox(height: 8),

          // Remove selected
          FloatingActionButton(
            heroTag: 'remove',
            mini: true,
            tooltip: 'Remove Selected',
            onPressed: _selectedElement != null
                ? () {
                    _removeElementWithCommand(_selectedElement!);
                    _selectedElement = null;
                  }
                : null,
            child: const Icon(Icons.delete),
          ),
          const SizedBox(height: 8),

          // Edit name
          FloatingActionButton(
            heroTag: 'edit',
            mini: true,
            tooltip: 'Edit Name',
            onPressed: _selectedElement != null
                ? () {
                    _showEditNameDialog(_selectedElement!);
                  }
                : null,
            child: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildElement(ElementData element) {
    final isSelected = _selectedElement?.id == element.id;

    Widget elementWidget;

    switch (element.type) {
      case ElementType.person:
        elementWidget = _buildPersonElement(element, isSelected);
        break;
      case ElementType.system:
        elementWidget = _buildSystemElement(element, isSelected);
        break;
      case ElementType.container:
        elementWidget = _buildContainerElement(element, isSelected);
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedElement = element;
        });
      },
      onPanStart: (details) {
        setState(() {
          _draggedElement = element;
          _dragStartPosition = element.position;
        });
      },
      onPanUpdate: (details) {
        if (_draggedElement?.id == element.id) {
          // Update the element position directly
          setState(() {
            element.position = Offset(
              element.position.dx + details.delta.dx,
              element.position.dy + details.delta.dy,
            );
          });
        }
      },
      onPanEnd: (details) {
        if (_draggedElement?.id == element.id && _dragStartPosition != null) {
          // Create an undoable command for the position change
          historyManager.moveElement(
            element.id,
            _dragStartPosition!,
            element.position,
            (id, newPosition) {
              final element = elements.firstWhere((e) => e.id == id);
              setState(() {
                element.position = newPosition;
              });
            },
          );

          _draggedElement = null;
          _dragStartPosition = null;
        }
      },
      child: elementWidget,
    );
  }

  Widget _buildPersonElement(ElementData element, bool isSelected) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[600]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            element.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemElement(ElementData element, bool isSelected) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey[600]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: const Icon(
              Icons.computer,
              size: 40,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            element.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerElement(ElementData element, bool isSelected) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey[600]!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: const Icon(
              Icons.storage,
              size: 40,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            element.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(ElementData element) {
    final TextEditingController controller =
        TextEditingController(text: element.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Element Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final oldName = element.name;
              final newName = controller.text;

              if (oldName != newName) {
                historyManager.updateProperty<String>(
                  element.id,
                  'name',
                  oldName,
                  newName,
                  (id, property, value) {
                    final element = elements.firstWhere((e) => e.id == id);
                    setState(() {
                      element.name = value;
                    });
                  },
                );
              }

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _addElementWithCommand(ElementData element) {
    // Add the element with an undoable command
    historyManager.addElement(
      element.id,
      (id) {
        setState(() {
          elements.add(element);
        });
      },
      (id) {
        setState(() {
          elements.removeWhere((e) => e.id == id);
        });
      },
    );
  }

  void _removeElementWithCommand(ElementData element) {
    // Create a copy for undo
    final elementCopy = ElementData(
      id: element.id,
      name: element.name,
      type: element.type,
      position: element.position,
    );

    // Remove the element with an undoable command
    historyManager.removeElement(
      element.id,
      (id) {
        setState(() {
          // Also remove any relationships connected to this element
          for (final rel in element.relationships.toList()) {
            _removeRelationshipById(rel.id);
          }
          elements.removeWhere((e) => e.id == id);
        });
      },
      (id) {
        setState(() {
          elements.add(elementCopy);

          // Restore relationships
          for (final rel in elementCopy.relationships) {
            // Find the source and target elements
            final source = elements.firstWhere(
              (e) => e.id == rel.sourceId,
              orElse: () =>
                  throw Exception('Source element not found: ${rel.sourceId}'),
            );

            final destination = elements.firstWhere(
              (e) => e.id == rel.destinationId,
              orElse: () => throw Exception(
                  'Destination element not found: ${rel.destinationId}'),
            );

            // Recreate the relationship
            source.relationships.add(rel);
            destination.relationships.add(rel);
          }
        });
      },
    );
  }

  void _addRelationshipWithCommand(RelationshipData relationship) {
    // Add the relationship with an undoable command
    historyManager.addRelationship(
      relationship.id,
      relationship.sourceId,
      relationship.destinationId,
      (id, sourceId, destinationId) {
        setState(() {
          // Find the source and target elements
          final source = elements.firstWhere((e) => e.id == sourceId);
          final destination = elements.firstWhere((e) => e.id == destinationId);

          // Add the relationship to both elements
          source.relationships.add(relationship);
          destination.relationships.add(relationship);
        });
      },
      (id) {
        setState(() {
          _removeRelationshipById(id);
        });
      },
    );
  }

  void _removeRelationshipById(String id) {
    // Find elements with this relationship
    for (final element in elements) {
      element.relationships.removeWhere((r) => r.id == id);
    }
  }
}

/// A simple model class for diagram elements
class ElementData {
  final String id;
  String name;
  final ElementType type;
  Offset position;
  final List<RelationshipData> relationships = [];

  ElementData({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
  });
}

/// Types of elements
enum ElementType {
  person,
  system,
  container,
}

/// A simple model class for relationships
class RelationshipData {
  final String id;
  final String sourceId;
  final String destinationId;
  String description;

  RelationshipData({
    required this.id,
    required this.sourceId,
    required this.destinationId,
    required this.description,
  });
}

/// A custom painter for drawing relationships between elements
class RelationshipPainter extends CustomPainter {
  final List<ElementData> elements;

  RelationshipPainter({required this.elements});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    // Draw a line for each relationship
    for (final element in elements) {
      for (final relationship in element.relationships) {
        // Only draw the relationship from the source to avoid duplicates
        if (relationship.sourceId == element.id) {
          // Find the source and target elements
          final source =
              elements.firstWhere((e) => e.id == relationship.sourceId);
          final destination =
              elements.firstWhere((e) => e.id == relationship.destinationId);

          // Draw the line
          canvas.drawLine(
            source.position,
            destination.position,
            paint,
          );

          // Draw an arrow at the target end
          _drawArrow(
            canvas,
            source.position,
            destination.position,
            arrowPaint,
          );

          // Draw the relationship description
          _drawRelationshipText(
            canvas,
            source.position,
            destination.position,
            relationship.description,
          );
        }
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Calculate the arrow direction
    final direction = (end - start).normalize();

    // Calculate perpendicular vectors for the arrow head
    final perpendicular = Offset(-direction.dy, direction.dx) * 5.0;

    // Calculate the arrow head points
    final arrowTip = end - direction * 15.0;
    final arrowCorner1 = arrowTip - direction * 8.0 + perpendicular;
    final arrowCorner2 = arrowTip - direction * 8.0 - perpendicular;

    // Draw the arrow head
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowCorner1.dx, arrowCorner1.dy)
      ..lineTo(arrowCorner2.dx, arrowCorner2.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawRelationshipText(
      Canvas canvas, Offset start, Offset end, String text) {
    // Calculate the midpoint of the line
    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // Create a text painter
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw a white background for the text
    final backgroundRect = Rect.fromCenter(
      center: midpoint,
      width: textPainter.width + 6,
      height: textPainter.height + 4,
    );

    canvas.drawRect(
      backgroundRect,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Draw the text
    textPainter.paint(
      canvas,
      Offset(
        midpoint.dx - textPainter.width / 2,
        midpoint.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint when the state changes
  }
}
